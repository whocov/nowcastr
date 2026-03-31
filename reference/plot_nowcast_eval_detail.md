# Plot Nowcast Evaluation Detail Over Time

For a selected delay, plots predicted and observed values over time
alongside the eventual true value. Vertical segments show which estimate
(raw observed or predicted) was closer to truth for each occurrence
date.

## Usage

``` r
plot_nowcast_eval_detail(
  x,
  delay = NULL,
  color_good = "#2166ac",
  color_bad = "#d6604d",
  ...
)
```

## Arguments

- x:

  A `nowcast_eval_results` S7 object from
  [`nowcast_eval()`](https://whocov.github.io/nowcastr/reference/nowcast_eval.md).

- delay:

  Numeric. Which delay to plot. Defaults to the minimum delay in the
  data.

- color_good:

  Character. Colour when prediction beats raw observed. Default
  `"#2166ac"`.

- color_bad:

  Character. Colour when raw observed beats prediction. Default
  `"#d6604d"`.

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
plot_nowcast_eval_detail(eval_res)

plot_nowcast_eval_detail(eval_res, delay = 7)

```
