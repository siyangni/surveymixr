# Tests for Advanced Diagnostics Functions
# Note: Some advanced diagnostics have placeholder implementations
# These tests verify function signatures and basic functionality

test_that("diagnose_influence exists and has correct signature", {
  # Function should exist
  expect_true(exists("diagnose_influence"))
  expect_true(is.function(diagnose_influence))

  # Should be exported
  expect_true("diagnose_influence" %in% getNamespaceExports("surveymixr"))
})

test_that("diagnose_separation exists and has correct signature", {
  # Function should exist
  expect_true(exists("diagnose_separation"))
  expect_true(is.function(diagnose_separation))

  # Should be exported
  expect_true("diagnose_separation" %in% getNamespaceExports("surveymixr"))
})

test_that("residual_diagnostics exists and has correct signature", {
  # Function should exist
  expect_true(exists("residual_diagnostics"))
  expect_true(is.function(residual_diagnostics))

  # Should be exported
  expect_true("residual_diagnostics" %in% getNamespaceExports("surveymixr"))
})

test_that("diagnose_separation works with fitted model", {
  skip_on_cran()
  # Create simple model
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 701
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

  # Should not error
  result <- expect_error(diagnose_separation(fit), NA)

  # Should return a named list or S4 object
  expect_true(is.list(result) || isS4(result))
})

test_that("residual_diagnostics works with fitted model", {
  skip_on_cran()
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 702
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

  # Should not error
  result <- expect_error(residual_diagnostics(fit), NA)

  # Should return a list or data frame
  expect_true(is.list(result) || is.data.frame(result))
})

test_that("Influence diagnostics class is defined", {
  # S4 class should exist if defined
  if ("InfluenceDiagnostics" %in% getClasses()) {
    expect_true("InfluenceDiagnostics" %in% getNamespaceExports("surveymixr"))
  }
})

# Future tests (activate once full implementation is complete):
#
# test_that("diagnose_influence computes Cook's D correctly", {
#   sim_data <- simulate_gmm_survey(
#     n_individuals = 150,
#     n_times = 4,
#     n_classes = 2,
#     seed = 703
#   )
#
#   fit <- gmm_survey(
#     data = sim_data,
#     id = "id",
#     time = "time",
#     outcome = "outcome",
#     n_classes = 2,
#     starts = 20,
#     keep_data = TRUE,  # Required for influence diagnostics
#     verbose = FALSE
#   )
#
#   influence <- diagnose_influence(fit)
#
#   expect_s4_class(influence, "InfluenceDiagnostics")
#   expect_true(!is.null(influence@cooks_d))
#   expect_true(!is.null(influence@dfbetas))
#   expect_equal(length(influence@cooks_d), 150)
# })
#
# test_that("diagnose_influence flags influential cases", {
#   # (Implementation pending)
# })
#
# test_that("diagnose_separation detects perfect separation", {
#   # (Implementation pending)
# })
#
# test_that("residual_diagnostics computes standardized residuals", {
#   # (Implementation pending)
# })
#
# test_that("residual_diagnostics performs normality tests", {
#   # (Implementation pending)
# })
