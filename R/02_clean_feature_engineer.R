# ============================================================
# 02_clean_feature_engineer.R
# Clean data + Feature Engineering (Corrected)
# ============================================================

library(ctrdata)
library(nodbi)
library(tidyverse)
library(lubridate)

# ----------------------------------------------------------
# Connect to database
# ----------------------------------------------------------
dbc <- nodbi::src_sqlite(dbname = "data/raw/ctgov_trials.sqlite")
dbc$collection <- "oncology_trials"

message("Extracting fields from database...")

# Extract fields + valid trial concepts only
raw_df <- dbGetFieldsIntoDf(
  fields = c(
    "protocolSection.identificationModule.nctId",
    "protocolSection.statusModule.startDateStruct.date",
    "protocolSection.statusModule.completionDateStruct.date",
    "protocolSection.designModule.phases",
    "protocolSection.designModule.enrollmentInfo.count",
    "protocolSection.sponsorCollaboratorsModule.leadSponsor.class",
    "protocolSection.contactsLocationsModule.locations",
    "protocolSection.designModule.studyType",
    "protocolSection.statusModule.overallStatus"
  ),
  calculate = c("f.startDate", "f.sampleSize", "f.sponsorType", "f.trialPhase", "f.numSites"),
  con = dbc
)

message("Cleaning and creating features...")

clean_df <- raw_df %>%
  # Rename for easier use
  rename(
    nct_id              = protocolSection.identificationModule.nctId,
    completion_date_raw = protocolSection.statusModule.completionDateStruct.date,
    phase_raw           = protocolSection.designModule.phases,
    enrollment_raw      = protocolSection.designModule.enrollmentInfo.count,
    sponsor_class       = protocolSection.sponsorCollaboratorsModule.leadSponsor.class,
    study_type          = protocolSection.designModule.studyType,
    overall_status      = protocolSection.statusModule.overallStatus
  ) %>%
  
  # Use calculated concepts where available
  mutate(
    start_date      = as_date(.startDate),
    completion_date = as_date(completion_date_raw),
    duration_months = as.numeric(completion_date - start_date) / 30.44,
    
    # Prefer calculated sample size if available
    enrollment = coalesce(as.numeric(.sampleSize), as.numeric(enrollment_raw)),
    
    # Prefer calculated number of sites
    n_sites = coalesce(as.integer(.numSites), 
                       map_int(protocolSection.contactsLocationsModule.locations,
                               ~ ifelse(is.null(.x), 0L, length(.x)))),
    
    # Clean phase
    phase_clean = case_when(
      !is.na(.trialPhase) ~ as.character(.trialPhase),
      str_detect(phase_raw, "PHASE1|Phase 1") ~ "Phase 1",
      str_detect(phase_raw, "PHASE2|Phase 2") ~ "Phase 2",
      str_detect(phase_raw, "PHASE3|Phase 3") ~ "Phase 3",
      str_detect(phase_raw, "PHASE4|Phase 4") ~ "Phase 4",
      TRUE ~ "Other/Not Specified"
    ),
    
    # Clean sponsor type
    sponsor_type = case_when(
      !is.na(.sponsorType) ~ as.character(.sponsorType),
      str_detect(sponsor_class, "INDUSTRY|Industry") ~ "Industry",
      TRUE ~ "Other"
    ),
    
    log_enrollment = log1p(enrollment),
    start_year = year(start_date)
  ) %>%
  
  # Keep only useful trials
  filter(
    !is.na(start_date),
    !is.na(completion_date),
    duration_months > 1,
    duration_months < 120,
    overall_status %in% c("COMPLETED", "Completed"),
    study_type == "INTERVENTIONAL"
  ) %>%
  
  select(
    nct_id,
    start_date,
    completion_date,
    duration_months,
    phase_clean,
    sponsor_type,
    enrollment,
    log_enrollment,
    n_sites,
    start_year
  ) %>%
  drop_na(duration_months, enrollment, phase_clean)

# ----------------------------------------------------------
# Summary
# ----------------------------------------------------------
message("\n===== Cleaning Summary =====")
cat("Number of trials after cleaning:", nrow(clean_df), "\n")
cat("Average duration (months):", round(mean(clean_df$duration_months, na.rm = TRUE), 1), "\n")
cat("Median duration (months):", round(median(clean_df$duration_months, na.rm = TRUE), 1), "\n\n")

print(table(clean_df$phase_clean))
print(table(clean_df$sponsor_type))

# Save
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_rds(clean_df, "data/processed/clean_trials.rds")
write_csv(clean_df, "data/processed/clean_trials.csv")

message("\nCleaned data saved successfully!")
message(" → data/processed/clean_trials.rds")

