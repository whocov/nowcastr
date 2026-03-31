# S7 object class for `nowcast_eval()` Results

The
[`nowcast_eval()`](https://whocov.github.io/nowcastr/reference/nowcast_eval.md)
function returns an object of this class.

## Usage

``` r
nowcast_eval_results(
  detail = (function (.data = list(), row.names = NULL) 
 {
     if (is.null(row.names))
    {
         list2DF(.data)
     }
     else {
         out <- list2DF(.data,
    length(row.names))
attr(out, "row.names") <- row.names
         out
     }

    })(),
  summary = (function (.data = list(), row.names = NULL) 
 {
     if (is.null(row.names))
    {
         list2DF(.data)
     }
     else {
         out <- list2DF(.data,
    length(row.names))
attr(out, "row.names") <- row.names
         out
     }

    })(),
  params = list(),
  n_past = integer(0),
  time_start = (function (.data = double(), tz = "") 
 {
     .POSIXct(.data, tz = tz)

    })(),
  time_end = (function (.data = double(), tz = "") 
 {
     .POSIXct(.data, tz = tz)

    })()
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
