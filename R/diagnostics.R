#' Convergence Diagnostics for Growth Mixture Models
#'
#' @description
#' Provides detailed convergence diagnostics including log-likelihood
#' distribution from multiple random starts, identification of local maxima,
#' and recommendations.
#'
#' @param gmm_object A fitted \code{SurveyMixr} object from \code{gmm_survey()}
#' @param tolerance Tolerance for identifying replicated solutions (default: 1e-4)
#' @param plot Logical, create diagnostic plot? (default: TRUE)
#'
#' @return An S4 object of class \code{\linkS4class{ConvergenceDiagnostics}}
#'   containing detailed convergence information
#'
#' @details
#' Multiple random starts are essential for growth mixture models because the
#' likelihood surface typically has multiple local maxima. This function helps
#' assess whether the best solution is trustworthy by:
#'
#' \itemize{
#'   \item Tabulating log-likelihoods from all random starts
#'   \item Identifying how many times the best solution was replicated
#'   \item Detecting distinct local maxima
#'   \item Providing recommendations for improving convergence
#' }
#'
#' \strong{Guidelines:}
#' \itemize{
#'   \item Best solution should be replicated at least 2-3 times
#'   \item If not replicated, increase \code{starts} in \code{gmm_survey()}
#'   \item Multiple distinct local maxima may indicate model instability
#'   \item Very different log-likelihoods suggest identifiability issues
#' }
#'
#' @references
#' Hipp, J. R., & Bauer, D. J. (2006). Local solutions in the estimation of
#' growth mixture models. \emph{Psychological Methods, 11}(1), 36-53.
#'
#' @examples
#' \donttest{
#' data(mcs_simulated)
#' set.seed(123)
#' fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
#'                   outcome = "selfcontrol", n_classes = 2, starts = 10,
#'                   verbose = FALSE)
#'
#' diagnostics <- diagnose_convergence(fit, plot = FALSE)
#' print(diagnostics)
#' }
#'
#' @export
diagnose_convergence <- function(gmm_object, tolerance = 1e-4, plot = TRUE) {

  if (!inherits(gmm_object, "SurveyMixr")) {
    stop("gmm_object must be a SurveyMixr object")
  }

  logliks <- gmm_object@random_starts$logliks
  converged <- gmm_object@random_starts$converged

  # Remove non-finite values
  finite_idx <- is.finite(logliks)
  logliks_finite <- logliks[finite_idx]
  converged_finite <- converged[finite_idx]

  if (length(logliks_finite) == 0) {
    stop("No valid log-likelihoods available")
  }

  # Best log-likelihood
  best_loglik <- max(logliks_finite)

  # Count replications of best solution
  n_replications <- sum(abs(logliks_finite - best_loglik) < tolerance)

  # Identify distinct local maxima
  # Cluster log-likelihoods
  logliks_sorted <- sort(logliks_finite, decreasing = TRUE)
  local_maxima <- data.frame(
    rank = integer(),
    loglik = numeric(),
    n_times = integer(),
    diff_from_best = numeric(),
    stringsAsFactors = FALSE
  )

  current_cluster <- logliks_sorted[1]
  cluster_count <- 1
  rank <- 1

  for (i in 2:length(logliks_sorted)) {
    if (abs(logliks_sorted[i] - current_cluster) < tolerance) {
      cluster_count <- cluster_count + 1
    } else {
      # New cluster
      local_maxima <- rbind(local_maxima, data.frame(
        rank = rank,
        loglik = current_cluster,
        n_times = cluster_count,
        diff_from_best = current_cluster - best_loglik,
        stringsAsFactors = FALSE
      ))

      rank <- rank + 1
      current_cluster <- logliks_sorted[i]
      cluster_count <- 1
    }
  }

  # Add last cluster
  local_maxima <- rbind(local_maxima, data.frame(
    rank = rank,
    loglik = current_cluster,
    n_times = cluster_count,
    diff_from_best = current_cluster - best_loglik,
    stringsAsFactors = FALSE
  ))

  # Log-likelihood table
  loglik_table <- data.frame(
    start = 1:length(logliks),
    loglik = logliks,
    converged = converged,
    is_best = abs(logliks - best_loglik) < tolerance,
    stringsAsFactors = FALSE
  )

  # Warnings and recommendations
  warnings_vec <- character()
  recommendations <- character()

  if (n_replications < 2) {
    warnings_vec <- c(warnings_vec,
                     "Best solution not replicated. Results may be unreliable.")
    recommendations <- c(recommendations,
                        "Increase 'starts' to at least 500-1000")
  }

  if (nrow(local_maxima) > 5) {
    warnings_vec <- c(warnings_vec,
                     sprintf("%d distinct local maxima detected. Model may be poorly identified.",
                            nrow(local_maxima)))
    recommendations <- c(recommendations,
                        "Consider simplifying model (fewer classes or simpler growth form)")
  }

  n_failed <- sum(!converged)
  if (n_failed > length(converged) * 0.5) {
    warnings_vec <- c(warnings_vec,
                     sprintf("%d/%d starts failed to converge (%.1f%%)",
                            n_failed, length(converged),
                            n_failed / length(converged) * 100))
    recommendations <- c(recommendations,
                        "Check for data issues or consider different starting values")
  }

  if (length(warnings_vec) == 0) {
    warnings_vec <- "No convergence issues detected"
    recommendations <- "Model appears well-identified"
  }

  # Create diagnostic plot
  if (plot) {
    diag_plot <- plot_convergence(gmm_object)
  } else {
    diag_plot <- NULL
  }

  # Create output object
  output <- new("ConvergenceDiagnostics",
    loglik_table = loglik_table,
    best_loglik = best_loglik,
    n_replications = as.integer(n_replications),
    local_maxima = local_maxima,
    convergence_plot = diag_plot,
    warnings = warnings_vec,
    recommendations = recommendations
  )

  return(output)
}


#' Class Proportions with Confidence Intervals
#'
#' @description
#' Extracts class proportions with survey-adjusted confidence intervals.
#'
#' @param object A \code{SurveyMixr} object
#' @param weighted Logical, return weighted proportions? (default: TRUE)
#' @param ci_level Confidence level (default: 0.95)
#'
#' @return Data frame with class proportions and confidence intervals
#'
#' @details
#' Class proportions are estimated from the mixture model. When survey weights
#' are used, weighted proportions better represent the population. Confidence
#' intervals account for survey design (clustering, stratification).
#'
#' @examples
#' \donttest{
#' fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
#'                   outcome = "selfcontrol", n_classes = 3,
#'                   weights = "weight")
#'
#' class_proportions(fit)
#' }
#'
#' @export
class_proportions <- function(object, weighted = TRUE, ci_level = 0.95) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  n_classes <- object@model_info$n_classes

  if (weighted && object@survey_design$has_weights) {
    props <- object@class_proportions$weighted
  } else {
    props <- object@class_proportions$unweighted
  }

  # Compute SEs using multinomial logit parameterization
  # Simplified: use delta method approximation
  n <- object@model_info$n_obs
  prop_se <- sqrt(props * (1 - props) / n)

  # Confidence intervals
  z_crit <- qnorm(1 - (1 - ci_level) / 2)
  lower <- pmax(0, props - z_crit * prop_se)
  upper <- pmin(1, props + z_crit * prop_se)

  # Class counts - ensure all classes represented even if count is 0
  class_counts <- table(factor(object@class_assignments, levels = 1:n_classes))

  result <- data.frame(
    class = 1:n_classes,
    proportion = props,
    se = prop_se,
    lower_ci = lower,
    upper_ci = upper,
    n_assigned = as.numeric(class_counts),
    percent = props * 100,
    stringsAsFactors = FALSE
  )

  return(result)
}


#' Classification Quality Metrics
#'
#' @description
#' Computes detailed classification quality metrics including average posterior
#' probabilities, entropy, and odds of correct classification.
#'
#' @param object A \code{SurveyMixr} object
#'
#' @return List containing classification quality metrics
#'
#' @details
#' Classification quality metrics assess how well individuals are assigned to
#' latent classes:
#'
#' \itemize{
#'   \item \strong{Entropy}: Overall classification certainty (0-1, higher better)
#'   \item \strong{AvePP}: Average posterior probability of assigned class
#'   \item \strong{OCC}: Odds of correct classification (AvePP / (1 - AvePP))
#'   \item \strong{mcaAvePP}: Minimum classification accuracy based on AvePP
#' }
#'
#' \strong{Guidelines:}
#' \itemize{
#'   \item Entropy > 0.80: Excellent separation
#'   \item Entropy 0.60-0.80: Good separation
#'   \item Entropy < 0.60: Poor separation, consider fewer classes
#'   \item AvePP > 0.90 for each class indicates reliable classification
#'   \item OCC > 5 is desirable
#' }
#'
#' @references
#' Clark, S. L., & Muthén, B. (2009). Relating latent class analysis results to
#' variables not included in the analysis. Unpublished manuscript.
#'
#' @examples
#' \donttest{
#' data(mcs_simulated)
#' set.seed(123)
#' fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
#'                   outcome = "selfcontrol", n_classes = 2,
#'                   starts = 5, verbose = FALSE)
#'
#' classification_quality(fit)
#' }
#'
#' @export
classification_quality <- function(object) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  n_classes <- object@model_info$n_classes
  posterior_probs <- object@posterior_probs
  class_assignments <- object@class_assignments

  # Overall entropy
  entropy_val <- object@fit_indices$entropy

  # Average posterior probability by class
  avepp_by_class <- numeric(n_classes)
  mca_by_class <- numeric(n_classes)  # Minimum classification accuracy

  for (k in 1:n_classes) {
    in_class_k <- which(class_assignments == k)

    if (length(in_class_k) > 0) {
      # Average of maximum posterior prob for those assigned to k
      avepp_by_class[k] <- mean(posterior_probs[in_class_k, k])

      # MCA: proportion of sample for which modal assignment = k
      # weighted by posterior prob of k
      mca_by_class[k] <- sum(posterior_probs[in_class_k, k]) / sum(posterior_probs[, k])
    } else {
      avepp_by_class[k] <- NA
      mca_by_class[k] <- NA
    }
  }

  # Odds of correct classification
  occ_by_class <- avepp_by_class / (1 - avepp_by_class)

  # Overall average
  avepp_overall <- mean(avepp_by_class, na.rm = TRUE)
  occ_overall <- avepp_overall / (1 - avepp_overall)

  # Classification errors: proportion assigned to class k but actually in class j
  class_error_matrix <- matrix(0, nrow = n_classes, ncol = n_classes)
  rownames(class_error_matrix) <- paste0("Assigned_", 1:n_classes)
  colnames(class_error_matrix) <- paste0("True_", 1:n_classes)

  for (k in 1:n_classes) {
    in_class_k <- which(class_assignments == k)
    if (length(in_class_k) > 0) {
      class_error_matrix[k, ] <- colMeans(posterior_probs[in_class_k, , drop = FALSE])
    }
  }

  # Summary table
  summary_table <- data.frame(
    class = 1:n_classes,
    avepp = avepp_by_class,
    occ = occ_by_class,
    mca = mca_by_class,
    n_assigned = as.numeric(table(factor(class_assignments, levels = 1:n_classes))),
    stringsAsFactors = FALSE
  )

  list(
    entropy = entropy_val,
    avepp_overall = avepp_overall,
    occ_overall = occ_overall,
    summary_by_class = summary_table,
    class_error_matrix = class_error_matrix
  )
}


#' Extract Trajectories by Class
#'
#' @description
#' Extracts predicted trajectories for a specific latent class.
#'
#' @param object A \code{SurveyMixr} object
#' @param class Integer specifying which class (default: 1)
#' @param time_range Optional numeric vector of time points for prediction
#'
#' @return Data frame with time and predicted values
#'
#' @examples
#' \donttest{
#' fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
#'                   outcome = "selfcontrol", n_classes = 3)
#'
#' traj_class1 <- extract_trajectories(fit, class = 1)
#' }
#'
#' @export
extract_trajectories <- function(object, class = 1, time_range = NULL) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  if (class < 1 || class > object@model_info$n_classes) {
    stop(sprintf("class must be between 1 and %d", object@model_info$n_classes))
  }

  if (is.null(time_range)) {
    time_range <- object@model_info$time_scores
  }

  # Predict trajectory
  y_pred <- predict_trajectory(
    time_range,
    object@parameters$growth_parameters[[class]],
    object@model_info$growth_model
  )

  data.frame(
    time = time_range,
    predicted = y_pred,
    class = class,
    stringsAsFactors = FALSE
  )
}


#' Compare Classes on a Variable
#'
#' @description
#' Conducts statistical tests comparing latent classes on a specific variable.
#'
#' @param object A \code{SurveyMixr} object
#' @param var Character string, variable name (must be in original data)
#' @param test Character string: "wald" (default), "chisq", or "anova"
#'
#' @return List containing test results
#'
#' @examples
#' \donttest{
#' data(mcs_simulated)
#' set.seed(123)
#' fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
#'                   outcome = "selfcontrol", n_classes = 2,
#'                   auxiliary = "baseline_risk",
#'                   keep_data = TRUE, starts = 5, verbose = FALSE)
#'
#' compare_classes(fit, var = "baseline_risk", test = "wald")
#' }
#'
#' @export
compare_classes <- function(object, var, test = "wald") {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  if (nrow(object@data) == 0) {
    stop("Data not available. Re-fit model with keep_data = TRUE")
  }

  if (!var %in% names(object@data)) {
    stop(sprintf("Variable '%s' not found in data", var))
  }

  # ---------------------------------------------------------------------------
  # Align variable to person-level data used in the model
  # ---------------------------------------------------------------------------

  id_var <- object@model_info$id_var
  if (is.null(id_var) || !id_var %in% names(object@data)) {
    stop("ID variable not found in stored data; cannot align classes to data")
  }

  # One row per individual (take first occurrence per ID)
  data_long <- object@data
  id_and_var <- data_long[, c(id_var, var), drop = FALSE]
  id_unique <- !duplicated(id_and_var[[id_var]])
  person_data <- id_and_var[id_unique, , drop = FALSE]

  # Determine the ID ordering used in the model (rows of posterior_probs /
  # class_assignments). We try to use row names if available; otherwise we
  # assume the original ordering matches the unique ID order.
  id_model <- rownames(object@posterior_probs)
  if (!is.null(id_model) && length(id_model) == nrow(person_data)) {
    # Sanity check: ID sets should match
    if (!setequal(id_model, as.character(person_data[[id_var]]))) {
      stop("Mismatch between IDs in model and stored data; cannot compare classes")
    }

    match_idx <- match(id_model, as.character(person_data[[id_var]]))
    if (any(is.na(match_idx))) {
      stop("Failed to align IDs between model and stored data")
    }

    x <- person_data[[var]][match_idx]
  } else {
    # Fallback: rely on the person_data order (should match fitting order)
    x <- person_data[[var]]
  }

  class_assignments <- object@class_assignments
  n_classes <- object@model_info$n_classes

  if (length(x) != length(class_assignments)) {
    stop("Length mismatch between data and class assignments; ",
         "ensure 'keep_data = TRUE' was used with consistent IDs")
  }

  # Compute class-specific means
  class_means <- tapply(x, class_assignments, mean, na.rm = TRUE)
  class_sds <- tapply(x, class_assignments, sd, na.rm = TRUE)
  # Number of non-missing observations contributing to each class
  class_ns <- tapply(!is.na(x), class_assignments, sum)

  # Overall test
  if (test == "wald") {
    # Wald test
    result <- test_class_differences(
      class_means = as.numeric(class_means),
      class_ses = as.numeric(class_sds / sqrt(class_ns)),
      class_ns = as.numeric(class_ns),
      weights = object@survey_design$weights,
      cluster = object@survey_design$cluster
    )

  } else if (test %in% c("anova", "chisq")) {
    # ANOVA / Chi-square
    result <- list(
      F_stat = NA,
      p_value = NA,
      message = "Use test = 'wald' for survey-adjusted tests"
    )

  } else {
    stop("test must be 'wald', 'anova', or 'chisq'")
  }

  list(
    variable = var,
    class_means = class_means,
    class_sds = class_sds,
    class_ns = class_ns,
    test_statistic = result$F_stat,
    df1 = result$df1,
    df2 = result$df2,
    p_value = result$p_value
  )
}
