test_that("check_delays works", {
  expect_error(check_delays(c()), "The data contains no delays")
  expect_error(check_delays(c(2)), "The data contains only 1 delay")
  expect_error(check_delays(c(0, 1.2, 2.4)), "Decimal values are detected")
  expect_true(check_delays(seq(2, 33, 7)))
  expect_true(check_delays(seq(0, 33, 7)))
  expect_error(check_delays(c(0, 1, 6)), "delays must be evenly distributed")
})


test_that("fit_model works for monomolecular", {
  data <- data.frame(x = 0:9, y = 1 - exp(-0.5 * 0:9))
  fit <- fit_model(data, "monomolecular")
  expect_s3_class(fit, "nls")
  expect_true(coef(fit)["b"] > 0)
})

test_that("fit_model works for linear", {
  data <- data.frame(x = 0:9, y = 0:9)
  fit <- fit_model(data, "linear")
  expect_s3_class(fit, "lm")
})

test_that("fit_model returns NULL for insufficient data", {
  data <- data.frame(x = 0:1, y = c(0, 1))
  expect_null(fit_model(data, "monomolecular"))
  expect_s3_class(fit_model(data, "linear"), "lm")
})

test_that("fit_model works for logistic", {
  data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .9, .95, .975, .985, .995, 1))
  fit <- fit_model(data, "logistic")
  expect_s3_class(fit, "nls")
})

test_that("fit_model works for gompertz", {
  data <- data.frame(x = 1:10, y = exp(-2 * exp(-0.5 * 1:10)))
  fit <- fit_model(data, "gompertz")
  expect_s3_class(fit, "nls")
})

test_that("fit_model works for asymptotic", {
  data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .9, .95, .975, .985, .995, 1))
  fit <- fit_model(data, "asymptotic")
  expect_s3_class(fit, "nls")
})

test_that("fit_model works for vonbertalanffy", {
  data <- data.frame(x = 0:9, y = 100 * (1 - exp(-0.1 * (0:9)))^3)
  fit <- fit_model(data, "vonbertalanffy")
  expect_s3_class(fit, "nls")
})

test_that("fit_model works for monomolecular_with_offset", {
  data <- data.frame(x = 0:9, y = 0.5 + 1 * (1 - exp(-0.5 * 0:9)))
  fit <- fit_model(data, "monomolecular_with_offset")
  expect_s3_class(fit, "nls")
})

test_that("fit_model returns NULL on convergence failure", {
  data <- data.frame(x = rep(0, 5), y = rep(1, 5))
  expect_null(fit_model(data, "monomolecular"))
})

test_that("fit_models selects best model", {
  data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .9, .95, .975, .985, .995, 1))
  fit <- fit_models(data)
  expect_s3_class(fit, c("nls", "lm"))
})

test_that("fit_models returns linear for small data", {
  data <- data.frame(x = 0:1, y = c(0, 1))
  fit <- fit_models(data)
  expect_s3_class(fit, "lm")
})

test_that("fit_models returns NULL for empty data", {
  data <- data.frame(x = numeric(0), y = numeric(0))
  expect_null(fit_models(data))
})

test_that("fit_models handles constant y values", {
  data <- data.frame(x = 0:9, y = rep(0.5, 10))
  fit <- fit_models(data)
  expect_s3_class(fit, "lm")
})

test_that("fit_models aborts on invalid modelnames", {
  data <- data.frame(x = 0:9, y = 0:9)
  expect_error(fit_models(data, modelnames = "invalid"), "Invalid model")
})

test_that("fit_models respects modelnames argument", {
  data <- data.frame(x = 0:9, y = 0:9)
  fit <- fit_models(data, modelnames = "linear")
  expect_s3_class(fit, "lm")
})

test_that("detect_model_type identifies linear", {
  data <- data.frame(x = 0:9, y = 0:9)
  fit <- fit_model(data, "linear")
  expect_equal(detect_model_type(fit), "linear")
})

test_that("detect_model_type identifies monomolecular", {
  data <- data.frame(x = 0:9, y = 1 - exp(-0.5 * 0:9))
  fit <- fit_model(data, "monomolecular")
  expect_equal(detect_model_type(fit), "monomolecular")
})

test_that("detect_model_type identifies logistic", {
  data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .9, .95, .975, .985, .995, 1))
  fit <- fit_model(data, "logistic")
  expect_equal(detect_model_type(fit), "logistic")
})

test_that("detect_model_type identifies gompertz", {
  data <- data.frame(x = 1:10, y = exp(-2 * exp(-0.5 * 1:10)))
  fit <- fit_model(data, "gompertz")
  expect_equal(detect_model_type(fit), "gompertz")
})

test_that("detect_model_type identifies asymptotic", {
  data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .9, .95, .975, .985, .995, 1))
  fit <- fit_model(data, "asymptotic")
  expect_equal(detect_model_type(fit), "asymptotic")
})

test_that("detect_model_type identifies vonbertalanffy", {
  data <- data.frame(x = 0:9, y = 100 * (1 - exp(-0.1 * (0:9)))^3)
  fit <- fit_model(data, "vonbertalanffy")
  expect_equal(detect_model_type(fit), "vonbertalanffy")
})

test_that("extract_model_params returns coefficients for lm", {
  data <- data.frame(x = 0:9, y = 0:9)
  fit <- fit_model(data, "linear")
  params <- extract_model_params(fit)
  expect_type(params, "double")
  expect_length(params, 2)
})

test_that("extract_model_params returns coefficients for nls", {
  data <- data.frame(x = 0:9, y = 1 - exp(-0.5 * 0:9))
  fit <- fit_model(data, "monomolecular")
  params <- extract_model_params(fit)
  expect_type(params, "double")
  expect_length(params, 2)
})

test_that("extract_model_params returns NULL for invalid input", {
  expect_null(extract_model_params(list()))
})

test_that("predict_values_from_fit returns data.frame for normal models", {
  data <- data.frame(x = 0:9, y = 1 - exp(-0.5 * 0:9))
  fit <- fit_model(data, "monomolecular")
  result <- predict_values_from_fit(fit, c(0, 5, 10))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_named(result, c("x", "y"))
})

test_that("predict_values_from_fit returns constant for flat linear", {
  data <- data.frame(x = rep(1, 10), y = rep(0.5, 10))
  fit <- fit_model(data, "linear")
  result <- predict_values_from_fit(fit, c(0, 5, 10))
  expect_type(result, "double")
  expect_length(result, 1)
  expect_equal(result, 0.5)
})

test_that("predict_values_from_fit returns NULL for NULL input", {
  expect_null(predict_values_from_fit(NULL, 0:9))
})

test_that("get_time_to_95_105_discrete returns correct time", {
  data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .95, .96, .97, .98, .99, 1))
  result <- get_time_to_95_105_discrete(data)
  expect_equal(result, 4)
})

test_that("get_time_to_95_105_discrete returns NA if never reached", {
  data <- data.frame(x = 0:9, y = seq(0, 0.9, by = 0.1))
  result <- get_time_to_95_105_discrete(data)
  expect_equal(result, NA)
})

test_that("get_time_to_95_105_discrete returns NA for NULL input", {
  expect_equal(get_time_to_95_105_discrete(NULL), NA)
})

test_that("get_time_to_95_105_precise returns correct time", {
  data <- data.frame(x = 0:9, y = c(0, .5, .7, .8, .9, .95, .975, .985, .995, 1))
  fit <- fit_models(data)
  result <- get_time_to_95_105_precise(fit)
  expect_type(result, "double")
  expect_true(result > 0)
})

test_that("get_time_to_95_105_precise returns NA for NULL input", {
  expect_equal(get_time_to_95_105_precise(NULL), NA_real_)
})

test_that("get_time_to_95_105_precise returns NA for try-error input", {
  expect_equal(get_time_to_95_105_precise(structure("err", class = "try-error")), NA_real_)
})

test_that("get_time_to_95_105_precise returns 0 if starts in band", {
  data <- data.frame(x = 0:9, y = rep(0.97, 10))
  fit <- fit_model(data, "linear")
  result <- get_time_to_95_105_precise(fit)
  expect_equal(result, 0)
})

test_that("get_time_to_95_105_precise returns NA if never reaches band", {
  data <- data.frame(x = 0:100, y = pmin(0.5 + 0:100 * 0.004, 0.9))
  fit <- fit_models(data)
  result <- get_time_to_95_105_precise(fit, max_delay = 100)
  expect_equal(result, NA_real_)
})
