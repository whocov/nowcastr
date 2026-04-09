# Nowcastr ggplot2 Theme

A clean, ggplot2 theme. Derived from ggplot2::theme_minimal(), with a
few bold elements and softer colors, and bigger texts by default.

## Usage

``` r
theme_nowcastr(
  base_size = 12,
  base_family = "sans",
  color_bg = "#fbfbfb",
  color_grid = "#EEEEEE",
  color_title1 = "#444444",
  color_title2 = "#555555",
  color_title3 = "#666666",
  color_title4 = "#777777"
)
```

## Arguments

- base_size:

  Base font size, in pts.

- base_family:

  Base font family.

- color_bg:

  Colour for plot.background.

- color_grid:

  Colour for major grid lines.

- color_title1:

  Darkest text colour (titles, axis texts).

- color_title2:

  Secondary text colour (legend text, strips, axis titles).

- color_title3:

  Tertiary text colour (legend titles).

- color_title4:

  Lightest text colour (subtitles).

## Value

A `theme` object applied to the current ggplot.

## Examples

``` r
library(ggplot2)

ggplot(mtcars, aes(mpg, wt)) +
  geom_point() +
  theme_nowcastr() +
  labs(
    title = "Fuel efficiency vs. weight",
    subtitle = "Source: Motor Trend US magazine",
    caption = "Data: mtcars"
  )
```
