#| label: read-clean-combine-write
#| eval: false


# Installing packages for cleaning ----------------------------------------

library(tidyverse)   # dplyr, ggplot2, tidyr, readr, stringr, forcats
library(here)        # project-relative paths; don't use setwd()
library(lubridate)   # dates
library(glue)        # easy string manipulation
library(janitor)     # for the clean_names() function

# Set up directories ------------------------------------------------------

raw_dir   <- here("data", "raw")
clean_dir <- here("data", "clean")


# Reading in raw data -----------------------------------------------------

polls_2016_raw <- read_csv(glue("{raw_dir}/state_polls_2016.csv"))
polls_2012_raw <- read_csv(glue("{raw_dir}/state_polls_2012.csv"))
results_1976_2024_raw <- read_csv(glue("{raw_dir}/1976-2024-president.csv"))

# Read in external data
income_raw <- read_csv(glue("{raw_dir}/income_by_state.csv"), skip = 3, col_names = TRUE)
poverty_raw <- read_csv(glue("{raw_dir}/poverty_by_state.csv"), skip = 3, col_names = TRUE)
unemployment_raw <- read_csv(glue("{raw_dir}/unemployment_by_state.csv"), skip = 3, col_names = TRUE)
smokefree_rate_raw <- read_csv(glue("{raw_dir}/smokefree_rate_by_state.csv"), skip = 4, col_names = TRUE)
education_raw <- read_csv(glue("{raw_dir}/education_by_state.csv"), skip = 4, col_names = TRUE)
incarceration_raw <- read_csv(glue("{raw_dir}/percent_children_with_incarcerated_guardian.csv"), skip = 4, col_names = TRUE)


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
polls_2016 <- polls_2016 |>
  mutate(
    year = str_extract(poll_info, "^\\d{4}"),
    state = str_extract(poll_info, "(?<=^\\d{4}-).*?(?=-president)")
  )
polls_2012 <- polls_2012 |>
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

#Cleaning the results dataset ---------------------------------------------

results_1976_2024_clean <- results_1976_2024_raw |>
  select(-c(state_fips, state_ic, state_cen, notes, office, state_po)) |>
  mutate(
    across(
      c(state, party_simplified, party_detailed),
      ~.x |> str_to_kebab() |> factor()
      ),
    percent_voted = round((candidatevotes / totalvotes) * 100, 7),
    has_slash = str_detect(version, "/"), #temporary column used to convert version to date
    version = coalesce(
      dmy(str_replace_all(if_else(has_slash, version, NA_character_), "/", "-")),
      ymd(if_else(has_slash, NA_character_, version))
      ),
    state = state |> fct_recode("washington-dc" = "district-of-columbia")
  ) |>
  select(-c(has_slash, totalvotes)) |>
  filter(if_all(c(candidate, writein, party_simplified), ~ !is.na(.)))

#Cleaning socioeconomic datasets, then combining into one ----------------

  #Quick cleaning function for socioeconomic data. Drops Puerto Rico, formats column names correctly and
  #removes the area code column
fast_clean <- function(raw_dataset)
{
  new_dataset <- raw_dataset |> clean_names() |>
    filter(!(state %in% c("Puerto Rico", "United States"))) |>
    select(-fips) |>
    arrange(state) |>
    mutate(
      state = factor(str_to_kebab(state)) |> 
        fct_recode("washington-dc" = "district-of-columbia")
    ) |>
    na.omit()
  return(new_dataset)
}

#Basic formatting and cleaning, then renaming columns appropriately and removing any unnecessary columns
income <- income_raw |> fast_clean() |>
  rename(family_income = dollars) |>
  select(-3)

poverty <- poverty_raw |> fast_clean() |>
  rename(percent_families_below_poverty = percent) |>
  select(-c(3, 4))

unemployment <- unemployment_raw |> fast_clean() |>
  rename(percent_unemployed = percent) |>
  select(-c(3, 4))

smokefree_rate <- smokefree_rate_raw |> fast_clean() |>
  rename(percent_smokefree = percent_1)

education <- education_raw |> fast_clean() |>
  rename(percent_uneducated = percent) |>
  select(-people_education_less_than_9th_grade, -c(3, 4))

incarceration <- incarceration_raw |> fast_clean() |>
  rename(percent_guardian_incaracerated = percent_1) |>
  mutate(
    percent_guardian_incaracerated = percent_guardian_incaracerated |>
      str_remove_all("!") |> as.numeric()
  )

#Combines all datasets into one
df_list <- list(income, poverty, unemployment, smokefree_rate, education, incarceration)

socioeconomic_clean <- df_list |> reduce(left_join, by = "state")


# Saving data sets as csv in clean folder ---------------------------------

write_csv(polls_long, "data/clean/polls_long_clean.csv")    # combined date
write_csv(polls_2012, "data/clean/polls_2012_clean.csv")    # clean 2012 data
write_csv(polls_2016, "data/clean/polls_2016_clean.csv")    # clean 2016 data
write_csv(polls_2012_long, "data/clean/polls_2012_long_clean.csv")  # 2012 long
write_csv(polls_2016_long, "data/clean/polls_2016_long_clean.csv")  # 2016 long

