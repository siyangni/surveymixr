# Basic tests for gmm_survey estimation

test_that("gmm_survey runs with minimal inputs", {

  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 111
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    verbose = FALSE
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@model_info$n_classes, 2)
  expect_true(fit@convergence_info$converged)
})

test_that("gmm_survey output has expected structure", {

  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 222
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    verbose = FALSE
  )

  # Check slots
  expect_true(length(fit@parameters$growth_parameters) == 2)
  expect_true(length(fit@parameters$class_proportions) == 2)
  expect_equal(ncol(fit@posterior_probs), 2)
  expect_equal(nrow(fit@posterior_probs), 100)

  # Check fit indices
  expect_true(!is.na(fit@fit_indices$loglik))
  expect_true(!is.na(fit@fit_indices$bic))
  expect_true(!is.na(fit@fit_indices$entropy))
  expect_true(fit@fit_indices$entropy >= 0 && fit@fit_indices$entropy <= 1)
})

test_that("gmm_survey handles survey design", {

  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "stratified_cluster",
    seed = 333
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    strata = "stratum",
    cluster = "psu",
    weights = "weight",
    starts = 10,
    verbose = FALSE
  )

  expect_true(fit@survey_design$has_weights)
  expect_true(fit@survey_design$has_cluster)
  expect_true(fit@survey_design$has_strata)
})

test_that("S4 methods work correctly", {

  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 444
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    verbose = FALSE
  )

  # Test methods don't error
  expect_error(print(fit), NA)
  expect_error(summary(fit), NA)
  expect_error(coef(fit), NA)
  expect_error(logLik(fit), NA)
  expect_error(AIC(fit), NA)
  expect_error(BIC(fit), NA)

  # Test coef returns named vector
  coeffs <- coef(fit)
  expect_type(coeffs, "double")
  expect_true(length(coeffs) > 0)
  expect_true(!is.null(names(coeffs)))
})

test_that("gmm_survey handles many time points without numerical underflow", {
  # Test numerical stability fix for log-sum-exp implementation
  # With T=15 time points, old implementation would have underflow issues

  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 15,  # Many time points - tests numerical stability
    n_classes = 2,
    seed = 999
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    verbose = FALSE
  )

  # Should converge successfully despite many time points
  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # Log-likelihood should be finite (not -Inf or NaN)
  expect_true(is.finite(fit@fit_indices$loglik))
  expect_true(fit@fit_indices$loglik < 0)  # Log-lik should be negative

  # Posterior probabilities should be valid (no NaN or extreme values)
  expect_true(all(is.finite(fit@posterior_probs)))
  expect_true(all(fit@posterior_probs >= 0 & fit@posterior_probs <= 1))

  # Row sums of posterior probs should be 1 (within tolerance)
  row_sums <- rowSums(fit@posterior_probs)
  expect_true(all(abs(row_sums - 1) < 1e-10))

  # Class proportions should sum to 1
  expect_equal(sum(fit@parameters$class_proportions), 1, tolerance = 1e-10)

  # Fit indices should all be finite
  expect_true(is.finite(fit@fit_indices$aic))
  expect_true(is.finite(fit@fit_indices$bic))
  expect_true(is.finite(fit@fit_indices$entropy))

  # Entropy should be in valid range
  expect_true(fit@fit_indices$entropy >= 0 && fit@fit_indices$entropy <= 1)
})
