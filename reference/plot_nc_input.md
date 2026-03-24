# Plot Nowcast Input Data

Can plot 2 types of plot: option="triangle" or "millipede"

## Usage

``` r
plot_nc_input(
  df,
  col_value,
  col_date_occurrence,
  col_date_reporting,
  group_cols = NULL,
  option = "millipede",
  do_rescale = TRUE,
  do_facet_groups = TRUE
)
```

## Arguments

- df:

  A data.frame or tibble.

- col_value:

  Column name for the value.

- col_date_occurrence:

  Column name for the date of occurrence/reference.

- col_date_reporting:

  Column name for the date of reporting.

- group_cols:

  Optional character vector of column names for grouping.

- option:

  "millipede" or "triangle".

- do_rescale:

  Rescale values 0-1. Boolean.

- do_facet_groups:

  Boolean. Should groups be faceted?

## Value

A ggplot object.
