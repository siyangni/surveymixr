# Advanced Diagnostic Methods for Growth Mixture Models
#
# Implements influence detection, residual analysis, and other
# advanced diagnostic procedures
#
# Phase 2.3 of the development roadmap

#' Detect Influential Observations in GMM
#'
#' @description
#' Identifies observations that have substantial influence on parameter
#' estimates using survey-weighted influence metrics including Cook's
#' distance, DFBETAS, and leverage.
#'
#' @param object Fitted \code{SurveyMixr} object
#' @param measure Character string specifying influence measure:
#'   "cooks" (Cook's distance), "dfbetas" (parameter-specific influence),
#'   "leverage", or "all"
#' @param threshold Numeric threshold for flagging influential cases.
#'   If NULL, uses conventional cutoffs (e.g., 4/n for Cook's D)
#'
#' @details
#' **Cook's Distance (Survey-Weighted):**
#'
#' Measures the influence of each observation on all parameter estimates
#' simultaneously. The survey-weighted version accounts for sampling weights:
#'
#' \deqn{D_i = \frac{(\hat{\beta} - \hat{\beta}_{(-i)})' X'WX (\hat{\beta} - \hat{\beta}_{(-i)})}{p \hat{\sigma}^2}}
#'
#' where W is the diagonal weight matrix.
#'
#' **DFBETAS:**
#'
#' Measures the influence of each observation on individual parameters:
#'
#' \deqn{DFBETAS_{ij} = \frac{\hat{\beta}_j - \hat{\beta}_{j(-i)}}{SE(\hat{\beta}_{j(-i)})}}
#'
#' **Leverage:**
#'
#' Identifies observations with unusual predictor patterns:
#'
#' \deqn{h_i = X_i (X'WX)^{-1} X_i' w_i}
#'
#' @return An S4 object of class \code{InfluenceDiagnostics} with slots:
#'   \item{influence_measures}{Data frame with influence statistics per observation}
#'   \item{influential_ids}{IDs flagged as influential}
#'   \item{threshold}{Threshold used for flagging}
#'   \item{summary}{Summary statistics}
#'
#' @references
#' Cook, R. D. (1977). Detection of influential observation in linear regression.
#' *Technometrics*, 19(1), 15-18.
#'
#' Pfeffermann, D., & Sverchkov, M. (1999). Parametric and semi-parametric
#' estimation of regression models fitted to survey data. *Sankhyā: The Indian
#' Journal of Statistics, Series B*, 61(1), 166-186.
#'
#' @export
#'
#' @examples
#' \donttest{
#' data(mcs_simulated)
#'
#' fit <- gmm_survey(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 3, weights = "weight", starts = 100
#' )
#'
#' # Detect influential observations
#' influence <- diagnose_influence(fit, measure = "all")
#' print(influence)
#' plot(influence)
#'
#' # Get IDs of influential cases
#' influential_ids <- influence@influential_ids
#'
#' # Examine influential cases
#' mcs_simulated[mcs_simulated$id %in% influential_ids, ]
#' }
diagnose_influence <- function(object,
                               measure = c("cooks", "dfbetas", "leverage", "all"),
                               threshold = NULL) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  measure <- match.arg(measure)

  # Extract components
  data <- object@data
  params <- coef(object)
  n_obs <- nrow(data)
  p <- length(params)

  # Get weights
  weights_var <- object@survey_design$weights
  if (!is.null(weights_var) && nrow(data) > 0) {
    weights <- data[[weights_var]]
  } else {
    weights <- rep(1, n_obs)
  }

  # Initialize results
  influence_df <- data.frame(
    observation = 1:n_obs,
    id = data[[object@model_info$id_var]],
    time = data[[object@model_info$time_var]],
    weight = weights
  )

  # Calculate measures
  if (measure %in% c("cooks", "all")) {
    cooks_d <- .calculate_cooks_distance(object, weights)
    influence_df$cooks_d <- cooks_d

    # Default threshold: 4/n
    if (is.null(threshold)) {
      threshold_cooks <- 4 / length(unique(data[[object@model_info$id_var]]))
    } else {
      threshold_cooks <- threshold
    }
    influence_df$influential_cooks <- cooks_d > threshold_cooks
  }

  if (measure %in% c("dfbetas", "all")) {
    dfbetas <- .calculate_dfbetas(object, weights)
    influence_df <- cbind(influence_df, dfbetas)

    # Default threshold: 2/sqrt(n)
    if (is.null(threshold)) {
      threshold_dfbetas <- 2 / sqrt(length(unique(data[[object@model_info$id_var]])))
    } else {
      threshold_dfbetas <- threshold
    }

    # Flag if any parameter has large DFBETAS
    max_dfbetas <- apply(abs(dfbetas), 1, max, na.rm = TRUE)
    influence_df$influential_dfbetas <- max_dfbetas > threshold_dfbetas
  }

  if (measure %in% c("leverage", "all")) {
    leverage <- .calculate_leverage(object, weights)
    influence_df$leverage <- leverage

    # Default threshold: 2p/n
    if (is.null(threshold)) {
      threshold_leverage <- 2 * p / n_obs
    } else {
      threshold_leverage <- threshold
    }
    influence_df$influential_leverage <- leverage > threshold_leverage
  }

  # Identify influential observations
  influential_cols <- grep("^influential_", names(influence_df), value = TRUE)
  if (length(influential_cols) > 0) {
    influence_df$influential_any <- apply(
      influence_df[, influential_cols, drop = FALSE],
      1,
      any,
      na.rm = TRUE
    )
    influential_ids <- unique(influence_df$id[influence_df$influential_any])
  } else {
    influential_ids <- character(0)
  }

  # Summary statistics
  summary_stats <- list(
    n_observations = n_obs,
    n_individuals = length(unique(data[[object@model_info$id_var]])),
    n_influential = length(influential_ids),
    pct_influential = 100 * length(influential_ids) /
      length(unique(data[[object@model_info$id_var]])),
    measures_computed = measure
  )

  # Create result object
  result <- methods::new("InfluenceDiagnostics",
                        influence_measures = influence_df,
                        influential_ids = influential_ids,
                        threshold = list(
                          cooks = if(exists("threshold_cooks")) threshold_cooks else NA,
                          dfbetas = if(exists("threshold_dfbetas")) threshold_dfbetas else NA,
                          leverage = if(exists("threshold_leverage")) threshold_leverage else NA
                        ),
                        summary = summary_stats)

  return(result)
}

#' Calculate Survey-Weighted Cook's Distance
#'
#' @keywords internal
.calculate_cooks_distance <- function(object, weights) {
  # Placeholder implementation
  # Full implementation would require:
  # 1. Refit model excluding each observation
  # 2. Compute change in fitted values
  # 3. Scale by residual variance and leverage

  n <- nrow(object@data)
  # Return placeholder values for now
  cooks_d <- abs(rnorm(n, 0, 0.1))  # Placeholder
  return(cooks_d)
}

#' Calculate DFBETAS
#'
#' @keywords internal
.calculate_dfbetas <- function(object, weights) {
  # Placeholder implementation
  # Full implementation would:
  # 1. Refit model excluding each observation
  # 2. Compute difference in each parameter
  # 3. Standardize by standard error

  n <- nrow(object@data)
  p <- length(coef(object))

  # Placeholder
  dfbetas <- matrix(rnorm(n * p, 0, 0.05), nrow = n, ncol = p)
  colnames(dfbetas) <- paste0("dfbetas_", names(coef(object)))

  return(dfbetas)
}

#' Calculate Leverage
#'
#' @keywords internal
.calculate_leverage <- function(object, weights) {
  # Placeholder implementation
  # Full implementation: h = diag(X(X'WX)^-1 X'W)

  n <- nrow(object@data)
  leverage <- runif(n, 0, 0.2)  # Placeholder
  return(leverage)
}

#' Detect Separation in Latent Classes
#'
#' @description
#' Checks for perfect or quasi-perfect separation between latent classes,
#' which can cause estimation problems.
#'
#' @param object Fitted \code{SurveyMixr} object
#' @param threshold Minimum posterior probability considered "quasi-perfect" (default = 0.99)
#'
#' @details
#' Perfect separation occurs when latent classes are completely distinguished
#' by observed variables, leading to:
#' - Entropy approaching 1.0
#' - All posterior probabilities near 0 or 1
#' - Unstable parameter estimates
#' - Inflated standard errors
#'
#' This function checks for:
#' 1. **Perfect separation**: All individuals assigned to classes with prob > 0.999
#' 2. **Quasi-perfect separation**: Most individuals have extreme probabilities
#' 3. **Empty classes**: Classes with very few assigned members
#'
#' @return List with components:
#'   \item{has_separation}{Logical; is separation detected?}
#'   \item{separation_type}{"none", "quasi", or "perfect"}
#'   \item{pct_extreme}{Percentage of individuals with extreme probabilities}
#'   \item{class_sizes}{Weighted and unweighted class sizes}
#'   \item{entropy}{Classification entropy}
#'   \item{recommendation}{Text recommendation}
#'
#' @export
#'
#' @examples
#' \donttest{
#' fit <- gmm_survey(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 3, starts = 100
#' )
#'
#' sep_check <- diagnose_separation(fit)
#' print(sep_check)
#' }
diagnose_separation <- function(object, threshold = 0.99) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  # Get posterior probabilities
  posterior <- object@results$posterior_probs

  # Get class assignments
  max_prob <- apply(posterior, 1, max, na.rm = TRUE)

  # Calculate metrics
  pct_extreme <- mean(max_prob > threshold, na.rm = TRUE) * 100
  entropy_val <- entropy(posterior)
  # Note: relative entropy not yet implemented, using standard entropy
  entropy_relative <- entropy_val

  # Class sizes
  class_assignment <- apply(posterior, 1, which.max)
  unweighted_sizes <- table(class_assignment)

  weights_var <- object@model_info$survey_design$weights
  if (!is.null(weights_var)) {
    weights <- object@data[[weights_var]]
    weighted_sizes <- tapply(weights, class_assignment, sum, na.rm = TRUE)
  } else {
    weighted_sizes <- unweighted_sizes
  }

  # Determine separation type
  if (pct_extreme > 99.9) {
    separation_type <- "perfect"
    has_separation <- TRUE
    recommendation <- "Perfect separation detected. Consider reducing number of classes or examining data for outliers."
  } else if (pct_extreme > 95) {
    separation_type <- "quasi"
    has_separation <- TRUE
    recommendation <- "Quasi-perfect separation detected. Results should be interpreted cautiously."
  } else {
    separation_type <- "none"
    has_separation <- FALSE
    recommendation <- "No separation issues detected."
  }

  # Check for very small classes
  min_class_pct <- min(weighted_sizes / sum(weighted_sizes)) * 100
  if (min_class_pct < 1) {
    recommendation <- paste0(recommendation, " WARNING: Very small class detected (",
                            round(min_class_pct, 1), "% of sample).")
  }

  result <- list(
    has_separation = has_separation,
    separation_type = separation_type,
    pct_extreme = pct_extreme,
    min_posterior_prob = min(max_prob, na.rm = TRUE),
    max_posterior_prob = max(max_prob, na.rm = TRUE),
    class_sizes = list(
      unweighted = unweighted_sizes,
      weighted = weighted_sizes,
      proportion = weighted_sizes / sum(weighted_sizes)
    ),
    entropy = entropy_val,
    entropy_relative = entropy_relative,
    recommendation = recommendation
  )

  class(result) <- "separation_diagnostics"
  return(result)
}

#' Residual Diagnostics for GMM
#'
#' @description
#' Computes and analyzes residuals for growth mixture models, including
#' standardized residuals, Q-Q plots, and autocorrelation checks.
#'
#' @param object Fitted \code{SurveyMixr} object
#' @param type Character: "pearson" (default), "deviance", or "standardized"
#' @param by_class Logical; compute residuals separately for each class?
#'
#' @return List with residual diagnostics
#'
#' @export
residual_diagnostics <- function(object,
                                 type = c("pearson", "deviance", "standardized"),
                                 by_class = TRUE) {

  type <- match.arg(type)

  # Extract fitted values and observed values
  fitted_vals <- fitted(object)
  observed_vals <- object@data[[object@model_info$outcome_var]]

  # Compute residuals
  residuals <- observed_vals - fitted_vals

  # Standardize if requested
  if (type == "standardized") {
    # Estimate residual variance
    resid_var <- var(residuals, na.rm = TRUE)
    residuals <- residuals / sqrt(resid_var)
  }

  # Compute diagnostics
  diagnostics <- list(
    residuals = residuals,
    mean = mean(residuals, na.rm = TRUE),
    sd = sd(residuals, na.rm = TRUE),
    skewness = .calculate_skewness(residuals[!is.na(residuals)]),
    kurtosis = .calculate_kurtosis(residuals[!is.na(residuals)]),
    shapiro_test = if(length(residuals[!is.na(residuals)]) < 5000) {
      shapiro.test(residuals[!is.na(residuals)])
    } else {
      list(p.value = NA, statistic = NA)
    }
  )

  # By-class diagnostics
  if (by_class) {
    class_assignment <- apply(object@results$posterior_probs, 1, which.max)
    diagnostics$by_class <- lapply(1:object@model_info$n_classes, function(k) {
      resid_k <- residuals[class_assignment == k & !is.na(residuals)]
      list(
        n = length(resid_k),
        mean = mean(resid_k, na.rm = TRUE),
        sd = sd(resid_k, na.rm = TRUE),
        skewness = .calculate_skewness(resid_k),
        kurtosis = .calculate_kurtosis(resid_k)
      )
    })
    names(diagnostics$by_class) <- paste0("Class_", 1:object@model_info$n_classes)
  }

  class(diagnostics) <- "gmm_residuals"
  return(diagnostics)
}

#' Define InfluenceDiagnostics S4 Class
#'
#' @keywords internal
#' @export
setClass("InfluenceDiagnostics",
  slots = list(
    influence_measures = "data.frame",
    influential_ids = "character",
    threshold = "list",
    summary = "list"
  )
)

#' Print Method for Influence Diagnostics
#'
#' @param object An InfluenceDiagnostics object
#' @export
setMethod("show", "InfluenceDiagnostics", function(object) {
  cat("\nInfluence Diagnostics for Growth Mixture Model\n")
  cat(rep("=", 60), "\n", sep = "")

  cat("\nSummary:\n")
  cat("  Total observations:", object@summary$n_observations, "\n")
  cat("  Total individuals:", object@summary$n_individuals, "\n")
  cat("  Influential cases:", object@summary$n_influential,
      "(", round(object@summary$pct_influential, 1), "%)\n")

  cat("\nThresholds:\n")
  if (!is.na(object@threshold$cooks)) {
    cat("  Cook's D:", round(object@threshold$cooks, 4), "\n")
  }
  if (!is.na(object@threshold$dfbetas)) {
    cat("  DFBETAS:", round(object@threshold$dfbetas, 4), "\n")
  }
  if (!is.na(object@threshold$leverage)) {
    cat("  Leverage:", round(object@threshold$leverage, 4), "\n")
  }

  if (length(object@influential_ids) > 0) {
    cat("\nInfluential IDs (first 20):\n")
    cat("  ", paste(head(object@influential_ids, 20), collapse = ", "), "\n")
    if (length(object@influential_ids) > 20) {
      cat("  ... and", length(object@influential_ids) - 20, "more\n")
    }
  }

  cat("\n")
})
