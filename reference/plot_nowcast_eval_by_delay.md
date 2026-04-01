# Plot Nowcast Evaluation by Delay

Plots evaluation metric as a function of delay, faceted by group. The
y-axis shows how much the nowcast improves over raw observed values,
across all delays. Background shading indicates the direction of
improvement.

## Usage

``` r
plot_nowcast_eval_by_delay(
  x,
  indicator = "SMAPE_improvement_med",
  color_good = "dodgerblue1",
  color_bad = "firebrick1",
  ...
)
```

## Arguments

- x:

  A `nowcast_eval_results` S7 object from
  [`nowcast_eval()`](https://whocov.github.io/nowcastr/reference/nowcast_eval.md).

- indicator:

  Character. Which metric to plot on the y-axis. One of:
  `"SMAPE_improvement_med"` (default), `"SMAPE_improvement_mean"`, or
  `"proportion_pred_is_better"`.

- color_good:

  Character. Fill colour for the "better" region. Default `"#2166ac"`.

- color_bad:

  Character. Fill colour for the "worse" region. Default `"#d6604d"`.

- ...:

  Ignored.

## Value

A `ggplot` object.

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
#> Warning: n_past (10) exceeds available reporting periods (8). Using all available.
plot_nowcast_eval_by_delay(eval_res)

plot_nowcast_eval_by_delay(eval_res, indicator = "proportion_pred_is_better")

```
