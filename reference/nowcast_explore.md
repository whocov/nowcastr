# Explore Nowcast Results with Shiny

Launch an interactive Shiny application to explore and visualize nowcast
results. The app displays a summary table of model statistics and allows
users to select groups to view corresponding plots for input data, delay
distributions, and nowcast results.

## Usage

``` r
nowcast_explore(nc_obj)
```

## Arguments

- nc_obj:

  A `nowcast_results` S7 object.

## Value

A Shiny app object.
