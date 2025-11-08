# Tests for utility functions
# Part of Week 2 testing expansion (ACTION-PLAN-PHASE1.md)

test_that("wide_to_long reshaping works correctly", {
  # Create wide format data
  wide_data <- data.frame(
    id = 1:100,
    y_t1 = rnorm(100, 5),
    y_t2 = rnorm(100, 6),
    y_t3 = rnorm(100, 7),
    sex = sample(0:1, 100, replace = TRUE),
    stratum = sample(1:3, 100, replace = TRUE)
  )

  # Reshape to long
  long_data <- wide_to_long(
    data = wide_data,
    id_var = "id",
    outcome_vars = c("y_t1", "y_t2", "y_t3"),
    time_values = c(1, 2, 3)
  )

  # Check structure
  expect_equal(nrow(long_data), 300)  # 100 * 3
  expect_true("time" %in% colnames(long_data))
  expect_true("outcome" %in% colnames(long_data))

  # Time-invariant variables should be preserved
  expect_true("sex" %in% colnames(long_data))
  expect_true("stratum" %in% colnames(long_data))
})

test_that("simulate_gmm_survey produces correct structure", {
  set.seed(701)

  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 3,
    time_scores = c(0, 1, 2, 3),
    class_proportions = c(0.5, 0.3, 0.2),
    design = "stratified",
    n_strata = 2,
    seed = 701
  )

  # Check dimensions
  expect_equal(nrow(sim_data), 200 * 4)
  expect_equal(length(unique(sim_data$id)), 200)

  # Check variables exist
  expect_true("id" %in% colnames(sim_data))
  expect_true("time" %in% colnames(sim_data))
  expect_true("outcome" %in% colnames(sim_data))
  expect_true("true_class" %in% colnames(sim_data))
  expect_true("stratum" %in% colnames(sim_data))

  # Check class proportions
  class_props <- table(unique(sim_data[, c("id", "true_class")])$true_class) / 200
  expect_equal(as.numeric(class_props), c(0.5, 0.3, 0.2), tolerance = 0.05)
})

test_that("simulate_gmm_survey handles different survey designs", {
  set.seed(702)

  # SRS - still has design columns but with default values
  data_srs <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 3,
    n_classes = 2,
    design = "srs",
    seed = 702
  )
  expect_true("stratum" %in% colnames(data_srs))
  expect_true("psu" %in% colnames(data_srs))
  expect_true("weight" %in% colnames(data_srs))
  # For SRS, all weights should be 1
  expect_equal(unique(data_srs$weight), 1)

  # Stratified
  data_strat <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 3,
    n_classes = 2,
    design = "stratified",
    n_strata = 3,
    seed = 703
  )
  expect_true("stratum" %in% colnames(data_strat))
  expect_equal(length(unique(data_strat$stratum)), 3)

  # Cluster
  data_clust <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 3,
    n_classes = 2,
    design = "cluster",
    n_clusters = 15,
    seed = 704
  )
  expect_true("psu" %in% colnames(data_clust))

  # Stratified cluster
  data_both <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 3,
    n_classes = 2,
    design = "stratified_cluster",
    n_strata = 2,
    n_clusters = 20,
    seed = 705
  )
  expect_true("stratum" %in% colnames(data_both))
  expect_true("psu" %in% colnames(data_both))
})

test_that("mplus_to_surveymixr conversion works", {
  skip("Mplus conversion requires Mplus syntax parser - implement in future")

  # Example Mplus syntax
  mplus_syntax <- "
  VARIABLE:
    NAMES = id age y;
    CLASSES = c(3);

  ANALYSIS:
    TYPE = MIXTURE;
  "

  # Convert to surveymixr
  # r_code <- mplus_to_surveymixr(mplus_syntax)

  # expect_true(!is.null(r_code))
  # expect_true(grepl("gmm_survey", r_code))
})

test_that("surveymixr_to_mplus export works", {
  skip("Mplus export requires template - implement in future")

  set.seed(706)
  sim_data <- simulate_gmm_survey(
    n_individuals = 100,
    n_times = 3,
    n_classes = 2,
    design = "srs",
    seed = 706
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Export to Mplus format
  # mplus_syntax <- surveymixr_to_mplus(fit, output_file = tempfile())

  # expect_true(file.exists(output_file))
})

test_that("class_proportions extracts correctly", {
  skip_on_cran()

  set.seed(707)
  sim_data <- simulate_gmm_survey(
    n_individuals = 300,
    n_times = 4,
    n_classes = 3,
    class_proportions = c(0.5, 0.3, 0.2),
    design = "srs",
    seed = 707
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 15,
    cores = 1
  )

  props <- class_proportions(fit)

  # Should have 3 rows
  expect_equal(nrow(props), 3)

  # Proportions should sum to 1
  expect_equal(sum(props$proportion), 1, tolerance = 0.001)

  # Should have confidence intervals
  expect_true("lower_ci" %in% colnames(props))
  expect_true("upper_ci" %in% colnames(props))
})

test_that("entropy calculation is correct", {
  skip_on_cran()

  set.seed(708)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 708
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Entropy via method
  ent1 <- entropy(fit)

  # Entropy from slot
  ent2 <- fit@entropy

  expect_equal(ent1, ent2)
  expect_true(ent1 >= 0 && ent1 <= 1)
})

test_that("classification_quality provides useful metrics", {
  skip_on_cran()

  set.seed(709)
  sim_data <- simulate_gmm_survey(
    n_individuals = 250,
    n_times = 4,
    n_classes = 3,
    design = "srs",
    seed = 709
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 15,
    cores = 1
  )

  qual <- classification_quality(fit)

  # Should be a list with expected components
  expect_true(is.list(qual))
  expect_true(!is.null(qual$entropy))
  expect_true(!is.null(qual$avepp_overall))
  expect_true(!is.null(qual$occ_overall))
  expect_true(!is.null(qual$summary_by_class))
  expect_true(!is.null(qual$class_error_matrix))

  # Entropy should match
  expect_equal(qual$entropy, fit@fit_indices$entropy, tolerance = 0.001)

  # Summary table should have correct structure
  expect_true(is.data.frame(qual$summary_by_class))
  expect_equal(nrow(qual$summary_by_class), 3)
  expect_true("avepp" %in% colnames(qual$summary_by_class))
  expect_true("occ" %in% colnames(qual$summary_by_class))
})

test_that("Parameter extraction utilities work", {
  skip_on_cran()

  set.seed(710)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 710
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # coef() method
  params <- coef(fit)
  expect_true(length(params) > 0)
  expect_true(!any(is.na(params)))

  # vcov() method
  vcov_mat <- vcov(fit)
  expect_true(is.matrix(vcov_mat))
  expect_true(nrow(vcov_mat) > 0)
  expect_true(ncol(vcov_mat) > 0)
  expect_equal(nrow(vcov_mat), ncol(vcov_mat))  # Should be square

  # vcov may have fewer params than coef (e.g., constrained class proportions)
  # but should have at least n_classes - 1 + 2*n_classes + n_classes = 4*n_classes - 1
  # For 2 classes: at least 7 parameters
  expect_true(nrow(vcov_mat) >= fit@model_info$n_classes * 4 - 1)

  # Standard errors
  se <- sqrt(diag(vcov_mat))
  expect_true(all(se > 0))
})

test_that("Fitted and residual methods work", {
  skip_on_cran()

  set.seed(711)
  sim_data <- simulate_gmm_survey(
    n_individuals = 150,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 711
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1,
    keep_data = TRUE  # Required for residuals
  )

  # Fitted values
  fitted_vals <- fitted(fit)
  expect_true(length(fitted_vals) > 0)

  # Residuals (requires keep_data = TRUE)
  resids <- residuals(fit)
  expect_true(length(resids) > 0)
  expect_equal(length(fitted_vals), length(resids))
})

test_that("Simulation with covariates works", {
  set.seed(712)

  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    covariates = TRUE,
    design = "srs",
    seed = 712
  )

  # Should have covariate columns
  expect_true("sex" %in% colnames(sim_data))
  expect_true("baseline_risk" %in% colnames(sim_data))
  expect_true("ses" %in% colnames(sim_data))
})

test_that("Simulation with custom growth parameters works", {
  set.seed(713)

  custom_params <- list(
    list(intercept = 10, slope = 0.5),
    list(intercept = 5, slope = -0.2)
  )

  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    growth_parameters = custom_params,
    design = "srs",
    seed = 713
  )

  expect_equal(nrow(sim_data), 800)

  # Check that trajectories differ by class
  class1_mean <- mean(sim_data$outcome[sim_data$true_class == 1], na.rm = TRUE)
  class2_mean <- mean(sim_data$outcome[sim_data$true_class == 2], na.rm = TRUE)

  expect_false(abs(class1_mean - class2_mean) < 0.5)  # Should be different
})

test_that("Summary method produces useful output", {
  skip_on_cran()

  set.seed(714)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 714
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # Summary should work (prints output, returns NULL invisibly)
  expect_output(summary(fit), "Growth Mixture Model")
  expect_output(summary(fit), "MODEL SPECIFICATION")
  expect_output(summary(fit), "GROWTH PARAMETERS")

  # Print should work and contain key information
  expect_output(print(fit), "Growth Mixture Model")
  expect_output(print(fit), "Class")
  expect_output(print(fit), "Survey Design")
  expect_output(print(fit), "Convergence")
})

test_that("AIC and BIC methods work correctly", {
  skip_on_cran()

  set.seed(715)
  sim_data <- simulate_gmm_survey(
    n_individuals = 200,
    n_times = 4,
    n_classes = 2,
    design = "srs",
    seed = 715
  )

  fit <- gmm_survey(
    data = sim_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 2,
    starts = 10,
    cores = 1
  )

  # AIC
  aic_val <- AIC(fit)
  expect_true(is.numeric(aic_val))
  expect_true(is.finite(aic_val))

  # BIC
  bic_val <- BIC(fit)
  expect_true(is.numeric(bic_val))
  expect_true(is.finite(bic_val))

  # BIC > AIC typically (stronger penalty)
  expect_true(bic_val > aic_val)
})
