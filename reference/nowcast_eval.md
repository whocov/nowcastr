# Evaluate Nowcasting Performance

Evaluates the historical performance of
[`nowcast_cl()`](https://whocov.github.io/nowcastr/reference/nowcast_cl.md)
by repeatedly peeling back the most recent reporting period and
comparing predictions against the last reported values (highest
`col_date_reporting` per occurrence date).

## Usage

``` r
nowcast_eval(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL,
  n_past = 10,
  time_units = "days",
  max_delay = NULL,
  max_reportunits = 10,
  max_completeness = 5,
  min_completeness_samples = 1,
  use_weighted_method = TRUE,
  do_propagate_missing_delays = FALSE,
  do_model_fitting = TRUE,
  model_names = c("monomolecular", "vonbertalanffy", "logistic", "gompertz",
    "asymptotic", "linear"),
  do_use_modelled_completeness = TRUE,
  rss_threshold = 0.01
)
```

## Arguments

- df:

  A data.frame or tibble.

- col_date_occurrence:

  Column name for the date of occurrence/reference.

- col_date_reporting:

  Column name for the date of reporting.

- col_value:

  Column name for the value.

- group_cols:

  Optional character vector of column names for grouping.

- n_past:

  Integer. Number of past reporting periods to evaluate. Each iteration
  peels off one reporting period (in `time_units`).

- time_units:

  Time unit for delay calculation. Accepted values: ("auto", "secs",
  "mins", "hours", "days", "weeks").

- max_delay:

  Max delay to keep in the analysis. Interger or NULL. If NULL, will
  take the max delay from the data.

- max_reportunits:

  Max number of col_date_reporting to use (in the unit of time_units).

- max_completeness:

  Maximum completeness ratio (e.g., 2 = 200%).

- min_completeness_samples:

  Min number of samples required to calculate completeness. Integer from
  1 to max_reportunits.

- use_weighted_method:

  Use weighted method, linear weight to older reported completeness
  values

- do_propagate_missing_delays:

  Fill missing completeness if lower delay has a value.

- do_model_fitting:

  Fit a model through the completeness by delay. Models are useful for
  indicators like 'time to 95% compl.' and also soften variability.

- model_names:

  Character vector with names of the models to test for best fit.
  Accepted values: "monomolecular", "vonbertalanffy", "logistic",
  "gompertz", "asymptotic", "linear"

- do_use_modelled_completeness:

  Use the modelled completeness values for the nowcasting. Boolean or
  NULL (for auto selective). (unused if do_model_fitting=FALSE)

- rss_threshold:

  Minimum RSS threshold to use model-fitted values. Only used if
  do_use_modelled_completeness is NULL. If the RSS of the fit is higher
  than this then observed completeness is used for nowcasting.

## Value

An S7 object of class `nowcast_eval_results` with slots:

- detail:

  data.frame with per-prediction errors (one row per occurrence date x
  delay x past period).

- summary:

  data.frame with aggregated SMAPE and proportion_pred_is_better, by
  group and delay.

- params:

  list of parameters used.

- n_past:

  number of past periods evaluated.

- time_start:

  POSIXct start time.

- time_end:

  POSIXct end time.

## Examples

``` r
input <- generate_test_data()
eval_res <- nowcast_eval(
  df = input,
  col_date_occurrence = date_occurrence,
  col_date_reporting = date_report,
  col_value = value,
  n_past = 10,
  time_units = "days"
)
#> Warning: n_past (10) exceeds available reporting periods (8). Will be using the max available instead: 7
```
