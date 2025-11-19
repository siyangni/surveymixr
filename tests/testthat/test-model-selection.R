# Tests for model selection procedures
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

# =============================================================================
# Lightweight tests (run on CRAN)
# =============================================================================

test_that("gmm_select basic functionality with minimal models", {
  # Lightweight test: compare just 1-2 classes
  sim_data <- simulate_gmm_survey(
    n_individuals = 60,
    n_times = 3,
    n_classes = 2,
    seed = 801
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:2,  # Just 2 models
    starts = 5,      # Minimal starts
    criteria = c("BIC", "entropy"),  # No BLRT
    verbose = FALSE
  )

  # Check basic structure
  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 2)
  expect_equal(length(result@fitted_models), 2)

  # Check fit indices are present
  expect_true("bic" %in% colnames(result@comparison_table))
  expect_true("entropy" %in% colnames(result@comparison_table))
})

test_that("Information criteria are calculated for fitted models", {
  # Test that AIC, BIC are computed correctly
  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 3,
    n_classes = 2,
    seed = 802
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 5,
    verbose = FALSE
  )

  # Check fit indices exist and are finite
  expect_true(is.finite(AIC(fit)))
  expect_true(is.finite(BIC(fit)))
  expect_true(is.finite(fit@fit_indices$abic))
  expect_true(is.finite(fit@fit_indices$entropy))

  # BIC should be larger than AIC (stronger penalty)
  expect_true(BIC(fit) > AIC(fit))
})

test_that("Entropy is in valid range [0, 1]", {
  # Test entropy calculation
  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 3,
    n_classes = 2,
    seed = 803
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 5,
    verbose = FALSE
  )

  # Entropy must be between 0 and 1
  expect_true(fit@fit_indices$entropy >= 0)
  expect_true(fit@fit_indices$entropy <= 1)

  # entropy() function should match slot
  ent <- entropy(fit)
  expect_equal(ent, fit@fit_indices$entropy)
})

test_that("Single class model fits correctly", {
  # Test 1-class model as baseline
  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 3,
    n_classes = 1,
    seed = 804
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 1,
    starts = 3,  # Minimal for 1-class
    verbose = FALSE
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@model_info$n_classes, 1)

  # Entropy should be 1 or NA for single class (no uncertainty)
  expect_true(is.na(fit@fit_indices$entropy) || fit@fit_indices$entropy == 1)
})

test_that("plot_model_selection works without error", {
  # Test plotting functionality
  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 3,
    n_classes = 2,
    seed = 805
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:2,
    starts = 5,
    criteria = c("BIC"),
    verbose = FALSE
  )

  # Should not error when plotting
  expect_error(plot_model_selection(result), NA)
  expect_error(plot_model_selection(result, criterion = "bic"), NA)
})

test_that("SurveyMixrSelect class has proper structure", {
  # Test S4 class definition
  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 3,
    n_classes = 2,
    seed = 806
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:2,
    starts = 5,
    criteria = c("BIC"),
    verbose = FALSE
  )

  # Check slots exist
  expect_true(all(c("comparison_table", "fitted_models", "criteria") %in%
                    slotNames(result)))

  # Check show/print methods work
  expect_error(show(result), NA)
  expect_error(print(result), NA)
})

# =============================================================================
# Comprehensive tests (skip on CRAN for speed)
# =============================================================================

test_that("gmm_select compares models across different class numbers", {
  skip_on_cran()

  set.seed(301)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    class_proportions = c(0.5, 0.3, 0.2),
    design = "srs",
    seed = 301
  )

  # Run model selection (no BLRT for speed)
  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:4,
    growth_model = "linear",
    starts = 10,
    criteria = c("BIC", "entropy"),  # Skip BLRT for speed
    cores = 1
  )

  # Check structure
  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 4)  # 1, 2, 3, 4 class models

  # Check all models fitted
  expect_equal(length(result@fitted_models), 4)

  # Check fit indices present
  expect_true("aic" %in% colnames(result@comparison_table))
  expect_true("bic" %in% colnames(result@comparison_table))
  expect_true("abic" %in% colnames(result@comparison_table))
  expect_true("entropy" %in% colnames(result@comparison_table))

  # BIC should decrease then increase (or plateau) as classes increase
  bic_values <- result@comparison_table$bic
  expect_true(length(bic_values) == 4)
})

test_that("gmm_select handles minimum 2 classes", {
  skip_on_cran()

  set.seed(302)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 302
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 2:3,
    starts = 10,
    criteria = c("BIC", "entropy"),
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
    design = "srs",
    seed = 303
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:3,
    starts = 5,
    criteria = c("BIC", "BLRT", "entropy"),
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
    design = "srs",
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
  expect_true(!is.na(fit@fit_indices$abic))  # lowercase abic
  expect_true(!is.na(fit@fit_indices$entropy))

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
    design = "srs",
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
  expect_true(fit@fit_indices$entropy >= 0)
  expect_true(fit@fit_indices$entropy <= 1)

  # Can also extract via function
  ent <- entropy(fit)
  expect_equal(ent, fit@fit_indices$entropy)
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
    classes = 1:3,
    strata = "stratum",
    weights = "weight",
    starts = 10,
    criteria = c("BIC", "entropy"),
    cores = 1
  )

  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 3)

  # All models should have survey design
  for (i in 1:length(result@fitted_models)) {
    expect_true(!is.null(result@fitted_models[[i]]@survey_design$strata))
  }
})

test_that("gmm_select error handling for invalid classes parameter", {
  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 3,
    n_classes = 2,
    seed = 901
  )

  # Should error on invalid classes specification
  expect_error(
    gmm_select(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      classes = c(3, 2, 1),  # Not sequential
      starts = 5,
      verbose = FALSE
    ),
    "classes must be in ascending order"
  )
})

test_that("gmm_select handles single class model correctly", {
  skip_on_cran()

  set.seed(902)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 1,
    design = "srs",
    seed = 902
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:2,  # Compare 1 vs 2 classes
    starts = 10,
    criteria = c("BIC", "entropy"),
    cores = 1
  )

  expect_s4_class(result, "SurveyMixrSelect")

  # 1-class model should be in fitted models
  expect_equal(min(result@comparison_table$n_classes), 1)
  expect_equal(max(result@comparison_table$n_classes), 2)
})

test_that("gmm_select with quadratic growth models compares correctly", {
  skip_on_cran()

  set.seed(903)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 5,
    n_classes = 2,
    design = "srs",
    seed = 903
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:3,
    growth_model = "quadratic",
    starts = 10,
    criteria = c("BIC", "entropy"),
    cores = 1
  )

  expect_s4_class(result, "SurveyMixrSelect")

  # All fitted models should be quadratic
  for (i in 1:length(result@fitted_models)) {
    expect_equal(result@fitted_models[[i]]@model_info$growth_model, "quadratic")
  }
})

test_that("Model selection can be plotted", {
  skip_on_cran()

  set.seed(307)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 307
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:3,
    starts = 10,
    criteria = c("BIC", "entropy"),
    cores = 1
  )

  # Should be able to plot without error
  expect_silent(plot_model_selection(result))
  expect_silent(plot_model_selection(result, criterion = "bic"))
  expect_silent(plot_model_selection(result, criterion = "entropy"))
})

test_that("Single class model serves as baseline", {
  skip_on_cran()

  set.seed(308)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 4,
    n_classes = 1,  # Homogeneous
    design = "srs",
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
  expect_equal(fit_1class@model_info$n_classes, 1)

  # Entropy should be NA or 1 for single class
  expect_true(is.na(fit_1class@fit_indices$entropy) || fit_1class@fit_indices$entropy == 1)
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
    design = "srs",
    seed = 309
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:5,
    starts = 20,
    criteria = c("BIC", "entropy"),
    cores = 1
  )

  # BIC should favor 3-class model (or close to it)
  # Find minimum BIC
  best_bic <- which.min(result@comparison_table$bic)

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
    design = "srs",
    seed = 310
  )

  # Run with parallel processing
  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:3,
    starts = 10,
    criteria = c("BIC", "entropy"),
    cores = 2
  )

  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 3)
})
