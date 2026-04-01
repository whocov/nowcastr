#### VISUALIZATIONS ########################################

## TRIANGLE (x = occurrence_date, y = reporting_date)
# |--------------/
# |             /
# |            /
# |           /
# |          /
# |         /
# |        /
# |-------/

## TRAPEZE (x = occurrence_date, y = reporting_date)

#         o
# <--------------->
#         /-------/   x
#        /       /    |
#       /       /     |
#      /       /      |
#     /       /       | r
#    /       /        |
#   /       /         |
#  /       /          |
# /-------/           x
# <------>
#     d


## MILLIPEDE (x = occurrence_date, y = value)
# ---\--\--\--\
#     \  \  \  \
#      \  \  \  \





## xxx to hamonize with
## print_ywk_rwk_matrix <- function(ccc, mmm, select_minrwk, dim = 9){}
## (cf. functions.R)
## TODO
# shorten col names ? or pivot them vertically
# #' Create Triangle table (to be finished)
# #' @inheritParams nowcast_cl
# #' @noRd
# table_triangle <- function(
#     df,
#     col_value,
#     col_date_occurrence,
#     col_date_reporting,
#     group_cols = NULL,
#     n_occ = 4
#     #
#     ) {
#   ## PREP INPUT ---
#   str_col_val <- rlang::as_name(rlang::enquo(col_value))
#   str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
#   str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
#   s_col_val <- rlang::sym(str_col_val)
#   s_col_occ <- rlang::sym(str_col_occ)
#   s_col_rep <- rlang::sym(str_col_rep)
#   s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols)

#   select_o <- df[[str_col_occ]] %>%
#     unique() %>%
#     sort(decreasing = T) %>%
#     head(n_occ) %>%
#     print()

#   df %>%
#     filter(!!s_col_occ %in% select_o) %>%
#     select(!!s_col_occ, !!s_col_rep, !!s_col_val) %>%
#     tidyr::pivot_wider(names_from = !!s_col_occ, values_from = !!s_col_val) %>%
#     arrange(!!s_col_rep %>% desc()) %>%
#     # arrange cols
#     select(!!s_col_rep, sort(tidyselect::peek_vars())) %>%
#     tibble::column_to_rownames(str_col_rep)
# }
# nowcast@data %>%
#   filter(metric == "Influenza ILI/ARI STL Detections") %>%
#   arrange(yw_date |> desc(), rw_date |> desc()) %>%
#   head(200) %>%
#   # print() %>%
#   table_triangle(
#     col_value = !!s_col_val,
#     col_date_occurrence = !!s_col_occ,
#     col_date_reporting = !!s_col_rep,
#     group_cols = group_cols,
#     n_occ = 11
#   )


#' Plot Nowcast Input Data
#'
#' Can plot 2 types of plot: option="triangle" or "millipede"
#'
#' @inheritParams nowcast_cl
#' @param option "millipede" or "triangle".
#' @param do_rescale Rescale values 0-1. Boolean.
#' @param do_facet_groups Boolean. Should groups be faceted?
#'
#' @return A ggplot object.
#' @import ggplot2
#' @export
plot_nc_input <- function(
    df,
    col_value,
    col_date_occurrence,
    col_date_reporting,
    group_cols = NULL,
    option = "millipede",
    do_rescale = TRUE,
    do_facet_groups = TRUE
    #
    ) {
  ## PREP INPUT ---
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols)

  ## rescale values (mandatory for color scales in facets)
  if (do_rescale) {
    df <- df %>%
      group_by(!!!s_group_cols) %>%
      mutate(!!s_col_val := scales::rescale(!!s_col_val, to = c(0, 1))) %>%
      ungroup()
  }

  # ## data transformations
  # if (rm_repeated_values) df <- df %>% rm_repeated_values({{ group_cols }}, {{ col_value }}, {{ col_date_occurrence }}, {{ col_date_reporting }})
  # if (fill_future_reported_values) df <- df %>% fill_future_reported_values({{ group_cols }}, {{ col_value }}, {{ col_date_occurrence }}, {{ col_date_reporting }})
  # # if (fill_past_reported_values) df <- df %>% fill_past_reported_values({{ group_cols }}, {{ col_value }}, {{ col_date_occurrence }}, {{ col_date_reporting }})

  if (option == "millipede") {
    fig <-
      plot_millipede(
        df = df,
        col_value = !!s_col_val,
        col_date_occurrence = !!s_col_occ,
        col_date_reporting = !!s_col_rep,
        # group_cols = group_cols,
        scale_percent = do_rescale
      ) +
      labs(
        y = ifelse(do_rescale, "Normalized Value", "Value")
      )
  } else if (option == "triangle") {
    fig <-
      plot_triangle(
        df = df,
        col_value = !!s_col_val,
        col_date_occurrence = !!s_col_occ,
        col_date_reporting = !!s_col_rep,
        # group_cols = group_cols,
        scale_percent = do_rescale
      ) +
      labs(
        fill = ifelse(do_rescale, "Normalized Value", "Value")
      )
  }

  ## facet groups
  if (do_facet_groups) {
    fig <- fig + facet_wrap(vars(!!!s_group_cols))
  }

  return(fig)
}




#' Triangle plot
#'
#' Draw a triangular heatmap where:
#' - x = date of occurrence
#' - y = date of reporting
#' - fill = value (e.g., counts or proportions)
#'
#' The plot is triangular because reporting dates cannot precede occurrence dates.
#' ```
#' |---------/
#' |        /
#' |       /
#' |      /
#' |     /
#' |----/
#' ```
#'
#' @inheritParams nowcast_cl
#' @param scale_percent Logical; if TRUE formats the fill legend as percentages and labels it "Percentage".
#'
#' @return A ggplot object.
#'
#' @details
#' Uses geom_raster with coord_fixed for square tiles.
#'
#' @examples
#' generate_test_data() %>%
#'   plot_triangle(
#'     col_value = value,
#'     col_date_occurrence = date_occurrence,
#'     col_date_reporting = date_report,
#'     scale_percent = FALSE
#'   )
#'
#' @seealso ggplot2::geom_raster, ggplot2::scale_fill_viridis_c
#' @import ggplot2
#' @importFrom scales percent
#' @export
plot_triangle <- function(
    df,
    col_value,
    col_date_occurrence,
    col_date_reporting,
    # group_cols = NULL,
    scale_percent = FALSE
    #
    ) {
  ## PREP INPUT ---
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  # s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols)

  fig <- df %>%
    ggplot(aes(
      x = !!s_col_occ, y = !!s_col_rep, fill = !!s_col_val,
    )) +
    geom_raster() +
    coord_fixed() +
    scale_fill_viridis_c(
      direction = 1, option = "turbo",
      labels = if (scale_percent) scales::percent else function(x) x
    ) +
    # guides(colour = "none", fill = "none") + ## remove legend
    labs(
      x = "Date Of Occurrence",
      y = "Date Of Reporting",
      fill = ifelse(scale_percent, "Percentage", "Value")
    )

  return(fig)
}

## optional mods:
#  + geom_text(aes(label = round(value * 10, 0)),
#       size = 3,
#       color = "black",
#       vjust = 0.5,
#       hjust = 0.5
#     )





#' Millipede plot
#'
#' Draw a line plot where each line represents one reporting date:
#' - x = date of occurrence
#' - y = value (e.g., counts or proportions)
#' - group + fill = date of reporting
#'
#' When there are reporting delays the plot look like this:
#' ```
#' ---\--\--\--\
#'     \  \  \  \
#'      \  \  \  \
#' ```
#'
#' @inheritParams plot_triangle
#' @return A ggplot object.
#'
#' @examples
#' generate_test_data() %>%
#'   plot_millipede(
#'     col_value = value,
#'     col_date_occurrence = date_occurrence,
#'     col_date_reporting = date_report,
#'     scale_percent = FALSE
#'   )
#'
#' @seealso ggplot2::geom_line, ggplot2::scale_color_viridis_c
#' @import ggplot2
#' @importFrom scales percent
#' @export
plot_millipede <- function(
    df,
    col_value,
    col_date_occurrence,
    col_date_reporting,
    # group_cols = NULL,
    scale_percent = FALSE
    #
    ) {
  ## PREP INPUT ---
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  # s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols)

  fig <- df %>%
    ggplot(aes(
      x = !!s_col_occ, y = !!s_col_val,
      group = !!s_col_rep,
      color = !!s_col_rep
    )) +
    geom_line() +
    scale_y_continuous(
      labels = if (scale_percent) scales::percent else function(x) x
    ) +
    ggplot2::scale_color_viridis_c(
      direction = -1, option = "viridis", trans = "date"
    ) +
    labs(
      x = "Date Of Occurrence",
      color = "Date Of Reporting",
      y = ifelse(scale_percent, "Percentage", "Value")
    )

  return(fig)
}




# res %>% plot(which = 'delays')






#' Plot Reporting Completeness by Delay
#'
#' Creates a scatter plot of reporting completeness against reporting delay.
#' If a `col_completeness_modelled` is present, it will be shown as a dotted line.
#'
#' @inheritParams nowcast_cl
#' @param df A data.frame containing 'delay' and `col_completeness` columns.
#'   An optional `modelled` column
#' @param col_completeness_obs Column name for the Observed Completeness. (dots)
#' @param col_completeness_modelled Column name for the Modelled Completeness. (line)
#' @param color1 Color for observed data. (dots)
#' @param color2 Color for modelled data. (line)
#' @param limits_y vector to be passed to limits of `ggplot2::scale_y_continuous`.
#'
#' @return A ggplot object showing completeness vs. delay.
#' @examples
#' delays <- data.frame(
#'   delay = 0:9,
#'   completeness = c(0.509, 0.802, 0.920, 0.967, 0.987, 0.995, 0.998, 0.999, 1, NA),
#'   modelled = c(0.509, 0.802, 0.920, 0.968, 0.987, 0.995, 0.998, 0.999, 1, 1)
#' )
#' plot_delays(
#'   df = delays,
#'   col_completeness_obs = completeness,
#'   col_completeness_modelled = modelled
#' )
#'
#' @import ggplot2
#' @importFrom scales percent
#' @export
plot_delays <- function(
    df,
    # col_date_occurrence,
    # col_date_reporting,
    # col_value,
    col_completeness_obs,
    col_completeness_modelled = "",
    group_cols = NULL,
    color1 = "#222222",
    color2 = "firebrick2",
    limits_y = c(NA, NA)
    #
    ) {
  ## PREP INPUT ---
  # str_col_val <- rlang::as_name(rlang::enquo(col_value))
  # str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  # str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  str_col_com_o <- rlang::as_name(rlang::enquo(col_completeness_obs))
  # s_col_val <- rlang::sym(str_col_val)
  # s_col_occ <- rlang::sym(str_col_occ)
  # s_col_rep <- rlang::sym(str_col_rep)
  s_col_com_o <- rlang::sym(str_col_com_o)
  s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols)

  # handle NULL
  # q_col_com_m <- rlang::enquo(col_completeness_modelled)
  # str_col_com_m <- if (rlang::quo_is_null(q_col_com_m)) NULL else rlang::as_name(q_col_com_m)
  str_col_com_m <- rlang::as_name(rlang::enquo(col_completeness_modelled))
  s_col_com_m <- rlang::sym(str_col_com_m)


  ## VALIDATION ---
  if (!str_col_com_o %in% names(df)) {
    rlang::abort(paste0("col_completeness is not in the dataframe:\n(", paste(names(df), collapse = ","), ")"))
  }
  stopifnot(
    # "col_completeness is not in the dataframe" = str_col_com_o %in% names(df),
    "delay is not in the dataframe" = "delay" %in% names(df)
  )

  fig <-
    df %>%
    ggplot(aes(
      x = .data$delay, y = !!s_col_com_o,
      group = interaction(!!!s_group_cols),
      # color = interaction(!!!s_group_cols)
    )) +
    scale_y_continuous(labels = scales::percent, limits = limits_y) +
    geom_point(color = color1) +
    # geom_line(color = color1) +
    labs(
      title = "Completeness by Delay",
      y = "Completeness",
      x = "Delay",
      # color = "Groups",
    )

  has_modelling <- FALSE
  if (str_col_com_m %in% names(df)) has_modelling <- TRUE
  if (has_modelling) {
    fig <- fig + geom_line(aes(y = !!s_col_com_m),
      linetype = "3131",
      color = color2
    )
  } else {
    fig <- fig + geom_line()
  }

  return(fig)
}






#' Plot Nowcasting Predictions
#'
#' @description
#' Compares observed data with nowcasted predictions over the occurrence date.
#' Observed values are plotted as a solid grey line, and predicted values as a
#' dashed black line.
#'
#' @inheritParams nowcast_cl
#' @param col_value_predicted Column name for the Predicted Value.
#' @param color1 Color for observed data.
#' @param color2 Color for predicted data.
#'
#' @return A ggplot object comparing observed and predicted values.
#'
#' @examples
#' df_nowcast <- data.frame(
#'   date_occurrence = as.Date("2023-01-01") + 0:9,
#'   value_observed = c(10, 12, 15, 13, 18, 20, 22, 24, 25, 20),
#'   value_predicted = c(10, 12, 15, 13, 18, 20, 22, 25, 28, 30)
#' )
#' plot_nowcast(
#'   df = df_nowcast,
#'   col_value = value_observed,
#'   col_date_occurrence = date_occurrence,
#'   col_value_predicted = value_predicted
#' )
#'
#' @import ggplot2
#' @export
plot_nowcast <- function(
    df,
    col_date_occurrence,
    # col_date_reporting,
    col_value,
    col_value_predicted,
    group_cols = NULL,
    color1 = "#333333",
    color2 = "firebrick1"
    # , scale_percent = TRUE
    #
    ) {
  ## PREP INPUT ---
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_val_pred <- rlang::as_name(rlang::enquo(col_value_predicted))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  # str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_val_pred <- rlang::sym(str_col_val_pred)
  s_col_occ <- rlang::sym(str_col_occ)
  # s_col_rep <- rlang::sym(str_col_rep)
  s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols)

  ## VALIDATION ---
  stopifnot(
    "value_predicted is not in the dataframe" = "value_predicted" %in% names(df),
    "col_value is not in the dataframe" = str_col_val %in% names(df),
    "col_date_occurrence is not in the dataframe" = str_col_occ %in% names(df)
  )

  fig <- df %>%
    ggplot(aes(
      x = !!s_col_occ, y = !!s_col_val,
      group = interaction(!!!s_group_cols),
      # color = interaction(!!!s_group_cols)
    )) +
    geom_line(aes(y = .data$value_predicted), linetype = "3131", color = color2) +
    geom_line(aes(y = !!s_col_val), color = color1) +
    labs(
      title = "Nowcasts",
      x = "Date Of Occurrence",
      y = "Value",
      # color = "Groups",
    )

  return(fig)
}






#' @rdname plot.nowcast_results
#' @param x A `nowcast_results` object.
#' @usage \method{plot}{nowcast_results}(x, which, option, do_rescale, add_model_info, ...)
#' @importFrom S7 S7_dispatch
#' @export
plot.nowcast_results <- function(
    x,
    which = "results",
    option = "millipede",
    do_rescale = FALSE,
    add_model_info = TRUE,
    ...) {
  S7::S7_dispatch()
}





#' Plotting method for nowcasting results
#'
#' @description
#' This is a plot method which can plot all `nowcast_cl()` outputs:
#' - data (`which = "data"`)
#' - delays (`which = "delays"`)
#' - results (`which = "results"`)
#' It will apply a theme, a caption and a facet wrap on groups.
#'
#' @name plot.nowcast_results
#' @param x A `nowcast_results` object.
#' @param which Which plot to draw, one of "results", "data", or "delays".
#' @param option Either "millipede" or "triangle". Only for `which = "data"`.
#' @param do_rescale Rescale values 0-1. Boolean. Only for `which = "data"` or `which = "delays"`.
#' @param add_model_info Add model info to the plot. Boolean. Only for `which = "delays"`.
#' @param ... Additional arguments passed to methods.
#' @return A ggplot object.
#' @import ggplot2
#' @importFrom graphics plot
#' @importFrom S7 method S7_dispatch
#' @importFrom scales rescale
#' @export
S7::method(plot, nowcast_results) <- function(
    x,
    which = "results",
    option = "millipede",
    do_rescale = FALSE,
    add_model_info = TRUE,
    color1 = "#333333",
    color2 = "firebrick1",
    ...
    #
    ) {
  ## PREP INPUT ---
  ## extract from @params
  col_value <- rlang::syms(x@params$col_value)[[1]]
  col_date_occurrence <- rlang::syms(x@params$col_date_occurrence)[[1]]
  col_date_reporting <- rlang::syms(x@params$col_date_reporting)[[1]]
  group_cols <- x@params$group_cols
  ## names and symbols
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols)


  ## INPUT VALIDATION ---
  which <- match.arg(which, c("results", "data", "delays"))
  option <- match.arg(option, c("triangle", "millipede", NULL))


  ## force modify do_rescale
  if (!do_rescale && which == "data" && option == "triangle" && x@n_groups > 1) {
    do_rescale <- TRUE
    message("Note: do_rescale has been changed to TRUE because multiple groups are present and color scales are free in facets")
  }


  fig <- NULL ## default
  base_size <- 15

  if (which == "data") {
    fig <- plot_nc_input(
      df = x@data,
      col_value = !!s_col_val,
      col_date_occurrence = !!s_col_occ,
      col_date_reporting = !!s_col_rep,
      group_cols = group_cols,
      option = option,
      do_rescale = do_rescale
    )
  } else if (which == "delays") {
    # do_rescale <- FALSE

    args <- list(
      df = x@delays,
      col_completeness_obs = "completeness_obs",
      group_cols = group_cols
    )

    if ("completeness_modelled" %in% names(x@delays)) {
      args$col_completeness_modelled <- "completeness_modelled"
    }

    fig <-
      do.call(plot_delays, args) +
      labs(x = paste0("Delays [", x@params$time_units, "]"))
    # + facet_wrap(vars(!!!s_group_cols))

    # browser()

    if (add_model_info && x@params$do_model_fitting) {
      # xxx todo:
      # we should also be able to add stats if no model fitting?: t_to_95_obs

      df_model_stats <- x %>%
        tbl_models_stats()

      ggtext_size <- function(base_size, ratio = 0.5) {
        ratio * base_size / ggplot2::.pt
      }

      fig <-
        fig +
        ## MODEL STATS INFO ---
        geom_text(
          data = df_model_stats,
          aes(
            label = paste0(
              "model: ", trimws(modelname),
              # "\niterations: ", iterations,
              # "\nRSS: ", RSS %>% signif(2),
              # "\nLog(RSS): ", log_RSS,
              "\nR2: ", signif(R2, 2), # should try R\u00b2, but superscript 2 is not allowed, non-ascii
              ""
            ),
            # x = Inf, hjust = 1.5, ## far right
            x = x@max_delay * 0.7, hjust = 0, # 70% from the end
            # y = ifelse(start_completeness_pred < 1, 1.04, .96),
            # y = 1,
            y = end_completeness_pred,
            vjust = ifelse(start_completeness_pred < 1, 1.9, -.9), ## above or below the line
          ),
          color = "#666666",
          fontface = "bold",
          # size = rel(3)
          # size = 7 / .pt
          size = ggtext_size(base_size)
        ) +
        ## MODEL TIME TO 95% ---
        geom_vline( ## doesnt force y limit to 0
          data = df_model_stats,
          aes(xintercept = t_to_95_model),
          alpha = 0.3,
          linetype = "dashed"
        ) +
        # geom_segment( ## The segment option forces y scale to start at 0
        #   data = df_model_stats,
        #   aes(
        #     x = t_to_95_model, xend = t_to_95_model,
        #     y = 0, yend = ifelse(start_completeness_pred < 1, 0.95, 1.05)
        #   ),
        #   alpha = 0.3, # since overlap
        #   linetype = "dashed"
        # ) +
        geom_label(
          data = df_model_stats,
          aes(
            label = t_to_95_model,
            x = t_to_95_model,
            y = ifelse(start_completeness_pred < 1, 0.95, 1.05),
            vjust = ifelse(start_completeness_pred < 1, 1.9, -.9),
          ),
          # color = "#666666",
          alpha = 0.8,
          fontface = "bold",
          # size = 7 / .pt
          size = ggtext_size(base_size)
        )
    }

    # ## add t_to_95_model
    # add_t_to_95_model <- TRUE
    # if (add_t_to_95_model) {
    #   fig <-
    #     fig +
    #     geom_vline(
    #       data = x@models,
    #       aes(xintercept = t_to_95_model),
    #       alpha = 0.3,
    #       linetype = "dashed"
    #     ) +
    #     geom_label(
    #       data = x@models,
    #       aes(
    #         x = t_to_95_model,
    #         label = t_to_95_model
    #       ),
    #       y = 0.1,
    #       size = 4,
    #       fontface = "bold"
    #     )
    # }
  } else if (which == "results") {
    do_rescale <- FALSE
    fig <-
      plot_nowcast(
        df = x@results,
        col_date_occurrence = !!s_col_occ,
        # col_date_reporting = !!s_col_rep,
        col_value = !!s_col_val,
        col_value_predicted = value_predicted,
        group_cols = group_cols,
        color1 = color1,
        color2 = color2
      )
  } else {
    rlang::abort('invalid `which`. must be one of: "results", "data", "delays"')
  }

  if (!is.null(fig)) {
    ## theme
    fig <- fig + theme_minimal(base_size)

    ## facet_wrap
    if (x@n_groups > 1) {
      wrapscales <- case_when(
        (which == "data" & option == "triangle") ~ "fixed", ## issue is scales cannot have color scale free
        which == "results" ~ "free_y",
        !do_rescale ~ "free_y",
        do_rescale ~ "fixed",
        TRUE ~ "free"
      )

      fig <- fig + facet_wrap(vars(!!!s_group_cols), scales = wrapscales)
    }
  }

  ## add caption
  fig <- fig + labs(caption = paste("Generated on", Sys.Date(), "; Last report date:", max(x@data[[str_col_rep]])))

  return(fig)
}




#' Unwrap nowcast models stats
#' @param nc_obj A `nowcast_results` object.
#' @param thresholds_r2 R squared threshold to classify `eval` into good or bad fit
#' @return tibble
#' @noRd
tbl_models_stats <- function(
    nc_obj,
    thresholds_r2 = 0.8
    # ,thresholds_rss = 0.011
    ) {
  group_cols <- nc_obj@params$group_cols
  # s_group_cols <- if (is.null(group_cols) || length(group_cols) == 0) list(rlang::expr(1)) else rlang::syms(group_cols)


  if (ncol(nc_obj@models) == 0) {
    return(nc_obj@models)
  } else {
    nc_obj@models %>%
      mutate(
        R2 = purrr::map2_dbl(.data$data, .data$RSS, function(dat, rss) {
          ss_tot <- sum((dat$y - mean(dat$y, na.rm = TRUE))^2)
          if (ss_tot == 0) {
            return(NA_real_)
          } # Prevent division by zero if data is perfectly flat
          round(1 - (rss / ss_tot), 3)
        })
      ) %>%
      arrange(.data$R2, .data$RSS |> desc()) %>% ## worse on top
      mutate(
        start_completeness_obs = purrr::map_dbl(.data$data, ~ .x$y[which.min(.x$x)]) %>% round(2),
        start_completeness_pred = purrr::map_dbl(.data$pred, ~ .x$y[which.min(.x$x)]) %>% round(2),
        end_completeness_obs = purrr::map_dbl(.data$data, ~ .x$y[which.max(.x$x)]) %>% round(2),
        end_completeness_pred = purrr::map_dbl(.data$pred, ~ .x$y[which.max(.x$x)]) %>% round(2),
      ) %>%
      mutate(
        coefs_str = purrr::map_chr(.data$fit, ~ paste(signif(coef(.x), 2), collapse = ", "))
      ) %>%
      # mutate(log_RSS = log10(.data$RSS) %>% round(1), ) %>%
      mutate(
        t_to_95_model = .data$t_to_95_model %>% signif(2) # %>% paste(., nc_obj@params$unit),
      ) %>%
      tidyr::separate(
        .data$coefs_str,
        into = c("a", "b", "c"),
        sep = ",",
        convert = TRUE,
        fill = "right"
      ) %>%
      ## eval good or bad fit
      mutate(eval = case_when(
        modelname != "linear" &
          # RSS < thresholds_rss[1] &
          R2 > thresholds_r2
        ~ "Good Fit",
        TRUE ~ "Bad Fit"
      )) %>%
      # select( -c("data", "pred", "fit") ) %>%
      select(
        all_of(group_cols),
        "iterations",
        "modelname",
        "a", "b", "c",
        "R2", "RSS",
        # "log_RSS",
        "t_to_95_obs", "t_to_95_model",
        "start_completeness_obs",
        "start_completeness_pred",
        "end_completeness_obs",
        "end_completeness_pred",
        everything()
      )
  }
}
