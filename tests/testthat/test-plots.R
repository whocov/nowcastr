test_that("plot_triangle produces a geom_raster ggplot with correct labels", {
  fig <- generate_test_data() %>%
    plot_triangle(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value
    )

  expect_s3_class(fig, "ggplot")
  # expect_equal(fig$labels$x, "Date Of Occurrence")
  # expect_equal(fig$labels$y, "Date Of Reporting")
  has_raster <- any(vapply(fig$layers, function(l) inherits(l$geom, "GeomRaster"), logical(1)))
  expect_true(has_raster)
})

test_that("plot_millipede produces a line ggplot with correct labels", {
  fig <- generate_test_data() %>%
    plot_millipede(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value
    )

  expect_s3_class(fig, "ggplot")
  # expect_equal(fig$labels$x, "Date Of Occurrence")
  # expect_equal(fig$labels$y, "Value")
  # expect_equal(fig$labels$colour, "Date Of Reporting")
  has_line <- any(vapply(fig$layers, function(l) inherits(l$geom, "GeomLine"), logical(1)))
  expect_true(has_line)
})

test_that("plot_nowcast produces two line layers (observed + predicted)", {
  data <- generate_test_data() %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "days"
    )

  fig <- data@results %>%
    plot_nowcast(
      col_date_occurrence = date_occurrence,
      col_value = value,
      col_value_predicted = value_predicted
    )

  expect_s3_class(fig, "ggplot")
  # expect_equal(fig$labels$x, "Date Of Occurrence")
  # expect_equal(fig$labels$y, "Value")
  n_line_layers <- sum(vapply(fig$layers, function(l) inherits(l$geom, "GeomLine"), logical(1)))
  expect_gte(n_line_layers, 2)
})

test_that("plot_delays produces points and adds model line when modelled is present", {
  nowcast <- generate_test_data() %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "days"
    )
  input <- nowcast@delays

  fig <- input %>%
    plot_delays(
      col_completeness_obs = "completeness_obs",
      col_completeness_modelled = "completeness_modelled"
    )

  expect_s3_class(fig, "ggplot")
  expect_true(any(vapply(fig$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1))))
  expect_true(any(vapply(fig$layers, function(l) inherits(l$geom, "GeomLine"), logical(1))))




  ## test it works with non-character names as well (tidy-eval)
  fig2 <- input %>%
    plot_delays(
      col_completeness_obs = completeness_obs,
      col_completeness_modelled = completeness_modelled
    )


  expect_s3_class(fig, "ggplot")
  expect_true(any(vapply(fig2$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1))))
  expect_true(any(vapply(fig2$layers, function(l) inherits(l$geom, "GeomLine"), logical(1))))


  # expect_equal(fig, fig2) # doesnt work because it will start evaluating symbols that dont exist.
  # expect_true(all.equal(fig, fig2)) # seems to work but might unsafe

  b1 <- ggplot_build(fig)
  b2 <- ggplot_build(fig2)
  expect_equal(b1$data, b2$data)
})
