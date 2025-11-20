#' Simulate Data from Growth Mixture Model with Survey Design
#'
#' @description
#' Generates simulated longitudinal data from a growth mixture model with
#' complex survey design features (stratification, clustering, weights).
#' Useful for testing, validation, and teaching.
#'
#' @param n_individuals Number of individuals to generate (default: 1000)
#' @param n_times Number of time points (default: 5)
#' @param n_classes Number of latent classes (default: 3)
#' @param time_scores Numeric vector of time scores (default: 0:(n_times-1))
#' @param class_proportions Numeric vector of class proportions (must sum to 1)
#' @param growth_parameters List of lists, each containing intercept and slope
#'   for each class. If NULL, reasonable defaults are generated.
#' @param residual_sds Numeric vector of residual standard deviations by class
#' @param design Character string: "srs" (simple random sample), "stratified",
#'   "cluster", or "stratified_cluster" (default)
#' @param n_strata Number of strata if stratified design (default: 4)
#' @param n_clusters Number of clusters (PSUs) if cluster design (default: 100)
#' @param cluster_size Average cluster size (default: 10)
#' @param weight_type Character: "none", "inverse_prob", or "calibrated"
#' @param missing_rate Proportion of missing data (default: 0.1)
#' @param missing_mechanism Character: "MCAR" (default), "MAR", or "MNAR"
#' @param covariates Logical, include time-invariant covariates? (default: TRUE)
#' @param seed Random seed for reproducibility (default: NULL)
#'
#' @return Data frame in long format with variables:
#' \describe{
#'   \item{id}{Individual ID}
#'   \item{time}{Time point}
#'   \item{outcome}{Observed outcome value}
#'   \item{true_class}{True latent class (for validation)}
#'   \item{stratum}{Stratum indicator (if stratified)}
#'   \item{psu}{Primary sampling unit (if clustered)}
#'   \item{weight}{Sampling weight (if weighted)}
#'   \item{covariates}{Additional covariates (if requested)}
#' }
#'
#' @details
#' This function generates data following a growth mixture model:
#'
#' For individual i in class k:
#' \deqn{y_{it} = (\beta_{0k} + u_{0i}) + (\beta_{1k} + u_{1i}) * t + \epsilon_{it}}
#'
#' where:
#' \itemize{
#'   \item \eqn{\beta_{0k}}, \eqn{\beta_{1k}} are class-specific intercept and slope
#'   \item \eqn{u_{0i}}, \eqn{u_{1i}} are random effects (optional, not yet implemented)
#'   \item \eqn{\epsilon_{it}} ~ N(0, \eqn{\sigma_k^2}) are residuals
#' }
#'
#' Survey design features:
#' \itemize{
#'   \item \strong{Stratification}: Population divided into strata, sampling within strata
#'   \item \strong{Clustering}: Individuals nested within PSUs (e.g., schools, neighborhoods)
#'   \item \strong{Weights}: Inverse probability weights to account for unequal selection probabilities
#' }
#'
#' The function can generate various missing data patterns to test robustness
#' of analyses.
#'
#' @references
#' Sterba, S. K. (2014). Fitting nonlinear latent growth curve models with
#' individually varying time points. \emph{Structural Equation Modeling, 21}(4),
#' 630-647.
#'
#' @examples
#' \donttest{
#' # Simple 3-class example
#' sim_data <- simulate_gmm_survey(
#'   n_individuals = 1000,
#'   n_times = 5,
#'   n_classes = 3,
#'   design = "stratified_cluster",
#'   seed = 123
#' )
#'
#' head(sim_data)
#' table(sim_data$true_class)
#'
#' # Fit model to simulated data
#' fit <- gmm_survey(
#'   data = sim_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "outcome",
#'   n_classes = 3,
#'   strata = "stratum",
#'   cluster = "psu",
#'   weights = "weight",
#'   starts = 100
#' )
#'
#' # Compare estimated vs true parameters
#' summary(fit)
#' }
#'
#' @export
#' @importFrom stats rnorm rbinom runif
simulate_gmm_survey <- function(n_individuals = 1000,
                                n_times = 5,
                                n_classes = 3,
                                time_scores = NULL,
                                class_proportions = NULL,
                                growth_parameters = NULL,
                                residual_sds = NULL,
                                design = "stratified_cluster",
                                n_strata = 4,
                                n_clusters = 100,
                                cluster_size = 10,
                                weight_type = "inverse_prob",
                                missing_rate = 0.1,
                                missing_mechanism = "MCAR",
                                covariates = TRUE,
                                seed = NULL) {

  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Default time scores
  if (is.null(time_scores)) {
    time_scores <- 0:(n_times - 1)
  }

  if (length(time_scores) != n_times) {
    stop("time_scores length must equal n_times")
  }

  # Default class proportions
  if (is.null(class_proportions)) {
    # Generate unequal proportions
    if (n_classes == 2) {
      class_proportions <- c(0.7, 0.3)
    } else if (n_classes == 3) {
      class_proportions <- c(0.5, 0.35, 0.15)
    } else if (n_classes == 4) {
      class_proportions <- c(0.4, 0.3, 0.2, 0.1)
    } else {
      class_proportions <- rep(1 / n_classes, n_classes)
    }
  }

  if (abs(sum(class_proportions) - 1) > 1e-6) {
    stop("class_proportions must sum to 1")
  }

  # Default growth parameters
  if (is.null(growth_parameters)) {
    growth_parameters <- list()

    if (n_classes == 2) {
      # Two distinct trajectories
      growth_parameters[[1]] <- list(intercept = 10, slope = 1.0)  # High stable
      growth_parameters[[2]] <- list(intercept = 5, slope = -0.5)  # Low declining

    } else if (n_classes == 3) {
      # Three trajectories: stable-high, moderate-increasing, low-declining
      growth_parameters[[1]] <- list(intercept = 12, slope = 0.2)
      growth_parameters[[2]] <- list(intercept = 8, slope = 0.8)
      growth_parameters[[3]] <- list(intercept = 4, slope = -0.6)

    } else if (n_classes == 4) {
      growth_parameters[[1]] <- list(intercept = 14, slope = 0.1)
      growth_parameters[[2]] <- list(intercept = 10, slope = 0.5)
      growth_parameters[[3]] <- list(intercept = 6, slope = -0.3)
      growth_parameters[[4]] <- list(intercept = 3, slope = -0.8)

    } else {
      # Generic: spread intercepts and slopes
      for (k in 1:n_classes) {
        growth_parameters[[k]] <- list(
          intercept = 5 + (k - 1) * 3,
          slope = 1 - (k - 1) * 0.5
        )
      }
    }
  }

  # Default residual SDs
  if (is.null(residual_sds)) {
    residual_sds <- rep(1.5, n_classes)
  }

  # ============================================================================
  # Generate Survey Design Structure
  # ============================================================================
  stratum_ids <- NULL
  psu_ids <- NULL
  weights <- NULL

  if (design == "srs") {
    # Simple random sample - no design features
    stratum_ids <- rep(1, n_individuals)
    psu_ids <- 1:n_individuals
    weights <- rep(1, n_individuals)

  } else if (design == "stratified") {
    # Stratified sampling
    stratum_ids <- sample(1:n_strata, n_individuals, replace = TRUE)
    psu_ids <- 1:n_individuals

    # Weights: inverse of sampling probability (varied by stratum)
    stratum_probs <- runif(n_strata, 0.5, 2)
    weights <- stratum_probs[stratum_ids]
    weights <- weights / mean(weights)  # Normalize

  } else if (design == "cluster") {
    # Cluster sampling
    stratum_ids <- rep(1, n_individuals)
    psu_ids <- sample(1:n_clusters, n_individuals, replace = TRUE)

    # Weights: inverse of cluster selection probability
    cluster_probs <- runif(n_clusters, 0.5, 2)
    weights <- cluster_probs[psu_ids]
    weights <- weights / mean(weights)

  } else if (design == "stratified_cluster") {
    # Stratified cluster sampling (most complex)
    stratum_ids <- sample(1:n_strata, n_individuals, replace = TRUE)

    # Clusters nested within strata
    clusters_per_stratum <- ceiling(n_clusters / n_strata)
    psu_ids <- numeric(n_individuals)

    for (s in 1:n_strata) {
      in_stratum <- which(stratum_ids == s)
      cluster_range <- ((s - 1) * clusters_per_stratum + 1):
                       (s * clusters_per_stratum)
      psu_ids[in_stratum] <- sample(cluster_range, length(in_stratum),
                                   replace = TRUE)
    }

    # Weights: product of stratum and cluster probabilities
    stratum_probs <- runif(n_strata, 0.5, 2)
    cluster_probs <- runif(max(psu_ids), 0.5, 2)
    weights <- stratum_probs[stratum_ids] * cluster_probs[psu_ids]
    weights <- weights / mean(weights)

  } else {
    stop("design must be one of: srs, stratified, cluster, stratified_cluster")
  }

  # ============================================================================
  # Assign Individuals to Latent Classes
  # ============================================================================
  true_classes <- sample(1:n_classes, n_individuals, replace = TRUE,
                        prob = class_proportions)

  # ============================================================================
  # Generate Outcome Data
  # ============================================================================
  data_list <- list()

  for (i in 1:n_individuals) {
    class_i <- true_classes[i]

    # Predicted trajectory for this individual's class
    intercept_i <- growth_parameters[[class_i]]$intercept
    slope_i <- growth_parameters[[class_i]]$slope

    y_true <- intercept_i + slope_i * time_scores

    # Add residual noise
    y_obs <- y_true + rnorm(n_times, 0, residual_sds[class_i])

    # Create individual's data
    df_i <- data.frame(
      id = i,
      time = time_scores,
      outcome = y_obs,
      true_class = class_i,
      stratum = stratum_ids[i],
      psu = psu_ids[i],
      weight = weights[i],
      stringsAsFactors = FALSE
    )

    data_list[[i]] <- df_i
  }

  # Combine all individuals
  sim_data <- do.call(rbind, data_list)

  # ============================================================================
  # Add Missing Data
  # ============================================================================
  if (missing_rate > 0) {
    n_obs <- nrow(sim_data)
    n_missing <- floor(n_obs * missing_rate)

    if (missing_mechanism == "MCAR") {
      # Missing completely at random
      missing_idx <- sample(1:n_obs, n_missing)
      sim_data$outcome[missing_idx] <- NA

    } else if (missing_mechanism == "MAR") {
      # Missing at random: higher missingness at later times
      prob_missing <- 0.05 + 0.15 * (sim_data$time / max(sim_data$time))
      missing_idx <- which(runif(n_obs) < prob_missing)
      sim_data$outcome[missing_idx] <- NA

    } else if (missing_mechanism == "MNAR") {
      # Missing not at random: low values more likely to be missing
      outcome_quantiles <- quantile(sim_data$outcome, c(0.25, 0.75), na.rm = TRUE)
      prob_missing <- ifelse(sim_data$outcome < outcome_quantiles[1], 0.2, 0.05)
      missing_idx <- which(runif(n_obs) < prob_missing)
      sim_data$outcome[missing_idx] <- NA
    }
  }

  # ============================================================================
  # Add Covariates
  # ============================================================================
  if (covariates) {
    # Time-invariant covariates
    covariate_data <- data.frame(
      id = 1:n_individuals,
      sex = rbinom(n_individuals, 1, 0.5),  # 0 = female, 1 = male
      baseline_risk = rnorm(n_individuals, 0, 1),
      ses = rnorm(n_individuals, 0, 1),  # Socioeconomic status
      stringsAsFactors = FALSE
    )

    # Make covariates related to class membership
    for (i in 1:n_individuals) {
      class_i <- true_classes[i]

      # Higher classes have higher SES
      covariate_data$ses[i] <- covariate_data$ses[i] + (class_i - mean(1:n_classes)) * 0.5

      # Risk factor inversely related to class
      covariate_data$baseline_risk[i] <- covariate_data$baseline_risk[i] -
                                         (class_i - mean(1:n_classes)) * 0.3
    }

    # Merge with main data
    sim_data <- merge(sim_data, covariate_data, by = "id")
  }

  # Sort by ID and time
  sim_data <- sim_data[order(sim_data$id, sim_data$time), ]
  rownames(sim_data) <- NULL

  return(sim_data)
}


#' Generate Data from Fitted Model (Internal)
#'
#' @description
#' Internal function used by BLRT to generate bootstrap samples.
#' Exported version is in gmm-select.R
#'
#' @keywords internal
#' @noRd
generate_data_from_parameters <- function(n, n_times, time_scores, class_props,
                                         growth_params, residual_vars,
                                         growth_model = "linear") {

  n_classes <- length(class_props)

  # Assign classes
  class_assignments <- sample(1:n_classes, n, replace = TRUE, prob = class_props)

  data_list <- list()

  for (i in 1:n) {
    class_i <- class_assignments[i]

    # Predict trajectory
    y_true <- predict_trajectory(time_scores, growth_params[[class_i]],
                                growth_model)

    # Add noise
    y_obs <- y_true + rnorm(n_times, 0, sqrt(residual_vars[class_i]))

    df_i <- data.frame(
      id = i,
      time = time_scores,
      outcome = y_obs,
      stringsAsFactors = FALSE
    )

    data_list[[i]] <- df_i
  }

  do.call(rbind, data_list)
}
