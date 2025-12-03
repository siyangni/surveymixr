# Tests for plotting edge cases and error handling
# Part of v0.2.2 improvements to increase coverage to 70%+

test_that("plot_trajectories handles different class numbers", {
  skip_on_cran()

  set.seed(701)

  # Test with 2 classes
  sim_data_2class <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 701
  )

  fit_2class <- gmm_survey(
    data = sim_data_2class,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 5,
    cores = 1,
    verbose = FALSE
  )

  expect_silent(p1 <- plot_trajectories(fit_2class))
  expect_s3_class(p1, "ggplot")

  # Test with 4 classes
  sim_data_4class <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 4,
    seed = 702
  )

  fit_4class <- gmm_survey(
    data = sim_data_4class,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 4,
    starts = 5,
    cores = 1,
    verbose = FALSE
  )

  expect_silent(p2 <- plot_trajectories(fit_4class))
  expect_s3_class(p2, "ggplot")
})

test_that("plot_trajectories handles custom color palettes", {
  skip_on_cran()

  set.seed(703)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 3,
    seed = 703
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 5,
    cores = 1,
    verbose = FALSE
  )

  # Test different color palettes
  palettes <- c("Set1", "Set2", "viridis", "RdYlBu")

  for (pal in palettes) {
    expect_silent(
      p <- plot_trajectories(fit, palette = pal)
    )
    expect_s3_class(p, "ggplot")
  }
})

test_that("plot_trajectories handles different time score formats", {
  skip_on_cran()

  set.seed(704)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 5,
    n_classes = 2,
    seed = 704
  )

  # Create data with irregular time points
  sim_data$age <- sim_data$time * 2 + 8  # Ages 8, 10, 12, 14, 16

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "age",
    outcome = "outcome",
    n_classes = 2,
    starts = 5,
    cores = 1,
    verbose = FALSE
  )

  expect_silent(p <- plot_trajectories(fit))
  expect_s3_class(p, "ggplot")
})

test_that("plot_entropy_distribution works correctly", {
  skip_on_cran()

  set.seed(705)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 4,
    n_classes = 3,
    seed = 705
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 5,
    cores = 1,
    verbose = FALSE
  )

  expect_silent(p <- plot_entropy_distribution(fit))
  expect_s3_class(p, "ggplot")
})

test_that("plot_convergence handles different convergence patterns", {
  skip_on_cran()

  set.seed(706)
  sim_data <- simulate_gmm_survey(
    n_individuals = 80,
    n_times = 4,
    n_classes = 2,
    seed = 706
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 20,  # Multiple starts to test convergence plot
    cores = 1,
    verbose = FALSE
  )

  expect_silent(p <- plot_convergence(fit))
  expect_s3_class(p, "ggplot")
})

test_that("plot_class_sizes shows weighted and unweighted class proportions", {
  skip_on_cran()

  set.seed(707)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 3,
    design = "stratified",
    n_strata = 2,
    seed = 707
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    strata = "stratum",
    weights = "weight",
    starts = 5,
    cores = 1,
    verbose = FALSE
  )

  # Weighted class sizes
  expect_silent(p1 <- plot_class_sizes(fit, weighted = TRUE))
  expect_s3_class(p1, "ggplot")

  # Unweighted class sizes
  expect_silent(p2 <- plot_class_sizes(fit, weighted = FALSE))
  expect_s3_class(p2, "ggplot")
})

test_that("plot_model_selection handles different criteria", {
  skip_on_cran()

  set.seed(708)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 4,
    n_classes = 2,
    seed = 708
  )

  result <- gmm_select(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    classes = 1:3,
    starts = 5,
    criteria = c("BIC", "entropy"),
    cores = 1,
    verbose = FALSE
  )

  # Test different criteria
  expect_silent(p1 <- plot_model_selection(result, criteria = "bic"))
  expect_s3_class(p1, "ggplot")

  expect_silent(p2 <- plot_model_selection(result, criteria = "entropy"))
  expect_s3_class(p2, "ggplot")

  # Multiple criteria
  expect_silent(p3 <- plot_model_selection(result, criteria = c("bic", "entropy")))
  expect_s3_class(p3, "ggplot")
})

test_that("plotting functions handle single class model", {
  skip_on_cran()

  set.seed(709)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 1,
    seed = 709
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 1,
    starts = 5,
    cores = 1,
    verbose = FALSE
  )

  # Should not error on single class
  expect_silent(p1 <- plot_trajectories(fit))
  expect_s3_class(p1, "ggplot")

  expect_silent(p2 <- plot_class_sizes(fit))
  expect_s3_class(p2, "ggplot")
})

test_that("plotting functions validate inputs correctly", {
  skip_on_cran()

  set.seed(710)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 710
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 5,
    cores = 1,
    verbose = FALSE
  )

  # Test invalid inputs give informative errors
  expect_error(
    plot_trajectories("not_a_fit"),
    "must be a fitted"
  )

  expect_error(
    plot_model_selection(fit),  # Should be SurveyMixrSelect object
    "must be a SurveyMixrSelect"
  )
})

test_that("plot_class_sizes handles empty classes gracefully", {
  skip_on_cran()

  set.seed(711)
  sim_data <- simulate_gmm_survey(
    n_individuals = 120,
    n_times = 4,
    n_classes = 3,
    class_proportions = c(0.8, 0.2, 0.0),  # One empty class
    seed = 711
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 10,
    cores = 1,
    verbose = FALSE
  )

  # Should handle empty class without error
  expect_silent(p <- plot_class_sizes(fit))
  expect_s3_class(p, "ggplot")
})
