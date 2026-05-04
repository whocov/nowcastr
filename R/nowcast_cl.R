#' Nowcasting with Chain-Ladder Method
#'
#' Performs nowcasting using non-cumulative Chain-Ladder Method.
#' Input dataset with 2 date columns; 1 value column; and a flexible number of group columns.
#' Output dataset with latest reported data joined with `completeness` ratio and final `value_predicted`.
#' You have the option to use model-free completeness ratio calculation or use model-fitted completeness.
#'
#' @param df A data.frame or tibble.
#' @param col_date_occurrence Column name for the date of occurrence/reference.
#' @param col_date_reporting Column name for the date of reporting.
#' @param col_value Column name for the value.
#' @param group_cols Optional character vector of column names for grouping.
#' @param time_units Time unit for delay calculation.
#'   Accepted values: ("auto", "secs", "mins", "hours", "days", "weeks").
#' @param max_delay Max delay to keep in the analysis. Interger or NULL.
#'   If NULL, will take the max delay from the data.
#' @param max_reportunits Max number of col_date_reporting to use (in the unit of time_units).
#' @param max_completeness Maximum completeness ratio (e.g., 2 = 200%).
#' @param min_completeness_samples Min number of samples required to calculate completeness.
#'   Integer from 1 to max_reportunits.
#' @param use_weighted_method Use weighted method, linear weight to older reported completeness values
#' @param do_propagate_missing_delays Fill missing completeness if lower delay has a value.
#' @param do_model_fitting Fit a model through the completeness by delay.
#'   Models are useful for indicators like 'time to 95% compl.' and also soften variability.
#' @param model_names Character vector with names of the models to test for best fit.
#'   Accepted values: "monomolecular", "vonbertalanffy", "logistic", "gompertz", "asymptotic", "linear"
#' @param do_use_modelled_completeness Use the modelled completeness values for the nowcasting.
#'   Boolean or NULL (for auto selective).  (unused if do_model_fitting=FALSE)
#' @param rss_threshold Minimum RSS threshold to use model-fitted values.
#'   Only used if do_use_modelled_completeness is NULL.
#'   If the RSS of the fit is higher than this then observed completeness is used for nowcasting.
#'
#' @return Returns an \bold{S7 object} of class \code{nowcast_results}.
#' This object serves as a comprehensive container for the analysis results and
#' metadata. Use the \code{@results} slot to access the primary prediction
#' data frame.
#'
#' The object includes:
#' \itemize{
#'   \item \bold{Predictions}: The \code{results} slot contains the latest
#'   observed values, the calculated \code{completeness} ratio, and the
#'   \code{value_predicted}.
#'   \item \bold{Calculation}: Predictions are derived using
#'   \eqn{value\_predicted = value / completeness}.
#'   \item \bold{Metadata}: Slots for \code{params}, \code{time_start},
#'   \code{max_delay}, and model diagnostics (\code{RSS}).
#' }
#'
#' @examples
#' input <- generate_test_data()
#' res <- input %>%
#'   nowcast_cl(
#'     col_date_occurrence = date_occurrence,
#'     col_date_reporting = date_report,
#'     col_value = value,
#'     time_units = "days"
#'   )
#'
#' # Access the predicted data:
#' head(res@results)
#'
#' @importFrom magrittr %>%
#' @importFrom rlang := !! enquo syms as_name .data
#' @importFrom dplyr filter mutate group_by ungroup arrange select
#' @importFrom dplyr left_join summarise last desc slice_max
#' @importFrom tidyr complete fill nest
#' @importFrom purrr map_dbl
#' @importFrom stats residuals weighted.mean
#' @importFrom utils head capture.output
#'
#' @export
nowcast_cl <- function(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL,
  time_units = "days",
  max_delay = NULL,
  #  max_delay = 12,
  max_reportunits = 10,
  #  max_yw_lookback = 12,
  max_completeness = 5,
  min_completeness_samples = 1, ## int from 1 to max_reportunits
  use_weighted_method = TRUE, ## method to alleviate BIAS1, more weight to older reported completeness
  do_propagate_missing_delays = FALSE,
  do_model_fitting = TRUE, ## flag we want to model completeness distribution
  model_names = c(
    "monomolecular", "vonbertalanffy",
    "logistic", "gompertz",
    "asymptotic", "linear"
  ),
  do_use_modelled_completeness = TRUE,
  rss_threshold = 1e-2
  #
) {
  time_start <- Sys.time() ## save start time


  ## ARGS THAT ARE FIXED FOR NOW, NOT AN OPTION
  do_delay_asnumeric <- TRUE
  # @param prediction_date_method Wich date to "by_group" / "by_occ_date". By groups or by groups and occurrence date.
  prediction_date_method <- "by_group"

  ### PREP INPUT -----
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  # s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols) ## this would create column `1`
  s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list() else rlang::syms(group_cols)


  if (!do_model_fitting) do_use_modelled_completeness <- FALSE ## force value

  ### INPUT VALIDATION -----
  valid_modelnames <- c("monomolecular", "vonbertalanffy", "logistic", "gompertz", "asymptotic", "linear")
  valid_t_units <- c("auto", "secs", "mins", "hours", "days", "weeks")
  time_units <- match.arg(time_units, valid_t_units, several.ok = FALSE)
  model_names <- match.arg(model_names, valid_modelnames, several.ok = TRUE)
  stopifnot(
    "col_value is not in the data" = str_col_val %in% names(df),
    "col_date_occurrence is not in the data" = str_col_occ %in% names(df),
    "col_date_reporting is not in the data" = str_col_rep %in% names(df),
    "The data is empty" = nrow(df) > 0,
    "col_date_reporting should never be < col_date_occurrence" = nrow(df %>% filter(!!s_col_occ <= !!s_col_rep)) != 0
  )
  if (max_completeness < 1) rlang::abort("max_completeness must be >= 1")
  if (min_completeness_samples < 1) rlang::abort("min_completeness_samples must be >= 1")
  if (min_completeness_samples > max_reportunits) rlang::abort("min_completeness_samples must be <= max_reportunits")
  if (!is.null(max_delay) && (!is.numeric(max_delay) || max_delay < 1)) rlang::abort("max_delay must be NULL or numeric >= 1")

  ## check that columns are dates
  bad_cols <- character()
  if (!inherits(df[[str_col_occ]], "Date")) bad_cols <- c(bad_cols, str_col_occ)
  if (!inherits(df[[str_col_rep]], "Date")) bad_cols <- c(bad_cols, str_col_rep)
  if (length(bad_cols) > 0) {
    rlang::abort(paste0("Validation error: column(s) must be Date class: ", paste(bad_cols, collapse = ", ")))
  }

  ## check and abort early if any occurrence date is after report date
  n_bad <- nrow(df %>% filter(!!s_col_occ > !!s_col_rep))
  if (n_bad > 0) {
    bad_sample <- df %>%
      filter(!!s_col_occ > !!s_col_rep) %>%
      utils::head(5)
    rlang::abort(
      paste0(
        "Validation error: ", n_bad, " rows with date_occ > date_rep. Examples:\n",
        paste(utils::capture.output(print(bad_sample)), collapse = "\n")
      )
    )
  }
  ## check minimum number of reporting dates
  if (dplyr::n_distinct(df[[str_col_rep]]) < 2) {
    rlang::abort("Insufficient reporting history: at least 2 distinct reporting dates are required.")
  }
  ## end of input validation


  ## calculate the number of groups
  n_groups <- ifelse((is.null(group_cols) | length(group_cols) == 0),
    1, nrow(df %>% distinct(!!!s_group_cols))
  )
  ## unused atm:
  # max_rwk = max(df[[str_col_rep]])
  # min_rwk = min(df[[str_col_rep]])
  # max_ywk = max(df[[str_col_occ]])
  # min_ywk = min(df[[str_col_occ]])


  ### ORDER & SELECT COLUMNS -----
  df <- df %>%
    select(!!!s_group_cols, !!s_col_occ, !!s_col_rep, !!s_col_val)


  ### CALCULATE DELAYS -----
  df_data_delays <- df %>%
    calc_delay(!!s_col_occ, !!s_col_rep,
      units = time_units, as_difftime = !do_delay_asnumeric
    )

  if (exists("verbose") && verbose) print(df_data_delays)

  ### SET AUTO MAX DELAY -----
  if (is.null(max_delay)) {
    max_delay <- max(df_data_delays$delay)
    if (exists("verbose") && verbose) message("max_delay set to ", max_delay)
  }

  list_delays_input <- sort(unique(df_data_delays$delay))
  min_delay <- min(list_delays_input)

  ### VALIDATION -----
  check_delays(list_delays_input)
  # print(list_delays_input)


  ## MAKE A THEORETICAL LIST OF DELAYS FROM MIN-MAX ---
  ## if some delays are missing then we add them here
  ## this will be used for model fitting

  list_delays <- as.difftime((as.numeric(min_delay)):as.numeric(max_delay), units = time_units)
  if (do_delay_asnumeric) {
    list_delays <- as.numeric(list_delays)
  }

  ## this can increase the number of delays.
  ## e.g. c(0,7,14) -> c(0,1,2,3,4,..., 14)
  # -> smoother fits


  # todo: optimisation
  # trim data to speed up calculations
  # df_data_delays <- df_data_delays %>% filter(as.numeric(.data$delay) <= max_delay + 2)
  # (2 is minimum to not impact df_completeness_details, to verify)

  ### CALCULATE COMPLETENESS -----
  df_completeness_details <-
    df_data_delays %>%
    ## LAST VALUE ---
    arrange(!!!s_group_cols, !!s_col_occ, !!s_col_rep) %>% ## very important to have !!s_col_rep ordered asc, for last()
    group_by(!!!s_group_cols, !!s_col_occ) %>%
    mutate(last_value = last(!!s_col_val)) %>%
    ## remove the last reported; because completeness is always 100%
    ## BIAS1: the last reported is only a clear one to remove, the bias is 100%
    ## but the reports before that has also overestimated completeness
    ## the more recent the reports, the more bias
    # filter(!!s_col_rep != max(!!s_col_rep), ) %>%
    ungroup() %>%
    ## COMPLETENESS ---
    mutate(completeness = ifelse(!!s_col_val == .data$last_value, 1, !!s_col_val / .data$last_value)) %>% ## takes care of 0/0
    mutate(completeness = pmin(.data$completeness, max_completeness)) %>% ## handless n/0=Inf + cap extremes
    arrange(!!!s_group_cols, desc(!!s_col_occ), desc(!!s_col_rep))

  ### ADD REPORTWEIGHT -----
  ## method to mitigate BIAS1
  if (use_weighted_method) {
    df_completeness_details <-
      df_completeness_details %>%
      mutate(
        .by = c(!!!s_group_cols),
        last_r_date = max(!!s_col_rep),
      ) %>%
      mutate(
        reportweight = as.numeric(difftime(.data$last_r_date, !!s_col_rep, units = time_units)),
        # reportweight = .data$reportweight + 1,
      ) %>%
      select(-"last_r_date")
  } else {
    df_completeness_details <-
      df_completeness_details %>%
      group_by(!!!s_group_cols, !!s_col_occ) %>%
      ## remove the most recent report
      filter(!!s_col_rep != max(!!s_col_rep), ) %>%
      ungroup()
  }


  ### AGGREGATE BY DELAY -----
  df_completeness_observed <-
    df_completeness_details %>%
    ## 2 filters to select only trapeze of (max_delay x max_reportunits)
    filter(as.numeric(.data$delay) <= max_delay) %>%
    ## get the last report date, by groups+delay, but only up to max_reportunits
    ## (each group+delay, will have 10 different report dates)
    slice_max(!!s_col_rep, n = max_reportunits, by = c(!!!s_group_cols, "delay")) %>%
    group_by(!!!s_group_cols, .data$delay) %>%
    summarise(
      n = n(),
      completeness_avg = if (isTRUE(use_weighted_method)) stats::weighted.mean(.data$completeness, .data$reportweight, na.rm = TRUE) else mean(.data$completeness, na.rm = TRUE)
    ) %>%
    ungroup() %>%
    filter(n >= min_completeness_samples) ## default is 1 -> no impact
  ## NOTE: completeness_avg is slightly overstimated here; cf. BIAS1

  if (all(is.na(df_completeness_observed$completeness_avg) | is.nan(df_completeness_observed$completeness_avg))) {
    rlang::abort(
      c(
        "Insufficient reporting history: cannot calculate completeness.",
        i = "This usually happens when there is only 1 reporting date in the data, resulting in 0 weights."
      )
    )
  }

  ## OPTIONAL: PROPAGATE MISSING DELAYS ---
  # Since non-cumulative approach, sometimes there are delays with missing completeness.
  # If missing, we propagate (copy) completeness_avg value from lower delays to higher delays,
  # we can do this because we should theoretically not have unkown completeness_avg
  # for higher delays, should be at least the same as shorter delays.
  # The advantage is that this should work with bot increasing and decreasing completeness.
  # This is a minimum approximation.
  if (do_propagate_missing_delays) {
    df_completeness_observed <-
      df_completeness_observed %>%
      group_by(!!!s_group_cols) %>%
      tidyr::complete(!!!list(delay = list_delays)) %>% ## make sure they all exist
      arrange(!!!s_group_cols, .data$delay) %>%
      tidyr::fill("completeness_avg", .direction = "down") %>%
      ungroup()
  }


  ### MODEL FITTING -----
  if (do_model_fitting) {
    df_fit <-
      df_completeness_observed %>%
      rename(x = "delay", y = "completeness_avg") %>%
      mutate(x = as.numeric(.data$x)) %>%
      select(!!!s_group_cols, "x", "y") %>%
      # arrange(!!!s_group_cols, .data$x) %>%
      group_by(!!!s_group_cols) %>%
      tidyr::nest() %>% ## create data column
      mutate(
        fit = purrr::map(.data$data, ~ fit_models(.x, modelnames = model_names))
      ) %>%
      mutate(
        RSS = purrr::map_dbl(.data$fit, ~ if (inherits(.x, c("nls", "lm"))) sum(stats::residuals(.x)^2) else NA_real_),
        RSS = .data$RSS %>% signif(3),
        iterations = purrr::map_dbl(.data$fit, ~ if (inherits(.x, "nls")) .x$convInfo$finIter else NA_real_)
      ) %>%
      mutate(modelname = purrr::map_chr(.data$fit, detect_model_type)) %>%
      ungroup()

    ## compute t_to_95
    df_models <-
      df_fit %>%
      ## make discrete predictions in data.frame
      mutate(pred = purrr::map(.data$fit, predict_values_from_fit, alldelays = list_delays)) %>%
      mutate(t_to_95_model = purrr::map_dbl(.data$fit, get_time_to_95_105_precise)) %>%
      mutate(t_to_95_obs = purrr::map_dbl(.data$data, get_time_to_95_105_discrete))

    ## unnest modelled values
    df_completeness_modelled <-
      df_models %>%
      select(!!!s_group_cols, "pred") %>%
      tidyr::unnest("pred") %>%
      rename(delay = "x") %>%
      rename(completeness_modelled = "y") %>%
      filter(.data$delay %in% list_delays) %>%
      filter(.data$completeness_modelled > 0) %>% ## BOUNDARY
      filter(.data$completeness_modelled < max_completeness) %>% ## BOUNDARY
      arrange(!!!s_group_cols, .data$delay)
  }


  ### ASSEMBLE OBSERVED AND MODELLED, FOR EXPORT -----
  df_delays <- df_completeness_observed %>%
    rename(completeness_obs = "completeness_avg")

  if (do_model_fitting) {
    ## join observed and modelled values
    df_delays <-
      df_delays %>%
      full_join(
        ## unpack discrete predictions
        df_completeness_modelled %>%
          select(!!!s_group_cols, "delay", "completeness_modelled"),
        by = c(group_cols, "delay")
      )

    if (is.null(do_use_modelled_completeness)) {
      df_delays <- df_delays %>%
        mutate(used = if_else(.data$RSS > rss_threshold, "completeness_obs", "completeness_modelled"))
    }
  }


  ### SELECT THE COMPLETENESS TO USE, FOR NOWCASTING -----
  if (do_model_fitting && do_use_modelled_completeness) {
    ## always use modelled
    df_completeness_final <- df_completeness_modelled %>%
      rename(completeness = "completeness_modelled")
  } else if (do_model_fitting && is.null(do_use_modelled_completeness)) {
    ## selectively use modelled, based on rss_threshold
    df_completeness_final <-
      df_delays %>%
      left_join(
        ## unpack discrete predictions
        df_models %>%
          select(!!!s_group_cols, "RSS"),
        by = c(group_cols)
      ) %>%
      mutate(completeness = if_else(.data$RSS > rss_threshold, .data$RSScompleteness_obs, .data$RSScompleteness_modelled))
  } else {
    ## do not use modelled
    df_completeness_final <- df_completeness_observed %>%
      rename(completeness = "completeness_avg")
  }

  ### NOWCASTING -----
  df_nowcasting <-
    df %>%
    ## KEEP ONLY LATEST VALUES, BY GROUP AND OCCURRENCE
    filter(
      .by = c(!!!s_group_cols, !!s_col_occ),
      !!s_col_rep == max(!!s_col_rep),
    ) %>%
    {
      ## DEFINE THE DELAY
      # - method A / "by_occ_date"
      #   (occ - report date)
      #   with this,
      # - method B / "by_group"
      #   (occ - last report date by group) <- probably best, gives same prediction date for whole group
      #   it means that if a group has no data since a while,
      #   then we can still make a nowcasting prediction at that last report date
      if (prediction_date_method == "by_occ_date") { ## not recommended in most cases, should be very rarely used
        calc_delay(., !!s_col_occ, !!s_col_rep,
          units = time_units, as_difftime = !do_delay_asnumeric
        )
      } else if (prediction_date_method == "by_group") { ## recommended
        ## add date of prediction and delay with date of prediction
        mutate(.,
          .by = c(!!!s_group_cols),
          last_r_date = max(!!s_col_rep),
        ) %>%
          calc_delay(!!s_col_occ, "last_r_date",
            units = time_units, as_difftime = !do_delay_asnumeric
          ) %>%
          select(-!!s_col_rep)
      } else {
        .
      }
    } %>%
    ## CAP THE DELAY
    filter(.data$delay <= max_delay) %>%
    ## ADD COMPLETENESS
    left_join(
      df_completeness_final %>%
        select(!!!s_group_cols, "delay", "completeness"),
      by = c(group_cols, "delay")
    ) %>%
    ## COMPUTE NOWCAST
    mutate(
      ## option a) explicit NA if completeness is NA
      value_predicted = !!s_col_val / .data$completeness,
      ## option b) non-explicit NA
      # value_predicted = ifelse(is.na(completeness), !!s_col_val, !!s_col_val / completeness),
    )

  ## REORDER COLUMNS FOR EXPORT
  df_nowcasting <-
    df_nowcasting %>%
    select(
      !!!s_group_cols,
      !!s_col_occ,
      any_of(c("last_r_date", str_col_rep)), ## depending on prediction_date_method
      "delay",
      !!s_col_val,
      "value_predicted",
      "completeness",
      everything()
    )


  ### RETURN S7 OBJECT -----

  ## MAKE LIST OF PARAMS ---
  # with actual values (no symbols, no calls), and also default args
  {
    call_args <- as.list(match.call(expand.dots = TRUE))[-1L] ## acutal function call (doesnt have defaults)

    ## remove df
    call_args <- call_args[names(call_args) != "df"]

    ## force use names
    call_args$col_value <- str_col_val
    call_args$col_date_occurrence <- str_col_occ
    call_args$col_date_reporting <- str_col_rep

    ## add defaults
    default_args <- as.list(formals(nowcast_cl)) ## all default values
    default_args <- default_args[names(default_args) != "..."] ## remove ...
    params <- default_args
    params[names(call_args)] <- call_args ## replace default_args with actual
    params <- params[names(params) != "df"]

    ## convert names and calls to str values
    call_env <- parent.frame() ## capture the env outside the lapply!
    params <- lapply(params, function(p) {
      if (is.name(p) || is.call(p)) {
        eval(p, envir = call_env) ## use the env outside of the lapply!
      } else {
        p
      }
    })
    # -> classes should be c("character", "NULL", "numeric", "logical")
    # check with: `params %>% lapply(class) %>% unlist() %>% unique()`
  }
  return(
    nowcast_results(
      name = Sys.time() %>% format("%Y%m%d_%H%M%S"),
      time_start = time_start,
      time_end = Sys.time(),
      params = params,
      n_groups = n_groups,
      max_delay = max_delay,
      data = df,
      completeness = df_completeness_details, # used in plot_delays_history
      delays = df_delays,
      models = if (exists("df_models")) df_models else data.frame(), # only if do_model_fitting
      results = df_nowcasting
    )
  )
}


#' S7 object class for `nowcast_cl()` Results
#'
#' The `nowcast_cl()` function returns an object of this class.
#'
#' @param name A character string with a timestamp for the run.
#' @param params A list with the parameters used for the nowcasting (unevaluated call).
#' @param time_start the sys time at which the function started.
#' @param time_end the sys time at which the function ended.
#' @param n_groups The number of groups processed.
#' @param max_delay The maximum delay used.
#' @param data Dataframe. The original input data frame (with only required columns).
#' @param completeness Dataframe. The original input data frame with delays and completeness columns.
#' @param delays Dataframe. A data frame with the final aggregated completeness estimates per delay (+ `modelled` column if do_model_fitting was TRUE).
#' @param models Dataframe. The resulting fitted models (empty data frame if do_model_fitting was FALSE)
#' @param results Dataframe. A data frame with the resulting nowcasting predictions.
#'
#' @return An \bold{S7 object} of class \code{nowcast_results}. This object is a
#' structured container for the entire nowcasting pipeline output. It consists
#' of the following properties (slots):
#' \describe{
#'   \item{name}{Character. A unique timestamp identifier for the run (\code{YYYYMMDD_HHMMSS}).}
#'   \item{params}{List. The evaluated parameters and arguments used in the function call.}
#'   \item{time_start, time_end}{POSIXct. Timestamps marking the duration of the calculation.}
#'   \item{n_groups}{Numeric. The total count of unique groups processed.}
#'   \item{max_delay}{Numeric. The maximum reporting delay (in \code{time_units}) considered.}
#'   \item{data}{Data frame. The subset of the original input used for the analysis.}
#'   \item{completeness}{Data frame. Detailed row-level completeness calculations and delays.}
#'   \item{delays}{Data frame. Aggregated completeness estimates per delay unit, including
#'   both observed and (optionally) modelled values.}
#'   \item{models}{Data frame. Results of the non-linear model fitting, including RSS and
#'   model types. Returns an empty data frame if \code{do_model_fitting} was \code{FALSE}.}
#'   \item{results}{Data frame. The final nowcasting table containing predicted values.}
#' }
#'
#' @importFrom S7 new_class class_character class_list class_data.frame class_numeric class_POSIXct
#' @export
#' @usage
#' nowcast_results(name, params, time_start, time_end, n_groups, max_delay,
#'   data, completeness, delays, models, results)
nowcast_results <-
  S7::new_class("nowcast_results",
    properties = list(
      name = S7::class_character,
      params = S7::class_list,
      time_start = S7::class_POSIXct,
      time_end = S7::class_POSIXct,
      n_groups = S7::class_numeric,
      max_delay = S7::class_numeric,
      data = S7::class_data.frame,
      completeness = S7::class_data.frame,
      delays = S7::class_data.frame,
      models = S7::class_data.frame,
      results = S7::class_data.frame
    )
  )
