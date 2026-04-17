#' Generate asymptotic test data for nowcating
#'
#' Create synthetic long-format test data following an asymptotic delay curve
#' and constant final value. Formula:
#' `value = final_value * (c + 1 * (1 - exp(-b * .data$delay))))`
#'
#' @param reportdate_from Character or Date. Start report date (e.g. "2025-02-01").
#' @param n_reportdates Integer. Number of consecutive report dates to generate.
#' @param delay_from Integer >= 0. Minimum delay value.
#' @param n_delays Integer. Number of delay values to generate.
#' @param time_units Time units. Accepted values: ("auto", "secs", "mins", "hours", "days", "weeks").
#' @param final_value Numeric. Asymptotic target (a in the formula).
#' @param c Numeric (0-1). Baseline fraction of final_value added to the curve.
#' @param b Numeric. Rate constant controlling how fast y approaches a; larger b → faster approach.
#' @param remove_delay Logical. If TRUE, remove the delay column in the output.
#' @return A tibble (long format) with columns date_report (Date), date_occurrence (Date), delay (integer, optional) and value (numeric).
#' @details With defaults this returns n_reportdates × (n_delays - delay_from + 1) rows (9 × 10 = 90).
#'         reportdate_from may be provided as a Date or parsable character; lubridate units are used for stepping.
#' @examples
#' generate_test_data()
#' generate_test_data(n_reportdates = 3, n_delays = 3)
#' generate_test_data(time_units = "weeks", remove_delay = TRUE)
#' @export
generate_test_data <- function(
  n_reportdates = 9,
  n_delays = 10,
  reportdate_from = "2025-02-01",
  # reportdate_to = "2025-02-09",
  delay_from = 0,
  time_units = "days",
  final_value = 100,
  c = .5,
  b = .9, # Units = 1/(x units). Larger b → faster approach; b ≤ 0 changes shape (b>0 for monotonic increase).
  remove_delay = FALSE
  #
) {
  stopifnot(c >= 0)

  a <- 1 - c ## assymptote to 100%

  # example: subtime(Sys.Date(), 1, "weeks")
  subtime <- function(date, n, time_units = "days") {
    seq(date, by = paste0("-", n, " ", time_units), length = 2)[2]
    # date - as.difftime(n, units = time_units) ## same but units is not as flexible with plurals
  }

  r_dates <- seq(as.Date(reportdate_from), by = paste0("+", 1, " ", time_units), length = n_reportdates)

  df <-
    expand.grid(
      date_report = r_dates,
      delay = delay_from:(delay_from + n_delays - 1)
    ) %>%
    rowwise() %>%
    mutate(date_occurrence = subtime(.data$date_report, .data$delay, time_units)) %>%
    ungroup() %>%
    select("date_occurrence", "date_report", "delay") %>%
    arrange(desc(.data$date_occurrence), desc(.data$date_report)) %>%
    mutate(value = final_value * (c + a * (1 - exp(-b * .data$delay))))

  if (remove_delay) df <- df %>% select(-"delay")
  return(df)
}


#' Calculate retro-scores for all groups
#'
#' The retro-score is the amount of retro-adjustments / max possible retro-adjustments
#' The higher the better for nowcast_cl()
#' retro_score = n_changes / max_changes or = retro_adjustments / max_retro_adj
#' Notes:
#' "retro-adjustments" = "value changes"
#' retro-score = number of changes / number of ywks (max changes)
#'
#' @inheritParams rm_repeated_values
#' @param method '2D_allgroups' (number of changes in 2D triangle) or 'at_least_1_change_by_occ' (number of occurrence dates with at least 2 reported values)
#' @param max_delay Maximum delay to consider. (only works with method '2D_allgroups')
#' @param aggrby A character vector of column names to aggregate by.
#' @return A tibble with group cols + retro_score (percentage 0-1)
#' @examples
#' generate_test_data() %>%
#'   calculate_retro_score(
#'     col_date_occurrence = date_occurrence,
#'     col_date_reporting = date_report,
#'     col_value = value,
#'     group_cols = NULL
#'     # , aggrby = country
#'     # , method = "at_least_1_change_by_occ"
#'   )
#'
#' @export
calculate_retro_score <- function(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL,
  # time_units = "weeks",
  method = "2D_allgroups", # at_least_1_change_by_occ / 2D_allgroups
  max_delay = Inf,
  aggrby
  #
) {
  ## PREP INPUT ---
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  s_group_cols <- rlang::syms(group_cols)

  ## INPUT VALIDATION ---
  method <- match.arg(method, c("2D_allgroups", "at_least_1_change_by_occ"))

  if (method == "2D_allgroups") {
    stopifnot(inherits(df[[str_col_occ]], "Date"))
    ## we need dates to compute a delay
  }

  n_ywks <- nrow(df %>% distinct(!!s_col_occ))
  n_rwks <- nrow(df %>% distinct(!!s_col_rep))

  # compute the number of value changes, by occurrence dates
  # count the number of different reported values, by occurrence dates
  res1 <-
    df %>%
    rm_repeated_values(
      col_value = !!s_col_val,
      col_date_occurrence = !!s_col_occ,
      col_date_reporting = !!s_col_rep,
      group_cols = group_cols
    ) %>%
    count(!!!s_group_cols, !!s_col_occ, name = "n_reported") %>%
    # filter(n_reported > 1) %>% ## all these are values never retro_adj
    mutate(n_changes = .data$n_reported - 1)

  if (method == "at_least_1_change_by_occ") {
    # retro-score = number of changes / number of ywks (max changes)
    res2 <-
      res1 %>%
      filter(.data$n_reported > 1) %>% ## all these are values never retro_adj
      count(!!!s_group_cols, name = "n_occurrences_with_changes") %>%
      arrange(desc(.data$n_occurrences_with_changes)) %>%
      mutate(retro_score = .data$n_occurrences_with_changes / n_ywks) %>%
      select(-"n_occurrences_with_changes")
  } else if (method == "2D_allgroups") {
    # max changes = matrix : occdate x delays
    report_delay_matrix <-
      df %>%
      distinct(!!s_col_occ, !!s_col_rep) %>%
      mutate(delay = !!s_col_rep - !!s_col_occ) %>% # simpler delay, unit do not matter
      filter(.data$delay <= max_delay) %>%
      distinct(!!s_col_rep, .data$delay)

    # max_retro_adj <- (report_delay_matrix %>% nrow()) - n_rwks ## wrong

    d <- nrow(report_delay_matrix %>% distinct(.data$delay))
    r <- nrow(report_delay_matrix %>% distinct(!!s_col_rep))
    # o <- d + r - 1
    # n_changes follows a distribution like this:
    # 0 1 2 3 ... 3 2 1 0
    # of length o = d + r - 1
    # (see trapeze shape to visualize)
    # max_retro_adj = sum of this distribution:
    max_retro_adj <- (d - 1) * (r - 1)

    # compute the number of value changes, in total
    res2 <-
      res1 %>%
      summarise(n_changes = sum(.data$n_changes, na.rm = T), .by = all_of(group_cols)) %>%
      mutate(max_retro_adj = max_retro_adj) %>%
      mutate(retro_score = .data$n_changes / max_retro_adj)
  }

  if (!missing(aggrby)) {
    res2 <- res2 %>%
      summarise(.by = {{ aggrby }}, retro_score = mean(.data$retro_score))
  }

  # ## check
  # res2 %>% count(retro_score, sort = T)
  # range(res2$retro_score)
  # hist(res2$retro_score,
  #   breaks = 20,
  #   main = "Histogram of retro_score",
  #   xlab = "retro_score"
  # )

  stopifnot(
    "POSTCHECK: retro_score < 0 " = min(res2$retro_score) >= 0,
    "POSTCHECK: retro_score > 1 " = max(res2$retro_score) <= 1
  )


  res2 <- res2 %>% arrange(desc(.data$retro_score))
  return(res2)
}


#' Remove duplicated reported values in reporting matrix
#'
#' @inheritParams nowcast_cl
#'
#' @return A tibble with the same columns as `df`, but with rows removed.
#'
#' @examples
#' library(dplyr)
#' generate_test_data(n_delays = 20, n_reportdates = 20) %>%
#'   mutate(value = round(value, 1)) %>% ## make values identical
#'   rm_repeated_values(
#'     col_value = value,
#'     col_date_occurrence = date_occurrence,
#'     col_date_reporting = date_report
#'   )
#' @export
rm_repeated_values <- function(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL
  #
) {
  ## PREP INPUT ---
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  s_group_cols <- rlang::syms(group_cols)

  df %>%
    arrange(!!!s_group_cols, !!s_col_occ, !!s_col_rep) %>% ## keep first change
    # arrange(!!!s_group_cols, !!s_col_occ, !!s_col_rep |> desc()) %>% ## keep last change
    distinct(!!!s_group_cols, !!s_col_occ, !!s_col_val, .keep_all = TRUE) %>%
    arrange(!!!s_group_cols, !!s_col_occ, !!s_col_rep)
}


## VERTICAL UP FILL

#' Fill future reported values with last known values
#'
#' This function completes a data frame to include all combinations
#' of occurrence and reporting dates (within each group).
#' It then fills in missing values by carrying the last known reported value
#' backward in time from future reports to past reports for a given occurrence.
#' This is useful for dealing with right-censored reporting data where reports
#' are updated over time.
#'
#' @inheritParams nowcast_cl
#' @param max_delay Inf / 'auto' / NULL / integer. 'auto' or NULL will keep the same max_delay as the input.
#'
#' @return A data frame with the same columns as `df`, but with rows added for
#'   missing reporting dates and `NA` values in `col_value` filled with the
#'   last available observation for each occurrence date within each group.
#'
#' @export
#' @importFrom dplyr group_by arrange desc ungroup filter
#' @importFrom tidyr complete fill
#' @importFrom rlang enquo syms as_name .data
#' @examples
#' library(dplyr)
#'
#' generate_test_data() %>%
#'   fill_future_reported_values(
#'     col_date_occurrence = date_occurrence,
#'     col_date_reporting = date_report,
#'     col_value = value,
#'     group_cols = NULL
#'   )
#' @export
fill_future_reported_values <- function(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL,
  max_delay = Inf # Inf / 'auto' / integer
  #
) {
  # --- Input validation
  stopifnot(
    "PRECHECK: `df` must be a data.frame." = is.data.frame(df)
    # ,
    # PRECHECK:  "`group_cols` must be a character vector." = is.character(group_cols)
  )

  ## PREP INPUT ---
  str_col_val <- rlang::as_name(rlang::enquo(col_value))
  str_col_occ <- rlang::as_name(rlang::enquo(col_date_occurrence))
  str_col_rep <- rlang::as_name(rlang::enquo(col_date_reporting))
  s_col_val <- rlang::sym(str_col_val)
  s_col_occ <- rlang::sym(str_col_occ)
  s_col_rep <- rlang::sym(str_col_rep)
  s_group_cols <- rlang::syms(group_cols)

  if (is.null(max_delay) || max_delay == "auto") {
    max_delay <- df %>%
      mutate(delay = !!s_col_rep - !!s_col_occ) %>% # simpler delay, unit do not matter
      pull(.data$delay) %>%
      max(na.rm = TRUE)
  }

  res <- df %>%
    tidyr::complete(!!!s_group_cols, !!s_col_occ, !!s_col_rep) %>%
    # or by groups might be needed:
    # dplyr::group_by(!!!s_group_cols) %>%
    # tidyr::complete(!!s_col_occ, !!s_col_rep) %>%
    # ungroup() %>%
    filter(!!s_col_occ <= !!s_col_rep) %>% ## complete added impossible future values
    arrange(!!!s_group_cols, desc(!!s_col_occ), desc(!!s_col_rep)) %>% ## important for the FILL
    group_by(!!!s_group_cols, !!s_col_occ) %>%
    tidyr::fill(!!s_col_val, .direction = "up") %>%
    ungroup() %>%
    filter(!is.na(!!s_col_val))

  if (max_delay != Inf) {
    res <- res %>%
      filter((!!s_col_rep - !!s_col_occ) <= max_delay)
  }

  return(res)
}


## VERTICAL DOWN FILL

# #' Fill Past reported values with first known values
# #' (should be rarely/never used)
# fill_past_reported_values <- function(
#     df,
#     group_cols,
#     col_value,
#     col_date_occurrence,
#     col_date_reporting
#     #
#     ) {
#   s_group_cols <- rlang::syms(group_cols)
#   s_col_val <- rlang::enquo(col_value)
#   s_col_occ <- rlang::enquo(col_date_occurrence)
#   s_col_rep <- rlang::enquo(col_date_reporting)

#   df %>%
#     # dplyr::group_by(!!!s_group_cols) %>%
#     tidyr::complete(!!!s_group_cols, !!s_col_occ, !!s_col_rep) %>%
#     # ungroup() %>%
#     filter(!!s_col_occ <= !!s_col_rep) %>% ## complete added impossible future values
#     arrange(!!!s_group_cols, desc(!!s_col_occ), desc(!!s_col_rep)) %>% ## important for the FILL
#     group_by(!!!s_group_cols, !!s_col_occ) %>%
#     tidyr::fill(!!s_col_val, .direction = "down") %>% ## up/down is the only difference with fill_future_reported_values()
#     ungroup() %>%
#     filter(!is.na(!!s_col_val))
# }


## HORIZONTAL FILL
## LEFT / RIGHT / CENTER


# #' Horizontal Gap-filling  values
# #' @export
# fill_gaps <- function(
#     df,
#     col_value,
#     col_date_occurrence,
#     col_date_reporting,
#     group_cols = NULL
#     #
#     ) {
#   s_group_cols <- rlang::syms(group_cols)
#   s_col_val <- rlang::enquo(col_value)
#   s_col_occ <- rlang::enquo(col_date_occurrence)
#   s_col_rep <- rlang::enquo(col_date_reporting)

#   # options:
#   # - propagate same values as last known
#   # - avg of value before / after
#   # - lm fit of a window of values?
#   # - propagate same proportions within higher groups
#   #   (e.g. if 1 country is missing then the gap can be filled with a 'normal' proportion of the sum of the other countries (or better a selection of the few that were stable enough))
# }
