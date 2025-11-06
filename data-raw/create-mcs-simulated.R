# Script to create mcs_simulated example dataset
# Simulates data similar to the UK Millennium Cohort Study
# Self-control trajectories from ages 3 to 17

library(surveymixr)

set.seed(42)

# Simulate MCS-like data
# 3 classes: High-stable, Moderate-increasing, Low-declining
# Complex survey design: stratified cluster sampling

mcs_simulated <- simulate_gmm_survey(
  n_individuals = 5000,
  n_times = 6,
  n_classes = 3,
  time_scores = c(3, 5, 7, 11, 14, 17),  # Ages in years
  class_proportions = c(0.55, 0.30, 0.15),
  growth_parameters = list(
    # Class 1: High self-control, stable (55%)
    list(intercept = 8.5, slope = 0.05),

    # Class 2: Moderate self-control, improving (30%)
    list(intercept = 6.0, slope = 0.20),

    # Class 3: Low self-control, declining (15%)
    list(intercept = 4.0, slope = -0.15)
  ),
  residual_sds = c(1.2, 1.5, 1.8),
  design = "stratified_cluster",
  n_strata = 4,
  n_clusters = 200,
  weight_type = "inverse_prob",
  missing_rate = 0.12,
  missing_mechanism = "MAR",
  covariates = TRUE,
  seed = 42
)

# Rename variables to be more intuitive
names(mcs_simulated)[names(mcs_simulated) == "outcome"] <- "selfcontrol"
names(mcs_simulated)[names(mcs_simulated) == "time"] <- "age"
names(mcs_simulated)[names(mcs_simulated) == "psu"] <- "cluster"

# Add additional realistic variables
n_individuals <- length(unique(mcs_simulated$id))

# Add delinquency score (inversely related to self-control class)
delinquency_data <- data.frame(
  id = 1:n_individuals,
  delinquency = NA
)

for (i in 1:n_individuals) {
  true_class <- unique(mcs_simulated$true_class[mcs_simulated$id == i])

  if (true_class == 1) {
    delinquency_data$delinquency[i] <- rnorm(1, mean = 2, sd = 1.5)
  } else if (true_class == 2) {
    delinquency_data$delinquency[i] <- rnorm(1, mean = 4, sd = 2)
  } else {
    delinquency_data$delinquency[i] <- rnorm(1, mean = 7, sd = 2.5)
  }
}

delinquency_data$delinquency <- pmax(0, pmin(10, delinquency_data$delinquency))

# Add academic achievement (positively related to self-control)
achievement_data <- data.frame(
  id = 1:n_individuals,
  academic_achievement = NA
)

for (i in 1:n_individuals) {
  true_class <- unique(mcs_simulated$true_class[mcs_simulated$id == i])

  if (true_class == 1) {
    achievement_data$academic_achievement[i] <- rnorm(1, mean = 105, sd = 12)
  } else if (true_class == 2) {
    achievement_data$academic_achievement[i] <- rnorm(1, mean = 95, sd = 15)
  } else {
    achievement_data$academic_achievement[i] <- rnorm(1, mean = 85, sd = 18)
  }
}

# Merge with main data
mcs_simulated <- merge(mcs_simulated, delinquency_data, by = "id")
mcs_simulated <- merge(mcs_simulated, achievement_data, by = "id")

# Add factor labels
mcs_simulated$sex_factor <- factor(mcs_simulated$sex,
                                  levels = c(0, 1),
                                  labels = c("Female", "Male"))

mcs_simulated$stratum_factor <- factor(mcs_simulated$stratum,
                                      levels = 1:4,
                                      labels = c("England-Advantaged",
                                               "England-Disadvantaged",
                                               "Scotland/Wales",
                                               "Northern Ireland"))

# Sort
mcs_simulated <- mcs_simulated[order(mcs_simulated$id, mcs_simulated$age), ]
rownames(mcs_simulated) <- NULL

# Select final columns
mcs_simulated <- mcs_simulated[, c("id", "age", "selfcontrol", "true_class",
                                  "stratum", "stratum_factor", "cluster",
                                  "weight", "sex", "sex_factor",
                                  "baseline_risk", "ses",
                                  "delinquency", "academic_achievement")]

# Save
usethis::use_data(mcs_simulated, overwrite = TRUE)

# Create documentation
cat('Generated mcs_simulated dataset\n')
cat(sprintf('  N = %d individuals\n', length(unique(mcs_simulated$id))))
cat(sprintf('  T = %d time points\n', length(unique(mcs_simulated$age))))
cat(sprintf('  Total observations = %d\n', nrow(mcs_simulated)))
cat(sprintf('  Missing = %.1f%%\n',
           mean(is.na(mcs_simulated$selfcontrol)) * 100))
