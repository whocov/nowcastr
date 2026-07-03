# Compute table with models result stats.

Summarizes fitted growth models per group, computing R-squared, fit
evaluation (good/bad), and completeness at start/end of observed data.

## Usage

``` r
tbl_models_stats(nc_obj, thresholds_r2 = 0.8)
```

## Arguments

- nc_obj:

  A `nowcast_results` object.

- thresholds_r2:

  Numeric scalar. R-squared threshold above which (combined with end
  completeness near 1) a model is classified `"Good Fit"`.

## Value

A tibble with one row per fitted model, including columns for group
variables, `R2`, `RSS`, model coefficients (`a`, `b`, `c`), completeness
at start/end, and `eval` ("Good Fit"/"Bad Fit"). If `nc_obj@models` has
no rows, it is returned unchanged.

## Examples

``` r
if (FALSE) { # \dontrun{
tbl_models_stats(nc_obj)
tbl_models_stats(nc_obj, thresholds_r2 = 0.9)
} # }
```
