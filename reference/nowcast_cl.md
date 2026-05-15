# Nowcasting with Chain-Ladder Method

Performs nowcasting using non-cumulative Chain-Ladder Method. Input
dataset with 2 date columns; 1 value column; and a flexible number of
group columns. Output dataset with latest reported data joined with
`completeness` ratio and final `value_predicted`. You have the option to
use model-free completeness ratio calculation or use model-fitted
completeness.

## Usage

``` r
nowcast_cl(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL,
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

Returns an **S7 object** of class `nowcast_results`. This object serves
as a comprehensive container for the analysis results and metadata. Use
the `@results` slot to access the primary prediction data frame.

The object includes:

- **Predictions**: The `results` slot contains the latest observed
  values, the calculated `completeness` ratio, and the
  `value_predicted`.

- **Calculation**: Predictions are derived using \\value\\predicted =
  value / completeness\\.

- **Metadata**: Slots for `params`, `time_start`, `max_delay`, and model
  diagnostics (`RSS`).

## Examples

``` r
input <- generate_test_data()
res <- input %>%
  nowcast_cl(
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    time_units = "days"
  )

# Access the predicted data:
head(res@results)
#> # A tibble: 6 × 6
#>   date_occurrence last_r_date delay value value_predicted completeness
#>   <date>          <date>      <dbl> <dbl>           <dbl>        <dbl>
#> 1 2025-02-09      2025-02-09      0  50              98.2        0.509
#> 2 2025-02-08      2025-02-09      1  79.7            99.4        0.802
#> 3 2025-02-07      2025-02-09      2  91.7            99.7        0.920
#> 4 2025-02-06      2025-02-09      3  96.6            99.9        0.968
#> 5 2025-02-05      2025-02-09      4  98.6            99.9        0.987
#> 6 2025-02-04      2025-02-09      5  99.4           100.0        0.995
```
