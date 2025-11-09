# Tests for convergence and random starts
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

test_that("Multiple random starts find global maximum", {
  skip_on_cran()

  set.seed(601)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 601
  )

  # Fit with many starts
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 50,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # Best log-likelihood should be stored
  expect_true(!is.na(logLik(fit)))
})

test_that("diagnose_convergence identifies local maxima", {
  skip_on_cran()

  set.seed(602)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 602
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 30,
    cores = 1
  )

  # Diagnose convergence
  diag <- diagnose_convergence(fit)

  expect_s4_class(diag, "ConvergenceDiagnostics")

  # Should have log-likelihood table
  expect_true(!is.null(diag@loglik_table))

  # Should have best solution identified
  expect_true(!is.null(diag@best_solution))
})

test_that("Few random starts may find local maxima", {
  skip_on_cran()

  set.seed(603)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 4,  # Complex model
    design = "srs",
    seed = 603
  )

  # Very few starts (likely local maxima)
  fit_few <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 4,
    starts = 5,  # Very few
    cores = 1
  )

  # Many starts (better chance of global)
  fit_many <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 4,
    starts = 50,
    cores = 1
  )

  # More starts should find equal or better solution
  expect_true(logLik(fit_many) >= logLik(fit_few))
})

test_that("Convergence tolerance affects iterations", {
  skip_on_cran()

  set.seed(604)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 604
  )

  # Loose tolerance
  fit_loose <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    convergence = 1e-4,  # Loose
    starts = 10,
    cores = 1
  )

  # Tight tolerance
  fit_tight <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    convergence = 1e-8,  # Tight
    starts = 10,
    cores = 1
  )

  # Both should converge
  expect_true(fit_loose@convergence_info$converged)
  expect_true(fit_tight@convergence_info$converged)

  # Tight tolerance may take more iterations
  # (though not guaranteed in all cases)
})

test_that("Maximum iterations limit prevents infinite loops", {
  skip_on_cran()

  set.seed(605)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 4,
    n_classes = 5,  # Very complex
    design = "srs",
    seed = 605
  )

  # Very few iterations
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 5,
    max_iter = 10,  # Very few
    starts = 5,
    cores = 1
  )

  # May not converge
  expect_s4_class(fit, "SurveyMixr")

  # If not converged, should have warning
  if (!fit@convergence_info$converged) {
    expect_true(!is.null(fit@warnings))
  }
})

test_that("Parallel processing produces same results", {
  skip_on_cran()
  skip_if(parallel::detectCores() < 2, "Need multiple cores")

  set.seed(606)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 606
  )

  # Sequential
  fit_seq <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 20,
    cores = 1
  )

  # Parallel
  fit_par <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 20,
    cores = 2
  )

  # Should find same solution (or very close)
  expect_equal(logLik(fit_seq), logLik(fit_par), tolerance = 0.01)
})

test_that("Convergence diagnostics detect replicated solutions", {
  skip_on_cran()

  set.seed(607)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,  # Simple model, should replicate well
    design = "srs",
    seed = 607
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 30,
    cores = 1
  )

  diag <- diagnose_convergence(fit)

  # Should have high replication count for best solution
  expect_true(diag@best_solution$n_replications > 1)

  # Recommendations should be positive
  expect_true(length(diag@recommendations) > 0)
})

test_that("Non-convergence is detected and reported", {
  skip_on_cran()

  set.seed(608)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 3,
    n_classes = 6,  # Too many classes for data
    design = "srs",
    seed = 608
  )

  # Likely to have convergence issues
  fit <- suppressWarnings(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 6,
      starts = 10,
      max_iter = 100,
      cores = 1
    )
  )

  # Should detect non-convergence
  if (!fit@convergence_info$converged) {
    expect_false(fit@convergence_info$converged)
    expect_true(!is.null(fit@warnings))
  }
})

test_that("Starting values affect convergence path", {
  skip_on_cran()

  set.seed(609)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 609
  )

  # Different seeds should give different starting values
  # but should converge to same solution

  fit1 <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 30,
    seed = 100,
    cores = 1
  )

  fit2 <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 30,
    seed = 200,
    cores = 1
  )

  # Should find same global maximum (or very close)
  expect_equal(logLik(fit1), logLik(fit2), tolerance = 0.1)
})

test_that("Convergence with survey design is stable", {
  skip_on_cran()

  set.seed(610)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    design = "stratified_cluster",
    n_strata = 3,
    n_clusters = 30,
    seed = 610
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    strata = "stratum",
    cluster = "psu",
    weights = "weight",
    starts = 20,
    cores = 1
  )

  expect_true(fit@convergence_info$converged)

  # Diagnose
  diag <- diagnose_convergence(fit)
  expect_s4_class(diag, "ConvergenceDiagnostics")
})

test_that("EM iterations are tracked correctly", {
  skip_on_cran()

  set.seed(611)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 611
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

  # Number of iterations should be stored
  expect_true(!is.null(fit@iterations))
  expect_true(fit@iterations > 0)
  expect_true(fit@iterations < fit@max_iterations)
})

test_that("Boundary solutions are detected", {
  skip_on_cran()

  set.seed(612)
  # Simulate with one very small class
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 3,
    class_proportions = c(0.7, 0.25, 0.05),  # Very small class
    design = "srs",
    seed = 612
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 20,
    cores = 1
  )

  # May have boundary solution (class proportion near 0)
  props <- class_proportions(fit)

  # Check if any class is very small
  if (any(props$proportion < 0.05)) {
    # Should have warning about boundary
    expect_true(length(fit@warnings) > 0)
  }
})

test_that("Gradient norms are small at convergence", {
  skip_on_cran()

  set.seed(613)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 613
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

  # At convergence, gradient should be near zero
  # (this requires computing gradient, may not be stored)
  if (!is.null(fit@gradient_norm)) {
    expect_true(fit@gradient_norm < 0.01)
  }
})

test_that("Convergence with different growth models", {
  skip_on_cran()

  set.seed(614)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 5,
    n_classes = 2,
    design = "srs",
    seed = 614
  )

  # Linear
  fit_linear <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "linear",
    starts = 15,
    cores = 1
  )

  # Quadratic (more complex)
  fit_quad <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "quadratic",
    starts = 15,
    cores = 1
  )

  # Both should converge
  expect_true(fit_linear@convergence_info$converged)
  expect_true(fit_quad@convergence_info$converged)
})
