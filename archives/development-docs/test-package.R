#!/usr/bin/env Rscript

# Test Script for surveymixr Package
# Run this from the package root directory

cat("==============================================\n")
cat("Testing surveymixr Package - Quick Test\n")
cat("==============================================\n\n")

# Step 1: Install required packages
cat("Step 1: Checking required packages...\n")
required_packages <- c("devtools", "testthat", "ggplot2", "MASS", "numDeriv")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("Installing %s...\n", pkg))
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
}

# Step 2: Load the package
cat("\nStep 2: Loading surveymixr package...\n")
devtools::load_all(".")

# Step 3: Test data simulation
cat("\nStep 3: Testing data simulation...\n")
test_data <- simulate_gmm_survey(
  n_individuals = 100,
  n_times = 4,
  n_classes = 2,
  time_scores = c(0, 1, 2, 3),
  class_proportions = c(0.7, 0.3),
  design = "stratified_cluster",
  seed = 12345
)

cat(sprintf("  Generated data: %d rows, %d individuals\n",
            nrow(test_data),
            length(unique(test_data$id))))
cat(sprintf("  Variables: %s\n", paste(names(test_data), collapse = ", ")))
cat(sprintf("  Missing data: %.1f%%\n", mean(is.na(test_data$outcome)) * 100))

# Step 4: Fit a simple 2-class model
cat("\nStep 4: Fitting 2-class growth mixture model...\n")
cat("  (Using only 20 random starts for quick testing)\n")

fit <- gmm_survey(
  data = test_data,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 2,
  growth_model = "linear",
  strata = "stratum",
  cluster = "psu",
  weights = "weight",
  starts = 20,
  cores = 1,
  verbose = FALSE
)

cat("  Model fitted successfully!\n")

# Step 5: Check results
cat("\nStep 5: Checking results...\n")
cat(sprintf("  Converged: %s\n", fit@convergence_info$converged))
cat(sprintf("  Log-likelihood: %.2f\n", fit@fit_indices$loglik))
cat(sprintf("  BIC: %.2f\n", fit@fit_indices$bic))
cat(sprintf("  Entropy: %.3f\n", fit@fit_indices$entropy))
cat(sprintf("  Class proportions: %.3f, %.3f\n",
            fit@class_proportions$weighted[1],
            fit@class_proportions$weighted[2]))

# Step 6: Test S4 methods
cat("\nStep 6: Testing S4 methods...\n")
test_methods <- function() {
  tryCatch({
    print(fit)
    cat("  ✓ print() works\n")
  }, error = function(e) cat("  ✗ print() failed\n"))

  tryCatch({
    summary(fit)
    cat("  ✓ summary() works\n")
  }, error = function(e) cat("  ✗ summary() failed\n"))

  tryCatch({
    coeffs <- coef(fit)
    cat(sprintf("  ✓ coef() works (returned %d parameters)\n", length(coeffs)))
  }, error = function(e) cat("  ✗ coef() failed\n"))

  tryCatch({
    ll <- logLik(fit)
    cat(sprintf("  ✓ logLik() works (%.2f)\n", as.numeric(ll)))
  }, error = function(e) cat("  ✗ logLik() failed\n"))
}

test_methods()

# Step 7: Test diagnostics
cat("\nStep 7: Testing diagnostic functions...\n")

tryCatch({
  props <- class_proportions(fit)
  cat(sprintf("  ✓ class_proportions() works (%d classes)\n", nrow(props)))
}, error = function(e) cat("  ✗ class_proportions() failed\n"))

tryCatch({
  qual <- classification_quality(fit)
  cat(sprintf("  ✓ classification_quality() works (entropy: %.3f)\n", qual$entropy))
}, error = function(e) cat("  ✗ classification_quality() failed\n"))

tryCatch({
  diag <- diagnose_convergence(fit, plot = FALSE)
  cat(sprintf("  ✓ diagnose_convergence() works (%d replications)\n",
              diag@n_replications))
}, error = function(e) cat("  ✗ diagnose_convergence() failed\n"))

# Step 8: Test plotting (save to file)
cat("\nStep 8: Testing plotting functions...\n")
tryCatch({
  png("test_trajectory_plot.png", width = 800, height = 600)
  p <- plot_trajectories(fit)
  print(p)
  dev.off()
  cat("  ✓ plot_trajectories() works (saved to test_trajectory_plot.png)\n")
}, error = function(e) {
  cat("  ✗ plot_trajectories() failed\n")
  if (dev.cur() > 1) dev.off()
})

# Step 9: Test model selection (very quick)
cat("\nStep 9: Testing model selection...\n")
cat("  (Testing 1-3 classes with minimal starts)\n")

tryCatch({
  selection <- gmm_select(
    data = test_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:3,
    strata = "stratum",
    cluster = "psu",
    weights = "weight",
    criteria = c("BIC", "entropy"),
    starts = 10,
    cores = 1,
    verbose = FALSE
  )
  cat(sprintf("  ✓ gmm_select() works (recommended: %d classes)\n",
              selection@recommended_classes))
}, error = function(e) {
  cat("  ✗ gmm_select() failed\n")
  print(e)
})

# Summary
cat("\n==============================================\n")
cat("Test Complete!\n")
cat("==============================================\n\n")

cat("Next steps:\n")
cat("1. Review test results above\n")
cat("2. Run full tests: devtools::test()\n")
cat("3. Check package: devtools::check()\n")
cat("4. Build documentation: devtools::document()\n")
cat("5. Try the example in README.md with more random starts\n\n")

cat("To use interactively:\n")
cat("  devtools::load_all('.')\n")
cat("  ?gmm_survey  # View help\n")
cat("  data(mcs_simulated)  # Load example data (once created)\n\n")
