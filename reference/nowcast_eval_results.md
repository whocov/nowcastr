# S7 object class for Nowcast Evaluation Results

The object returned by
[`nowcast_eval`](https://whocov.github.io/nowcastr/reference/nowcast_eval.md).
It is an S7 class with the following slots (accessible with `@`):

## Usage

``` r
nowcast_eval_results(detail, summary, params, n_past, time_start, time_end)
```

## Arguments

- detail:

  data.frame.

- summary:

  data.frame.

- params:

  list.

- n_past:

  integer.

- time_start:

  POSIXct.

- time_end:

  POSIXct.

## Value

An S7 object of class `nowcast_eval_results`.

## Details

- detail:

  data.frame with per-prediction errors (observed, predicted, last
  reported values).

- summary:

  data.frame with aggregated SMAPE and winrate, by group and delay.

- params:

  list of parameters used.

- n_past:

  number of past periods evaluated.

- time_start:

  POSIXct start time.

- time_end:

  POSIXct end time.

## See also

[`nowcast_eval`](https://whocov.github.io/nowcastr/reference/nowcast_eval.md),
[`plot_nowcast_eval`](https://whocov.github.io/nowcastr/reference/plot_nowcast_eval.md),
[`plot_nowcast_eval_by_delay`](https://whocov.github.io/nowcastr/reference/plot_nowcast_eval_by_delay.md),
[`plot_nowcast_eval_detail`](https://whocov.github.io/nowcastr/reference/plot_nowcast_eval_detail.md)

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

# Access slots
eval_res@summary
#> # A tibble: 10 × 9
#>    delay n_periods n_obs smape_diff_med smape_diff_q1 smape_diff_q3 winrate
#>    <dbl>     <int> <int>          <dbl>         <dbl>         <dbl>   <dbl>
#>  1     0         7     7      0.266          0.243      0.298         1    
#>  2     1         7     7      0.0883         0.0780     0.100         1    
#>  3     2         7     7      0.0321         0.0284     0.0372        1    
#>  4     3         7     7      0.0126         0.0107     0.0144        1    
#>  5     4         7     7      0.00512        0.00421    0.00575       1    
#>  6     5         7     7      0.00207        0.00183    0.00237       1    
#>  7     6         7     7      0.000997       0.000873   0.00104       1    
#>  8     7         7     7      0.000225       0.000139   0.000280      1    
#>  9     8         7     7     -0.0000624     -0.000178  -0.000000725   0.286
#> 10     9         7     7     -0.000198      -0.000334  -0.000127      0    
#> # ℹ 2 more variables: winrate_low <dbl>, winrate_high <dbl>
eval_res@detail
#> # A tibble: 70 × 11
#>    cut_date   date_occurrence last_r_date value value_predicted value_true delay
#>    <date>     <date>          <date>      <dbl>           <dbl>      <dbl> <dbl>
#>  1 2025-02-02 2025-01-24      2025-02-02  100.0           100.       100.0     9
#>  2 2025-02-02 2025-01-25      2025-02-02  100.0           100.       100.0     8
#>  3 2025-02-03 2025-01-25      2025-02-03  100.0           100.       100.0     9
#>  4 2025-02-02 2025-01-26      2025-02-02   99.9           100.       100.0     7
#>  5 2025-02-03 2025-01-26      2025-02-03  100.0           100.       100.0     8
#>  6 2025-02-04 2025-01-26      2025-02-04  100.0           100.       100.0     9
#>  7 2025-02-02 2025-01-27      2025-02-02   99.8           100.0      100.0     6
#>  8 2025-02-03 2025-01-27      2025-02-03   99.9           100.       100.0     7
#>  9 2025-02-04 2025-01-27      2025-02-04  100.0           100.       100.0     8
#> 10 2025-02-05 2025-01-27      2025-02-05  100.0           100.       100.0     9
#> # ℹ 60 more rows
#> # ℹ 4 more variables: SAPE_pred <dbl>, SAPE_obs <dbl>, SAPE_improvement <dbl>,
#> #   isWin <int>
```
