#!/usr/bin/env Rscript
# Quick verification script for the nest parameter fix
# Run from package root: source("scripts/verify-nest-fix.R")

cat("========================================\n")
cat("Testing nest parameter fix\n")
cat("========================================\n\n")

# Load package
library(devtools)
load_all()

cat("Running test for nested design...\n")

# Test 1: Nested design works correctly
set.seed(205)
sim_data <- simulate_gmm_survey(
  n_individuals = 300,
  n_times = 4,
  n_classes = 2,
  design = "stratified_cluster",
  n_strata = 3,
  n_clusters = 30,
  seed = 205
)

fit <- gmm_survey(
  data = sim_data,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 2,
  strata = "stratum",
  cluster = "psu",
  nest = TRUE,
  starts = 10,
  cores = 1,
  verbose = FALSE
)

cat("\nChecking if nest parameter is stored:\n")
cat(sprintf("  fit@survey_design$nest = %s\n",
           ifelse(is.null(fit@survey_design$nest), "NULL",
                  as.character(fit@survey_design$nest))))

if (is.null(fit@survey_design$nest)) {
  cat("\n✗ FAILED: nest parameter is NULL\n")
} else if (fit@survey_design$nest == TRUE) {
  cat("\n✓ PASSED: nest parameter correctly stored as TRUE\n")
} else {
  cat(sprintf("\n✗ FAILED: nest parameter is %s (expected TRUE)\n",
             fit@survey_design$nest))
}

# Test 2: Survey design with all components
cat("\n\nRunning test for full survey design...\n")

set.seed(207)
sim_data2 <- simulate_gmm_survey(
  n_individuals = 400,
  n_times = 4,
  n_classes = 2,
  design = "stratified_cluster",
  n_strata = 4,
  n_clusters = 40,
  weight_type = "inverse_prob",
  seed = 207
)

fit2 <- gmm_survey(
  data = sim_data2,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 2,
  strata = "stratum",
  cluster = "psu",
  weights = "weight",
  nest = TRUE,
  starts = 10,
  cores = 1,
  verbose = FALSE
)

cat("\nChecking all survey components:\n")
cat(sprintf("  strata: %s\n",
           ifelse(is.null(fit2@survey_design$strata), "NULL", "✓")))
cat(sprintf("  cluster: %s\n",
           ifelse(is.null(fit2@survey_design$cluster), "NULL", "✓")))
cat(sprintf("  weights: %s\n",
           ifelse(is.null(fit2@survey_design$weights), "NULL", "✓")))
cat(sprintf("  nest: %s\n",
           ifelse(is.null(fit2@survey_design$nest), "NULL",
                  as.character(fit2@survey_design$nest))))

all_pass <- !is.null(fit2@survey_design$strata) &&
            !is.null(fit2@survey_design$cluster) &&
            !is.null(fit2@survey_design$weights) &&
            !is.null(fit2@survey_design$nest) &&
            fit2@survey_design$nest == TRUE

if (all_pass) {
  cat("\n✓ PASSED: All survey components correctly stored\n")
} else {
  cat("\n✗ FAILED: Some survey components missing or incorrect\n")
}

cat("\n========================================\n")
cat("Verification complete!\n")
cat("========================================\n")
