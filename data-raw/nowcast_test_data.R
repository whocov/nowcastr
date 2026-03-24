library(dplyr)
# library(readxl)

nowcast_test_data <-
  dplyr::tribble(
    ~country, ~onset_week, ~report_week, ~cases,
    # --- Country A: constant underreporting ---
    # "A", "2023-W02", "2023-W01", 1, ## should make error
    "A", "2023-W01", "2023-W01", 70,
    "A", "2023-W01", "2023-W07", 100,
    "A", "2023-W02", "2023-W02", 70,
    "A", "2023-W02", "2023-W07", 100,
    "A", "2023-W03", "2023-W03", 70,
    "A", "2023-W03", "2023-W07", 100,
    "A", "2023-W04", "2023-W04", 70,
    "A", "2023-W04", "2023-W07", 100,
    "A", "2023-W05", "2023-W05", 70,
    "A", "2023-W05", "2023-W07", 100,
    "A", "2023-W06", "2023-W06", 70, # -> normally no prediction because no 1w delay completeness can be found.
    "A", "2023-W07", "2023-W07", 70, # -> should be predicted 100

    # --- Country B: exponential underreporting ---
    # Onset W01:
    "B", "2023-W01", "2023-W01", 1, # delay = 0w ; final val = 4 (x4)
    "B", "2023-W01", "2023-W02", 2, # delay = 1w ; final val = 4 (x2)
    "B", "2023-W01", "2023-W03", 4, # delay = 2w ; this is final val ; to be up-weighted (but no value todo)
    # Onset W02:
    "B", "2023-W02", "2023-W02", 2, # delay = 0w ; final val = 8 (x4)
    "B", "2023-W02", "2023-W03", 8, # delay = 1w ; this is final val ; to be up-weighted (x2)
    # Onset W03:
    "B", "2023-W03", "2023-W03", 11, # to be up-weighted (x4)


    # # --- exponential underreporting ---
    # # this is urrealistic, it wont work because values never stabilise
    # # W01:
    # "B", "2026-W01", "2026-W01", 1, # delay = 0w ;
    # "B", "2026-W01", "2026-W02", 2, # delay = 1w ;
    # "B", "2026-W01", "2026-W03", 4, # delay = 2w ;
    # "B", "2026-W01", "2026-W04", 8, # delay = 3w ;
    # "B", "2026-W01", "2026-W05", 16, # delay = 4w ;
    # "B", "2026-W01", "2026-W06", 32, # delay = 5w ;
    # "B", "2026-W01", "2026-W07", 64, # delay = 6w ;
    # "B", "2026-W01", "2026-W08", 128, # delay = 7w ;
    # "B", "2026-W01", "2026-W09", 256, # delay = 8w ;
    # # W02:
    # "B", "2026-W02", "2026-W02", 1, # delay = 0w ;
    # "B", "2026-W02", "2026-W03", 2, # delay = 1w ;
    # "B", "2026-W02", "2026-W04", 4, # delay = 2w ;
    # "B", "2026-W02", "2026-W05", 8, # delay = 3w ;
    # "B", "2026-W02", "2026-W06", 16, # delay = 4w ;
    # "B", "2026-W02", "2026-W07", 32, # delay = 5w ;
    # "B", "2026-W02", "2026-W08", 64, # delay = 6w ;
    # "B", "2026-W02", "2026-W09", 128, # delay = 7w ;
    # # W03:
    # "B", "2026-W03", "2026-W03", 1, # delay = 0w ;
    # "B", "2026-W03", "2026-W04", 2, # delay = 1w ;
    # "B", "2026-W03", "2026-W05", 4, # delay = 2w ;
    # "B", "2026-W03", "2026-W06", 8, # delay = 3w ;
    # "B", "2026-W03", "2026-W07", 16, # delay = 4w ;
    # "B", "2026-W03", "2026-W08", 32, # delay = 5w ;
    # "B", "2026-W03", "2026-W09", 64, # delay = 6w ;
    # # W04:
    # "B", "2026-W04", "2026-W04", 1, # delay = 0w ;
    # "B", "2026-W04", "2026-W05", 2, # delay = 1w ;
    # "B", "2026-W04", "2026-W06", 4, # delay = 2w ;
    # "B", "2026-W04", "2026-W07", 8, # delay = 3w ;
    # "B", "2026-W04", "2026-W08", 16, # delay = 4w ;
    # "B", "2026-W04", "2026-W09", 32, # delay = 5w ;
    # # W05:
    # "B", "2026-W05", "2026-W05", 1, # delay = 0w ;
    # "B", "2026-W05", "2026-W06", 2, # delay = 1w ;
    # "B", "2026-W05", "2026-W07", 4, # delay = 2w ;
    # "B", "2026-W05", "2026-W08", 8, # delay = 3w ;
    # "B", "2026-W05", "2026-W09", 16, # delay = 4w ;
    # # W06:
    # "B", "2026-W06", "2026-W06", 1, # delay = 0w ;
    # "B", "2026-W06", "2026-W07", 2, # delay = 1w ;
    # "B", "2026-W06", "2026-W08", 4, # delay = 2w ;
    # "B", "2026-W06", "2026-W09", 8, # delay = 3w ;



    ## it takes 8w to reach 100% completeness
    # # W01:
    # "C", "2026-W01", "2026-W01", 100 * .97**8, # delay = 0w ;
    # "C", "2026-W01", "2026-W02", 100 * .97**7, # delay = 1w ;
    # "C", "2026-W01", "2026-W03", 100 * .97**6, # delay = 2w ;
    # "C", "2026-W01", "2026-W04", 100 * .97**5, # delay = 3w ;
    # "C", "2026-W01", "2026-W05", 100 * .97**4, # delay = 4w ;
    # "C", "2026-W01", "2026-W06", 100 * .97**3, # delay = 5w ;
    # "C", "2026-W01", "2026-W07", 100 * .97**2, # delay = 6w ;
    # "C", "2026-W01", "2026-W08", 100 * .97**1, # delay = 7w ;
    # "C", "2026-W01", "2026-W09", 100 * .97**0, # delay = 8w ;
    # # W02:
    # "C", "2026-W02", "2026-W02", 64, # delay = 0w ;
    # "C", "2026-W02", "2026-W03", 72, # delay = 1w ;
    # "C", "2026-W02", "2026-W04", 79, # delay = 2w ;
    # "C", "2026-W02", "2026-W05", 85, # delay = 3w ;
    # "C", "2026-W02", "2026-W06", 90, # delay = 4w ;
    # "C", "2026-W02", "2026-W07", 94, # delay = 5w ;
    # "C", "2026-W02", "2026-W08", 97, # delay = 6w ;
    # "C", "2026-W02", "2026-W09", 99, # delay = 7w ;
    # # W03:
    # "C", "2026-W03", "2026-W03", 64, # delay = 0w ;
    # "C", "2026-W03", "2026-W04", 72, # delay = 1w ;
    # "C", "2026-W03", "2026-W05", 79, # delay = 2w ;
    # "C", "2026-W03", "2026-W06", 85, # delay = 3w ;
    # "C", "2026-W03", "2026-W07", 90, # delay = 4w ;
    # "C", "2026-W03", "2026-W08", 94, # delay = 5w ;
    # "C", "2026-W03", "2026-W09", 97, # delay = 6w ;
    # # W04:
    # "C", "2026-W04", "2026-W04", 64, # delay = 0w ;
    # "C", "2026-W04", "2026-W05", 72, # delay = 1w ;
    # "C", "2026-W04", "2026-W06", 79, # delay = 2w ;
    # "C", "2026-W04", "2026-W07", 85, # delay = 3w ;
    # "C", "2026-W04", "2026-W08", 90, # delay = 4w ;
    # "C", "2026-W04", "2026-W09", 94, # delay = 5w ;
    # # W05:
    # "C", "2026-W05", "2026-W05", 64, # delay = 0w ;
    # "C", "2026-W05", "2026-W06", 72, # delay = 1w ;
    # "C", "2026-W05", "2026-W07", 79, # delay = 2w ;
    # "C", "2026-W05", "2026-W08", 85, # delay = 3w ;
    # "C", "2026-W05", "2026-W09", 90, # delay = 4w ;
    # # W06:
    # "C", "2026-W06", "2026-W06", 64, # delay = 0w ;
    # "C", "2026-W06", "2026-W07", 72, # delay = 1w ;
    # "C", "2026-W06", "2026-W08", 79, # delay = 2w ;
    # "C", "2026-W06", "2026-W09", 85, # delay = 3w ;
    # # W07:
    # "C", "2026-W07", "2026-W07", 64, # delay = 0w ;
    # "C", "2026-W07", "2026-W08", 72, # delay = 1w ;
    # "C", "2026-W07", "2026-W09", 79, # delay = 2w ;
    # # W08:
    # "C", "2026-W08", "2026-W08", 64, # delay = 0w ;
    # "C", "2026-W08", "2026-W09", 72, # delay = 1w ;
    # # W09:
    # "C", "2026-W09", "2026-W09", 64, # delay = 0w ;
  )


# data <-
#   nowcast_test_data2 %>%
#   mutate(
#     onset_date = ISOweek2date(paste0(onset_week, "-1")),
#     report_date = ISOweek2date(paste0(report_week, "-1")) + 0,
#   )






# readxl::write_csv(nowcast_test_data, "data-raw/nowcast_test_data.csv")
usethis::use_data(nowcast_test_data, overwrite = TRUE)
