# S7 object class for `nowcast_cl()` Results

The `nowcast_cl` function returns an object of this class.

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
