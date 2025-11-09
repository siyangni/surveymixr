# Tests for different growth model specifications
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

test_that("linear growth model works correctly", {
  skip_on_cran()

  # Simulate simple linear growth data
  set.seed(123)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    growth_parameters = list(
      list(intercept = 5, slope = 0.5),
      list(intercept = 3, slope = -0.2)
    ),
    design = "srs",
    seed = 123
  )

  # Fit linear model
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "linear",
    starts = 10,  # Low for testing speed
    cores = 1
  )

  # Check structure
  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@n_classes, 2)
  expect_equal(fit@growth_model, "linear")

  # Check parameters exist
  expect_true(all(!is.na(coef(fit))))

  # Check convergence
  expect_true(fit@convergence_info$converged)

  # Check fit indices
  expect_true(!is.na(AIC(fit)))
  expect_true(!is.na(BIC(fit)))
  expect_true(fit@entropy >= 0 && fit@entropy <= 1)
})

test_that("quadratic growth model works correctly", {
  skip_on_cran()

  set.seed(124)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 5,
    n_classes = 2,
    growth_parameters = list(
      list(intercept = 5, slope = 1.0, quadratic = -0.1),
      list(intercept = 3, slope = 0.2, quadratic = 0.05)
    ),
    design = "srs",
    seed = 124
  )

  # Fit quadratic model
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "quadratic",
    starts = 10,
    cores = 1
  )

  # Check structure
  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@growth_model, "quadratic")

  # Check convergence
  expect_true(fit@convergence_info$converged)

  # Parameters should include quadratic terms
  params <- coef(fit)
  expect_true(any(grepl("quadratic", names(params))))
})

test_that("free basis growth model works correctly", {
  skip_on_cran()

  set.seed(125)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 125
  )

  # Fit free basis model
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "free_basis",
    starts = 10,
    cores = 1
  )

  # Check structure
  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@growth_model, "free_basis")
  expect_true(fit@convergence_info$converged)
})

test_that("nonlinear growth model works correctly", {
  skip_on_cran()

  set.seed(126)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 5,
    n_classes = 2,
    design = "srs",
    seed = 126
  )

  # Fit nonlinear model
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "nonlinear",
    starts = 10,
    cores = 1
  )

  # Check structure
  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@growth_model, "nonlinear")
})

test_that("growth models with covariates work", {
  skip_on_cran()

  set.seed(127)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    covariates = TRUE,
    design = "srs",
    seed = 127
  )

  # Fit with covariates
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "linear",
    covariates = ~ sex + baseline_risk,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # Check covariate effects are estimated
  params <- coef(fit)
  expect_true(any(grepl("sex|baseline_risk", names(params))))
})

test_that("model comparison across growth types works", {
  skip_on_cran()

  set.seed(128)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 5,
    n_classes = 2,
    design = "srs",
    seed = 128
  )

  # Fit different models
  fit_linear <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "linear",
    starts = 5,
    cores = 1
  )

  fit_quadratic <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "quadratic",
    starts = 5,
    cores = 1
  )

  # Can compare fit indices
  expect_true(AIC(fit_linear) != AIC(fit_quadratic))
  expect_true(BIC(fit_linear) != BIC(fit_quadratic))
})
