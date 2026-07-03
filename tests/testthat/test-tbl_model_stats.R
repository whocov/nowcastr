test_that("tbl_models_stats returns a tibble with expected columns", {
  input <- generate_test_data()
  nc_obj <- input %>%
    nowcast_cl(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      time_units = "days"
    )

  model_stats <- nc_obj %>% tbl_models_stats()

  expect_s3_class(model_stats, "data.frame")

  expected_cols <- c(
    "iterations", "modelname", "a", "b", "c",
    "R2", "RSS", "t_to_95_obs", "t_to_95_model",
    "start_completeness_obs", "start_completeness_pred",
    "end_completeness_obs", "end_completeness_pred",
    "eval"
  )
  expect_true(all(expected_cols %in% names(model_stats)))
})

test_that("R2 is bounded above by 1 and rounded to 3 decimals", {
  input <- generate_test_data()
  nc_obj <- input %>% nowcast_cl(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    time_units = "days"
  )
  model_stats <- tbl_models_stats(nc_obj)

  r2 <- model_stats$R2[!is.na(model_stats$R2)]
  expect_true(all(r2 <= 1))
  expect_equal(r2, round(r2, 3))
})

test_that("eval is only Good Fit or Bad Fit", {
  input <- generate_test_data()
  nc_obj <- input %>% nowcast_cl(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    time_units = "days"
  )
  model_stats <- tbl_models_stats(nc_obj)

  expect_true(all(model_stats$eval %in% c("Good Fit", "Bad Fit")))
})

test_that("Good Fit rows satisfy the stated criteria", {
  input <- generate_test_data()
  nc_obj <- input %>% nowcast_cl(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    time_units = "days"
  )
  model_stats <- tbl_models_stats(nc_obj, thresholds_r2 = 0.8)

  good <- model_stats[model_stats$eval == "Good Fit", ]
  if (nrow(good) > 0) {
    expect_true(all(good$modelname != "linear"))
    expect_true(all(good$R2 > 0.8))
    expect_true(all(good$end_completeness_pred > 0.95 & good$end_completeness_pred < 1.05))
  }
})

test_that("raising thresholds_r2 never increases the number of Good Fit rows", {
  input <- generate_test_data()
  nc_obj <- input %>% nowcast_cl(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    time_units = "days"
  )

  low <- tbl_models_stats(nc_obj, thresholds_r2 = 0.5)
  high <- tbl_models_stats(nc_obj, thresholds_r2 = 0.95)

  n_good_low <- sum(low$eval == "Good Fit")
  n_good_high <- sum(high$eval == "Good Fit")

  expect_true(n_good_high <= n_good_low)
})

test_that("rows are sorted worst-fit first (ascending R2)", {
  input <- generate_test_data()
  nc_obj <- input %>% nowcast_cl(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    time_units = "days"
  )
  model_stats <- tbl_models_stats(nc_obj)

  r2_non_na <- model_stats$R2[!is.na(model_stats$R2)]
  expect_true(all(diff(r2_non_na) >= 0))
})

test_that("linear model rows are never classified Good Fit", {
  input <- generate_test_data() %>% mutate(value = 9)
  nc_obj <- input %>% nowcast_cl(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    time_units = "days"
  )
  model_stats <- tbl_models_stats(nc_obj, thresholds_r2 = 0) # lowest possible bar

  linear_rows <- model_stats[model_stats$modelname == "linear", ]
  if (nrow(linear_rows) > 0) {
    expect_true(all(linear_rows$eval == "Bad Fit"))
  }
})

test_that("empty models slot is returned unchanged", {
  input <- generate_test_data()
  nc_obj <- input %>% nowcast_cl(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    time_units = "days"
  )
  nc_obj@models <- nc_obj@models[0, ]

  result <- tbl_models_stats(nc_obj)
  expect_identical(result, nc_obj@models)
})

test_that("group columns from nc_obj@params are preserved in output", {
  input <-
    bind_rows(
      generate_test_data() %>% mutate(group = "A"),
      generate_test_data() %>% mutate(group = "B")
    )
  nc_obj <- input %>% nowcast_cl(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    group_cols = c("group"),
    time_units = "days"
  )
  model_stats <- tbl_models_stats(nc_obj)

  group_cols <- nc_obj@params$group_cols
  if (!is.null(group_cols) && length(group_cols) > 0) {
    expect_true(all(group_cols %in% names(model_stats)))
  }
})
