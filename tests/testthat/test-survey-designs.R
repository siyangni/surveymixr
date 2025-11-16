# Tests for different complex survey designs
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

test_that("Simple Random Sampling (SRS) works", {

  set.seed(201)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 201
  )

  # Fit without survey design specified
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # For SRS, weighted and unweighted proportions should be similar
  props <- class_proportions(fit)
  expect_equal(nrow(props), 2)
})

test_that("Stratified sampling works correctly", {

  set.seed(202)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "stratified",
    n_strata = 3,
    seed = 202
  )

  # Fit with stratification
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    strata = "stratum",
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)
  expect_true(!is.null(fit@survey_design$strata))
})

test_that("Cluster sampling works correctly", {

  set.seed(203)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "cluster",
    n_clusters = 30,
    seed = 203
  )

  # Fit with clustering
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    cluster = "psu",
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)
  expect_true(!is.null(fit@survey_design$cluster))
})

test_that("Stratified cluster sampling works correctly", {

  set.seed(204)
  sim_data <- simulate_gmm_survey(
    n_individuals = 400,
    n_times = 4,
    n_classes = 2,
    design = "stratified_cluster",
    n_strata = 3,
    n_clusters = 30,
    seed = 204
  )

  # Fit with both stratification and clustering
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    strata = "stratum",
    cluster = "psu",
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)
  expect_true(!is.null(fit@survey_design$strata))
  expect_true(!is.null(fit@survey_design$cluster))
})

test_that("Nested design works correctly", {

  set.seed(205)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "stratified_cluster",
    n_strata = 3,
    n_clusters = 30,
    seed = 205
  )

  # Fit with nesting (clusters nested within strata)
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    strata = "stratum",
    cluster = "psu",
    nest = TRUE,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)
  expect_true(fit@survey_design$nest)
})

test_that("Probability weights are applied correctly", {

  set.seed(206)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "stratified",
    n_strata = 3,
    weight_type = "inverse_prob",
    seed = 206
  )

  # Fit with weights
  fit_weighted <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    weights = "weight",
    starts = 10,
    cores = 1
  )

  # Fit without weights
  fit_unweighted <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Weighted and unweighted should differ
  props_weighted <- class_proportions(fit_weighted, weighted = TRUE)
  props_unweighted <- class_proportions(fit_unweighted, weighted = FALSE)

  # Class proportions should be different
  expect_false(all(abs(props_weighted$proportion - props_unweighted$proportion) < 0.01))
})

test_that("Survey design with all components works", {

  set.seed(207)
  sim_data <- simulate_gmm_survey(
    n_individuals = 400,
    n_times = 4,
    n_classes = 2,
    design = "stratified_cluster",
    n_strata = 4,
    n_clusters = 40,
    weight_type = "inverse_prob",
    seed = 207
  )

  # Fit with full survey design
  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    strata = "stratum",
    cluster = "psu",
    weights = "weight",
    nest = TRUE,
    starts = 10,
    cores = 1
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_true(fit@convergence_info$converged)

  # Check all survey components are stored
  expect_true(!is.null(fit@survey_design$strata))
  expect_true(!is.null(fit@survey_design$cluster))
  expect_true(!is.null(fit@survey_design$weights))
  expect_true(fit@survey_design$nest)
})

test_that("Survey design standard errors are adjusted", {

  set.seed(208)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 2,
    design = "cluster",
    n_clusters = 30,
    seed = 208
  )

  # Fit with clustering (should have larger SEs)
  fit_cluster <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    cluster = "psu",
    starts = 10,
    cores = 1
  )

  # Fit ignoring clustering (SEs will be too small)
  fit_naive <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Get standard errors
  vcov_cluster <- vcov(fit_cluster)
  vcov_naive <- vcov(fit_naive)

  # Cluster-adjusted SEs should generally be larger
  # (accounting for design effect)
  expect_true(any(diag(vcov_cluster) > diag(vcov_naive)))
})

test_that("Invalid survey design specifications are caught", {
  set.seed(209)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 3,
    n_classes = 2,
    design = "srs",
    seed = 209
  )

  # Non-existent strata variable
  expect_error(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      strata = "nonexistent_var",
      starts = 5
    )
  )

  # Non-existent cluster variable
  expect_error(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      cluster = "nonexistent_var",
      starts = 5
    )
  )

  # Non-existent weight variable
  expect_error(
    gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 2,
      weights = "nonexistent_var",
      starts = 5
    )
  )
})
