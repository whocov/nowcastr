test_that("generate_test_data works", {
  n_delays <- 5
  n_reportdates <- 5
  res <- generate_test_data(n_delays = n_delays, n_reportdates = n_reportdates)

  expect_true(ncol(res) == 4)
  # expect_true(all(c("date_occurrence", "date_report", "delay", "value") %in% names(res)))
  expect_named(res, c("date_occurrence", "date_report", "delay", "value"), ignore.order = TRUE)
  expect_true(nrow(res) == n_delays * n_reportdates)
})


test_that("rm_repeated_values works", {
  res <- generate_test_data(n_delays = 20, n_reportdates = 20) %>% ## 400 records
    mutate(value = round(value, 1)) %>% ## make some values identical
    rm_repeated_values(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report
    )

  ## check visually:
  # res %>%
  # plot_triangle(
  #   col_value = value,
  #   col_date_occurrence = date_occurrence,
  #   col_date_reporting = date_report
  # )

  expect_true(ncol(res) == 4)
  expect_lt(nrow(res), 400)
})


test_that("fill_future_reported_values works", {
  n_delays <- 10
  n_reportdates <- 10
  input <- generate_test_data(n_delays = n_delays, n_reportdates = n_reportdates) ## 100 records
  res <- input %>%
    fill_future_reported_values(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      # max_delay = 'auto'
    )

  expect_true(ncol(res) == ncol(input))
  expect_gt(nrow(res %>% distinct(date_occurrence, date_report)), n_delays * n_reportdates)

  ## visual check:
  # res %>%
  # plot_triangle(
  #   col_value = value,
  #   col_date_occurrence = date_occurrence,
  #   col_date_reporting = date_report
  # )
})


test_that("calculate_retro_score works", {
  res <- generate_test_data() %>%
    calculate_retro_score(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = NULL
      # , aggrby = country
      # , method = "at_least_1_change_by_occ"
    )

  expect_true("retro_score" %in% names(res))
  expect_equal(res$retro_score[1], 1)

  res <- generate_test_data() %>%
    mutate(value = round(value, 1)) %>% ## make some values identical
    calculate_retro_score(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = NULL
      # , aggrby = country
      # , method = "at_least_1_change_by_occ"
    )
  expect_lte(res$retro_score[1], 1)
  expect_gte(res$retro_score[1], 0)
})
