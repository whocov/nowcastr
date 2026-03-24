# Triangle plot

Draw a triangular heatmap where:

- x = date of occurrence

- y = date of reporting

- fill = value (e.g., counts or proportions)

## Usage

``` r
plot_triangle(
  df,
  col_value,
  col_date_occurrence,
  col_date_reporting,
  scale_percent = FALSE
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

- scale_percent:

  Logical; if TRUE formats the fill legend as percentages and labels it
  "Percentage".

## Value

A ggplot object.

## Details

The plot is triangular because reporting dates cannot precede occurrence
dates.

    |---------/
    |        /
    |       /
    |      /
    |     /
    |----/

Uses geom_raster with coord_fixed for square tiles.

## See also

ggplot2::geom_raster, ggplot2::scale_fill_viridis_c

## Examples

``` r
generate_test_data() %>%
  plot_triangle(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    scale_percent = FALSE
  )

```
