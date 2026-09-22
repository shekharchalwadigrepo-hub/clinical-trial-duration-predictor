# ============================================================
# 04_utils.R
# Helper / Utility functions
# Project: Clinical Trial Duration Predictor
# ============================================================

#' Load the cleaned trials data
#'
#' @return A tibble with cleaned clinical trial data
load_clean_data <- function() {
  path <- "data/processed/clean_trials.rds"
  
  if (!file.exists(path)) {
    stop("Cleaned data not found. Please run 02_clean_feature_engineer.R first.")
  }
  
  readr::read_rds(path)
}

#' Load the best trained model
#'
#' @return A fitted workflow / model object
load_best_model <- function() {
  path <- "models/best_duration_model.rds"
  
  if (!file.exists(path)) {
    stop("Model not found. Please run 03_model_train.R first.")
  }
  
  readr::read_rds(path)
}

#' Predict trial duration for new data
#'
#' @param model Fitted model
#' @param new_data A data frame with the required predictors
#' @return A tibble with predictions
predict_duration <- function(model, new_data) {
  predict(model, new_data) %>%
    dplyr::rename(predicted_duration = .pred)
}

#' Format duration nicely
#'
#' @param months Numeric vector of months
#' @return Character vector (e.g. "2.3 years")
format_duration <- function(months) {
  years <- months / 12
  ifelse(
    years < 1,
    paste0(round(months, 1), " months"),
    paste0(round(years, 1), " years")
  )
}

#' Quick summary of the cleaned dataset
#'
#' @param data Cleaned data frame
summarise_trials <- function(data = load_clean_data()) {
  cat("===== Clinical Trial Dataset Summary =====\n")
  cat("Total trials:        ", nrow(data), "\n")
  cat("Date range:          ", 
      min(data$start_date, na.rm = TRUE), "to", 
      max(data$start_date, na.rm = TRUE), "\n")
  cat("Average duration:    ", round(mean(data$duration_months, na.rm = TRUE), 1), "months\n")
  cat("Median duration:     ", round(median(data$duration_months, na.rm = TRUE), 1), "months\n\n")
  
  cat("Phase distribution:\n")
  print(table(data$phase_clean))
  
  cat("\nSponsor type:\n")
  print(table(data$sponsor_type))
}

#' Create a simple prediction input row (useful for Shiny)
#'
#' @param phase Phase of the trial
#' @param sponsor_type Industry or Other
#' @param enrollment Number of participants
#' @param n_sites Number of sites
#' @param start_year Year the trial started
#' @return A one-row tibble ready for prediction
make_prediction_input <- function(phase = "Phase 2",
                                  sponsor_type = "Industry",
                                  enrollment = 200,
                                  n_sites = 20,
                                  start_year = 2020) {
  
  tibble::tibble(
    phase_clean    = phase,
    sponsor_type   = sponsor_type,
    log_enrollment = log1p(enrollment),
    n_sites        = n_sites,
    start_year     = start_year
  )
}