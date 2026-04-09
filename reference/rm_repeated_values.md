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
  )
#> # A tibble: 191 × 4
#>    date_occurrence date_report delay value
#>    <date>          <date>      <int> <dbl>
#>  1 2025-01-13      2025-02-01     19   100
#>  2 2025-01-14      2025-02-01     18   100
#>  3 2025-01-15      2025-02-01     17   100
#>  4 2025-01-16      2025-02-01     16   100
#>  5 2025-01-17      2025-02-01     15   100
#>  6 2025-01-18      2025-02-01     14   100
#>  7 2025-01-19      2025-02-01     13   100
#>  8 2025-01-20      2025-02-01     12   100
#>  9 2025-01-21      2025-02-01     11   100
#> 10 2025-01-22      2025-02-01     10   100
#> # ℹ 181 more rows
```
