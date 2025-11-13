#!/usr/bin/env Rscript

# Example Usage of surveymixr Package
# This script demonstrates the basic workflow

# Load the package (development mode)
# Run this from the package root directory
if (!require("devtools")) install.packages("devtools")
devtools::load_all()

cat("===============================================\n")
cat("surveymixr Example: Self-Control Trajectories\n")
cat("===============================================\n\n")

# STEP 1: Simulate Data
# ---------------------
cat("Step 1: Simulating data (N=500, T=5, K=3)...\n")

sim_data <- simulate_gmm_survey(
  n_individuals = 500,
  n_times = 5,
  n_classes = 3,
  time_scores = c(3, 5, 7, 11, 14),  # Ages
  class_proportions = c(0.55, 0.30, 0.15),
  growth_parameters = list(
    list(intercept = 8.5, slope = 0.05),   # High-stable
    list(intercept = 6.0, slope = 0.20),   # Moderate-increasing
    list(intercept = 4.0, slope = -0.15)   # Low-declining
  ),
  residual_sds = c(1.2, 1.5, 1.8),
  design = "stratified_cluster",
  n_strata = 4,
  n_clusters = 50,
  missing_rate = 0.10,
  covariates = TRUE,
  seed = 42
)

cat(sprintf("  Generated: %d observations from %d individuals\n",
            nrow(sim_data), length(unique(sim_data$id))))
cat(sprintf("  True classes: %s\n",
            paste(table(unique(sim_data[, c("id", "true_class")])$true_class),
                  collapse = ", ")))
cat(sprintf("  Missing: %.1f%%\n\n", mean(is.na(sim_data$outcome)) * 100))

# STEP 2: Fit 3-Class Model
# --------------------------
cat("Step 2: Fitting 3-class growth mixture model...\n")
cat("  (Using 50 random starts - increase to 500+ for publication)\n\n")

fit <- gmm_survey(
  data = sim_data,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 3,
  growth_model = "linear",
  strata = "stratum",
  cluster = "psu",
  weights = "weight",
  starts = 50,
  cores = 2,
  verbose = TRUE
)

# STEP 3: View Results
# ---------------------
cat("\n")
cat("Step 3: Results Summary\n")
cat("=======================\n\n")

cat("Model Fit:\n")
cat(sprintf("  Log-likelihood: %.2f\n", fit@fit_indices$loglik))
cat(sprintf("  AIC: %.2f\n", fit@fit_indices$aic))
cat(sprintf("  BIC: %.2f\n", fit@fit_indices$bic))
cat(sprintf("  Entropy: %.3f\n", fit@fit_indices$entropy))

cat("\nClass Proportions (Weighted):\n")
for (k in 1:3) {
  cat(sprintf("  Class %d: %.3f (%.1f%%)\n",
              k,
              fit@class_proportions$weighted[k],
              fit@class_proportions$weighted[k] * 100))
}

cat("\nGrowth Parameters:\n")
for (k in 1:3) {
  gp <- fit@parameters$growth_parameters[[k]]
  se <- fit@standard_errors$growth_parameters[[k]]
  cat(sprintf("  Class %d:\n", k))
  cat(sprintf("    Intercept: %.3f (SE=%.3f)\n", gp$intercept, se$intercept))
  cat(sprintf("    Slope:     %.3f (SE=%.3f)\n", gp$slope, se$slope))
}

cat("\nConvergence:\n")
cat(sprintf("  Status: %s\n", ifelse(fit@convergence_info$converged,
                                     "Converged", "Not converged")))
cat(sprintf("  Iterations: %d\n", fit@convergence_info$iterations))
cat(sprintf("  Best solution replicated: %d times\n",
            fit@convergence_info$n_replications))

# STEP 4: Diagnostics
# --------------------
cat("\n")
cat("Step 4: Classification Quality\n")
cat("===============================\n\n")

qual <- classification_quality(fit)
cat(sprintf("Overall Entropy: %.3f\n\n", qual$entropy))
cat("By Class:\n")
print(qual$summary_by_class)

# STEP 5: Plotting
# ----------------
cat("\n")
cat("Step 5: Creating Visualizations\n")
cat("================================\n\n")

# Trajectory plot
cat("Creating trajectory plot...\n")
p1 <- plot_trajectories(fit, include_ci = TRUE)

# Try to save
tryCatch({
  ggsave("example_trajectories.png", p1, width = 8, height = 6, dpi = 300)
  cat("  ✓ Saved to: example_trajectories.png\n")
}, error = function(e) {
  cat("  Note: Could not save plot (ggplot2 issue)\n")
})

# Convergence plot
cat("Creating convergence diagnostic plot...\n")
tryCatch({
  png("example_convergence.png", width = 800, height = 600)
  plot(fit, type = "convergence")
  dev.off()
  cat("  ✓ Saved to: example_convergence.png\n")
}, error = function(e) {
  cat("  Note: Could not save plot\n")
  if (dev.cur() > 1) dev.off()
})

# STEP 6: Model Selection (Optional - takes longer)
# --------------------------------------------------
cat("\n")
cat("Step 6: Model Selection (Optional)\n")
cat("===================================\n")
cat("Comparing 1-4 class models...\n")
cat("(This takes ~5 minutes with current settings)\n\n")

run_selection <- readline(prompt = "Run model selection? (y/n): ")

if (tolower(run_selection) == "y") {
  selection <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:4,
    strata = "stratum",
    cluster = "psu",
    weights = "weight",
    criteria = c("BIC", "entropy"),
    starts = 30,
    cores = 2,
    verbose = TRUE
  )

  cat("\nModel Selection Results:\n")
  print(selection@comparison_table)
  cat(sprintf("\nRecommended: %d classes\n", selection@recommended_classes))
} else {
  cat("Skipping model selection.\n")
}

# STEP 7: R3STEP Analysis (Optional)
# -----------------------------------
cat("\n")
cat("Step 7: R3STEP Analysis (Optional)\n")
cat("===================================\n")

run_r3step <- readline(prompt = "Run R3STEP analysis of auxiliary variables? (y/n): ")

if (tolower(run_r3step) == "y") {
  # Need unique rows per individual
  unique_data <- sim_data[!duplicated(sim_data$id), ]

  cat("Analyzing relationship between classes and covariates...\n")

  r3_results <- r3step(
    gmm_object = fit,
    distal_vars = c("ses", "baseline_risk"),
    data = unique_data,
    method = "BCH"
  )

  cat("\nR3STEP Results:\n")
  print(summary(r3_results))
} else {
  cat("Skipping R3STEP analysis.\n")
}

# Summary
cat("\n")
cat("===============================================\n")
cat("Example Complete!\n")
cat("===============================================\n\n")

cat("Files created:\n")
cat("  - example_trajectories.png (if successful)\n")
cat("  - example_convergence.png (if successful)\n\n")

cat("Try these next:\n")
cat("  1. View detailed summary: summary(fit)\n")
cat("  2. Extract coefficients: coef(fit)\n")
cat("  3. Get class proportions: class_proportions(fit)\n")
cat("  4. Check convergence: diagnose_convergence(fit)\n")
cat("  5. Compare model fit: AIC(fit), BIC(fit)\n\n")

cat("For more examples, see:\n")
cat("  - README.md\n")
cat("  - vignettes/surveymixr-intro.Rmd\n")
cat("  - ?gmm_survey\n\n")
