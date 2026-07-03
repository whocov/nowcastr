#' Compute table with models result stats.
#'
#' Summarizes fitted growth models per group, computing R-squared, fit
#' evaluation (good/bad), and completeness at start/end of observed data.
#'
#' @param nc_obj A `nowcast_results` object.
#' @param thresholds_r2 Numeric scalar. R-squared threshold above which
#'   (combined with end completeness near 1) a model is classified `"Good Fit"`.
#' @param thresholds_asymptote Numeric double. Gap from 100% Completeness tolerated to end_completeness_pred to categorise the model with good or bad fit.
#'
#' @return A tibble with one row per fitted model, including columns for
#'   group variables, `R2`, `RSS`, model coefficients (`a`, `b`, `c`),
#'   completeness at start/end, and `eval` ("Good Fit"/"Bad Fit"). If
#'   `nc_obj@models` has no rows, it is returned unchanged.
#'
#' @examples
#' \dontrun{
#' tbl_models_stats(nc_obj)
#' tbl_models_stats(nc_obj, thresholds_r2 = 0.9, thresholds_asymptote = 0.05)
#' }
#' @export
tbl_models_stats <- function(
  nc_obj,
  thresholds_r2 = 0.8,
  thresholds_asymptote = 0.07
) {
  group_cols <- nc_obj@params$group_cols

  if (nrow(nc_obj@models) == 0) {
    return(nc_obj@models)
  } else {
    nc_obj@models %>%
      mutate(
        R2 = purrr::map2_dbl(.data$data, .data$RSS, function(dat, rss) {
          ss_tot <- sum((dat$y - mean(dat$y, na.rm = TRUE))^2, na.rm = TRUE)
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
      mutate(
        t_to_95_model = .data$t_to_95_model %>% signif(2)
      ) %>%
      tidyr::separate(
        .data$coefs_str,
        into = c("a", "b", "c"),
        sep = ",",
        convert = TRUE,
        fill = "right"
      ) %>%
      ## eval good or bad fit ---
      mutate(eval = case_when(
        .data$modelname != "linear" &
          ## 1. THE FIT IS CORRECT : THERE IS ALIGNMENT BETWEEN POINTS
          .data$R2 > thresholds_r2 &
          ## 2. THE LINE ENDS TOWARDS 100% COMPLETENESS
          .data$end_completeness_pred > 1 - thresholds_asymptote &
          .data$end_completeness_pred < 1 + thresholds_asymptote
        ~ "Good Fit",
        TRUE ~ "Bad Fit"
      )) %>%
      select(
        all_of(group_cols),
        "iterations",
        "modelname",
        "a", "b", "c",
        "R2", "RSS",
        "t_to_95_obs", "t_to_95_model",
        "start_completeness_obs",
        "start_completeness_pred",
        "end_completeness_obs",
        "end_completeness_pred",
        everything()
      )
  }
}
