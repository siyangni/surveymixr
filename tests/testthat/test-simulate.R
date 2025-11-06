# Tests for data simulation

test_that("simulate_gmm_survey creates data with correct structure", {
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 123
  )

  expect_s3_class(sim_data, "data.frame")
  expect_true("id" %in% names(sim_data))
  expect_true("time" %in% names(sim_data))
  expect_true("outcome" %in% names(sim_data))
  expect_true("true_class" %in% names(sim_data))

  # Check dimensions
  expect_equal(nrow(sim_data), 100 * 4)
  expect_equal(length(unique(sim_data$id)), 100)
  expect_equal(length(unique(sim_data$time)), 4)
})

test_that("simulate_gmm_survey respects class proportions", {
  sim_data <- simulate_gmm_survey(
    n_individuals = 1000,
    n_times = 3,
    n_classes = 3,
    class_proportions = c(0.5, 0.3, 0.2),
    seed = 456
  )

  true_classes <- unique(sim_data[, c("id", "true_class")])$true_class
  props <- prop.table(table(true_classes))

  # Allow 10% deviation from specified proportions
  expect_equal(as.numeric(props[1]), 0.5, tolerance = 0.1)
  expect_equal(as.numeric(props[2]), 0.3, tolerance = 0.1)
  expect_equal(as.numeric(props[3]), 0.2, tolerance = 0.1)
})

test_that("simulate_gmm_survey handles different designs", {
  designs <- c("srs", "stratified", "cluster", "stratified_cluster")

  for (design in designs) {
    sim_data <- simulate_gmm_survey(
      n_individuals = 100,
      n_times = 3,
      n_classes = 2,
      design = design,
      seed = 789
    )

    expect_true("weight" %in% names(sim_data))
    expect_true("stratum" %in% names(sim_data))
    expect_true("psu" %in% names(sim_data))
  }
})

test_that("simulate_gmm_survey includes missing data", {
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 5,
    n_classes = 2,
    missing_rate = 0.2,
    seed = 321
  )

  missing_prop <- mean(is.na(sim_data$outcome))
  expect_gt(missing_prop, 0)
  expect_lt(missing_prop, 0.3)  # Allow some variation
})
