# Remove duplicated reported values in reporting matrix

Remove duplicated reported values in reporting matrix

## Usage

``` r
rm_repeated_values(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL
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

## Value

A tibble with the same columns as `df`, but with rows removed.

## Examples

``` r
library(dplyr)
generate_test_data(n_delays = 20, n_reportdates = 20) %>%
  mutate(value = round(value, 1)) %>% ## make values identical
  rm_repeated_values(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report
  ) %>%
  plot_triangle(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report
  )
```
