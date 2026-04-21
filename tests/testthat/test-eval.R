test_that("nowcast_eval returns S7 object with correct slots", {
  input <- generate_test_data()
  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    n_past = 3,
    time_units = "days"
  )

  expect_s7_class(res, nowcast_eval_results)
  expect_true(is.data.frame(res@detail))
  expect_true(is.data.frame(res@summary))
  expect_type(res@params, "list")
  expect_type(res@n_past, "integer")
  expect_s3_class(res@time_start, "POSIXct")
  expect_s3_class(res@time_end, "POSIXct")
})


test_that("nowcast_eval detail has expected columns", {
  input <- generate_test_data()
  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    n_past = 3,
    time_units = "days"
  )

  expected_cols <- c(
    "cut_date", "delay", "value_predicted", "value_true",
    "SAPE_pred", "SAPE_obs", "SAPE_improvement", "pred_is_better"
  )
  expect_true(all(expected_cols %in% names(res@detail)))
  expect_true(nrow(res@detail) > 0)
})

test_that("nowcast_eval summary has expected columns", {
  input <- generate_test_data()
  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    n_past = 3,
    time_units = "days"
  )

  expected_cols <- c(
    "delay", "SMAPE_pred", "SMAPE_obs", "SMAPE_improvement_med",
    "winrate", "CI_lower", "CI_upper", "n_obs", "n_pairs"
  )
  expect_true(all(expected_cols %in% names(res@summary)))
})

test_that("nowcast_eval n_past is capped when exceeding available periods", {
  input <- generate_test_data()
  expect_warning(
    res <- nowcast_eval(
      df = input,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      n_past = 9999,
      time_units = "days"
    ),
    regexp = "n_past"
  )
  expect_true(res@n_past < 9999)
})

test_that("nowcast_eval rejects invalid inputs", {
  input <- generate_test_data()
  expect_error(nowcast_eval("not a df", date_occurrence, date_report, value, n_past = 1))
  expect_error(nowcast_eval(input, date_occurrence, date_report, value, n_past = -1))
})

test_that("plot_nowcast_eval returns a ggplot", {
  input <- generate_test_data()
  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    n_past = 3,
    time_units = "days"
  )

  p <- plot_nowcast_eval(res)
  expect_s3_class(p, "ggplot")

  p2 <- plot_nowcast_eval(res, delay = min(res@summary$delay))
  expect_s3_class(p2, "ggplot")
})

test_that("plot_nowcast_eval rejects invalid delay", {
  input <- generate_test_data()
  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    n_past = 3,
    time_units = "days"
  )
  expect_error(plot_nowcast_eval(res, delay = -999), regexp = "not found")
})

test_that("plot_nowcast_eval_by_delay returns a ggplot for each indicator", {
  input <- generate_test_data()
  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    n_past = 3,
    time_units = "days"
  )

  for (ind in c("SMAPE_improvement_med", "SMAPE_improvement_mean", "winrate")) {
    p <- plot_nowcast_eval_by_delay(res, indicator = ind)
    expect_s3_class(p, "ggplot")
  }
})

test_that("plot_nowcast_eval_detail returns a ggplot", {
  input <- generate_test_data()
  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    n_past = 3,
    time_units = "days"
  )

  p <- plot_nowcast_eval_detail(res)
  expect_s3_class(p, "ggplot")
})

test_that("plot generic dispatches to plot_nowcast_eval", {
  input <- generate_test_data()
  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    n_past = 3,
    time_units = "days"
  )

  p <- plot(res)
  expect_s3_class(p, "ggplot")
})

test_that("plot functions reject non-nowcast_eval_results input", {
  expect_error(plot_nowcast_eval("wrong"), regexp = "nowcast_eval_results")
  expect_error(plot_nowcast_eval_by_delay("wrong"), regexp = "nowcast_eval_results")
  expect_error(plot_nowcast_eval_detail("wrong"), regexp = "nowcast_eval_results")
})

test_that("nowcast_eval works with grouped data", {
  input <- generate_test_data() %>%
    dplyr::mutate(region = sample(c("A", "B"), dplyr::n(), replace = TRUE))

  res <- nowcast_eval(
    df = input,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    group_cols = "region",
    n_past = 3,
    time_units = "days"
  )

  expect_s7_class(res, nowcast_eval_results)
  expect_true("region" %in% names(res@summary))
  expect_true("region" %in% names(res@detail))

  p <- plot_nowcast_eval(res)
  expect_s3_class(p, "ggplot")
})
