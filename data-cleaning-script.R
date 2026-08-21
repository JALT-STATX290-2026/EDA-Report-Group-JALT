#| label: read-clean-combine-write
#| eval: false


# Installing packages for cleaning ----------------------------------------

library(tidyverse)   # dplyr, ggplot2, tidyr, readr, stringr, forcats
library(here)        # project-relative paths; don't use setwd()
library(lubridate)   # dates
library(glue)        # easy string manipulation


# Set up directories ------------------------------------------------------

raw_dir   <- here("data", "raw")
clean_dir <- here("data", "clean")


# Reading in raw data -----------------------------------------------------

polls_2016_raw <- read_csv(glue("{raw_dir}/state_polls_2016.csv"))
polls_2012_raw <- read_csv(glue("{raw_dir}/state_polls_2012.csv"))
results_1976_2024_raw <- read_csv(glue("{raw_dir}/1976-2024-president.csv"))


# Cleaning the datasets ---------------------------------------------------

# Time to election
# Define election day = first Tuesday after the first Monday in November.
election_day <- c("2012" = as.Date("2012-11-06"),
                  "2016" = as.Date("2016-11-08"))

# Adding time to election as column to data sets
polls_2016 <- polls_2016_raw |>
  mutate(
    start_date = as.Date(start_date),
    end_date   = as.Date(end_date),
    days_to_election = as.integer(election_day["2016"] - end_date)
  )
polls_2012 <- polls_2012_raw |>
  mutate(
    start_date = as.Date(start_date),
    end_date   = as.Date(end_date),
    days_to_election = as.integer(election_day["2012"] - end_date)
  )

# Extracting the year and candidate name for each row
polls_2016 <- polls_2016_raw |>
  mutate(
    year = str_extract(poll_info, "^\\d{4}"),
    state = str_extract(poll_info, "(?<=^\\d{4}-).*?(?=-president)")
  )
polls_2012 <- polls_2012_raw |>
  mutate(
    year = str_extract(poll_info, "^\\d{4}"),
    state = str_extract(poll_info, "(?<=^\\d{4}-).*?(?=-president)")
  )

# Creating longer data sets with each candidate on a new row
candidate_cols_2016 <- c("Trump", "Clinton", "Johnson", "McMullin", 
                         "Other", "Undecided")
polls_2016_long <- polls_2016 |>
  pivot_longer(cols = all_of(candidate_cols_2016),
               values_transform = as.numeric,
               names_to = "candidate", values_to = "pct")

candidate_cols_2012 <- c("Obama", "Romney", "Other", "Undecided")
polls_2012_long <- polls_2012 |>
  pivot_longer(cols = all_of(candidate_cols_2012),
               values_transform = as.numeric,
               names_to = "candidate", values_to = "pct")


# Combining datasets into long set ----------------------------------------
# Removing negative population values

polls_long <- bind_rows(polls_2012_long, polls_2016_long) |>
  mutate(sample_size = na_if(sample_size, -1),
         across(c(sample_subpopulation, mode, partisanship,
                  partisan_affiliation, state, candidate),
                factor)
  )


# Saving data sets as csv in clean folder ---------------------------------

write_csv(polls_long, "data/clean/polls_long_clean.csv")    # combined date
write_csv(polls_2012, "data/clean/polls_2012_clean.csv")    # clean 2012 data
write_csv(polls_2016, "data/clean/polls_2016_clean.csv")    # clean 2016 data
write_csv(polls_2012_long, "data/clean/polls_2012_long_clean.csv")  # 2012 long
write_csv(polls_2016_long, "data/clean/polls_2016_long_clean.csv")  # 2016 long