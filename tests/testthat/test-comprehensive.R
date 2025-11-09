# Comprehensive tests for all surveymixr functions
# This file provides comprehensive coverage for all exported functions
# and replaces the functionality of week1-setup.R

# =============================================================================
# CORE ESTIMATION FUNCTIONS
# =============================================================================

test_that("gmm_survey core functionality works", {
  skip_on_cran()

  set.seed(1001)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1001
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1,
    verbose = FALSE
  )

  # Basic structure checks
  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@model_info$n_classes, 2)
  expect_true(fit@convergence_info$converged)
  expect_true(!is.na(fit@fit_indices$loglik))
  expect_true(!is.na(fit@fit_indices$bic))
})

test_that("gmm_select works across class range", {
  skip_on_cran()

  set.seed(1002)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 1002
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 1,
    max_classes = 4,
    starts = 10,
    run_blrt = FALSE,
    cores = 1
  )

  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 4)
  expect_true(all(c("AIC", "BIC", "aBIC", "entropy") %in% colnames(result@comparison_table)))
})

# =============================================================================
# EXTRACTION FUNCTIONS
# =============================================================================

test_that("extract_fit_indices extracts all fit measures", {
  skip_on_cran()

  set.seed(1003)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1003
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  indices <- extract_fit_indices(fit)

  # Check structure
  expect_true(is.data.frame(indices) || is.list(indices))

  # Check all expected indices present
  expect_true(!is.null(indices$loglik) || !is.null(indices$logLik))
  expect_true(!is.null(indices$AIC))
  expect_true(!is.null(indices$BIC))
  expect_true(!is.null(indices$aBIC))
  expect_true(!is.null(indices$entropy))

  # Check values are numeric and finite
  if (is.data.frame(indices)) {
    expect_true(all(sapply(indices, is.numeric)))
    expect_true(all(sapply(indices, is.finite)))
  }
})

test_that("extract_fit_indices handles multiple models", {
  skip_on_cran()

  set.seed(1004)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 1004
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 2,
    max_classes = 3,
    starts = 10,
    run_blrt = FALSE,
    cores = 1
  )

  # Extract from selection object
  indices <- extract_fit_indices(result)

  expect_true(is.data.frame(indices))
  expect_equal(nrow(indices), 2)  # 2 and 3 class models
})

test_that("extract_trajectories produces predicted trajectories", {
  skip_on_cran()

  set.seed(1005)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1005
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  trajectories <- extract_trajectories(fit)

  # Check structure
  expect_true(is.data.frame(trajectories) || is.list(trajectories))

  # Should have class identifier
  expect_true("class" %in% names(trajectories) || !is.null(trajectories$class))

  # Should have time points
  expect_true("time" %in% names(trajectories) || !is.null(trajectories$time))

  # Should have predicted values
  expect_true(any(c("fitted", "predicted", "value") %in% names(trajectories)))
})

test_that("extract_trajectories handles confidence intervals", {
  skip_on_cran()

  set.seed(1006)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1006
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  trajectories <- extract_trajectories(fit, ci = TRUE)

  # Should have CI columns
  expect_true(any(c("lower", "upper", "lower_ci", "upper_ci") %in% names(trajectories)))
})

# =============================================================================
# DIAGNOSTIC FUNCTIONS
# =============================================================================

test_that("entropy calculation is accurate", {
  skip_on_cran()

  set.seed(1007)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1007
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  ent <- entropy(fit)

  expect_true(is.numeric(ent))
  expect_true(ent >= 0 && ent <= 1)
  expect_equal(ent, fit@fit_indices$entropy, tolerance = 0.001)

  # Test with posterior probability matrix
  ent_from_matrix <- entropy(fit@posterior_probs)
  expect_equal(ent, ent_from_matrix, tolerance = 0.001)
})

test_that("class_proportions provides complete information", {
  skip_on_cran()

  set.seed(1008)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 1008
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 10,
    cores = 1
  )

  props <- class_proportions(fit)

  expect_s3_class(props, "data.frame")
  expect_equal(nrow(props), 3)
  expect_true("proportion" %in% names(props))
  expect_true("se" %in% names(props))
  expect_equal(sum(props$proportion), 1, tolerance = 0.001)
  expect_true(all(props$proportion >= 0 & props$proportion <= 1))
})

test_that("classification_quality provides comprehensive metrics", {
  skip_on_cran()

  set.seed(1009)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 1009
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 10,
    cores = 1
  )

  qual <- classification_quality(fit)

  expect_type(qual, "list")
  expect_true("entropy" %in% names(qual))
  expect_true("avepp_overall" %in% names(qual))
  expect_true("occ_overall" %in% names(qual))
  expect_true("summary_by_class" %in% names(qual))
  expect_true("class_error_matrix" %in% names(qual))

  # Check summary table
  expect_s3_class(qual$summary_by_class, "data.frame")
  expect_equal(nrow(qual$summary_by_class), 3)
  expect_true(all(c("avepp", "occ") %in% colnames(qual$summary_by_class)))
})

test_that("diagnose_convergence identifies convergence issues", {
  skip_on_cran()

  set.seed(1010)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1010
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 20,
    cores = 1
  )

  diag <- diagnose_convergence(fit, plot = FALSE)

  expect_s4_class(diag, "ConvergenceDiagnostics")
  expect_true(!is.na(diag@best_loglik))
  expect_true(diag@n_replications >= 1)
  expect_s3_class(diag@loglik_table, "data.frame")
  expect_true("loglik" %in% names(diag@loglik_table))
  expect_true("frequency" %in% names(diag@loglik_table))
})

# =============================================================================
# COMPARISON FUNCTIONS
# =============================================================================

test_that("compare_classes performs statistical comparisons", {
  skip_on_cran()

  set.seed(1011)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    covariates = TRUE,
    design = "srs",
    seed = 1011
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 10,
    cores = 1
  )

  # Compare classes on covariate
  comparison <- compare_classes(fit, variable = "ses", data = sim_data)

  expect_true(is.list(comparison) || is.data.frame(comparison))

  # Should have statistical test results
  expect_true(!is.null(comparison$test_statistic) || "statistic" %in% names(comparison))
  expect_true(!is.null(comparison$p_value) || "p.value" %in% names(comparison))
})

test_that("compare_classes handles multiple variables", {
  skip_on_cran()

  set.seed(1012)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    covariates = TRUE,
    design = "srs",
    seed = 1012
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Compare on multiple variables
  comparison <- compare_classes(
    fit,
    variable = c("ses", "baseline_risk"),
    data = sim_data
  )

  expect_true(is.list(comparison))
  expect_true(length(comparison) >= 2)
})

test_that("compare_with_mplus validates model equivalence", {
  skip("Mplus comparison requires Mplus installation - test manually")

  set.seed(1013)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1013
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Mock Mplus results for testing
  mplus_results <- list(
    loglik = fit@fit_indices$loglik,
    aic = AIC(fit),
    bic = BIC(fit)
  )

  comparison <- compare_with_mplus(fit, mplus_results)

  expect_true(is.list(comparison))
  expect_true("differences" %in% names(comparison))
})

# =============================================================================
# PLOTTING FUNCTIONS
# =============================================================================

test_that("plot_trajectories creates trajectory plot", {
  skip_on_cran()

  set.seed(1014)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1014
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Should produce plot without error
  expect_silent(p <- plot_trajectories(fit))
  expect_true(inherits(p, "ggplot") || inherits(p, "plotly"))
})

test_that("plot_trajectories handles confidence intervals", {
  skip_on_cran()

  set.seed(1015)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1015
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  expect_silent(p <- plot_trajectories(fit, ci = TRUE))
  expect_true(inherits(p, "ggplot") || inherits(p, "plotly"))
})

test_that("plot_class_comparison creates comparison plot", {
  skip_on_cran()

  set.seed(1016)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    covariates = TRUE,
    design = "srs",
    seed = 1016
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 10,
    cores = 1
  )

  expect_silent(p <- plot_class_comparison(fit, variable = "ses", data = sim_data))
  expect_true(inherits(p, "ggplot") || inherits(p, "plotly"))
})

test_that("plot_model_selection creates selection plot", {
  skip_on_cran()

  set.seed(1017)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1017
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 1,
    max_classes = 3,
    starts = 10,
    run_blrt = FALSE,
    cores = 1
  )

  expect_silent(p <- plot_model_selection(result))
  expect_true(inherits(p, "ggplot") || inherits(p, "plotly"))

  expect_silent(p <- plot_model_selection(result, criterion = "BIC"))
  expect_silent(p <- plot_model_selection(result, criterion = "entropy"))
})

# =============================================================================
# S4 METHODS
# =============================================================================

test_that("All S4 methods work correctly", {
  skip_on_cran()

  set.seed(1018)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1018
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1,
    keep_data = TRUE
  )

  # print method
  expect_output(print(fit), "Growth Mixture Model")

  # show method (same as print for S4)
  expect_output(show(fit), "Growth Mixture Model")

  # summary method
  expect_output(summary(fit), "MODEL SPECIFICATION")

  # coef method
  coeffs <- coef(fit)
  expect_type(coeffs, "double")
  expect_true(length(coeffs) > 0)
  expect_true(!is.null(names(coeffs)))

  # vcov method
  vcov_mat <- vcov(fit)
  expect_true(is.matrix(vcov_mat))
  expect_equal(nrow(vcov_mat), ncol(vcov_mat))

  # logLik method
  ll <- logLik(fit)
  expect_true(is.numeric(ll))
  expect_true(is.finite(ll))

  # AIC method
  aic <- AIC(fit)
  expect_true(is.numeric(aic))
  expect_true(is.finite(aic))

  # BIC method
  bic <- BIC(fit)
  expect_true(is.numeric(bic))
  expect_true(is.finite(bic))
  expect_true(bic > aic)  # BIC typically larger due to stronger penalty

  # fitted method
  fitted_vals <- fitted(fit)
  expect_true(length(fitted_vals) > 0)

  # residuals method
  resids <- residuals(fit)
  expect_true(length(resids) > 0)
  expect_equal(length(fitted_vals), length(resids))

  # plot method
  expect_silent(plot(fit))
})

# =============================================================================
# R3STEP AUXILIARY ANALYSIS
# =============================================================================

test_that("r3step works with all methods", {
  skip_on_cran()

  set.seed(1019)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    covariates = TRUE,
    design = "srs",
    seed = 1019
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 10,
    cores = 1
  )

  # BCH method
  r3_bch <- r3step(fit, distal_vars = "ses", data = sim_data, method = "BCH")
  expect_s4_class(r3_bch, "R3StepResults")
  expect_equal(r3_bch@method, "BCH")

  # ML method
  r3_ml <- r3step(fit, distal_vars = "ses", data = sim_data, method = "ML")
  expect_s4_class(r3_ml, "R3StepResults")
  expect_equal(r3_ml@method, "ML")

  # Manual method
  r3_manual <- r3step(fit, distal_vars = "ses", data = sim_data, method = "manual")
  expect_s4_class(r3_manual, "R3StepResults")
  expect_equal(r3_manual@method, "manual")
})

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

test_that("wide_to_long reshaping works correctly", {
  wide_data <- data.frame(
    id = 1:100,
    y_t1 = rnorm(100, 5),
    y_t2 = rnorm(100, 6),
    y_t3 = rnorm(100, 7),
    sex = sample(0:1, 100, replace = TRUE)
  )

  long_data <- wide_to_long(
    data = wide_data,
    id_var = "id",
    outcome_vars = c("y_t1", "y_t2", "y_t3"),
    time_values = c(1, 2, 3)
  )

  expect_equal(nrow(long_data), 300)
  expect_true(all(c("time", "outcome", "sex") %in% colnames(long_data)))
})

test_that("simulate_gmm_survey produces valid data", {
  set.seed(1020)

  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 3,
    class_proportions = c(0.5, 0.3, 0.2),
    design = "stratified",
    seed = 1020
  )

  expect_equal(nrow(sim_data), 800)
  expect_equal(length(unique(sim_data$id)), 200)
  expect_true(all(c("id", "time", "outcome", "true_class") %in% colnames(sim_data)))

  # Check class proportions
  props <- table(unique(sim_data[, c("id", "true_class")])$true_class) / 200
  expect_equal(as.numeric(props), c(0.5, 0.3, 0.2), tolerance = 0.05)
})

# =============================================================================
# SURVEY DESIGN FEATURES
# =============================================================================

test_that("Survey designs are properly handled", {
  skip_on_cran()

  set.seed(1021)

  # Stratified design
  data_strat <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "stratified",
    n_strata = 3,
    seed = 1021
  )

  fit_strat <- gmm_survey(
    data = data_strat,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    strata = "stratum",
    weights = "weight",
    starts = 10,
    cores = 1
  )

  expect_true(fit_strat@survey_design$has_strata)
  expect_true(fit_strat@survey_design$has_weights)

  # Cluster design
  data_clust <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "cluster",
    n_clusters = 20,
    seed = 1022
  )

  fit_clust <- gmm_survey(
    data = data_clust,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    cluster = "psu",
    weights = "weight",
    starts = 10,
    cores = 1
  )

  expect_true(fit_clust@survey_design$has_cluster)
})

# =============================================================================
# EDGE CASES AND ERROR HANDLING
# =============================================================================

test_that("Functions handle edge cases gracefully", {
  skip_on_cran()

  set.seed(1023)

  # Small sample size
  small_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 3,
    n_classes = 2,
    design = "srs",
    seed = 1023
  )

  expect_warning(
    fit_small <- gmm_survey(
      data = small_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      starts = 5,
      cores = 1
    ),
    regexp = "small sample|convergence|boundary"
  )
})

test_that("Invalid inputs are properly rejected", {
  set.seed(1024)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 1024
  )

  # Missing required arguments
  expect_error(
    gmm_survey(data = sim_data, id = "id", time = "time"),
    regexp = "outcome"
  )

  # Invalid number of classes
  expect_error(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 0
    ),
    regexp = "n_classes"
  )

  # Invalid column names
  expect_error(
    gmm_survey(
      data = sim_data,
      id = "nonexistent_id",
      time = "time",
      outcome = "outcome",
      n_classes = 2
    ),
    regexp = "not found|missing|column"
  )
})

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

test_that("Full workflow completes successfully", {
  skip_on_cran()

  set.seed(1025)

  # 1. Simulate data
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 5,
    n_classes = 3,
    covariates = TRUE,
    design = "stratified",
    n_strata = 3,
    seed = 1025
  )

  expect_true(nrow(sim_data) == 1500)

  # 2. Model selection
  selection <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 2,
    max_classes = 4,
    strata = "stratum",
    weights = "weight",
    starts = 10,
    run_blrt = FALSE,
    cores = 1
  )

  expect_s4_class(selection, "SurveyMixrSelect")

  # 3. Fit final model
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    strata = "stratum",
    weights = "weight",
    starts = 15,
    cores = 1,
    keep_data = TRUE
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # 4. Extract diagnostics
  props <- class_proportions(fit)
  qual <- classification_quality(fit)

  expect_s3_class(props, "data.frame")
  expect_type(qual, "list")

  # 5. R3STEP analysis
  r3 <- r3step(fit, distal_vars = "ses", data = sim_data, method = "BCH")

  expect_s4_class(r3, "R3StepResults")

  # 6. Plotting
  expect_silent(plot(fit))
  expect_silent(plot_trajectories(fit))
  expect_silent(plot_model_selection(selection))
})
