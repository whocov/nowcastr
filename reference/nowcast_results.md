# S7 object class for `nowcast_cl()` Results

The
[`nowcast_cl()`](https://whocov.github.io/nowcastr/reference/nowcast_cl.md)
function returns an object of this class.

## Usage

``` r
nowcast_results(name, params, time_start, time_end, n_groups, max_delay,
  data, completeness, delays, models, results)
```

## Arguments

- name:

  A character string with a timestamp for the run.

- params:

  A list with the parameters used for the nowcasting (unevaluated call).

- time_start:

  the sys time at which the function started.

- time_end:

  the sys time at which the function ended.

- n_groups:

  The number of groups processed.

- max_delay:

  The maximum delay used.

- data:

  Dataframe. The original input data frame (with only required columns).

- completeness:

  Dataframe. The original input data frame with delays and completeness
  columns.

- delays:

  Dataframe. A data frame with the final aggregated completeness
  estimates per delay (+ `modelled` column if do_model_fitting was
  TRUE).

- models:

  Dataframe. The resulting fitted models (empty data frame if
  do_model_fitting was FALSE)

- results:

  Dataframe. A data frame with the resulting nowcasting predictions.

## Value

An **S7 object** of class `nowcast_results`. This object is a structured
container for the entire nowcasting pipeline output. It consists of the
following properties (slots):

- name:

  Character. A unique timestamp identifier for the run
  (`YYYYMMDD_HHMMSS`).

- params:

  List. The evaluated parameters and arguments used in the function
  call.

- time_start, time_end:

  POSIXct. Timestamps marking the duration of the calculation.

- n_groups:

  Numeric. The total count of unique groups processed.

- max_delay:

  Numeric. The maximum reporting delay (in `time_units`) considered.

- data:

  Data frame. The subset of the original input used for the analysis.

- completeness:

  Data frame. Detailed row-level completeness calculations and delays.

- delays:

  Data frame. Aggregated completeness estimates per delay unit,
  including both observed and (optionally) modelled values.

- models:

  Data frame. Results of the non-linear model fitting, including RSS and
  model types. Returns an empty data frame if `do_model_fitting` was
  `FALSE`.

- results:

  Data frame. The final nowcasting table containing predicted values.
