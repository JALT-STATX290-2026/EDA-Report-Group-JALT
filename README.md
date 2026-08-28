# EDA-Report-Group-JALT

This is the group assignment for STATX290 Statistical Practice: Exploratory Data Analysis (Group) JALT.

## Repository Structure

```         
EDA-Report-Group-JALT/
├── README.md                     <- this file
├── EDA-Report-JALT.qmd           <- report on how data was cleaned, and analysing polls
├── data-cleaning-script.R        <- R script which cleans polling data
└── data/
    ├── raw/                      <- raw data files. DO NOT EDIT
    │   ├── state_polls_2012.csv
    │   ├── state_polls_2016.csv
    |   ├── 1976-2024-president.csv
    │   └── ...
    └── clean/                    <- cleaned data files used for anaylsis
```

`data-cleaning-script.R` contains only the code to clean the data. This only needs to be run once. All of the code is also contained in parts in `EDA-Report-JALT.qmd`. The code will load all required libraries, but will not install any missing ones.
