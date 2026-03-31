# Plot Nowcast Evaluation Results

Plots a horizontal bar chart of nowcasting evaluation metrics per group,
at a selected delay. Two panels are shown side by side:

- **SMAPE improvement**: median per-prediction SMAPE difference (obs
  minus pred; positive = prediction is better), with IQR as error bar.

- **Proportion better**: share of past periods where prediction beat raw
  observed, centered at 0 (0.5 = no improvement), with Wilson 95% CI.

Bars are coloured by whether the improvement is significant (IQR / CI
fully above or below zero) or not.

## Usage

``` r
plot_nowcast_eval(
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

  Character. Colour for significantly better predictions. Default
  `"#2166ac"`.

- color_bad:

  Character. Colour for significantly worse predictions. Default
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
plot(eval_res)

plot(eval_res, delay = 2)

```
