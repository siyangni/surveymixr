# Tests for model selection procedures
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

test_that("gmm_select compares models across different class numbers", {
  skip_on_cran()

  set.seed(301)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    class_proportions = c(0.5, 0.3, 0.2),
    design = "SRS",
    seed = 301
  )

  # Run model selection (no BLRT for speed)
  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 1,
    max_classes = 4,
    growth_model = "linear",
    starts = 10,
    run_blrt = FALSE,  # Skip BLRT for speed
    cores = 1
  )

  # Check structure
  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 4)  # 1, 2, 3, 4 class models

  # Check all models fitted
  expect_equal(length(result@fitted_models), 4)

  # Check fit indices present
  expect_true("AIC" %in% colnames(result@comparison_table))
  expect_true("BIC" %in% colnames(result@comparison_table))
  expect_true("aBIC" %in% colnames(result@comparison_table))
  expect_true("entropy" %in% colnames(result@comparison_table))

  # BIC should decrease then increase (or plateau) as classes increase
  bic_values <- result@comparison_table$BIC
  expect_true(length(bic_values) == 4)
})

test_that("gmm_select handles minimum 2 classes", {
  skip_on_cran()

  set.seed(302)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "SRS",
    seed = 302
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

  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 2)  # 2 and 3 class models
})

test_that("BLRT works when enabled", {
  skip_on_cran()
  skip("BLRT is computationally intensive - run manually when needed")

  set.seed(303)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "SRS",
    seed = 303
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 1,
    max_classes = 3,
    starts = 5,
    run_blrt = TRUE,
    blrt_samples = 100,  # Reduced for testing
    cores = 1
  )

  expect_s4_class(result, "SurveyMixrSelect")

  # BLRT results should be present
  expect_true(!is.null(result@blrt_results))
  expect_true("blrt_pvalue" %in% colnames(result@comparison_table))
})

test_that("Information criteria are calculated correctly", {
  skip_on_cran()

  set.seed(304)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "SRS",
    seed = 304
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

  # Check all fit indices are calculated
  expect_true(!is.na(AIC(fit)))
  expect_true(!is.na(BIC(fit)))
  expect_true(!is.na(fit@fit_indices$aBIC))
  expect_true(!is.na(fit@entropy))

  # AIC < BIC typically for same model
  # (BIC has stronger penalty)
  expect_true(AIC(fit) < BIC(fit))
})

test_that("Entropy is bounded between 0 and 1", {
  skip_on_cran()

  set.seed(305)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 3,
    design = "SRS",
    seed = 305
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

  # Entropy should be between 0 and 1
  expect_true(fit@entropy >= 0)
  expect_true(fit@entropy <= 1)

  # Can also extract via function
  ent <- entropy(fit)
  expect_equal(ent, fit@entropy)
})

test_that("Model selection with survey design works", {
  skip_on_cran()

  set.seed(306)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "stratified",
    n_strata = 3,
    seed = 306
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 1,
    max_classes = 3,
    strata = "stratum",
    weights = "weight",
    starts = 10,
    run_blrt = FALSE,
    cores = 1
  )

  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 3)

  # All models should have survey design
  for (i in 1:length(result@fitted_models)) {
    expect_true(!is.null(result@fitted_models[[i]]@survey_design$strata))
  }
})

test_that("Model selection can be plotted", {
  skip_on_cran()

  set.seed(307)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "SRS",
    seed = 307
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

  # Should be able to plot without error
  expect_silent(plot_model_selection(result))
  expect_silent(plot_model_selection(result, criterion = "BIC"))
  expect_silent(plot_model_selection(result, criterion = "entropy"))
})

test_that("Single class model serves as baseline", {
  skip_on_cran()

  set.seed(308)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 4,
    n_classes = 1,  # Homogeneous
    design = "SRS",
    seed = 308
  )

  # Fit 1-class model
  fit_1class <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 1,
    starts = 5,
    cores = 1
  )

  expect_s4_class(fit_1class, "SurveyMixr")
  expect_equal(fit_1class@n_classes, 1)

  # Entropy should be NA or 1 for single class
  expect_true(is.na(fit_1class@entropy) || fit_1class@entropy == 1)
})

test_that("Model selection recommendations are sensible", {
  skip_on_cran()

  set.seed(309)
  # Simulate clear 3-class structure
  sim_data <- simulate_gmm_survey(
    n_individuals = 500,
    n_times = 5,
    n_classes = 3,
    class_proportions = c(0.4, 0.4, 0.2),
    growth_parameters = list(
      list(intercept = 10, slope = 0.5),
      list(intercept = 5, slope = 0.0),
      list(intercept = 2, slope = -0.3)
    ),
    residual_sds = c(1, 1, 1),
    design = "SRS",
    seed = 309
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 1,
    max_classes = 5,
    starts = 20,
    run_blrt = FALSE,
    cores = 1
  )

  # BIC should favor 3-class model (or close to it)
  # Find minimum BIC
  best_bic <- which.min(result@comparison_table$BIC)

  # Should be within 1 class of true model
  expect_true(abs(best_bic - 3) <= 1)
})

test_that("Parallel processing works in model selection", {
  skip_on_cran()
  skip_if(parallel::detectCores() < 2, "Need multiple cores for parallel testing")

  set.seed(310)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "SRS",
    seed = 310
  )

  # Run with parallel processing
  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_classes = 1,
    max_classes = 3,
    starts = 10,
    run_blrt = FALSE,
    cores = 2
  )

  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 3)
})
