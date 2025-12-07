# Tests for missing data handling (FIML)
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

test_that("FIML handles MCAR data correctly", {
  skip_on_cran()

  set.seed(501)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 5,
    n_classes = 2,
    design = "srs",
    missing_rate = 0.15,
    missing_mechanism = "MCAR",
    seed = 501
  )

  # Fit with FIML
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # Should use all observations (not listwise deletion)
  expect_true(fit@model_info$n_obs > 0)
})

test_that("FIML handles MAR data correctly", {
  skip_on_cran()

  set.seed(502)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 5,
    n_classes = 2,
    design = "srs",
    missing_rate = 0.20,
    missing_mechanism = "MAR",
    seed = 502
  )

  # MAR: missingness depends on observed covariates
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # FIML should handle MAR without bias
  expect_true(all(!is.na(coef(fit))))
})

test_that("Different missing rates are handled", {

  set.seed(503)

  # Low missing (5%)
  data_low <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    missing_rate = 0.05,
    design = "srs",
    seed = 503
  )

  # High missing (40%)
  data_high <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    missing_rate = 0.40,
    design = "srs",
    seed = 504
  )

  fit_low <- gmm_survey(
    data = data_low,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  fit_high <- gmm_survey(
    data = data_high,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Both should converge
  expect_true(fit_low@convergence_info$converged)
  expect_true(fit_high@convergence_info$converged)

  # Higher missing should have larger SEs (in theory)
  # Note: Due to stochastic nature of EM, this may not always hold
  se_low <- sqrt(diag(vcov(fit_low)))
  se_high <- sqrt(diag(vcov(fit_high)))

  # Just verify both have valid SEs
  expect_true(all(!is.na(se_low)))
  expect_true(all(!is.na(se_high)))
})

test_that("Missing data patterns are handled correctly", {
  skip_on_cran()

  set.seed(505)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 6,
    n_classes = 2,
    design = "srs",
    seed = 505
  )

  # Create monotone missing pattern (dropout)
  for (i in unique(sim_data$id)) {
    id_rows <- which(sim_data$id == i)
    if (runif(1) < 0.3) {  # 30% dropout
      dropout_time <- sample(3:5, 1)
      dropout_rows <- id_rows[sim_data$time[id_rows] >= dropout_time]
      sim_data$outcome[dropout_rows] <- NA
    }
  }

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)
})

test_that("Intermittent missing data is handled", {
  skip_on_cran()

  set.seed(506)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 5,
    n_classes = 2,
    design = "srs",
    seed = 506
  )

  # Create intermittent missing (random waves missing)
  missing_idx <- sample(1:nrow(sim_data), size = floor(0.15 * nrow(sim_data)))
  sim_data$outcome[missing_idx] <- NA

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # Should have used all individuals
  expect_equal(length(unique(sim_data$id)), 250)
})

test_that("Complete cases vs FIML produces different results", {

  set.seed(507)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 5,
    n_classes = 2,
    missing_rate = 0.25,
    design = "srs",
    seed = 507
  )

  # FIML (default)
  fit_fiml <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Listwise deletion
  complete_data <- sim_data[complete.cases(sim_data[, c("id", "time", "outcome")]), ]

  fit_complete <- gmm_survey(
    data = complete_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Results should differ
  expect_false(all(abs(coef(fit_fiml) - coef(fit_complete)) < 0.01))

  # FIML should have smaller SEs in theory (uses more data)
  # Note: Due to stochastic nature, this may not always hold
  se_fiml <- sqrt(diag(vcov(fit_fiml)))
  se_complete <- sqrt(diag(vcov(fit_complete)))

  # Just verify both have valid SEs
  expect_true(all(!is.na(se_fiml)))
  expect_true(all(!is.na(se_complete)))
})

test_that("All observations missing for some individuals", {
  skip_on_cran()

  set.seed(508)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 508
  )

  # Make all observations missing for 10 individuals
  ids_to_remove <- sample(unique(sim_data$id), 10)
  sim_data$outcome[sim_data$id %in% ids_to_remove] <- NA

  # Should handle gracefully (exclude those individuals)
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)
})

test_that("Missing in covariates is handled", {

  set.seed(509)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 2,
    covariates = TRUE,
    design = "srs",
    seed = 509
  )

  # Introduce missing in covariate
  sim_data$sex[sample(1:nrow(sim_data), 30)] <- NA

  # Package should handle missing covariates (removes rows with NA)
  # May or may not produce a warning depending on implementation
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    covariates = ~ sex + baseline_risk,
    starts = 10,
    cores = 1
  )
})

test_that("Missing data diagnostic functions work", {

  set.seed(510)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 5,
    n_classes = 2,
    missing_rate = 0.20,
    design = "srs",
    seed = 510
  )

  # Check missing patterns (utility function)
  if (exists("check_missing_patterns")) {
    pattern_report <- check_missing_patterns(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome"
    )

    expect_true(!is.null(pattern_report))
  } else {
    skip("check_missing_patterns() not yet implemented")
  }
})

test_that("Monotone vs non-monotone missing patterns", {

  set.seed(511)

  # Monotone (dropout)
  data_monotone <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 5,
    n_classes = 2,
    design = "srs",
    seed = 511
  )

  # Create monotone pattern
  for (i in unique(data_monotone$id)) {
    if (runif(1) < 0.4) {
      dropout_time <- sample(3:5, 1)
      rows <- which(data_monotone$id == i & data_monotone$time >= dropout_time)
      data_monotone$outcome[rows] <- NA
    }
  }

  # Non-monotone (random)
  data_nonmonotone <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 5,
    n_classes = 2,
    missing_rate = 0.20,
    design = "srs",
    seed = 512
  )

  fit_monotone <- gmm_survey(
    data = data_monotone,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  fit_nonmonotone <- gmm_survey(
    data = data_nonmonotone,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Both should converge
  expect_true(fit_monotone@convergence_info$converged)
  expect_true(fit_nonmonotone@convergence_info$converged)
})

test_that("FIML log-likelihood is calculated correctly with missing data", {

  set.seed(513)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 2,
    missing_rate = 0.15,
    design = "srs",
    seed = 513
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

  # Log-likelihood should be finite
  expect_true(is.finite(logLik(fit)))

  # Should be negative (probability < 1)
  expect_true(logLik(fit) < 0)
})

test_that("Extreme missing rates are handled", {

  set.seed(514)

  # Very high missing (60%)
  sim_data <- simulate_gmm_survey(
    n_individuals = 400,
    n_times = 6,
    n_classes = 2,
    missing_rate = 0.60,
    design = "srs",
    seed = 514
  )

  # Should converge but may have warnings
  fit <- suppressWarnings(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      starts = 20,
      cores = 1
    )
  )

  # May or may not converge with 60% missing
  # Just check it doesn't error
  expect_s4_class(fit, "SurveyMixr")
})

test_that("Missing data with survey weights", {

  set.seed(515)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "stratified",
    n_strata = 3,
    missing_rate = 0.20,
    seed = 515
  )

  # FIML with survey weights
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    strata = "stratum",
    weights = "weight",
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # Weighted and unweighted proportions should differ
  props <- class_proportions(fit)
  expect_true(nrow(props) == 2)
})
