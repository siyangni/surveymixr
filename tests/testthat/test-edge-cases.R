# Tests for edge cases and boundary conditions
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

test_that("Single class model works (no mixture)", {
  skip_on_cran()

  set.seed(801)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 1,  # No mixture
    design = "SRS",
    seed = 801
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 1,
    starts = 5,  # Fewer starts needed
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@n_classes, 1)

  # Entropy should be NA or 1 for single class
  expect_true(is.na(fit@entropy) || fit@entropy == 1)
})

test_that("Very small sample size (n < 100)", {
  skip_on_cran()

  set.seed(802)
  sim_data <- simulate_gmm_survey(
    n_individuals = 50,  # Very small
    n_times = 4,
    n_classes = 2,
    design = "SRS",
    seed = 802
  )

  # Should warn about small sample
  expect_warning(
    fit <- gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      starts = 10,
      cores = 1
    ),
    regexp = "small|sample"
  )

  # May still converge
  expect_s4_class(fit, "SurveyMixr")
})

test_that("Perfect class separation", {
  skip_on_cran()

  set.seed(803)

  # Create data with perfect separation
  data_perfect <- data.frame(
    id = rep(1:100, each = 4),
    time = rep(0:3, 100),
    outcome = c(
      rep(10, 4 * 50),  # Class 1: all high
      rep(2, 4 * 50)    # Class 2: all low
    ),
    true_class = rep(c(1, 2), each = 4 * 50)
  )

  fit <- gmm_survey(
    data = data_perfect,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Should converge easily
  expect_true(fit@converged)

  # Entropy should be very high (near 1)
  expect_true(fit@entropy > 0.95)
})

test_that("All individuals in one class (degenerate solution)", {
  skip_on_cran()

  set.seed(804)

  # Homogeneous data that should collapse to one class
  sim_data <- data.frame(
    id = rep(1:150, each = 4),
    time = rep(0:3, 150),
    outcome = rnorm(600, mean = 5, sd = 0.5)  # Very similar trajectories
  )

  # Try to fit 3 classes
  fit <- suppressWarnings(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 3,
      starts = 10,
      cores = 1
    )
  )

  # May have empty or very small classes
  props <- class_proportions(fit)

  # Check for degenerate solution
  if (any(props$proportion < 0.05)) {
    expect_true(length(fit@warnings) > 0)
  }
})

test_that("Very large number of classes (model too complex)", {
  skip_on_cran()

  set.seed(805)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,  # True model: 2 classes
    design = "SRS",
    seed = 805
  )

  # Try to fit too many classes
  fit <- suppressWarnings(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 8,  # Way too many
      starts = 10,
      max_iter = 100,
      cores = 1
    )
  )

  # May not converge or have issues
  # Just check it doesn't error
  expect_s4_class(fit, "SurveyMixr")
})

test_that("Only 2 time points (minimal longitudinal)", {
  skip_on_cran()

  set.seed(806)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 2,  # Minimal
    n_classes = 2,
    design = "SRS",
    seed = 806
  )

  # Linear model should work
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    growth_model = "linear",
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@converged)

  # Quadratic should not be identifiable
  expect_error(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      growth_model = "quadratic",  # Can't fit with only 2 time points
      starts = 5,
      cores = 1
    ),
    regexp = "time points|identif"
  )
})

test_that("Extreme values in outcome", {
  skip_on_cran()

  set.seed(807)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "SRS",
    seed = 807
  )

  # Add extreme outliers
  outlier_idx <- sample(1:nrow(sim_data), 10)
  sim_data$outcome[outlier_idx] <- sim_data$outcome[outlier_idx] * 10

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Should still converge (mixture models can handle outliers)
  expect_s4_class(fit, "SurveyMixr")
})

test_that("Constant variance vs class-varying variance", {
  skip_on_cran()

  set.seed(808)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 2,
    residual_sds = c(1.0, 3.0),  # Different variances
    design = "SRS",
    seed = 808
  )

  # Default: class-varying variance
  fit_varying <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    variance = "class_varying",
    starts = 10,
    cores = 1
  )

  # Constrained: equal variance
  fit_equal <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    variance = "equal",
    starts = 10,
    cores = 1
  )

  # Varying variance should fit better (true model)
  expect_true(logLik(fit_varying) > logLik(fit_equal))
})

test_that("Unbalanced data (different numbers of observations)", {
  skip_on_cran()

  set.seed(809)

  # Create unbalanced data
  unbalanced_data <- data.frame(
    id = c(rep(1:50, each = 6),   # 50 people with 6 obs
           rep(51:100, each = 4),  # 50 people with 4 obs
           rep(101:150, each = 3)), # 50 people with 3 obs
    time = c(rep(0:5, 50), rep(0:3, 50), rep(0:2, 50)),
    outcome = rnorm(50*6 + 50*4 + 50*3, 5, 2)
  )

  fit <- gmm_survey(
    data = unbalanced_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@converged)
})

test_that("All missing for one time point", {
  skip_on_cran()

  set.seed(810)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 5,
    n_classes = 2,
    design = "SRS",
    seed = 810
  )

  # Make time point 3 completely missing
  sim_data$outcome[sim_data$time == 2] <- NA

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Should handle gracefully
  expect_s4_class(fit, "SurveyMixr")
})

test_that("Negative weights are rejected", {
  set.seed(811)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 3,
    n_classes = 2,
    design = "stratified",
    n_strata = 2,
    seed = 811
  )

  # Make some weights negative
  sim_data$weight[1:10] <- -1

  expect_error(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      weights = "weight",
      starts = 5
    ),
    regexp = "negative|weight"
  )
})

test_that("Zero weights are handled", {
  skip_on_cran()

  set.seed(812)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 3,
    n_classes = 2,
    design = "stratified",
    n_strata = 2,
    seed = 812
  )

  # Make some weights zero
  sim_data$weight[1:5] <- 0

  # Should warn and exclude
  expect_warning(
    fit <- gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      weights = "weight",
      starts = 10,
      cores = 1
    ),
    regexp = "zero|weight"
  )
})

test_that("Single observation per individual", {
  set.seed(813)

  # Cross-sectional data (no longitudinal)
  cross_sectional <- data.frame(
    id = 1:200,
    time = rep(0, 200),  # All at same time
    outcome = rnorm(200, 5, 2)
  )

  # Should error or warn (not longitudinal)
  expect_error(
    gmm_survey(
      data = cross_sectional,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      starts = 5
    ),
    regexp = "longitudinal|variation|time"
  )
})

test_that("Non-numeric outcome is rejected", {
  set.seed(814)

  bad_data <- data.frame(
    id = rep(1:50, each = 3),
    time = rep(0:2, 50),
    outcome = sample(letters[1:5], 150, replace = TRUE)  # Character
  )

  expect_error(
    gmm_survey(
      data = bad_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      starts = 5
    ),
    regexp = "numeric|character"
  )
})

test_that("Factor variables in covariates work", {
  skip_on_cran()

  set.seed(815)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    covariates = TRUE,
    design = "SRS",
    seed = 815
  )

  # Convert sex to factor
  sim_data$sex_factor <- factor(sim_data$sex, levels = c(0, 1), labels = c("Female", "Male"))

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    covariates = ~ sex_factor,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@converged)
})

test_that("Very high entropy (near-perfect classification)", {
  skip_on_cran()

  set.seed(816)

  # Well-separated classes
  data_sep <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 5,
    n_classes = 2,
    growth_parameters = list(
      list(intercept = 15, slope = 1.0),  # Very different
      list(intercept = 2, slope = -0.5)
    ),
    residual_sds = c(0.5, 0.5),  # Low noise
    design = "SRS",
    seed = 816
  )

  fit <- gmm_survey(
    data = data_sep,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Entropy should be very high
  expect_true(fit@entropy > 0.9)
})

test_that("Very low entropy (poor classification)", {
  skip_on_cran()

  set.seed(817)

  # Overlapping classes
  data_overlap <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    growth_parameters = list(
      list(intercept = 5.0, slope = 0.1),  # Very similar
      list(intercept = 5.2, slope = 0.12),
      list(intercept = 4.8, slope = 0.08)
    ),
    residual_sds = c(2, 2, 2),  # High noise
    design = "SRS",
    seed = 817
  )

  fit <- suppressWarnings(
    gmm_survey(
      data = data_overlap,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 3,
      starts = 20,
      cores = 1
    )
  )

  # Entropy should be low
  expect_true(fit@entropy < 0.7)
})
