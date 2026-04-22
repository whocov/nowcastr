#' Evaluate Nowcasting Performance
#'
#' Evaluates the historical performance of `nowcast_cl()` by repeatedly
#' peeling back the most recent reporting period and comparing predictions
#' against the last reported values (highest `col_date_reporting`
#' per occurrence date).
#'
#' @param n_past Integer. Number of past reporting periods to evaluate.
#'   Each iteration peels off one reporting period (in `time_units`).
#' @inheritParams nowcast_cl
#'
#' @return An S7 object of class \link{nowcast_eval_results}.
#'
#' @examples
#' input <- generate_test_data()
#' eval_res <- nowcast_eval(
#'   df = input,
#'   col_date_occurrence = date_occurrence,
#'   col_date_reporting = date_report,
#'   col_value = value,
#'   n_past = 10,
#'   time_units = "days"
#' )
#'
#' @import dplyr
#' @importFrom rlang := !! enquo syms as_name
#' @importFrom cli cli_progress_bar cli_progress_update cli_progress_done
#' @importFrom stats median quantile
#'
#' @export
nowcast_eval <- function(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL,
  n_past = 10,
  time_units = "days",
  max_delay = NULL,
  max_reportunits = 10,
  max_completeness = 5,
  min_completeness_samples = 1,
  use_weighted_method = TRUE,
  do_propagate_missing_delays = FALSE,
  do_model_fitting = TRUE,
  model_names = c(
    "monomolecular", "vonbertalanffy",
    "logistic", "gompertz",
    "asymptotic", "linear"
  ),
  do_use_modelled_completeness = TRUE,
  rss_threshold = 1e-2
) {
  time_start <- Sys.time()

  ## CAPTURE COLUMN NAMES -----
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  s_col_val <- rlang::sym(str_col_val)
  s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list() else rlang::syms(group_cols)

  ## INPUT VALIDATION -----
  stopifnot(
    "df must be a data.frame or tibble" = is.data.frame(df),
    "n_past must be a positive integer" = is.numeric(n_past) && n_past >= 1
  )
  if (!inherits(df[[str_col_rep]], "Date")) {
    rlang::abort(paste0("col_date_reporting must be Date class: ", str_col_rep))
  }

  ## GROUND TRUTH -----
  ## For each occurrence date (+ groups), the 'true value' is the one reported
  ## at the highest col_date_reporting — i.e. what was eventually fully reported.
  df_truth <-
    df %>%
    arrange(!!!s_group_cols, !!s_col_occ, !!s_col_rep) %>%
    group_by(!!!s_group_cols, !!s_col_occ) %>%
    slice_tail(n = 1) %>%
    ungroup() %>%
    select(!!!s_group_cols, !!s_col_occ, value_true = !!s_col_val)

  ## LIST OF REPORTING PERIODS TO PEEL -----
  ## sorted descending: most recent first, we go n_past steps back
  all_rep_dates <- sort(unique(df[[str_col_rep]]), decreasing = TRUE)

  ## remove the most recent reporting date:
  ## accuracy at that date is trivially 100% (no future to compare against)
  all_rep_dates <- all_rep_dates[-1]

  ## -1 is because we cannot run nowcating when only 1 reporting period is left
  max_npast <- length(all_rep_dates) - 1
  if (n_past > max_npast) {
    rlang::warn(paste0(
      "n_past (", n_past, ") exceeds available reporting periods (",
      length(all_rep_dates), "). Will be using the max available instead: ", max_npast
    ))
    n_past <- max_npast
  }

  list_cut_dates <- all_rep_dates[seq_len(n_past)]

  ## LOOP -----
  cli::cli_progress_bar(
    name = "Evaluating nowcast",
    total = n_past,
    format = "{cli::pb_name} {cli::pb_bar} {cli::pb_current}/{cli::pb_total} | ETA: {cli::pb_eta}"
  )

  list_results <- vector("list", n_past)

  for (i in seq_along(list_cut_dates)) {
    cut_date <- list_cut_dates[[i]]

    ## PEEL: keep only data up to cut_date
    df_peeled <- df %>% filter(!!s_col_rep <= cut_date)

    ## RUN NOWCAST
    nc_obj <-
      tryCatch(
        nowcast_cl(
          df = df_peeled,
          col_date_occurrence = !!rlang::sym(str_col_occ),
          col_date_reporting = !!rlang::sym(str_col_rep),
          col_value = !!rlang::sym(str_col_val),
          group_cols = group_cols,
          time_units = time_units,
          max_delay = max_delay,
          max_reportunits = max_reportunits,
          max_completeness = max_completeness,
          min_completeness_samples = min_completeness_samples,
          use_weighted_method = use_weighted_method,
          do_propagate_missing_delays = do_propagate_missing_delays,
          do_model_fitting = do_model_fitting,
          model_names = model_names,
          do_use_modelled_completeness = do_use_modelled_completeness,
          rss_threshold = rss_threshold
        ),
        error = function(e) {
          rlang::warn(paste("SILENCED ERROR:", conditionMessage(e)))
          NULL
        }
      )

    if (!is.null(nc_obj)) {
      nc <- nc_obj@results
      nc$cut_date <- cut_date
      list_results[[i]] <- nc
    }

    cli::cli_progress_update()
  }

  cli::cli_progress_done()

  ## ASSEMBLE ALL PREDICTIONS -----
  df_all <- dplyr::bind_rows(list_results)

  if (nrow(df_all) == 0) {
    rlang::abort("No successful nowcast runs. Check your data or parameters.")
  }

  ## JOIN GROUND TRUTH -----
  df_detail <-
    df_all %>%
    left_join(df_truth, by = c(group_cols, str_col_occ)) %>%
    ## remove the cut_date == max reporting date rows: trivially perfect
    filter(.data$cut_date < max(df[[str_col_rep]])) %>%
    mutate(
      ## sMAPE-style: Symmetric Absolute Percentage Error (per prediction)
      ## Formula: |pred - true| / (|pred| + |true|)
      ## Bounded [0, 1]; handles zeros symmetrically
      SAPE_pred = abs(.data$value_predicted - .data$value_true) / (abs(.data$value_predicted) + abs(.data$value_true)),
      SAPE_obs = abs(!!s_col_val - .data$value_true) / (abs(!!s_col_val) + abs(.data$value_true)),
      SAPE_improvement = .data$SAPE_obs - .data$SAPE_pred,
      ## Pairwise: is prediction closer to truth than raw observed?
      isWin = dplyr::case_when(
        abs(.data$value_predicted - .data$value_true) < abs(!!s_col_val - .data$value_true) ~ 1L, # TRUE
        abs(.data$value_predicted - .data$value_true) > abs(!!s_col_val - .data$value_true) ~ 0L, # FALSE
        TRUE ~ NA_integer_ ## tie
      )
    ) %>%
    arrange(!!!s_group_cols, !!s_col_occ, .data$cut_date, .data$delay) %>%
    select(-"completeness") %>%
    select(
      all_of(group_cols),
      "cut_date",
      all_of(str_col_occ),
      "last_r_date",
      all_of(str_col_val),
      "value_predicted",
      "value_true",
      everything()
    )

  ## SUMMARY BY GROUP x DELAY -----
  df_summary <-
    df_detail %>%
    # nowcast_eval_summarise()
    group_by(!!!s_group_cols, .data$delay) %>%
    reframe(
      n_periods = dplyr::n_distinct(.data$cut_date),
      n_obs = dplyr::n(),

      # SMAPE_pred = mean(.data$SAPE_pred[is.finite(.data$SAPE_pred)], na.rm = TRUE),
      # SMAPE_obs = mean(.data$SAPE_obs[is.finite(.data$SAPE_obs)], na.rm = TRUE),

      ## median + IQR
      # smape_diff_n = sum(!is.na(.data$SAPE_improvement[is.finite(.data$SAPE_improvement)])),
      smape_diff_med = stats::median(.data$SAPE_improvement[is.finite(.data$SAPE_improvement)], na.rm = TRUE),
      smape_diff_q1 = stats::quantile(.data$SAPE_improvement[is.finite(.data$SAPE_improvement)], .25, na.rm = TRUE),
      smape_diff_q3 = stats::quantile(.data$SAPE_improvement[is.finite(.data$SAPE_improvement)], .75, na.rm = TRUE),

      ## winrate + Wilson score 95% CI
      winrate = mean(.data$isWin, na.rm = TRUE),
      .p = .data$winrate,
      .z = stats::qnorm(0.975),
      .n = sum(!is.na(.data$isWin)), ## n_pairs
      winrate_low = (.data$.p + .data$.z^2 / (2 * .data$.n) -
        .data$.z * sqrt((.data$.p * (1 - .data$.p) + .data$.z^2 / (4 * .data$.n)) / .data$.n)) /
        (1 + .data$.z^2 / .data$.n),
      winrate_high = (.data$.p + .data$.z^2 / (2 * .data$.n) +
        .data$.z * sqrt((.data$.p * (1 - .data$.p) + .data$.z^2 / (4 * .data$.n)) / .data$.n)) /
        (1 + .data$.z^2 / .data$.n),
    ) %>%
    select(-".p", -".z", -".n") %>%
    arrange(!!!s_group_cols, .data$delay)


  ## PARAMS -----
  params <- list(
    col_date_occurrence = str_col_occ,
    col_date_reporting = str_col_rep,
    col_value = str_col_val,
    group_cols = group_cols,
    n_past = n_past,
    time_units = time_units,
    max_delay = max_delay,
    max_reportunits = max_reportunits,
    max_completeness = max_completeness,
    min_completeness_samples = min_completeness_samples,
    use_weighted_method = use_weighted_method,
    do_propagate_missing_delays = do_propagate_missing_delays,
    do_model_fitting = do_model_fitting,
    model_names = model_names,
    do_use_modelled_completeness = do_use_modelled_completeness,
    rss_threshold = rss_threshold
  )


  ## RETURN S7 OBJECT -----
  nowcast_eval_results(
    detail     = df_detail,
    summary    = df_summary,
    params     = params,
    n_past     = as.integer(n_past),
    time_start = time_start,
    time_end   = Sys.time()
  )
}





#' S7 object class for Nowcast Evaluation Results
#'
#' The object returned by \code{\link{nowcast_eval}}. It is an S7 class with
#' the following slots (accessible with \code{@}):
#'
#' \describe{
#'   \item{detail}{data.frame with per-prediction errors (observed, predicted, last reported values).}
#'   \item{summary}{data.frame with aggregated SMAPE and winrate, by group and delay.}
#'   \item{params}{list of parameters used.}
#'   \item{n_past}{number of past periods evaluated.}
#'   \item{time_start}{POSIXct start time.}
#'   \item{time_end}{POSIXct end time.}
#' }
#'
#' @usage nowcast_eval_results(detail, summary, params, n_past, time_start, time_end)
#'
#' @param detail data.frame.
#' @param summary data.frame.
#' @param params list.
#' @param n_past integer.
#' @param time_start POSIXct.
#' @param time_end POSIXct.
#'
#' @return An S7 object of class `nowcast_eval_results`.
#' @seealso \code{\link{nowcast_eval}}, \code{\link{plot_nowcast_eval}},
#'   \code{\link{plot_nowcast_eval_by_delay}}, \code{\link{plot_nowcast_eval_detail}}
#'
#' @examples
#' input <- generate_test_data()
#' eval_res <- nowcast_eval(
#'   df = input,
#'   col_date_occurrence = date_occurrence,
#'   col_date_reporting = date_report,
#'   col_value = value,
#'   n_past = 10,
#'   time_units = "days"
#' )
#'
#' # Access slots
#' eval_res@summary
#' eval_res@detail
#'
#' @importFrom S7 new_class class_list class_data.frame class_numeric class_POSIXct
#' @export
nowcast_eval_results <-
  S7::new_class("nowcast_eval_results",
    properties = list(
      detail     = S7::class_data.frame,
      summary    = S7::class_data.frame,
      params     = S7::class_list,
      n_past     = S7::class_numeric,
      time_start = S7::class_POSIXct,
      time_end   = S7::class_POSIXct
    )
  )


#' Plot Nowcast Evaluation Results
#'
#' Plots a horizontal bar chart of nowcasting evaluation metrics per group,
#' at a selected delay. Two panels are shown side by side:
#' \itemize{
#'   \item \strong{Differential SMAPE}: median per-prediction SMAPE difference
#'     (obs minus pred; positive = prediction is better), with IQR as error bar.
#'   \item \strong{winrate}: share of past periods where prediction beat
#'     raw observed, centered at 0 (0.5 = no improvement), with Wilson 95% CI.
#' }
#' Bars are coloured by whether the improvement is significant (IQR / CI fully
#' above or below zero) or not.
#'
#' @param x A `nowcast_eval_results` S7 object from `nowcast_eval()`.
#' @param delay Numeric. Which delay to plot. Defaults to the minimum delay in the data if missing.
#' @param color_good Character. Colour for significantly better predictions.`.
#' @param color_bad  Character. Colour for significantly worse predictions.`.
#' @param alpha_less alpha value for the "less significant" bars, 0-1.
#' @param ... Ignored.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' input <- generate_test_data()
#' eval_res <- nowcast_eval(
#'   df = input,
#'   col_date_occurrence = date_occurrence,
#'   col_date_reporting = date_report,
#'   col_value = value,
#'   n_past = 10,
#'   time_units = "days"
#' )
#' plot(eval_res)
#' plot(eval_res, delay = 2)
#'
#' @import ggplot2
#' @importFrom dplyr filter mutate bind_rows select all_of
#' @importFrom rlang .data
#' @importFrom scales percent alpha
#'
#' @export
plot_nowcast_eval <- function(
  x,
  delay = NULL,
  color_good = "dodgerblue1",
  color_bad = "firebrick1",
  alpha_less = .35,
  ...
) {
  ## VALIDATE -----
  if (!S7::S7_inherits(x, nowcast_eval_results)) {
    rlang::abort("x must be a nowcast_eval_results object.")
  }

  ## SELECT DELAY -----
  if (is.null(delay)) delay <- min(x@summary$delay, na.rm = TRUE)
  if (!delay %in% x@summary$delay) {
    rlang::abort(paste0(
      "delay ", delay, " not found. Available: ",
      paste(sort(unique(x@summary$delay)), collapse = ", ")
    ))
  }

  ## FILTER SUMMARY TO SELECTED DELAY -----
  group_cols <- x@params$group_cols
  df <- x@summary %>% dplyr::filter(.data$delay == !!delay)

  ## BUILD Y-AXIS LABEL -----
  if (!is.null(group_cols) && length(group_cols) > 0) {
    df <- df %>%
      dplyr::mutate(.y = do.call(paste, c(dplyr::across(dplyr::all_of(group_cols)), sep = " | ")))
  } else {
    df <- df %>% dplyr::mutate(.y = "all")
  }


  ## BUILD TWO INDICATOR DATA FRAMES THEN BIND -----
  df_smape <-
    df %>%
    dplyr::mutate(
      indicator = "dsmape",
      value = .data$smape_diff_med,
      low = .data$smape_diff_q1,
      high = .data$smape_diff_q3,
    ) %>%
    dplyr::select("indicator", "value", "low", "high", ".y")

  df_winrate <-
    df %>%
    dplyr::mutate(
      indicator = "winrate",
      value = .data$winrate - 0.50, ## to center on 0
      low = .data$winrate_low - 0.50, ## to center on 0
      high = .data$winrate_high - 0.50, ## to center on 0
    ) %>%
    dplyr::select("indicator", "value", "low", "high", ".y")

  df_plot <-
    dplyr::bind_rows(df_smape, df_winrate) %>%
    ## SIGNIFICANCE COLOUR
    ## good     = value >= 0 and low >= 0  (interval fully above zero)
    ## lessgood = value >= 0 and low <  0  (positive but interval crosses zero)
    ## bad      = value <  0 and high <= 0  (interval fully below zero)
    ## lessbad  = value <  0 and high >  0  (negative but interval crosses zero)
    dplyr::mutate(
      .fill = dplyr::case_when(
        .data$value >= 0 & .data$low >= 0 ~ "good",
        .data$value >= 0 & .data$low < 0 ~ "lessgood",
        .data$value < 0 & .data$high <= 0 ~ "bad",
        TRUE ~ "lessbad"
      )
    )

  n_periods <- df$n_periods[[1]]

  ## PLOT -----
  ggplot2::ggplot(df_plot, ggplot2::aes(x = .data$value, y = .data$.y)) +
    ggplot2::geom_col(ggplot2::aes(fill = .data$.fill)) +
    ggplot2::scale_fill_manual(
      values = c(
        "good"     = color_good,
        "lessgood" = scales::alpha(color_good, alpha_less),
        "bad"      = color_bad,
        "lessbad"  = scales::alpha(color_bad, alpha_less)
      ),
      labels = c(
        "good"     = "Better (significant)",
        "lessgood" = "Better (not significant)",
        "bad"      = "Worse (significant)",
        "lessbad"  = "Worse (not significant)"
      ),
      name = NULL,
      drop = FALSE
    ) +
    ## error bars: white outline for contrast, then grey on top
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$low, xend = .data$high, yend = .data$.y),
      colour = "white", linewidth = 1.4
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$low, xend = .data$high, yend = .data$.y),
      colour = "#555555", linewidth = 0.9
    ) +
    ggplot2::geom_vline(xintercept = 0, linetype = "22", alpha = 0.7) +
    ggplot2::facet_wrap(
      ~indicator,
      scales = "free_x",
      labeller = ggplot2::labeller(indicator = c(
        "dsmape" = "Differential sMAPE", # expression(Delta * sMAPE),
        "winrate" = "Win Rate - 50%"
      ))
    ) +
    #
    # ggh4x::facetted_pos_scales(
    #   x = list(
    #     indicator == "winrate" ~ scale_x_continuous(
    #       labels = function(x) scales::percent(x + 0.5)
    #     ),
    #     indicator == "dsmape" ~ scale_x_continuous(
    #       labels = scales::percent
    #     )
    #   )
    # ) +
    ggplot2::scale_x_continuous(labels = scales::percent) +
    ggplot2::labs(
      title = paste0("Nowcast evaluation at delay = ", delay),
      subtitle = paste0("Repeated over ", n_periods, " past reporting periods"),
      x = NULL,
      y = NULL
    ) +
    theme_nowcastr() +
    ggplot2::theme(
      legend.position = "top",
      # strip.text       = ggplot2::element_text(face = "bold"),
      # panel.grid.minor = ggplot2::element_blank()
    )
}


# ### S3 WRAPPER
# # @return A ggplot object.

# #' @rdname plot.nowcast_eval_results
# #' @param x A `nowcast_eval_results` object.
# #' @usage \method{plot}{nowcast_eval_results}(x, delay, ...)
# #' @return A ggplot object.
# #' @importFrom S7 S7_dispatch
# #' @export
# plot.nowcast_eval_results <- function(
#   x,
#   delay = NULL,
#   ...
# ) {
#   S7::S7_dispatch()
# }

#' Plotting method for nowcasting eval results
#'
#' @name plot.nowcast_eval_results
#' @param x A `nowcast_eval_results` object.
#' @param delay Integer. Delay to plot.
#' @importFrom graphics plot
#' @noRd
S7::method(plot, nowcast_eval_results) <- function(x, delay = NULL, ...) {
  plot_nowcast_eval(x, delay = delay, ...)
}


#' Plot Nowcast Evaluation by Delay
#'
#' Plots evaluation metric as a function of delay, faceted by group.
#' The y-axis shows how much the nowcast improves over raw observed values,
#' across all delays. Background shading indicates the direction of improvement.
#'
#' @param x A `nowcast_eval_results` S7 object from `nowcast_eval()`.
#' @param indicator Character. Which metric to plot on the y-axis. One of:
#'   `"smape_diff_med"`, or `"winrate"`.
#' @param color_good Character. Fill colour for the "better" region.`.
#' @param color_bad  Character. Fill colour for the "worse" region.`.
#' @param ... Ignored.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' input <- generate_test_data()
#' eval_res <- nowcast_eval(
#'   df = input,
#'   col_date_occurrence = date_occurrence,
#'   col_date_reporting = date_report,
#'   col_value = value,
#'   n_past = 10,
#'   time_units = "days"
#' )
#' plot_nowcast_eval_by_delay(eval_res)
#' plot_nowcast_eval_by_delay(eval_res, indicator = "winrate")
#'
#' @import ggplot2
#' @importFrom dplyr filter
#' @importFrom rlang .data sym
#' @importFrom scales percent
#'
#' @export
plot_nowcast_eval_by_delay <- function(
  x,
  indicator = "smape_diff_med",
  color_good = "dodgerblue1",
  color_bad = "firebrick1",
  ...
) {
  ## VALIDATE -----
  if (!S7::S7_inherits(x, nowcast_eval_results)) {
    rlang::abort("x must be a nowcast_eval_results object.")
  }
  valid_indicators <- c("smape_diff_med", "winrate")
  indicator <- match.arg(indicator, valid_indicators)

  ## midpoint: 0 for SMAPE indicators, 0.5 for proportion
  midpoint <- if (indicator == "winrate") 0.5 else 0

  group_cols <- x@params$group_cols

  ## FACET FORMULA -----
  facet <- if (!is.null(group_cols) && length(group_cols) > 0) {
    ggplot2::facet_wrap(group_cols, scales = "fixed")
  } else {
    NULL
  }

  ## Y-AXIS LABEL -----
  y_label <- switch(indicator,
    "smape_diff_med" = "Differential sMAPE",
    "winrate" = "Proportion of predictions better than observed"
  )

  ## PLOT -----
  ggplot2::ggplot(
    x@summary,
    ggplot2::aes(x = .data$delay, y = !!rlang::sym(indicator))
  ) +
    theme_nowcastr() +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = midpoint, ymax = Inf),
      fill = color_good, alpha = 0.15
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = midpoint, ymax = -Inf),
      fill = color_bad, alpha = 0.15
    ) +
    ggplot2::geom_hline(yintercept = midpoint, linetype = "22", alpha = 0.6) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::scale_y_continuous(labels = scales::percent) +
    facet +
    ggplot2::labs(
      title = paste0("Nowcast evaluation by delay"),
      subtitle = paste0("Repeated over ", max(x@summary$n_periods, na.rm = TRUE), " past reporting periods"),
      x = paste0("Delay (", x@params$time_units, ")"),
      y = y_label
    ) +
    ggplot2::theme(
      # strip.text       = ggplot2::element_text(face = "bold"),
      # panel.grid.minor = ggplot2::element_blank()
    )
}


#' Plot Nowcast Evaluation Detail Over Time
#'
#' For a selected delay, plots predicted and observed values over time alongside
#' the last reported value. Vertical segments show which estimate (raw observed
#' or predicted) was closer to truth for each occurrence date.
#'
#' @param x A `nowcast_eval_results` S7 object from `nowcast_eval()`.
#' @param delay Numeric. Which delay to plot. Defaults to the minimum delay in the data if missing.
#' @param color_good Character. Colour when prediction beats raw observed.`.
#' @param color_bad  Character. Colour when raw observed beats prediction.`.
#' @param ... Ignored.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' input <- generate_test_data()
#' eval_res <- nowcast_eval(
#'   df = input,
#'   col_date_occurrence = date_occurrence,
#'   col_date_reporting = date_report,
#'   col_value = value,
#'   n_past = 10,
#'   time_units = "days"
#' )
#' plot_nowcast_eval_detail(eval_res)
#' plot_nowcast_eval_detail(eval_res, delay = 7)
#'
#' @import ggplot2
#' @importFrom dplyr filter mutate
#' @importFrom rlang .data
#'
#' @export
plot_nowcast_eval_detail <- function(
  x,
  delay = NULL,
  color_good = "dodgerblue1",
  color_bad = "firebrick1",
  ...
) {
  ## VALIDATE -----
  if (!S7::S7_inherits(x, nowcast_eval_results)) {
    rlang::abort("x must be a nowcast_eval_results object.")
  }

  ## SELECT DELAY -----
  if (is.null(delay)) delay <- min(x@detail$delay, na.rm = TRUE)
  if (!delay %in% x@detail$delay) {
    rlang::abort(paste0(
      "delay ", delay, " not found. Available: ",
      paste(sort(unique(x@detail$delay)), collapse = ", ")
    ))
  }

  group_cols <- x@params$group_cols
  str_col_occ <- x@params$col_date_occurrence
  str_col_val <- x@params$col_value

  ## FILTER AND PREP -----
  df <- x@detail %>%
    dplyr::filter(.data$delay == !!delay) %>%
    dplyr::mutate(
      ## segment endpoint: the worse of the two estimates (furthest from truth)
      ## NA (no segment) when both estimates are equally wrong
      .seg_yend = dplyr::case_when(
        abs(.data[[str_col_val]] - .data$value_true) == abs(.data$value_predicted - .data$value_true) ~ NA_real_,
        abs(.data[[str_col_val]] - .data$value_true) < abs(.data$value_predicted - .data$value_true) ~ .data[[str_col_val]],
        TRUE ~ .data$value_predicted
      ),
      .seg_color = dplyr::case_when(
        abs(.data[[str_col_val]] - .data$value_true) == abs(.data$value_predicted - .data$value_true) ~ NA_character_,
        abs(.data[[str_col_val]] - .data$value_true) < abs(.data$value_predicted - .data$value_true) ~ "bad",
        TRUE ~ "good"
      )
    )

  ## FACET -----
  facet <- if (!is.null(group_cols) && length(group_cols) > 0) {
    ggplot2::facet_wrap(group_cols, scales = "free")
  } else {
    NULL
  }

  ## PLOT -----
  ggplot2::ggplot(df, ggplot2::aes(x = .data[[str_col_occ]])) +
    theme_nowcastr() +
    ggplot2::geom_segment(
      data = ~ dplyr::filter(.x, !is.na(.data$.seg_yend)),
      ggplot2::aes(
        xend   = .data[[str_col_occ]],
        y      = .data$value_true,
        yend   = .data$.seg_yend,
        color  = .data$.seg_color
      ),
      linewidth = 3
    ) +
    ggplot2::scale_color_manual(
      values = c(good = color_good, bad = color_bad),
      labels = c(good = "Prediction better", bad = "Observed better"),
      name   = "Absolute Error"
    ) +
    ggplot2::geom_line(ggplot2::aes(y = .data[[str_col_val]]), color = color_bad, alpha = 0.8) +
    ggplot2::geom_line(ggplot2::aes(y = .data$value_predicted), color = color_good, linetype = "3131") +
    ggplot2::geom_line(ggplot2::aes(y = .data$value_true), color = "black") +
    ggplot2::geom_point(ggplot2::aes(y = .data$value_true), color = "black") +
    facet +
    ggplot2::labs(
      title = paste0("Nowcast evaluation detail at delay = ", delay),
      subtitle = paste0("Solid Black = last reported values  |  Dashed Blue = predicted values  |  Solid Red = raw observed values"),
      x = "Date of Occurence",
      y = "Value",
      color = "Absolute Error",
    ) +
    ggplot2::theme(
      legend.position = "top"
    )
}
