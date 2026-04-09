### LOAD PKG -----

# pak::pak("whocov/nowcastr") ## install from github
# library(nowcastr)


### WITH DEMO DATA -----
{
  ## Visualize input data
  nowcast_demo %>%
    plot_nc_input(
      option = "triangle",
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = "group"
    )

  ## Fill the missing (optional)
  data <-
    nowcast_demo %>%
    fill_future_reported_values(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = "group",
      max_delay = "auto"
    )

  ## Visualize the change
  data %>%
    plot_nc_input(
      option = "triangle",
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = "group"
    )

  data %>%
    plot_nc_input(
      option = "millipede",
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = "group"
    )

  message("Nowcast")
  nc_obj <- data %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = "group",
      time_units = "weeks",
      do_model_fitting = TRUE,
    )

  ## Delays
  message("Results Delays")
  print(nc_obj@delays)
  fig <- nc_obj %>% plot(which = "delays") +
    labs(
      caption = NULL,
      subtitle = paste0("From data reported on: ", ISOweek::ISOweek(max(data$date_report)))
    )

  ## Results
  message("Results Nowcasts")
  print(nc_obj@results)
  fig <- nc_obj %>% plot(which = "results") +
    labs(
      caption = NULL,
      subtitle = paste0("From data reported on: ", ISOweek::ISOweek(max(data$date_report)))
    )
}


## Evaluation
{
  message("Running Evaluation")
  nc_eval_obj <-
    data %>%
    nowcast_eval(
      n_past = 10,
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      group_cols = "group",
      time_units = "weeks",
      do_model_fitting = TRUE
    )

  message("Evaluation PLots")
  fig <- plot_nowcast_eval(nc_eval_obj)
  fig <- plot_nowcast_eval_detail(nc_eval_obj)
  fig <- plot_nowcast_eval_detail(nc_eval_obj, delay = 1)
}


### WITH GENERATED DATA -----
{
  data <- generate_test_data(100, 15)

  fig1 <- data %>%
    plot_nc_input(
      option = "triangle",
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value
    )

  nc_obj <- data %>%
    nowcast_cl(
      col_date_occurrence = date_occurrence,
      col_date_reporting = date_report,
      col_value = value,
      time_units = "days"
    )

  fig <- nc_obj %>% plot(which = "data", option = "millipede")
  fig <- nc_obj %>% plot()
}
