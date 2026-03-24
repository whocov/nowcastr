library(testthat)
library(ISOweek)
# devtools::document("nowcastr")




test_that("nowcast_cl works with groups", {
  input <- generate_test_data(n_reportdates = 5, n_delays = 5) %>%
    mutate(gr = "A") %>%
    rbind(generate_test_data(n_reportdates = 5, n_delays = 5) %>%
      mutate(gr = "B"))

  res <- input %>%
    nowcast_cl(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      group_cols = c("gr"),
      time_units = "days"
    )

  expect_true(grepl("nowcast_results", class(res)[1]))
  expect_equal(res@params$group_cols, c("gr"))
  expect_true("gr" %in% names(res@results))
  expect_equal(2, length(unique(res@results$gr)))
})

test_that("nowcast_cl outputs correct structure", {
  res <- generate_test_data(n_reportdates = 5, n_delays = 5) %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "days",
      do_model_fitting = F
    )

  expect_true(grepl("nowcast_results", class(res)[1]))
  all_classes <- res@params %>%
    lapply(class) %>%
    unlist() %>%
    unique()
  allowed <- c("character", "NULL", "numeric", "logical") # no "call"
  expect_true(all(all_classes %in% allowed))

  expect_equal(res@params$col_date_occurrence, "date_occurrence")
  expect_equal(res@params$col_date_reporting, "date_report")
  expect_equal(res@params$col_value, "value")
  expect_equal(res@params$time_unit, "days")
  expect_equal(res@params$group_cols, NULL)
  expect_equal(res@params$do_model_fitting, FALSE)
  # expect_equal(res@params$do_propagate_missing_delays, FALSE)
  # expect_equal(res@params$min_completeness_samples, 1)
})


# test_that input validation works
# generate_test_data() %>%
#   nowcast_cl(
#     col_date_occurrence = date_occurrence,
#     col_date_reporting = date_report,
#     col_value = value,
#     time_units = "zzz"
#   )




## xxx
# bug if n are very low:
# test_that("nowcast_cl ... ", {
#   input <- generate_test_data(n_reportdates = 2, n_delays = 2)
#   res <- input %>% nowcast_cl(
#     col_date_occurrence = date_occurrence,
#     col_date_reporting = date_report,
#     col_value = value,
#     time_units = "weeks"
#   )
# })


test_that("nowcast_cl works with generate_test_data", {
  input <- generate_test_data()
  res <- input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "days"
    )
  res <- res@results

  expect_gt(nrow(res), 0)
  expect_true(all(c("value", "value_predicted") %in% names(res)))
  expect_true(all(res$value <= res$value_predicted))
})


test_that("nowcast_cl works with nowcast_demo", {
  input <- nowcast_demo
  res <- input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = "group",
      time_units = "weeks",
    )
  res <- res@results

  # res_delay1 <- res %>% filter(delay == 1)
  # res_delay1$value
  # res_delay1$value_predicted

  expect_gt(nrow(res), 0)
  expect_true(all(c("value", "value_predicted") %in% names(res)))
  # expect_true(all(res_delay1$value != res_delay1$value_predicted))
})



test_that("nowcast_cl works with different types of inputs : 1", {
  input <- generate_test_data()

  ## normal
  res <- input %>%
    nowcast_cl(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      time_units = "days"
    )
  expect_equal(class(res@params$col_value), "character")
  expect_equal(res@params$col_value, "value")
})


test_that("nowcast_cl works with different types of inputs : 2", {
  input <- generate_test_data()

  ## string
  res <- input %>%
    nowcast_cl(
      col_value = "value",
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      time_units = "days"
    )
  expect_equal(class(res@params$col_value), "character")
  expect_equal(res@params$col_value, "value")
})



test_that("nowcast_cl works with different types of inputs : 3", {
  input <- generate_test_data()
  ## symbol
  zzz <- "value"
  s_col_val <- rlang::sym(zzz)
  res <- input %>%
    nowcast_cl(
      col_value = !!s_col_val,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      time_units = "days"
    )
  expect_equal(class(res@params$col_value), "character")
  expect_equal(res@params$col_value, "value")

  ## name in the environment whose value is a character vector
  # res <- input %>%
  #   nowcast_cl(
  #     col_value = zzz, ## will not work -> ERROR: col_value is not in the data
  #     col_date_occurrence = date_occurrence,
  #     col_date_reporting = date_report,
  #     time_units = "days"
  #   )
})



test_that("nowcast_cl works with different types of inputs : 4", {
  input <- generate_test_data()

  ## group cols: single string
  res <- input %>%
    mutate(country = "A") %>%
    nowcast_cl(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      group_cols = "country",
      time_units = "days"
    )
  expect_equal(class(res@params$group_cols), "character")
  expect_equal(res@params$group_cols, "country")
})



test_that("nowcast_cl works with different types of inputs : 5", {
  input <- generate_test_data()
  ## group cols: vector of single string
  res <- input %>%
    mutate(country = "A") %>%
    nowcast_cl(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      group_cols = c("country"),
      time_units = "days"
    )
  expect_equal(class(res@params$group_cols), "character")
  expect_equal(res@params$group_cols, "country")
})



test_that("nowcast_cl works with different types of inputs : 6", {
  input <- generate_test_data()
  ## group cols: vector of multiple strings
  res <- input %>%
    mutate(aa = "A", bb = "B", cc = "C") %>%
    nowcast_cl(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      group_cols = c("aa", "bb", "cc"),
      time_units = "days"
    )
  expect_equal(class(res@params$group_cols), "character")
  expect_equal(res@params$group_cols, c("aa", "bb", "cc"))
})



test_that("nowcast_cl works with different types of inputs : 7", {
  input <- generate_test_data()
  ## group cols: name of single string
  yyy <- c("aa")
  res_7 <- input %>%
    mutate(aa = "A") %>%
    nowcast_cl(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      group_cols = yyy,
      time_units = "days"
    )
  expect_equal(class(res_7@params$group_cols), "character")
  expect_equal(res_7@params$group_cols, "aa")
})



test_that("nowcast_cl works with different types of inputs : 8", {
  input <- generate_test_data()
  ## group cols: name of multiple strings
  yyy <- c("aa", "bb", "cc")
  res_8 <- input %>%
    mutate(aa = "A", bb = "B", cc = "C") %>%
    nowcast_cl(
      col_value = value,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      group_cols = yyy,
      time_units = "days"
    )
  expect_equal(class(res_8@params$group_cols), "character")
  expect_equal(res_8@params$group_cols, c("aa", "bb", "cc"))
})

## group cols: symbol --> Error in !s_group_cols : invalid argument type
# s_group_cols <- rlang::syms('aa')
# res <- input %>%
#   mutate(aa = "A") %>%
#   nowcast_cl(
#     col_value = value,
#     col_date_occurrence = date_occurrence,
#     col_date_reporting = date_report,
#     group_cols = !!!s_group_cols,
#     time_units = "weeks"
#   )




# test_that("xxx", {
# })


# test_that("xxx", {
# })



test_that("nowcast_cl most basic example works", {
  nowcast_test_data <-
    dplyr::tribble(
      ~country, ~onset_week, ~report_week, ~cases,
      # --- Country A: constant underreporting ---
      # "A", "2023-W02", "2023-W01", 1, ## should make error
      "A", "2023-W01", "2023-W01", 70, ## delay=0; comp=70%
      "A", "2023-W01", "2023-W07", 100,
      "A", "2023-W02", "2023-W02", 70, ## delay=0; comp=70%
      "A", "2023-W02", "2023-W07", 100,
      "A", "2023-W03", "2023-W03", 70, ## delay=0; comp=70%
      "A", "2023-W03", "2023-W07", 100,
      "A", "2023-W04", "2023-W04", 70, ## delay=0; comp=70%
      "A", "2023-W04", "2023-W07", 100,
      "A", "2023-W05", "2023-W05", 70, ## delay=0; comp=70%
      "A", "2023-W05", "2023-W07", 100,
      "A", "2023-W06", "2023-W06", 70, # -> normally no prediction because no 1w delay completeness can be found.
      "A", "2023-W07", "2023-W07", 70, # -> should be predicted 100

      # --- Country B: exponential underreporting ---
      # Onset W01:
      "B", "2023-W01", "2023-W01", 1, # delay=0w; comp=25%; final val = 4 (x4)
      "B", "2023-W01", "2023-W02", 2, # delay=1w; comp=50% ; final val = 4 (x2)
      "B", "2023-W01", "2023-W03", 4, # delay=2w; comp=/ ; this is final val ; to be up-weighted (but no cant be done)
      # Onset W02: ;
      "B", "2023-W02", "2023-W02", 2, # delay=0w; comp=25%; final val = 8 (x4)
      "B", "2023-W02", "2023-W03", 8, # delay=1w; comp=/; this is final val ; to be up-weighted (x2)
      # Onset W03:
      "B", "2023-W03", "2023-W03", 11, # to be up-weighted (x4)
    )

  ## convert weeks to dates
  input <-
    nowcast_test_data %>%
    mutate(
      date_occurrence = ISOweek::ISOweek2date(paste0(onset_week, "-1")),
      date_report = ISOweek::ISOweek2date(paste0(report_week, "-1")) + 0,
    ) %>%
    select(-"onset_week", -"report_week")

  # Run nowcast
  res <-
    input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = cases,
      group_cols = "country",
      time_units = "weeks",
      max_delay = 3,
      do_propagate_missing_delays = TRUE,
      do_model_fitting = FALSE,
      use_weighted_method = FALSE
    )
  results <- res@results %>%
    mutate(onset_week = ISOweek::ISOweek(date_occurrence), )

  # --- Test Structure ---
  expect_true("value_predicted" %in% names(results))
  expect_true("completeness" %in% names(results))

  # --- Test Country A ---
  res_A <- results %>% filter(country == "A")
  Aw7 <- res_A %>% filter(onset_week == "2023-W07")
  Aw6 <- res_A %>% filter(onset_week == "2023-W06")
  expect_equal(Aw7$completeness, .7, tolerance = 1e-6)
  expect_equal(Aw7$value_predicted, 100, tolerance = 1e-6)
  expect_gt(Aw6$value_predicted, 70) ## ~100, depends on do_propagate_missing_delays

  # --- Test Country B ---
  res_B <- results %>% filter(country == "B")
  Bw1 <- res_B %>% filter(onset_week == "2023-W01")
  Bw2 <- res_B %>% filter(onset_week == "2023-W02")
  Bw3 <- res_B %>% filter(onset_week == "2023-W03")
  expect_gt(Bw1$value_predicted, 4) ## ~8, depends on do_propagate_missing_delays
  expect_equal(Bw2$value_predicted, 16, tolerance = 1e-6)
  expect_lt(Bw3$completeness, 1) # Completeness must be < 100%
  expect_gt(Bw3$value_predicted, Bw3$cases) # Prediction must be > reported
  expect_equal(Bw3$value_predicted, 44, tolerance = 1e-6) # Based on perfect math of this small set
})



## TIME_UNITS ---

test_that("nowcast_cl (unweighted, nofits), produces same results with lower time_units", {
  input <- generate_test_data(time_units = "weeks")
  res1 <- input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "weeks",
      do_model_fitting = FALSE,
      use_weighted_method = FALSE
    )

  res2 <- input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "days",
      do_model_fitting = FALSE,
      use_weighted_method = FALSE
    )

  comp1 <- res1@results$completeness %>% signif(4)
  comp2 <- res2@results$completeness %>% signif(4)
  expect_setequal(comp1, comp2)
})

test_that("nowcast_cl (weighted, nofits), produces same results with lower time_units", {
  input <- generate_test_data(time_units = "weeks")
  res1 <- input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "weeks",
      do_model_fitting = FALSE,
      use_weighted_method = TRUE
    )

  res2 <- input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "days",
      do_model_fitting = FALSE,
      use_weighted_method = TRUE
    )

  comp1 <- res1@results$completeness %>% signif(4)
  comp2 <- res2@results$completeness %>% signif(4)

  expect_setequal(comp1, comp2)
})

test_that("nowcast_cl (weighted, fits), produces same results with lower time_units", {
  input <- generate_test_data(time_units = "weeks")
  res1 <- input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "weeks",
      use_weighted_method = TRUE,
      do_model_fitting = TRUE,
      do_use_modelled_completeness = TRUE
    )

  res2 <- input %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "days",
      use_weighted_method = TRUE,
      do_model_fitting = TRUE,
      do_use_modelled_completeness = TRUE
    )

  comp1 <- res1@results$completeness %>% signif(4)
  comp2 <- res2@results$completeness %>% signif(4)

  expect_setequal(comp1, comp2)
})
