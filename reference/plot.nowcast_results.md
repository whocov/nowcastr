# Plotting method for nowcasting results

This is a plot method which can plot all
[`nowcast_cl()`](https://whocov.github.io/nowcastr/reference/nowcast_cl.md)
outputs:

- data (`which = "data"`)

- delays (`which = "delays"`)

- results (`which = "results"`) It will apply a theme, a caption and a
  facet wrap on groups.

## Usage

``` r
# S3 method for class 'nowcast_results'
plot(x, which, option, do_rescale, add_model_info, ...)
```

## Arguments

- x:

  A `nowcast_results` object.

- which:

  Which plot to draw, one of "results", "data", or "delays".

- option:

  Either "millipede" or "triangle". Only for `which = "data"`.

- do_rescale:

  Rescale values 0-1. Boolean. Only for `which = "data"` or
  `which = "delays"`.

- add_model_info:

  Add model info to the plot. Boolean. Only for `which = "delays"`.

- ...:

  Additional arguments passed to methods.

## Value

A ggplot object.
