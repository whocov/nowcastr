#' Calculate delay between 2 dates
#'
#' Add (or overwrite) a column named 'delay' (name is parametrable)
#'
#' @param date1 an unquoted column name of type date
#' @param date2 an unquoted column name of type date
#' @param units a value from c("auto", "secs", "mins", "hours", "days", "weeks")
#' @param as_difftime Flag to return difftime (TRUE) or numeric (FALSE)
#' @param col_name output column name (string)
#' @return A data.frame with the delay column added (or overwritten).
#' @noRd
calc_delay <- function(
  df,
  date1,
  date2,
  units = "weeks",
  as_difftime = TRUE,
  col_name = "delay"
  #
) {
  name_date1 <- rlang::as_name(rlang::enquo(date1))
  name_date2 <- rlang::as_name(rlang::enquo(date2))
  s_date1 <- rlang::sym(name_date1)
  s_date2 <- rlang::sym(name_date2)

  ## Input validation ---
  {
    date1_name <- rlang::as_name(s_date1)
    date2_name <- rlang::as_name(s_date2)
    if (!is.data.frame(df)) rlang::abort("`df` must be a data frame.")
    if (!all(c(date1_name, date2_name) %in% names(df))) rlang::abort("`date1` and `date2` must be columns in `df`.")
    if (!inherits(df[[date1_name]], c("Date", "POSIXt")) || !inherits(df[[date2_name]], c("Date", "POSIXt"))) {
      rlang::abort("`date1` and `date2` columns must be of Date or POSIXt type.")
    }
    allowed_units <- c("auto", "secs", "mins", "hours", "days", "weeks")
    if (!units %in% allowed_units) {
      rlang::abort(paste("`units` must be one of:", paste(allowed_units, collapse = ", ")))
    }
    if (!is.logical(as_difftime) || length(as_difftime) != 1) rlang::abort("`as_difftime` must be a single logical value.")
    if (!is.character(col_name) || length(col_name) != 1) rlang::abort("`col_name` must be a single string.")
  }

  # Calculate delay on unique pairs
  delays <- df %>%
    dplyr::distinct(!!s_date1, !!s_date2) %>%
    dplyr::mutate(
      !!rlang::sym(col_name) := difftime(!!s_date2, !!s_date1, units = units)
    )

  # Convert to numeric
  if (!as_difftime) {
    delays <- delays %>%
      dplyr::mutate(!!rlang::sym(col_name) := as.numeric(.data[[col_name]]))
  }

  # Overwrite: delete col if exists
  if (col_name %in% names(df)) df <- df %>% dplyr::select(-dplyr::any_of(col_name))
  # Join
  dplyr::left_join(df, delays, by = c(rlang::as_name(s_date1), rlang::as_name(s_date2)))
}
