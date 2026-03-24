# Generate asymptotic test data for nowcating

Create synthetic long-format test data following an asymptotic delay
curve and constant final value. Formula:
`value = final_value * (c + 1 * (1 - exp(-b * .data$delay))))`

## Usage

``` r
generate_test_data(
  reportdate_from = "2025-02-01",
  n_reportdates = 9,
  delay_from = 0,
  n_delays = 10,
  time_units = "days",
  final_value = 100,
  c = 0.5,
  b = 0.9,
  remove_delay = FALSE
)
```

## Arguments

- reportdate_from:

  Character or Date. Start report date (e.g. "2025-02-01").

- n_reportdates:

  Integer. Number of consecutive report dates to generate.

- delay_from:

  Integer \>= 0. Minimum delay value.

- n_delays:

  Integer. Number of delay values to generate.

- time_units:

  Time units. Accepted values: ("auto", "secs", "mins", "hours", "days",
  "weeks").

- final_value:

  Numeric. Asymptotic target (a in the formula).

- c:

  Numeric (0-1). Baseline fraction of final_value added to the curve.

- b:

  Numeric. Rate constant controlling how fast y approaches a; larger b →
  faster approach.

- remove_delay:

  Logical. If TRUE, remove the delay column in the output.

## Value

A tibble (long format) with columns date_report (Date), date_occurrence
(Date), delay (integer, optional) and value (numeric).

## Details

With defaults this returns n_reportdates × (n_delays - delay_from + 1)
rows (9 × 10 = 90). reportdate_from may be provided as a Date or
parsable character; lubridate units are used for stepping.

## Examples

``` r
generate_test_data()
#> # A tibble: 90 × 4
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
#> # ℹ 80 more rows
generate_test_data(n_reportdates = 3, n_delays = 3) # A tibble: 9 × 4
#> # A tibble: 9 × 4
#>   date_occurrence date_report delay value
#>   <date>          <date>      <int> <dbl>
#> 1 2025-02-03      2025-02-03      0  50  
#> 2 2025-02-02      2025-02-03      1  79.7
#> 3 2025-02-02      2025-02-02      0  50  
#> 4 2025-02-01      2025-02-03      2  91.7
#> 5 2025-02-01      2025-02-02      1  79.7
#> 6 2025-02-01      2025-02-01      0  50  
#> 7 2025-01-31      2025-02-02      2  91.7
#> 8 2025-01-31      2025-02-01      1  79.7
#> 9 2025-01-30      2025-02-01      2  91.7
generate_test_data(time_units = "weeks", remove_delay = TRUE)
#> # A tibble: 90 × 3
#>    date_occurrence date_report value
#>    <date>          <date>      <dbl>
#>  1 2025-03-29      2025-03-29   50  
#>  2 2025-03-22      2025-03-29   79.7
#>  3 2025-03-22      2025-03-22   50  
#>  4 2025-03-15      2025-03-29   91.7
#>  5 2025-03-15      2025-03-22   79.7
#>  6 2025-03-15      2025-03-15   50  
#>  7 2025-03-08      2025-03-29   96.6
#>  8 2025-03-08      2025-03-22   91.7
#>  9 2025-03-08      2025-03-15   79.7
#> 10 2025-03-08      2025-03-08   50  
#> # ℹ 80 more rows
```
