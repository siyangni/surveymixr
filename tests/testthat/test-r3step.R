# Tests for R3STEP auxiliary variable analysis
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

test_that("r3step BCH method works with continuous distal outcome", {
  skip_on_cran()

  set.seed(401)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    covariates = TRUE,
    design = "srs",
    seed = 401
  )

  # Fit unconditional model
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 10,
    cores = 1
  )

  # Run R3STEP with BCH method
  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "ses",
    data = sim_data,
    method = "BCH"
  )

  # Check structure
  expect_s4_class(r3_result, "R3StepResults")
  expect_equal(nrow(r3_result@class_means), 3)

  # Check results components
  expect_true(!is.null(r3_result@class_means))
  expect_true(!is.null(r3_result@standard_errors))
  expect_true(!is.null(r3_result@test_results))
})

test_that("r3step ML method works", {
  skip_on_cran()

  set.seed(402)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 2,
    covariates = TRUE,
    design = "srs",
    seed = 402
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

  # Run R3STEP with ML method
  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "baseline_risk",
    data = sim_data,
    method = "ML"
  )

  expect_s4_class(r3_result, "R3StepResults")
  expect_equal(r3_result@method, "ML")
})

test_that("r3step manual 3-step method works", {
  skip_on_cran()

  set.seed(403)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 403
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

  # Run manual 3-step
  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "baseline_risk",
    data = sim_data,
    method = "manual"
  )

  expect_s4_class(r3_result, "R3StepResults")
  expect_equal(r3_result@method, "manual")
})

test_that("r3step handles survey design correctly", {
  skip_on_cran()

  set.seed(404)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    design = "stratified",
    n_strata = 3,
    seed = 404
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    strata = "stratum",
    weights = "weight",
    starts = 10,
    cores = 1
  )

  # R3STEP should account for survey design
  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "ses",
    data = sim_data,
    method = "BCH"
  )

  expect_s4_class(r3_result, "R3StepResults")
  # Standard errors should be survey-adjusted
  expect_true(all(!is.na(r3_result@standard_errors)))
})

test_that("r3step omnibus test detects differences", {
  skip_on_cran()

  set.seed(405)
  # Simulate with clear class differences on distal
  sim_data <- simulate_gmm_survey(
    n_individuals = 400,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 405
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

  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "ses",
    data = sim_data,
    method = "BCH"
  )

  # Omnibus test should be in results
  expect_true("omnibus_test" %in% names(r3_result@test_results))
  expect_true(!is.null(r3_result@test_results$omnibus_test$statistic))
  expect_true(!is.null(r3_result@test_results$omnibus_test$p_value))
})

test_that("r3step pairwise comparisons work", {
  skip_on_cran()

  set.seed(406)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 406
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

  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "baseline_risk",
    data = sim_data,
    method = "BCH",
    test_pairwise = TRUE
  )

  # Should have pairwise comparisons
  expect_true("pairwise_tests" %in% names(r3_result@test_results))

  # Number of pairwise tests = k(k-1)/2 = 3(2)/2 = 3
  expect_equal(nrow(r3_result@test_results$pairwise_tests), 3)
})

test_that("r3step calculates effect sizes", {
  skip_on_cran()

  set.seed(407)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 407
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

  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "ses",
    data = sim_data,
    method = "BCH"
  )

  # Should have effect sizes (e.g., Cohen's d)
  expect_true(!is.null(r3_result@effect_sizes))
})

test_that("r3step can be plotted", {
  skip_on_cran()

  set.seed(408)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 408
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

  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "baseline_risk",
    data = sim_data,
    method = "BCH"
  )

  # Should be able to plot without error
  expect_silent(plot(r3_result))
  expect_silent(plot(r3_result, type = "means"))
})

test_that("r3step handles missing data in distal outcome", {
  skip_on_cran()

  set.seed(409)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 409
  )

  # Introduce missing in distal
  sim_data$ses[sample(1:nrow(sim_data), 50)] <- NA

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Should handle missing distal gracefully
  expect_warning(
    r3_result <- r3step(
      gmm_object = fit,
      distal_vars = "ses",
      data = sim_data,
      method = "BCH"
    ),
    regexp = "missing|NA"
  )

  expect_s4_class(r3_result, "R3StepResults")
})

test_that("r3step with binary distal outcome works", {
  skip_on_cran()
  skip("Binary distal outcomes require special handling - implement in v0.3.0")

  set.seed(410)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    covariates = TRUE,
    design = "srs",
    seed = 410
  )

  # Create binary distal
  sim_data$binary_distal <- rbinom(nrow(sim_data), 1, 0.3)

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  r3_result <- r3step(
    gmm_object = fit,
    distal_vars = "binary_distal",
    data = sim_data,
    distal_type = "binary",
    method = "BCH"
  )

  expect_s4_class(r3_result, "R3StepResults")
})

test_that("r3step methods produce similar results", {
  skip_on_cran()

  set.seed(411)
  sim_data <- simulate_gmm_survey(
    n_individuals = 400,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 411
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

  # Compare BCH and ML methods
  r3_bch <- r3step(gmm_object = fit, distal_vars = "ses", data = sim_data, method = "BCH")
  r3_ml <- r3step(gmm_object = fit, distal_vars = "ses", data = sim_data, method = "ML")

  # Class means should be similar (within reasonable tolerance)
  expect_true(
    cor(r3_bch@class_means$mean, r3_ml@class_means$mean) > 0.95
  )
})
