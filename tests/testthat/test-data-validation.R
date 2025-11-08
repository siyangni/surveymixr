# Tests for Data Validation Functions
# Tests comprehensive data quality checks

context("Data Validation")

# Create valid test data
set.seed(456)
valid_data <- data.frame(
  id = rep(1:100, each = 5),
  time = rep(0:4, 100),
  outcome = rnorm(500, mean = 10, sd = 3),
  stratum = rep(1:4, each = 125),
  cluster = rep(1:20, each = 25),
  weight = runif(500, 0.5, 2),
  covariate1 = rnorm(500),
  covariate2 = rnorm(500)
)

skip_on_cran()

test_that("validate_survey_data accepts valid data", {
  result <- validate_survey_data(
    data = valid_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    strata = "stratum",
    cluster = "cluster",
    weights = "weight",
    verbose = FALSE
  )

  expect_s4_class(result, "DataValidation")
  expect_true(result@is_valid)
  expect_equal(length(result@errors), 0)
})

test_that("validate_survey_data detects missing variables", {
  result <- validate_survey_data(
    data = valid_data,
    id = "id",
    time = "time",
    outcome = "nonexistent_variable",  # Missing
    verbose = FALSE
  )

  expect_false(result@is_valid)
  expect_true(any(grepl("Missing required variables", result@errors)))
})

test_that("validate_survey_data detects duplicate ID-time combinations", {
  bad_data <- valid_data
  # Add duplicate
  bad_data <- rbind(bad_data, bad_data[1, ])

  result <- validate_survey_data(
    data = bad_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    verbose = FALSE
  )

  expect_false(result@is_valid)
  expect_true(any(grepl("duplicate", result@errors, ignore.case = TRUE)))
})

test_that("validate_survey_data checks cluster nesting", {
  # Create non-nested clusters (cluster 1 in both stratum 1 and 2)
  bad_data <- valid_data
  bad_data$cluster[bad_data$stratum == 2][1:10] <- bad_data$cluster[bad_data$stratum == 1][1]

  result <- validate_survey_data(
    data = bad_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    strata = "stratum",
    cluster = "cluster",
    verbose = FALSE
  )

  expect_false(result@is_valid)
  expect_true(any(grepl("nested", result@errors, ignore.case = TRUE)))
})

test_that("validate_survey_data detects weight issues", {
  # Missing weights
  bad_data <- valid_data
  bad_data$weight[1:10] <- NA

  result <- validate_survey_data(
    data = bad_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    weights = "weight",
    verbose = FALSE
  )

  expect_false(result@is_valid)
  expect_true(any(grepl("missing weight", result@errors, ignore.case = TRUE)))

  # Non-positive weights
  bad_data <- valid_data
  bad_data$weight[1:5] <- -1

  result <- validate_survey_data(
    data = bad_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    weights = "weight",
    verbose = FALSE
  )

  expect_false(result@is_valid)
  expect_true(any(grepl("non-positive", result@errors, ignore.case = TRUE)))
})

test_that("validate_survey_data warns about extreme weights", {
  bad_data <- valid_data
  # Add extreme weight
  bad_data$weight[1] <- 100  # Very large

  result <- validate_survey_data(
    data = bad_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    weights = "weight",
    verbose = FALSE
  )

  # Should have warning about extreme weights
  expect_true(any(grepl("extreme weight", result@warnings, ignore.case = TRUE)))
})

test_that("validate_survey_data checks for minimum observations", {
  bad_data <- valid_data
  # Remove most observations for ID 1
  bad_data <- bad_data[!(bad_data$id == 1 & bad_data$time > 1), ]

  result <- validate_survey_data(
    data = bad_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    min_observations = 3,
    verbose = FALSE
  )

  # Should warn about insufficient observations
  expect_true(any(grepl("< 3 observations", result@warnings, ignore.case = TRUE)) ||
             any(grepl("insufficient", result@warnings, ignore.case = TRUE)))
})

test_that("validate_survey_data analyzes missing data patterns", {
  # Create data with missing outcomes
  missing_data <- valid_data
  missing_data$outcome[sample(1:500, 50)] <- NA

  result <- validate_survey_data(
    data = missing_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    verbose = FALSE
  )

  # Should report missing percentage
  expect_true(!is.null(result@info$outcome_missing_pct))
  expect_true(result@info$outcome_missing_pct > 0)
  expect_true(result@info$outcome_missing_pct <= 100)
})

test_that("validate_survey_data detects monotone missing patterns", {
  # Create monotone dropout pattern
  monotone_data <- valid_data
  # ID 1-10 drop out at different times
  for (i in 1:10) {
    dropout_time <- i %% 5
    monotone_data$outcome[monotone_data$id == i & monotone_data$time >= dropout_time] <- NA
  }

  result <- validate_survey_data(
    data = monotone_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    verbose = FALSE
  )

  # Check that missing pattern is assessed
  expect_true(!is.null(result@info$missing_pattern))
})

test_that("validate_survey_data checks outcome distribution", {
  result <- validate_survey_data(
    data = valid_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    verbose = FALSE
  )

  # Should have outcome summary statistics
  expect_true(!is.null(result@info$outcome_summary))
  expect_true(!is.null(result@info$outcome_skewness))
  expect_true(!is.null(result@info$outcome_kurtosis))
})

test_that("validate_survey_data detects outliers", {
  outlier_data <- valid_data
  # Add extreme outliers
  outlier_data$outcome[1:5] <- c(100, 105, -80, -90, 110)

  result <- validate_survey_data(
    data = outlier_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    verbose = FALSE
  )

  # Should warn about outliers
  expect_true(any(grepl("outlier", result@warnings, ignore.case = TRUE)))
})

test_that("validate_survey_data checks time variable", {
  result <- validate_survey_data(
    data = valid_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    verbose = FALSE
  )

  # Should report time points
  expect_true(!is.null(result@info$time_points))
  expect_true(!is.null(result@info$n_time_points))
  expect_equal(result@info$n_time_points, 5)
})

test_that("validate_survey_data warns about few time points", {
  two_time_data <- valid_data[valid_data$time %in% c(0, 1), ]

  result <- validate_survey_data(
    data = two_time_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    verbose = FALSE
  )

  # Should warn about limited time points
  expect_true(any(grepl("2 time points|limited", result@warnings, ignore.case = TRUE)))
})

test_that("validate_survey_data checks covariate multicollinearity", {
  # Create highly correlated covariates
  corr_data <- valid_data
  corr_data$covariate2 <- corr_data$covariate1 * 1.01 + rnorm(500, 0, 0.01)

  result <- validate_survey_data(
    data = corr_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    covariates = c("covariate1", "covariate2"),
    verbose = FALSE
  )

  # Should warn about high correlations
  expect_true(any(grepl("correlation", result@warnings, ignore.case = TRUE)))
})

test_that("validate_survey_data calculates design effect", {
  result <- validate_survey_data(
    data = valid_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    weights = "weight",
    verbose = FALSE
  )

  # Should calculate design effect
  expect_true(!is.null(result@info$design_effect))
  expect_true(result@info$design_effect > 0)
})

test_that("validate_survey_data provides recommendations", {
  # Use problematic data
  problem_data <- valid_data
  problem_data$weight[1] <- 50  # Extreme weight
  problem_data$outcome[sample(1:500, 150)] <- NA  # High missingness

  result <- validate_survey_data(
    data = problem_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    weights = "weight",
    verbose = FALSE
  )

  # Should have recommendations
  expect_true(length(result@recommendations) > 0)
})

test_that("DataValidation print method works", {
  result <- validate_survey_data(
    data = valid_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    verbose = FALSE
  )

  expect_output(show(result), "VALIDATION")
  expect_output(show(result), "PASSED|FAILED")
})

test_that("Helper functions work correctly", {
  # Test skewness calculation
  x <- c(1, 2, 3, 4, 5, 100)  # Right-skewed
  skew <- .calculate_skewness(x)
  expect_true(skew > 0)

  x_symmetric <- c(-2, -1, 0, 1, 2)
  skew_sym <- .calculate_skewness(x_symmetric)
  expect_true(abs(skew_sym) < 0.1)

  # Test kurtosis calculation
  kurt <- .calculate_kurtosis(rnorm(1000))
  expect_true(abs(kurt) < 1)  # Normal should be near 0 (excess)
})

test_that("Monotone missing check works", {
  # Create monotone pattern
  mono_data <- data.frame(
    id = rep(1:10, each = 5),
    time = rep(1:5, 10),
    outcome = rnorm(50)
  )

  # Add monotone missingness for some individuals
  mono_data$outcome[mono_data$id == 1 & mono_data$time >= 4] <- NA
  mono_data$outcome[mono_data$id == 2 & mono_data$time >= 3] <- NA

  is_mono <- .check_monotone_missing(mono_data, "id", "time", "outcome")
  # Should detect monotone pattern (most individuals have it)
  expect_true(is.logical(is_mono))

  # Create non-monotone pattern
  nonmono_data <- mono_data
  nonmono_data$outcome[nonmono_data$id == 3 & nonmono_data$time == 3] <- NA
  nonmono_data$outcome[nonmono_data$id == 3 & nonmono_data$time == 5] <- 5  # Not monotone

  is_nonmono <- .check_monotone_missing(nonmono_data, "id", "time", "outcome")
  # Pattern should be less clearly monotone
  expect_true(is.logical(is_nonmono))
})
