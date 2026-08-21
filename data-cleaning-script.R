#| label: read-clean-combine-write
#| eval: false

# install.packages(c("tidyverse", "here", "lubridate", "glue"))
library(tidyverse)   # dplyr, ggplot2, tidyr, readr, stringr, forcats
library(here)        # project-relative paths; don't use setwd()
library(lubridate)   # dates
library(glue)        # easy string manipulation

# set up directories
raw_dir   <- here("data", "raw")
clean_dir <- here("data", "clean")

# Election day = first Tuesday after the first Monday in November.
election_day <- c("2012" = as.Date("2012-11-06"),
                  "2016" = as.Date("2016-11-08"))

# read in raw data
polls_2016_raw <- read_csv(glue("{raw_dir}/state_polls_2016.csv"))
polls_2012_raw <- read_csv(glue("{raw_dir}/state_polls_2012.csv"))
results_1976_2024_raw <- read_csv(glue("{raw_dir}/1976-2024-president.csv"))

# clean datasets
# Time to election
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
polls_2016 |>
  ggplot(aes(days_to_election)) +
  geom_histogram(binwidth = 7) +
  scale_x_reverse() +
  labs(x = "Days to election (binned by week)", y = "Number of polls")
polls_2012 |>
  ggplot(aes(days_to_election)) +
  geom_histogram(binwidth = 7) +
  scale_x_reverse() +
  labs(x = "Days to election (binned by week)", y = "Number of polls")

# extracting the year and candidate name for each row
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

# creating longer data sets with each candidate on a new row
candidate_cols_2016 <- c("Trump", "Clinton", "Johnson",
                         "McMullin", "Other", "Undecided")
polls_2016_long <- polls_2016 |>
  pivot_longer(cols = all_of(candidate_cols_2016),
               values_transform = as.numeric,
               names_to = "candidate", values_to = "pct")
candidate_cols_2012 <- c("Obama", "Romney", "Other", "Undecided")
polls_2012_long <- polls_2012 |>
  pivot_longer(cols = all_of(candidate_cols_2012),
               values_transform = as.numeric,
               names_to = "candidate", values_to = "pct")


# combine datasets as required
polls_long <- bind_rows(polls_2012_long, polls_2016_long) |>
  mutate(sample_size = na_if(sample_size, -1),
         across(c(sample_subpopulation, mode, partisanship,
                  partisan_affiliation, state, candidate),
                factor)
  )

# save datasets (ASK MONDAY)
write_csv(polls_long, "data/clean/polls_long_clean.csv")
write_csv(polls_2012, "data/clean/polls_2012_clean.csv")
write_csv(polls_2016, "data/clean/polls_2016_clean.csv")
write_csv(polls_2012_long, "data/clean/polls_2012_long_clean.csv")
write_csv(polls_2016_long, "data/clean/polls_2016_long_clean.csv")