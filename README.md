

# nowcastr

R package for nowcasting with non-cumulative chain-ladder method.  

- 1 main nowcast function
  - `nowcast_cl()` returns object with all intermediary results
- 4 plots, accessible via 1 main `plot()`
  - `plot_triangle()`
  - `plot_millipede()`
  - `plot_delays()`
  - `plot_nowcast()`
- 3 utils functions
  - `calculate_retro_score()`: Calculate retro-scores for all groups
  - `rm_repeated_values()`: Remove duplicated reported values in reporting matrix
  - `fill_future_reported_values()`: Fill future reported values with last known values


## Installation

``` r
install.packages("nowcastr")
```
``` r
devtools::install_github(".../nowcastr")
```
``` r
devtools::load_all("nowcastr")
```

## Usage

The core functionality is provided by the `nowcast_cl()` function.  
You will need a dataset with 2 date columns and a value.  
You can also have one or more group_by column(s) for batch processing.  
(the delays should be the same within all groups)


**Data**

``` r
print(nowcast_demo)

# # A tibble: 1,624 × 4
#     value date_occurrence date_report group        
#     <dbl> <date>         <date>      <chr>
#  1 251563 2024-12-16     2025-05-26  Syndromic ARI
#  2 219818 2024-12-23     2025-05-26  Syndromic ARI
#  3 219815 2024-12-23     2025-06-02  Syndromic ARI
#  4 253451 2024-12-30     2025-05-26  Syndromic ARI
#  5 253454 2024-12-30     2025-06-09  Syndromic ARI
#  6 311660 2025-01-06     2025-05-26  Syndromic ARI
#  7 311666 2025-01-06     2025-06-02  Syndromic ARI
#  8 311654 2025-01-06     2025-06-09  Syndromic ARI
#  9 311657 2025-01-06     2025-06-16  Syndromic ARI
# 10 313798 2025-01-13     2025-05-26  Syndromic ARI
# # ℹ 1,614 more rows

## Visualize input data
nowcast_demo %>%
  plot_nc_input(
    option = "triangle",
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    group_cols = "group"
  )

## Fill the missing (optional)
data <-
  nowcast_demo %>%
  fill_future_reported_values(
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    group_cols = "group",
    max_delay = "auto"
  )

## Visualize the change
data %>%
  plot_nc_input(
    option = "triangle",
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    group_cols = "group"
  )

```

**Nowcast**

``` r
nowcast <- data %>%
  nowcast_cl(
    col_date_occurrence = date_occurrence,
    col_date_reporting = date_report,
    col_value = value,
    group_cols = "group",
    time_units = "weeks",
    do_model_fitting = TRUE,
  )
```


**Plot delays**

``` r
print(nowcast@delays)
nowcast %>% plot(which = "delays")
```


**Plot nowcast**

``` r
print(nowcast@results)
nowcast %>% plot(which = "results")
```


## Methods

Summary:  
1. Input Data: Ensure three core columns: `observed_value` / `date_of_reporting` / `date_of_occurrence` (e.g. date_of_event / date_of_onset)
![alt text](figs/gif2_fig0_5.png)
1. Calculate the `reporting_delay` (= `date_of_reporting` - `date_of_occurrence`)
![alt text](figs/fig_delays.png)
1. Compute the `completeness` (= `observed_value` / `true_value` (approximated by `last_reported_value`))
![alt text](figs/fig_completeness.png)
1. Aggregate the `avg_completeness` for each `reporting_delay`
![alt text](figs/fig1.png)
1. Optional: Fit a curve through that
![alt text](figs/fig3_3.png)
1. Apply Nowcast: `nowcast` = `observed_value` / `avg_completeness`
![alt text](figs/fig4_example.png)

