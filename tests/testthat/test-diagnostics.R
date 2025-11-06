# Tests for diagnostic functions

test_that("entropy function works", {
  # Test matrix input
  post_probs <- matrix(c(0.9, 0.1, 0.2, 0.8, 0.7, 0.3), nrow = 3, byrow = TRUE)
  ent <- entropy(post_probs)

  expect_type(ent, "double")
  expect_true(ent >= 0 && ent <= 1)
})

test_that("class_proportions works", {
  skip_on_cran()

  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 3,
    seed = 555
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 10,
    verbose = FALSE
  )

  props <- class_proportions(fit)

  expect_s3_class(props, "data.frame")
  expect_equal(nrow(props), 3)
  expect_true("proportion" %in% names(props))
  expect_true("se" %in% names(props))
  expect_true(all(props$proportion >= 0 & props$proportion <= 1))
  expect_equal(sum(props$proportion), 1, tolerance = 1e-6)
})

test_that("classification_quality works", {
  skip_on_cran()

  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 666
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

  qual <- classification_quality(fit)

  expect_type(qual, "list")
  expect_true("entropy" %in% names(qual))
  expect_true("avepp_overall" %in% names(qual))
  expect_true("summary_by_class" %in% names(qual))
  expect_s3_class(qual$summary_by_class, "data.frame")
})

test_that("diagnose_convergence works", {
  skip_on_cran()

  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 4,
    n_classes = 2,
    seed = 777
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 20,
    verbose = FALSE
  )

  diag <- diagnose_convergence(fit, plot = FALSE)

  expect_s4_class(diag, "ConvergenceDiagnostics")
  expect_true(!is.na(diag@best_loglik))
  expect_true(diag@n_replications >= 1)
  expect_s3_class(diag@loglik_table, "data.frame")
})
