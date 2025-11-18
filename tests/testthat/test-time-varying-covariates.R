# Tests for Time-Varying Covariates Functions
# Note: TVC functionality is currently a placeholder/stub
# These tests verify function signatures and expected behavior

test_that("gmm_survey_tvc exists and has correct signature", {
  # Function should exist
  expect_true(exists("gmm_survey_tvc"))
  expect_true(is.function(gmm_survey_tvc))

  # Should be exported
  expect_true("gmm_survey_tvc" %in% getNamespaceExports("surveymixr"))
})

test_that("gmm_survey_tvc gives informative error for unimplemented functionality", {
  # Create simple test data with a time-varying covariate
  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 4,
    n_classes = 2,
    seed = 888
  )

  # Add a time-varying covariate
  sim_data$tvc1 <- rnorm(nrow(sim_data))

  # Should throw informative error about pending implementation
  expect_error(
    gmm_survey_tvc(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      tvc_formula = ~ tvc1,
      n_classes = 2,
      starts = 5,
      verbose = FALSE
    ),
    "Full implementation pending"
  )
})

test_that("extract_tvc_effects exists and has correct signature", {
  # Function should exist
  expect_true(exists("extract_tvc_effects"))
  expect_true(is.function(extract_tvc_effects))

  # Should be exported
  expect_true("extract_tvc_effects" %in% getNamespaceExports("surveymixr"))
})

test_that("test_tvc_effects exists and has correct signature", {
  # Function should exist
  expect_true(exists("test_tvc_effects"))
  expect_true(is.function(test_tvc_effects))

  # Should be exported
  expect_true("test_tvc_effects" %in% getNamespaceExports("surveymixr"))
})

test_that("SurveyMixrTVC class is defined", {
  # S4 class should exist
  expect_true("SurveyMixrTVC" %in% getClasses())

  # Should be exported
  expect_true("SurveyMixrTVC" %in% getNamespaceExports("surveymixr"))

  # Should inherit from SurveyMixr
  expect_true("SurveyMixr" %in% extends("SurveyMixrTVC"))
})

test_that("plot_tvc_effects exists", {
  # Function should exist
  expect_true(exists("plot_tvc_effects"))
  expect_true(is.function(plot_tvc_effects))

  # Should be exported
  expect_true("plot_tvc_effects" %in% getNamespaceExports("surveymixr"))
})

# Future tests (activate once implementation is complete):
#
# test_that("gmm_survey_tvc fits model with time-varying covariates", {
#   sim_data <- simulate_gmm_survey(
#     n_individuals = 150,
#     n_times = 4,
#     n_classes = 2,
#     seed = 901
#   )
#
#   # Add time-varying covariate
#   sim_data$stress <- rnorm(nrow(sim_data), mean = 5, sd = 2)
#
#   fit <- gmm_survey_tvc(
#     data = sim_data,
#     id = "id",
#     time = "time",
#     outcome = "outcome",
#     tvc_formula = ~ stress,
#     n_classes = 2,
#     tvc_type = "direct",
#     starts = 10,
#     verbose = FALSE
#   )
#
#   expect_s4_class(fit, "SurveyMixrTVC")
#   expect_true(fit@convergence_info$converged)
#   expect_true(!is.null(fit@tvc_effects))
# })
#
# test_that("gmm_survey_tvc supports within-between decomposition", {
#   # (Implementation pending)
# })
#
# test_that("extract_tvc_effects returns proper data frame", {
#   # (Implementation pending)
# })
#
# test_that("test_tvc_effects performs Wald tests", {
#   # (Implementation pending)
# })
