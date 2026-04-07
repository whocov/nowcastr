#' Verify the delays are valid
#'
#' The delays should
#' be either numeric or difftime
#' - contain no decimals
#' - be ordered from small to large
#' - be evenly distributed and follow a pattern of:
#'   c(min_delay, min_delay+1*time_units, min_delay+2*time_units, ..., max_delay ) )
#' - max_delay should be within reasonable range: e.g. not years
#'
#' @param list_delays A numeric vector or difftime object of delays.
#' @return \code{TRUE} if the delays are valid, otherwise throws an error.
#'
#' @noRd
check_delays <- function(list_delays) { # xxx todo
  list_delays <- list_delays %>%
    unique() %>%
    as.numeric() %>%
    sort()

  ## number of delays
  if (length(list_delays) == 0) {
    rlang::abort("The data contains no delays.")
  }
  if (length(list_delays) == 1) {
    rlang::abort("The data contains only 1 delay")
  }
  if (length(list_delays) > 999) {
    rlang::abort("The number of delays exceeds 999. Please verify time_units and the dates of the input data.")
  }
  ## no decimals
  if (!all(list_delays %% 1 == 0)) {
    rlang::abort("Decimal values are detected in the delays. Please verify time_units and the dates of the input data.")
  }
  ## evenly distributed
  if (length(list_delays) > 2 && length(unique(diff(list_delays))) > 1) {
    rlang::abort("delays must be evenly distributed")
  }
  return(TRUE)
}
