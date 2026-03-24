## LOAD ---
devtools::load_all("nowcastr")
pacman::p_load(dplyr, tidyr, ISOweek, glue, stringr)








{
  df_raw_long_sm <- readRDS(file = "out/data/df_raw_long_sm.rds") %>% tibble()
  ## ~500K rows

  ## CONVERT TO DATES
  source("scripts/functions.R")
  data1 <-
    df_raw_long_sm %>%
    pipe_add_yw_date() %>%
    pipe_add_rw_date() %>%
    select(-yearweek, -reportweek, -delay) %>%
    # mutate(rw_date = rw_date + 7) %>% ## delay correction ?
    rename()


  # FIND THE BEST RETRO_SCORES ---
  if (0) {
    list_euros <- df_raw_long_sm %>%
      distinct(country) %>%
      filter(stringr::str_detect(country, stringr::fixed("EURO"))) %>%
      pull()

    retro_scores <-
      data1 %>%
      filter(!country %in% list_euros) %>%
      calculate_retro_score(
        group_cols = c("country", "metric"),
        col_value = value,
        col_date_occurrence = yw_date,
        col_date_reporting = rw_date
        # , aggrby = country
        # , method = "at_least_1_change_by_occ"
      )

    # # A tibble: 1,142 × 5
    #    country metric                         n_changes max_retro_adj retro_score
    #    <chr>   <chr>                              <dbl>         <int>       <dbl>
    #  1 GBE     SARS-CoV-2 non-STL Positivity        385           598       0.644
    #  2 GBE     SARS-CoV-2 non-STL Tests             375           598       0.627
    #  3 PRT     SARS-CoV-2 Hospital Admissions       374           598       0.625
    #  4 NOR     Syndromic ILI                        371           598       0.620
    #  5 POL     SARS-CoV-2 non-STL Positivity        320           598       0.535
    #  6 POL     SARS-CoV-2 non-STL Tests             301           598       0.503
    #  7 ESP     Syndromic ARI                        299           598       0.5
    #  8 EST     Syndromic SARI                       212           598       0.355
    #  9 AUT     Syndromic SARI                       208           598       0.348
    # 10 EST     Influenza SARI Tests                 206           598       0.34
  }


  mmm1 <- "SARS-CoV-2 non-STL Positivity"
  ccc1 <- "GBE"

  mmm2 <- "SARS-CoV-2 Hospital Admissions"
  ccc2 <- "PRT"

  mmm3 <- "Syndromic ILI"
  ccc3 <- "NOR"

  mmm4 <- "Syndromic ARI"
  ccc4 <- "ESP"

  ## COMPACT DATASET
  nowcast_demo <-
    data1 %>%
    filter((country == ccc1 & metric == mmm1) |
      (country == ccc2 & metric == mmm2) |
      (country == ccc3 & metric == mmm3) |
      (country == ccc4 & metric == mmm4)) %>%
    rm_repeated_values(
      group_cols = c("country", "metric"),
      col_value = value,
      col_date_occurrence = yw_date,
      col_date_reporting = rw_date
    ) %>%
    # mutate(group = case_when(
    #   metric == mmm1 ~ "ARI",
    #   metric == mmm2 ~ "Hospitalisations",
    #   metric == mmm2 ~ "Positivity",
    #   TRUE ~ metric
    # )) %>%
    mutate(group = metric) %>%
    select(-country, -metric) %>%
    rename(
      date_occurrence = yw_date,
      date_report = rw_date,
    )

  # A tibble: 1,204 × 4


  # nowcast_demo %>% count(group)


  rm(df_raw_long_sm, data1)
  gc()
}



## EXPORT


# data %>% saveRDS("out/data/nowcast_demo.rds")
# data <- readRDS("out/data/nowcast_demo.rds")



# readxl::write_csv(nowcast_test_data, "data-raw/nowcast_test_data.csv")
# usethis::use_data(nowcast_demo, overwrite = TRUE)

# nowcast_demo <- nowcast_demo %>% rename(date_occurrence = date_occurence)

# if (!dir.exists("data")) dir.create("data")
save(nowcast_demo, file = "data/nowcast_demo.rda", compress = "xz")
