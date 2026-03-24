# Calculate retro-scores for all groups

The retro-score is the amount of retro-adjustments / max possible
retro-adjustments The higher the better for nowcast_cl() retro_score =
n_changes / max_changes or = retro_adjustments / max_retro_adj Notes:
"retro-adjustments" = "value changes" retro-score = number of changes /
number of ywks (max changes)

## Usage

``` r
calculate_retro_score(
  df,
  col_date_occurrence,
  col_date_reporting,
  col_value,
  group_cols = NULL,
  method = "2D_allgroups",
  max_delay = Inf,
  aggrby
)
```

## Arguments

- df:

  A data.frame or tibble.

- col_date_occurrence:

  Column name for the date of occurrence/reference.

- col_date_reporting:

  Column name for the date of reporting.

- col_value:

  Column name for the value.

- group_cols:

  Optional character vector of column names for grouping.

- method:

  '2D_allgroups' (number of changes in 2D triangle) or
  'at_least_1_change_by_occ' (number of occurrence dates with at least 2
  reported values)

- max_delay:

  Maximum delay to consider. (only works with method '2D_allgroups')

- aggrby:

  A character vector of column names to aggregate by.

## Value

A tibble with group cols + retro_score (percentage 0-1)

## Examples

``` r
generate_test_data() %>%
  calculate_retro_score(
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    group_cols = NULL
    # , aggrby = country
    # , method = "at_least_1_change_by_occ"
  )
#> # A tibble: 1 × 3
#>   n_changes max_retro_adj retro_score
#>       <dbl>         <dbl>       <dbl>
#> 1        72            72           1
```
