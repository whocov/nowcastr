# Millipede plot

Draw a line plot where each line represents one reporting date:

- x = date of occurrence

- y = value (e.g., counts or proportions)

- group + fill = date of reporting

## Usage

``` r
plot_millipede(
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

When there are reporting delays the plot look like this:

    ---\--\--\--\
        \  \  \  \
         \  \  \  \

## See also

ggplot2::geom_line, ggplot2::scale_color_viridis_c

## Examples

``` r
generate_test_data() %>%
  plot_millipede(
    col_value = value,
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    scale_percent = FALSE
  )

```
