# ============================================================
# 01_download_data.R
# Download ClinicalTrials.gov data using {ctrdata}
# Project: Clinical Trial Duration Predictor
# ============================================================

# Load required packages
library(ctrdata)
library(nodbi)
library(tidyverse)

# Create folder if it doesn't exist
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

# ----------------------------------------------------------
# Database connection (corrected version)
# ----------------------------------------------------------
dbc <- nodbi::src_sqlite(dbname = "data/raw/ctgov_trials.sqlite")
dbc$collection <- "oncology_trials"

# ----------------------------------------------------------
# Focused query: Phase 3 only (to stay under 10,000 trials)
# ----------------------------------------------------------
query_url <- "https://clinicaltrials.gov/search?cond=Cancer&aggFilters=status:com,studyType:int,phase:3"

message("Starting download from ClinicalTrials.gov...")
message("Using Phase 3 Oncology trials only...")

# Download the data
ctrLoadQueryIntoDb(
  queryterm = query_url,
  con = dbc,
  euctrresults = FALSE,
  annotation.text = "Oncology - Completed - Interventional - Phase 3",
  annotation.mode = "replace"
)

# Check what was downloaded
history <- dbQueryHistory(con = dbc)
print(history)

message("\nDownload completed successfully!")
message("Database saved at: data/raw/ctgov_trials.sqlite")
