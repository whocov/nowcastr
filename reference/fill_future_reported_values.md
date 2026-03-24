# Fill future reported values with last known values

This function completes a data frame to include all combinations of
occurrence and reporting dates (within each group). It then fills in
missing values by carrying the last known reported value backward in
time from future reports to past reports for a given occurrence. This is
useful for dealing with right-censored reporting data where reports are
updated over time.

## Usage

``` r
fill_future_reported_values(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL,
  max_delay = Inf
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

- max_delay:

  Inf / 'auto' / NULL / integer. 'auto' or NULL will keep the same
  max_delay as the input.

## Value

A data frame with the same columns as `df`, but with rows added for
missing reporting dates and `NA` values in `col_value` filled with the
last available observation for each occurrence date within each group.

## Examples

``` r
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union

generate_test_data() %>%
  fill_future_reported_values(
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    group_cols = NULL
  )
#> # A tibble: 126 × 4
#>    date_occurrence date_report delay value
#>    <date>          <date>      <int> <dbl>
#>  1 2025-02-09      2025-02-09      0  50  
#>  2 2025-02-08      2025-02-09      1  79.7
#>  3 2025-02-08      2025-02-08      0  50  
#>  4 2025-02-07      2025-02-09      2  91.7
#>  5 2025-02-07      2025-02-08      1  79.7
#>  6 2025-02-07      2025-02-07      0  50  
#>  7 2025-02-06      2025-02-09      3  96.6
#>  8 2025-02-06      2025-02-08      2  91.7
#>  9 2025-02-06      2025-02-07      1  79.7
#> 10 2025-02-06      2025-02-06      0  50  
#> # ℹ 116 more rows
```
