# S7 object class for `nowcast_eval()` Results

The
[`nowcast_eval()`](https://whocov.github.io/nowcastr/reference/nowcast_eval.md)
function returns an object of this class.

## Usage

``` r
nowcast_eval_results(
  detail,
  summary,
  params,
  n_past,
  time_start,
  time_end
)
```

## Arguments

- detail:

  data.frame. Per-prediction errors with columns for observed value,
  predicted value, true value, SAPE (pred and obs), and
  `pred_is_better`.

- summary:

  data.frame. Aggregated metrics per group x delay: SMAPE (pred and
  obs), SMAPE improvement, proportion_pred_is_better, Wilson CIs.

- params:

  list. Parameters used for the evaluation run.

- n_past:

  numeric. Number of past reporting periods evaluated.

- time_start:

  POSIXct. Time the function started.

- time_end:

  POSIXct. Time the function ended.
