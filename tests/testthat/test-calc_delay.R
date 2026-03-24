### calc_delay
test_that("calc_delay basic works", {
  input <- generate_test_data(n_reportdates = 2, n_delays = 3, remove_delay = TRUE)
  res <- input %>% calc_delay(date_occurrence, date_report, units = "weeks")
  expect_false("delay" %in% names(input))
  expect_equal(ncol(res), ncol(input) + 1)
  expect_true("delay" %in% names(res))
  expect_true(class(res$delay) == "difftime")
  expect_true(attr(res$delay, "units") == "weeks")
})
test_that("calc_delay can output numeric col types", {
  input <- generate_test_data(n_reportdates = 2, n_delays = 3)
  res <- input %>% calc_delay(date_occurrence, date_report, as_difftime = FALSE)
  expect_true(class(res$delay) == "numeric")
})
test_that("calc_delay can output other column names", {
  input <- generate_test_data(n_reportdates = 2, n_delays = 3)
  res <- input %>% calc_delay(date_occurrence, date_report, col_name = "zzz")
  expect_true("zzz" %in% names(res))
  expect_true(ncol(res) == ncol(input) + 1)
})
test_that("calc_delay overwrite columns with same name", {
  input <- generate_test_data(n_reportdates = 2, n_delays = 3)
  res <- input %>% calc_delay(date_occurrence, date_report, units = "weeks")
  expect_true("delay" %in% names(input))
  expect_true("delay" %in% names(res))
  expect_equal(ncol(res), ncol(input))
  expect_true(ncol(res) == ncol(input))
})
test_that("calc_delay can generate other units", {
  input <- generate_test_data(n_reportdates = 2, n_delays = 3)
  res <- input %>% calc_delay(date_occurrence, date_report, units = "days")
  expect_true(attr(res$delay, "units") == "days")
})

test_that("calc_delay can take strings", {
  input <- generate_test_data(n_reportdates = 2, n_delays = 3)
  res <- input %>% calc_delay("date_occurrence", "date_report", units = "days")
  expect_true(attr(res$delay, "units") == "days")
})
# test_that("calc_delay can take .data$", {
#   input <- generate_test_data(n_reportdates = 2, n_delays = 3)
#   res <- input %>% calc_delay(.data$date_occurrence, .data$date_report, units = "days")
#   expect_true(attr(res$delay, "units") == "days")
# })
# test_that("calc_delay can take quo", {
#   input <- generate_test_data(n_reportdates = 2, n_delays = 3)
#   zzz = "date_occurrence"
#   res <- input %>% calc_delay(!!sym(zzz), date_report, units = "days")
#   expect_true(attr(res$delay, "units") == "days")
# })
