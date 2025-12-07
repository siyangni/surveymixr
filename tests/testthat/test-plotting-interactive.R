# Tests for Interactive Plotting Functions
# These functions require plotly package (Suggests dependency)

test_that("plot_interactive exists and has correct signature", {
  # Function should exist
  expect_true(exists("plot_interactive"))
  expect_true(is.function(plot_interactive))

  # Should be exported
  expect_true("plot_interactive" %in% getNamespaceExports("surveymixr"))
})

test_that("plot_model_selection_interactive exists and has correct signature", {
  # Function should exist
  expect_true(exists("plot_model_selection_interactive"))
  expect_true(is.function(plot_model_selection_interactive))

  # Should be exported
  expect_true("plot_model_selection_interactive" %in% getNamespaceExports("surveymixr"))
})

test_that("plot_interactive handles missing plotly gracefully", {
  skip_on_cran()
  # This test checks behavior when plotly is not available
  skip_if(requireNamespace("plotly", quietly = TRUE), "plotly is available")

  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 4,
    n_classes = 2,
    seed = 601
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

  # Should give informative message about plotly
  expect_message(
    plot_interactive(fit),
    "plotly|required"
  )
})

test_that("plot_interactive creates plot when plotly available", {
  skip_on_cran()
  skip_if_not_installed("plotly")

  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 4,
    n_classes = 2,
    seed = 602
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

  # Should create a plotly object
  p <- plot_interactive(fit, type = "trajectories")

  expect_true(inherits(p, "plotly") || inherits(p, "htmlwidget"))
})

test_that("plot_interactive supports different plot types", {
  skip_on_cran()
  skip_if_not_installed("plotly")

  sim_data <- simulate_gmm_survey(
    n_individuals = 50,
    n_times = 4,
    n_classes = 2,
    seed = 603
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

  # Test different plot types
  types <- c("trajectories", "individual", "spaghetti")

  for (plot_type in types) {
    expect_error(
      plot_interactive(fit, type = plot_type),
      NA,
      info = paste("plot_interactive with type =", plot_type)
    )
  }
})

# Future tests (activate once full implementation is complete):
#
# test_that("plot_interactive customization options work", {
#   skip_if_not_installed("plotly")
#
#   sim_data <- simulate_gmm_survey(
#     n_individuals = 100,
#     n_times = 4,
#     n_classes = 3,
#     seed = 604
#   )
#
#   fit <- gmm_survey(
#     data = sim_data,
#     id = "id",
#     time = "time",
#     outcome = "outcome",
#     n_classes = 3,
#     starts = 10,
#     verbose = FALSE
#   )
#
#   # Test color palette
#   p1 <- plot_interactive(fit, palette = "Set2")
#   expect_true(inherits(p1, "plotly"))
#
#   # Test confidence intervals
#   p2 <- plot_interactive(fit, show_ci = TRUE)
#   expect_true(inherits(p2, "plotly"))
#
#   # Test sample size for individual plots
#   p3 <- plot_interactive(fit, type = "individual", sample_n = 10)
#   expect_true(inherits(p3, "plotly"))
# })
#
# test_that("plot_model_selection_interactive works with gmm_select object", {
#   # (Implementation pending)
# })
