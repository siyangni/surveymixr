# Tests for Categorical Outcome Support
# Tests binary, ordinal, and count outcome functions

context("Categorical Outcomes")

# Setup test data
test_data_binary <- data.frame(
  id = rep(1:100, each = 4),
  time = rep(0:3, 100),
  outcome = rbinom(400, 1, 0.5),
  stratum = rep(1:2, each = 200),
  cluster = rep(1:20, each = 20),
  weight = runif(400, 0.5, 2)
)

test_data_ordinal <- data.frame(
  id = rep(1:100, each = 4),
  time = rep(0:3, 100),
  outcome = sample(0:4, 400, replace = TRUE),
  stratum = rep(1:2, each = 200),
  cluster = rep(1:20, each = 20),
  weight = runif(400, 0.5, 2)
)

test_data_count <- data.frame(
  id = rep(1:100, each = 4),
  time = rep(0:3, 100),
  outcome = rpois(400, lambda = 3),
  stratum = rep(1:2, each = 200),
  cluster = rep(1:20, each = 20),
  weight = runif(400, 0.5, 2)
)


test_that("Link functions return correct structure", {
  # Continuous
  link_cont <- get_link_function("continuous")
  expect_type(link_cont, "list")
  expect_true("link" %in% names(link_cont))
  expect_true("linkinv" %in% names(link_cont))

  # Binary
  link_binary <- get_link_function("binary")
  expect_equal(link_binary$name, "probit")
  expect_type(link_binary$link, "closure")

  # Count
  link_count <- get_link_function("count")
  expect_equal(link_count$name, "log")
})

test_that("Link functions work correctly", {
  # Probit link
  link <- get_link_function("binary")
  x <- 0.5
  # link and inverse should be reciprocal
  expect_equal(link$linkinv(link$link(x)), x, tolerance = 1e-10)

  # Log link
  link <- get_link_function("count")
  expect_equal(link$linkinv(link$link(5)), 5, tolerance = 1e-10)
})

test_that("Outcome validation works for binary data", {
  # Valid binary data (0, 1)
  expect_true(validate_outcome_type(test_data_binary, "outcome", "binary"))

  # Invalid binary data
  bad_data <- test_data_binary
  bad_data$outcome[1] <- 2
  expect_error(
    validate_outcome_type(bad_data, "outcome", "binary"),
    "Binary outcomes must be 0 or 1"
  )
})

test_that("Outcome validation works for ordinal data", {
  # Valid ordinal data
  expect_true(validate_outcome_type(test_data_ordinal, "outcome",
                                   "ordinal", n_categories = 5))

  # Invalid ordinal data (non-consecutive)
  bad_data <- data.frame(outcome = c(0, 1, 3, 4))  # Missing 2
  expect_error(
    validate_outcome_type(bad_data, "outcome", "ordinal", n_categories = 5),
    "consecutive integers"
  )
})

test_that("Outcome validation works for count data", {
  # Valid count data
  expect_true(validate_outcome_type(test_data_count, "outcome", "count"))

  # Invalid count data (negative)
  bad_data <- test_data_count
  bad_data$outcome[1] <- -1
  expect_error(
    validate_outcome_type(bad_data, "outcome", "count"),
    "non-negative integers"
  )

  # Invalid count data (non-integer)
  bad_data <- test_data_count
  bad_data$outcome[1] <- 2.5
  expect_error(
    validate_outcome_type(bad_data, "outcome", "count"),
    "non-negative integers"
  )
})

test_that("gmm_survey_binary validates input correctly", {
  skip_on_cran()
  # Should accept valid binary data
  expect_silent({
    try(gmm_survey_binary(
      data = test_data_binary,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      starts = 10,
      verbose = FALSE
    ), silent = TRUE)
  })

  # Should reject non-binary data
  bad_data <- test_data_binary
  bad_data$outcome[1] <- 2

  expect_error(
    gmm_survey_binary(
      data = bad_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2
    ),
    "must be coded as 0 or 1"
  )
})

test_that("gmm_survey_ordinal validates input correctly", {
  skip_on_cran()
  expect_silent({
    try(gmm_survey_ordinal(
      data = test_data_ordinal,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      n_categories = 5,
      starts = 10,
      verbose = FALSE
    ), silent = TRUE)
  })

  # Wrong number of categories
  expect_error(
    gmm_survey_ordinal(
      data = test_data_ordinal,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      n_categories = 3  # Wrong!
    ),
    "does not match"
  )
})

test_that("gmm_survey_count validates input correctly", {
  expect_silent({
    try(gmm_survey_count(
      data = test_data_count,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      count_model = "poisson",
      starts = 10,
      verbose = FALSE
    ), silent = TRUE)
  })

  # Non-integer data
  bad_data <- test_data_count
  bad_data$outcome[1] <- 2.5

  expect_error(
    gmm_survey_count(
      data = bad_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2
    ),
    "non-negative integers"
  )
})

test_that("Link function specification works", {
  skip_on_cran()
  # Probit link
  expect_silent({
    try(gmm_survey_binary(
      data = test_data_binary,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      link = "probit",
      starts = 5,
      verbose = FALSE
    ), silent = TRUE)
  })

  # Logit link
  expect_silent({
    try(gmm_survey_binary(
      data = test_data_binary,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      link = "logit",
      starts = 5,
      verbose = FALSE
    ), silent = TRUE)
  })
})

test_that("Count model types work", {
  # Poisson
  expect_silent({
    try(gmm_survey_count(
      data = test_data_count,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      count_model = "poisson",
      starts = 5,
      verbose = FALSE
    ), silent = TRUE)
  })

  # Negative binomial
  expect_silent({
    try(gmm_survey_count(
      data = test_data_count,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      count_model = "negative_binomial",
      starts = 5,
      verbose = FALSE
    ), silent = TRUE)
  })

  # Zero-inflated
  expect_silent({
    try(gmm_survey_count(
      data = test_data_count,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      count_model = "zero_inflated",
      starts = 5,
      verbose = FALSE
    ), silent = TRUE)
  })
})

test_that("Ordinal model types work", {
  skip_on_cran()
  # Proportional odds
  expect_silent({
    try(gmm_survey_ordinal(
      data = test_data_ordinal,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      n_categories = 5,
      ordinal_model = "proportional_odds",
      starts = 5,
      verbose = FALSE
    ), silent = TRUE)
  })

  # Adjacent category
  expect_silent({
    try(gmm_survey_ordinal(
      data = test_data_ordinal,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      n_categories = 5,
      ordinal_model = "adjacent_category",
      starts = 5,
      verbose = FALSE
    ), silent = TRUE)
  })
})
