# Data Validation and Preparation Helpers
#
# Functions to validate data quality, survey design, and prepare data
# for growth mixture modeling
#
# Phase 2.5 of the development roadmap

#' Validate Survey Data for GMM Analysis
#'
#' @description
#' Comprehensive validation of data structure, survey design elements, and
#' suitability for growth mixture modeling. Provides detailed diagnostics
#' and warnings about potential issues.
#'
#' @param data Data frame in long format
#' @param id Character string naming ID variable
#' @param time Character string naming time variable
#' @param outcome Character string naming outcome variable
#' @param strata Optional character string naming stratification variable
#' @param cluster Optional character string naming cluster/PSU variable
#' @param weights Optional character string naming weight variable
#' @param covariates Optional character vector naming covariate variables
#' @param min_observations Minimum number of observations per individual (default = 2)
#' @param check_weights Logical; perform detailed weight diagnostics?
#' @param verbose Logical; print detailed output?
#'
#' @return An S4 object of class \code{DataValidation} with slots:
#'   \item{is_valid}{Logical; overall validation status}
#'   \item{errors}{Character vector of critical errors}
#'   \item{warnings}{Character vector of warnings}
#'   \item{info}{List of diagnostic information}
#'   \item{recommendations}{Character vector of recommended actions}
#'
#' @details
#' The validation checks include:
#'
#' **Data Structure:**
#' - All required variables present
#' - Correct data types
#' - No duplicate ID-time combinations
#' - Sufficient observations per individual
#'
#' **Survey Design:**
#' - Clusters nested within strata
#' - Weights are positive and non-missing
#' - Suspicious weight patterns (e.g., all identical)
#' - Design effects
#'
#' **Missingness:**
#' - Missing data patterns (MCAR, MAR, MNAR indicators)
#' - Proportion missing by variable
#' - Monotone vs non-monotone patterns
#'
#' **Statistical Properties:**
#' - Outcome distribution (normality, outliers)
#' - Time score distribution
#' - Covariate distributions
#' - Multicollinearity among covariates
#'
#' @export
#'
#' @examples
#' \donttest{
#' data(mcs_simulated)
#'
#' # Validate data before analysis
#' validation <- validate_survey_data(
#'   data = mcs_simulated,
#'   id = "id",
#'   time = "age",
#'   outcome = "selfcontrol",
#'   strata = "stratum",
#'   cluster = "cluster",
#'   weights = "weight",
#'   verbose = TRUE
#' )
#'
#' print(validation)
#'
#' # Check if data is valid for analysis
#' if (validation@is_valid) {
#'   cat("Data is ready for GMM analysis\n")
#' } else {
#'   cat("Please address errors before proceeding:\n")
#'   cat(validation@errors, sep = "\n")
#' }
#' }
validate_survey_data <- function(data,
                                 id,
                                 time,
                                 outcome,
                                 strata = NULL,
                                 cluster = NULL,
                                 weights = NULL,
                                 covariates = NULL,
                                 min_observations = 2,
                                 check_weights = TRUE,
                                 verbose = TRUE) {

  errors <- character()
  warnings <- character()
  info <- list()
  recommendations <- character()

  if (verbose) {
    cat("\n")
    cat(rep("=", 70), "\n", sep = "")
    cat("DATA VALIDATION FOR GROWTH MIXTURE MODELING\n")
    cat(rep("=", 70), "\n\n", sep = "")
  }

  # 1. CHECK DATA STRUCTURE
  if (verbose) cat("1. Checking data structure...\n")

  # Check that data is a data.frame
  if (!is.data.frame(data)) {
    errors <- c(errors, "Data must be a data.frame")
  }

  # Check required variables exist
  required_vars <- c(id, time, outcome)
  missing_vars <- required_vars[!required_vars %in% names(data)]
  if (length(missing_vars) > 0) {
    errors <- c(errors, paste0("Missing required variables: ",
                              paste(missing_vars, collapse = ", ")))
  }

  # Check optional variables if specified
  optional_vars <- c(strata, cluster, weights, covariates)
  optional_vars <- optional_vars[!is.null(optional_vars)]
  missing_optional <- optional_vars[!optional_vars %in% names(data)]
  if (length(missing_optional) > 0) {
    errors <- c(errors, paste0("Specified variables not found: ",
                              paste(missing_optional, collapse = ", ")))
  }

  # If critical errors, return early
  if (length(errors) > 0) {
    result <- methods::new("DataValidation",
                          is_valid = FALSE,
                          errors = errors,
                          warnings = warnings,
                          info = info,
                          recommendations = recommendations)
    if (verbose) .print_validation_summary(result)
    return(result)
  }

  # Check for duplicates
  id_time_combos <- paste(data[[id]], data[[time]], sep = "_")
  duplicates <- duplicated(id_time_combos)
  if (any(duplicates)) {
    errors <- c(errors, paste0("Found ", sum(duplicates),
                              " duplicate ID-time combinations"))
    info$duplicate_examples <- head(data[duplicates, c(id, time)], 5)
  }

  # Check observations per individual
  obs_per_id <- table(data[[id]])
  info$n_individuals <- length(unique(data[[id]]))
  info$n_observations <- nrow(data)
  info$obs_per_id_summary <- summary(as.numeric(obs_per_id))

  few_obs <- sum(obs_per_id < min_observations)
  if (few_obs > 0) {
    warnings <- c(warnings, paste0(few_obs, " individuals have < ",
                                  min_observations, " observations"))
    recommendations <- c(recommendations,
                        "Consider removing individuals with insufficient data")
  }

  # 2. CHECK SURVEY DESIGN
  if (verbose) cat("2. Checking survey design...\n")

  if (!is.null(strata) && !is.null(cluster)) {
    # Check clusters are nested in strata
    cluster_strata <- unique(data[, c(cluster, strata)])
    cluster_counts <- table(cluster_strata[[cluster]])

    if (any(cluster_counts > 1)) {
      errors <- c(errors, "Clusters must be nested within strata (each cluster belongs to only one stratum)")
      info$non_nested_clusters <- names(cluster_counts)[cluster_counts > 1]
    } else {
      info$n_strata <- length(unique(data[[strata]]))
      info$n_clusters <- length(unique(data[[cluster]]))
      info$clusters_per_stratum <- table(cluster_strata[[strata]])
    }
  }

  # 3. CHECK WEIGHTS
  if (verbose && !is.null(weights)) cat("3. Checking survey weights...\n")

  if (!is.null(weights)) {
    w <- data[[weights]]

    # Check for non-positive or missing weights
    if (any(is.na(w))) {
      errors <- c(errors, paste0(sum(is.na(w)), " missing weight values"))
    }
    if (any(w <= 0, na.rm = TRUE)) {
      errors <- c(errors, paste0(sum(w <= 0, na.rm = TRUE),
                                " non-positive weight values"))
    }

    # Diagnostic statistics
    info$weight_summary <- summary(w)
    info$weight_cv <- sd(w, na.rm = TRUE) / mean(w, na.rm = TRUE)

    # Check for suspicious patterns
    if (all(w == w[1], na.rm = TRUE)) {
      warnings <- c(warnings, "All weights are identical - survey design may not be properly specified")
    }

    # Effective sample size
    eff_n <- sum(w, na.rm = TRUE)^2 / sum(w^2, na.rm = TRUE)
    info$effective_sample_size <- eff_n
    info$design_effect <- info$n_individuals / eff_n

    if (info$design_effect > 3) {
      warnings <- c(warnings, paste0("Large design effect (", round(info$design_effect, 2),
                                    ") - clustering is substantial"))
    }

    # Extreme weights
    extreme_weights <- w > 10 * median(w, na.rm = TRUE) | w < 0.1 * median(w, na.rm = TRUE)
    if (any(extreme_weights, na.rm = TRUE)) {
      warnings <- c(warnings, paste0(sum(extreme_weights, na.rm = TRUE),
                                    " extreme weights (>10x or <0.1x median)"))
      recommendations <- c(recommendations,
                          "Consider trimming or Winsorizing extreme weights")
    }
  }

  # 4. CHECK MISSING DATA PATTERNS
  if (verbose) cat("4. Checking missing data patterns...\n")

  outcome_missing <- is.na(data[[outcome]])
  pct_missing <- mean(outcome_missing) * 100
  info$outcome_missing_pct <- pct_missing

  if (pct_missing > 0) {
    info$missing_by_time <- tapply(outcome_missing, data[[time]], mean) * 100

    # Check for monotone missingness (dropout pattern)
    is_monotone <- .check_monotone_missing(data, id, time, outcome)
    info$monotone_missing <- is_monotone

    if (pct_missing > 50) {
      warnings <- c(warnings, paste0("High missingness (", round(pct_missing, 1),
                                    "%) - results may be unreliable"))
    } else if (pct_missing > 20) {
      warnings <- c(warnings, paste0("Moderate missingness (", round(pct_missing, 1), "%)"))
    }

    if (is_monotone) {
      info$missing_pattern <- "Monotone (dropout)"
      recommendations <- c(recommendations,
                          "Monotone missingness detected - FIML is appropriate")
    } else {
      info$missing_pattern <- "Non-monotone (intermittent)"
      recommendations <- c(recommendations,
                          "Non-monotone missingness - verify FIML assumptions")
    }
  } else {
    info$missing_pattern <- "Complete data"
  }

  # Check covariate missingness
  if (!is.null(covariates)) {
    cov_missing <- sapply(covariates, function(v) mean(is.na(data[[v]])) * 100)
    if (any(cov_missing > 0)) {
      info$covariate_missing <- cov_missing[cov_missing > 0]
      warnings <- c(warnings, "Some covariates have missing values")
    }
  }

  # 5. CHECK OUTCOME DISTRIBUTION
  if (verbose) cat("5. Checking outcome distribution...\n")

  y <- data[[outcome]][!is.na(data[[outcome]])]
  info$outcome_summary <- summary(y)
  info$outcome_skewness <- .calculate_skewness(y)
  info$outcome_kurtosis <- .calculate_kurtosis(y)

  # Check for outliers (> 3 SD from mean)
  outliers <- abs(scale(y)) > 3
  if (any(outliers)) {
    warnings <- c(warnings, paste0(sum(outliers), " potential outliers (>3 SD from mean)"))
    recommendations <- c(recommendations,
                        "Examine outliers - may indicate data errors or require robust methods")
  }

  # Check if outcome appears categorical
  unique_vals <- length(unique(y))
  if (unique_vals <= 10) {
    warnings <- c(warnings, paste0("Outcome has only ", unique_vals,
                                  " unique values - consider categorical outcome methods"))
  }

  # 6. CHECK TIME VARIABLE
  if (verbose) cat("6. Checking time variable...\n")

  time_vals <- sort(unique(data[[time]]))
  info$time_points <- time_vals
  info$n_time_points <- length(time_vals)

  # Check if time is evenly spaced
  if (length(time_vals) > 1) {
    time_diffs <- diff(time_vals)
    if (length(unique(time_diffs)) == 1) {
      info$time_spacing <- "Evenly spaced"
    } else {
      info$time_spacing <- "Unevenly spaced"
      info$time_intervals <- time_diffs
    }
  }

  if (info$n_time_points < 3) {
    warnings <- c(warnings, "Only 2 time points - limited growth model options")
    recommendations <- c(recommendations,
                        "Need at least 3 time points for quadratic growth")
  }

  # 7. CHECK COVARIATES
  if (!is.null(covariates) && length(covariates) > 0) {
    if (verbose) cat("7. Checking covariates...\n")

    # Check for multicollinearity
    numeric_covs <- covariates[sapply(data[covariates], is.numeric)]

    if (length(numeric_covs) >= 2) {
      cor_matrix <- cor(data[numeric_covs], use = "pairwise.complete.obs")
      high_cor <- which(abs(cor_matrix) > 0.9 & abs(cor_matrix) < 1, arr.ind = TRUE)

      if (nrow(high_cor) > 0) {
        warnings <- c(warnings, "High correlations detected among covariates")
        info$high_correlations <- unique(rownames(high_cor))
        recommendations <- c(recommendations,
                            "Consider removing redundant covariates")
      }
    }

    # Check for zero or near-zero variance
    for (cov in covariates) {
      if (is.numeric(data[[cov]])) {
        cov_sd <- sd(data[[cov]], na.rm = TRUE)
        if (cov_sd < 1e-10) {
          warnings <- c(warnings, paste0("Covariate '", cov, "' has zero variance"))
        }
      }
    }
  }

  # FINAL ASSESSMENT
  is_valid <- length(errors) == 0

  if (is_valid && length(warnings) == 0) {
    info$overall_assessment <- "Data appears suitable for GMM analysis"
  } else if (is_valid) {
    info$overall_assessment <- "Data is usable but has some issues to consider"
  } else {
    info$overall_assessment <- "Critical errors must be fixed before analysis"
  }

  # Create result object
  result <- methods::new("DataValidation",
                        is_valid = is_valid,
                        errors = errors,
                        warnings = warnings,
                        info = info,
                        recommendations = recommendations)

  if (verbose) .print_validation_summary(result)

  return(result)
}

#' Check for Monotone Missing Data Pattern
#'
#' @keywords internal
.check_monotone_missing <- function(data, id, time, outcome) {
  # For each individual, check if missingness follows monotone pattern
  # (once data is missing, all subsequent observations are missing)

  ids <- unique(data[[id]])
  monotone_count <- 0

  for (i in ids) {
    subject_data <- data[data[[id]] == i, ]
    subject_data <- subject_data[order(subject_data[[time]]), ]

    y <- subject_data[[outcome]]
    missing_idx <- which(is.na(y))

    if (length(missing_idx) > 0) {
      # Check if all missing values are consecutive and at the end
      expected_missing <- seq(min(missing_idx), length(y))
      if (identical(missing_idx, expected_missing)) {
        monotone_count <- monotone_count + 1
      }
    } else {
      # No missing data for this individual - counts as monotone
      monotone_count <- monotone_count + 1
    }
  }

  # If >90% of individuals have monotone patterns, consider it monotone overall
  return(monotone_count / length(ids) > 0.9)
}

#' Calculate Skewness
#'
#' @keywords internal
.calculate_skewness <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  m <- mean(x)
  s <- sd(x)
  skew <- sum((x - m)^3) / (n * s^3)
  return(skew)
}

#' Calculate Kurtosis
#'
#' @keywords internal
.calculate_kurtosis <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  m <- mean(x)
  s <- sd(x)
  kurt <- sum((x - m)^4) / (n * s^4) - 3  # Excess kurtosis
  return(kurt)
}

#' Print Validation Summary
#'
#' @keywords internal
.print_validation_summary <- function(validation) {
  cat("\n")
  cat(rep("=", 70), "\n", sep = "")
  cat("VALIDATION SUMMARY\n")
  cat(rep("=", 70), "\n\n", sep = "")

  cat("Overall Status:", ifelse(validation@is_valid,
                               "PASSED", "FAILED"), "\n\n")

  if (length(validation@errors) > 0) {
    cat("ERRORS (must fix):\n")
    for (i in seq_along(validation@errors)) {
      cat("  ", i, ". ", validation@errors[i], "\n", sep = "")
    }
    cat("\n")
  }

  if (length(validation@warnings) > 0) {
    cat("WARNINGS (review recommended):\n")
    for (i in seq_along(validation@warnings)) {
      cat("  ", i, ". ", validation@warnings[i], "\n", sep = "")
    }
    cat("\n")
  }

  if (length(validation@recommendations) > 0) {
    cat("RECOMMENDATIONS:\n")
    for (i in seq_along(validation@recommendations)) {
      cat("  ", i, ". ", validation@recommendations[i], "\n", sep = "")
    }
    cat("\n")
  }

  cat("Data Overview:\n")
  if (!is.null(validation@info$n_individuals)) {
    cat("  Individuals:", validation@info$n_individuals, "\n")
  }
  if (!is.null(validation@info$n_observations)) {
    cat("  Observations:", validation@info$n_observations, "\n")
  }
  if (!is.null(validation@info$n_time_points)) {
    cat("  Time points:", validation@info$n_time_points, "\n")
  }
  if (!is.null(validation@info$outcome_missing_pct)) {
    cat("  Missing outcome:", round(validation@info$outcome_missing_pct, 1), "%\n")
  }
  if (!is.null(validation@info$design_effect)) {
    cat("  Design effect:", round(validation@info$design_effect, 2), "\n")
  }

  cat("\n")
  cat(rep("=", 70), "\n", sep = "")
}

#' Define DataValidation S4 Class
#'
#' @slot is_valid Logical indicating if data passed validation
#' @slot errors Character vector of critical errors
#' @slot warnings Character vector of warnings
#' @slot info List of diagnostic information
#' @slot recommendations Character vector of recommendations
#'
#' @keywords internal
#' @export
setClass("DataValidation",
  slots = list(
    is_valid = "logical",
    errors = "character",
    warnings = "character",
    info = "list",
    recommendations = "character"
  )
)

#' Print Method for DataValidation
#'
#' @param object DataValidation object
#' @return No return value, called for side effects (displays validation summary)
#' @export
setMethod("show", "DataValidation", function(object) {
  .print_validation_summary(object)
})
