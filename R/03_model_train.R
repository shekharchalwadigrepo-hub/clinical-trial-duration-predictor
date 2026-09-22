# ============================================================
# 03_model_train.R
# Train models to predict clinical trial duration
# Project: Clinical Trial Duration Predictor
# ============================================================
library(ranger)
library(tidyverse)
library(tidymodels)
library(lubridate)
library(glmnet)

# ----------------------------------------------------------
# 1. Load cleaned data
# ----------------------------------------------------------
clean_df <- read_rds("data/processed/clean_trials.rds")

message("Loaded cleaned data: ", nrow(clean_df), " trials")

# ----------------------------------------------------------
# 2. Create time-based train/test split (important!)
# ----------------------------------------------------------
# Train on older trials, test on more recent ones
# This is more realistic than a random split

split_year <- 2018   # You can adjust this

train_data <- clean_df %>% filter(start_year < split_year)
test_data  <- clean_df %>% filter(start_year >= split_year)

message("Training set: ", nrow(train_data), " trials (before ", split_year, ")")
message("Test set:     ", nrow(test_data), " trials (", split_year, " and later)")

# ----------------------------------------------------------
# 3. Prepare recipe
# ----------------------------------------------------------
duration_recipe <- recipe(duration_months ~ phase_clean + sponsor_type + 
                            log_enrollment + n_sites + start_year,
                          data = train_data) %>%
  step_dummy(all_nominal_predictors()) %>%
  step_zv(all_predictors()) %>%
  step_normalize(all_numeric_predictors())

# ----------------------------------------------------------
# 4. Define models
# ----------------------------------------------------------

# Elastic Net (good baseline)
elastic_net_spec <- linear_reg(penalty = tune(), mixture = tune()) %>%
  set_engine("glmnet")

# Random Forest
rf_spec <- rand_forest(mtry = tune(), min_n = tune(), trees = 500) %>%
  set_engine("ranger", importance = "impurity") %>%
  set_mode("regression")

# ----------------------------------------------------------
# 5. Create workflows
# ----------------------------------------------------------
elastic_wf <- workflow() %>%
  add_recipe(duration_recipe) %>%
  add_model(elastic_net_spec)

rf_wf <- workflow() %>%
  add_recipe(duration_recipe) %>%
  add_model(rf_spec)

# ----------------------------------------------------------
# 6. Cross-validation setup
# ----------------------------------------------------------
set.seed(123)
cv_folds <- vfold_cv(train_data, v = 5)

# ----------------------------------------------------------
# 7. Tune models
# ----------------------------------------------------------
message("\nTuning Elastic Net...")
elastic_res <- tune_grid(
  elastic_wf,
  resamples = cv_folds,
  grid = 20,
  metrics = metric_set(rmse, rsq, mae)
)

message("Tuning Random Forest...")
rf_res <- tune_grid(
  rf_wf,
  resamples = cv_folds,
  grid = 15,
  metrics = metric_set(rmse, rsq, mae)
)

# ----------------------------------------------------------
# 8. Select best models
# ----------------------------------------------------------
best_elastic <- select_best(elastic_res, metric = "rmse")
best_rf      <- select_best(rf_res, metric = "rmse")

final_elastic <- finalize_workflow(elastic_wf, best_elastic)
final_rf      <- finalize_workflow(rf_wf, best_rf)

# ----------------------------------------------------------
# 9. Fit on full training data
# ----------------------------------------------------------
elastic_fit <- fit(final_elastic, data = train_data)
rf_fit      <- fit(final_rf, data = train_data)

# ----------------------------------------------------------
# 10. Evaluate on test set
# ----------------------------------------------------------
message("\n===== Test Set Performance =====")

# Elastic Net
elastic_pred <- predict(elastic_fit, test_data) %>%
  bind_cols(test_data %>% select(duration_months))

elastic_metrics <- elastic_pred %>%
  metrics(truth = duration_months, estimate = .pred)

# Random Forest
rf_pred <- predict(rf_fit, test_data) %>%
  bind_cols(test_data %>% select(duration_months))

rf_metrics <- rf_pred %>%
  metrics(truth = duration_months, estimate = .pred)

print("Elastic Net:")
print(elastic_metrics)

print("\nRandom Forest:")
print(rf_metrics)

# ----------------------------------------------------------
# 11. Save the best model
# ----------------------------------------------------------
dir.create("models", showWarnings = FALSE)

# Save the better performing model (usually RF)
best_model <- rf_fit
write_rds(best_model, "models/best_duration_model.rds")

# Also save predictions for later use in Shiny
write_rds(list(
  elastic = elastic_pred,
  rf = rf_pred,
  metrics = list(elastic = elastic_metrics, rf = rf_metrics)
), "models/test_predictions.rds")

message("\nBest model saved to: models/best_duration_model.rds")