# Clinical Trial Duration Predictor

An end-to-end data science project that predicts the duration of clinical trials using publicly available data from [ClinicalTrials.gov](https://clinicaltrials.gov/).

Built with **R**, **tidymodels**, and **Shiny**.

---

## Project Overview

Clinical trials often take longer than expected. This project builds a machine learning model to estimate trial duration based on key characteristics such as:

- Trial phase
- Sponsor type (Industry vs Others)
- Number of participants
- Number of sites
- Start year

The model is trained on completed interventional oncology trials and evaluated using a **time-based split** (more realistic than a random split).

---

## Features

- Data extraction from ClinicalTrials.gov using `{ctrdata}`
- Data cleaning & feature engineering
- Machine learning models (Elastic Net + Random Forest)
- Interactive Shiny dashboard for predictions
- Fully reproducible workflow with `{renv}`

---

## Live Demo

> **Coming soon** – Link to shinyapps.io will be added here after deployment.

---

## Project Structure
clinical-trial-duration-predictor/
├── data/
│   ├── raw/                  # SQLite database from ClinicalTrials.gov
│   └── processed/            # Cleaned dataset
├── R/
│   ├── 01_download_data.R
│   ├── 02_clean_feature_engineer.R
│   ├── 03_model_train.R
│   └── 04_utils.R
├── models/                   # Saved model
├── app/
│   └── app.R                 # Shiny application
├── reports/                  # Quarto report (optional)
└── README.md
text---

## How to Run Locally

### 1. Clone the repository

```bash
git clone https://github.com/shekharchalwadigrepo-hub/clinical-trial-duration-predictor.git
cd clinical-trial-duration-predictor
2. Open in RStudio
Open the .Rproj file.
3. Restore packages
Rrenv::restore()
4. Run the pipeline (in order)
Rsource("R/01_download_data.R")          # Download data (takes time)
source("R/02_clean_feature_engineer.R") # Clean + feature engineering
source("R/03_model_train.R")            # Train models
5. Launch the Shiny app
Rshiny::runApp("app")

Key Results

ModelRMSE (months)R²MAE (months)Elastic Net–––Random Forest–––
Replace the dashes with your actual results after running the modeling script.
Important note:

A random train-test split usually gives optimistic performance. A time-based split (training on older trials and testing on newer ones) provides a more honest estimate of real-world performance.

Tech Stack

R + tidyverse
ctrdata + nodbi (data extraction)
tidymodels (modeling)
Shiny + bslib (dashboard)
renv (reproducibility)


Future Improvements

Add more therapeutic areas
Include additional features (number of arms, endpoints, etc.)
Deploy to shinyapps.io / Posit Connect
Add prediction intervals
Create a Quarto report


Author
Shekhar Chalwadi

R Shiny Developer | Clinical Trials Domain | Data Science

GitHub: shekharchalwadigrepo-hub
LinkedIn: (add your LinkedIn link)


License
MIT License
text---

### How to use it

1. Open `README.md` in your project.
2. Delete the existing content.
3. Paste the above text.
4. Update the results table after you run the modeling script.
5. Commit and push:

```r
# In RStudio Git tab
# Stage README.md → Commit → Push
