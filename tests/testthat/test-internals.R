test_that("check_delays works", {
  expect_error(check_delays(c()), "The data contains no delays")
  expect_error(check_delays(c(2)), "The data contains only 1 delay")
  expect_error(check_delays(c(0, 1.2, 2.4)), "Decimal values are detected")
  expect_true(check_delays(seq(2, 33, 7)))
  expect_true(check_delays(seq(0, 33, 7)))
  expect_error(check_delays(c(0, 1, 6)), "delays must be evenly distributed")
})
