#' S4 Methods for SurveyMixr Objects
#'
#' @description
#' Standard methods for objects returned by surveymixr functions.
#'
#' @param object A \code{SurveyMixr} object
#' @param x A \code{SurveyMixr} object
#' @param y Not used (required for S4 plot signature)
#' @param k Integer specifying class number (for class-specific methods)
#' @param ... Additional arguments passed to plotting or summary functions
#'
#' @return
#' The \code{show}, \code{print}, and \code{plot} methods are called for their side effects
#' (displaying or plotting results) and return the object invisibly. The \code{summary} method
#' returns an enhanced summary of the model invisibly. Other methods return specific values:
#' \describe{
#'   \item{\code{show()}}{No return value, called for side effects (displays object summary)}
#'   \item{\code{print()}}{No return value, called for side effects (prints object summary)}
#'   \item{\code{summary()}}{No return value, called for side effects (prints detailed summary)}
#'   \item{\code{coef()}}{Named vector of all model parameters (class proportions and growth parameters)}
#'   \item{\code{vcov()}}{Variance-covariance matrix of parameter estimates}
#'   \item{\code{fitted()}}{Matrix of fitted trajectories (rows = individuals, columns = time points)}
#'   \item{\code{residuals()}}{Matrix of residuals (observed - fitted values)}
#'   \item{\code{logLik()}}{Log-likelihood value with attributes for degrees of freedom and sample size}
#'   \item{\code{AIC()}}{Akaike Information Criterion value}
#'   \item{\code{BIC()}}{Bayesian Information Criterion value}
#'   \item{\code{plot()}}{No return value, called for side effects (generates plots)}
#' }
#'
#' @name surveymixr-methods
#' @rdname surveymixr-methods
NULL

# =============================================================================
# Show/Print Methods
# =============================================================================

#' @rdname surveymixr-methods
#' @export
setMethod("show", "SurveyMixr", function(object) {
  cat("Growth Mixture Model with", object@model_info$n_classes, "Classes\n")
  cat("=====================================\n\n")

  cat("Model:\n")
  cat(sprintf("  Growth model: %s\n", object@model_info$growth_model))
  cat(sprintf("  N = %d individuals\n", object@model_info$n_obs))
  cat(sprintf("  T = %d time points\n", object@model_info$n_times))
  cat(sprintf("  Parameters: %d\n", object@model_info$n_parameters))

  cat("\nSurvey Design:\n")
  cat(sprintf("  Weights: %s\n", ifelse(object@survey_design$has_weights, "Yes", "No")))
  cat(sprintf("  Clustering: %s\n", ifelse(object@survey_design$has_cluster, "Yes", "No")))
  cat(sprintf("  Stratification: %s\n", ifelse(object@survey_design$has_strata, "Yes", "No")))

  cat("\nFit:\n")
  cat(sprintf("  LogLik: %.2f\n", object@fit_indices$loglik))
  cat(sprintf("  AIC: %.2f\n", object@fit_indices$aic))
  cat(sprintf("  BIC: %.2f\n", object@fit_indices$bic))
  cat(sprintf("  Entropy: %.3f\n", object@fit_indices$entropy))

  cat("\nClass Proportions (Weighted):\n")
  for (k in 1:object@model_info$n_classes) {
    cat(sprintf("  Class %d: %.3f\n", k, object@class_proportions$weighted[k]))
  }

  cat("\nConvergence:\n")
  cat(sprintf("  Status: %s\n", ifelse(object@convergence_info$converged,
                                       "Converged", "Not converged")))
  cat(sprintf("  Iterations: %d\n", object@convergence_info$iterations))
  cat(sprintf("  Random starts: %d\n", object@convergence_info$n_starts))
  cat(sprintf("  Best solution replicated: %d times\n",
             object@convergence_info$n_replications))

  cat("\n---\n")
  cat("Use summary() for detailed results\n")
  cat("Use plot() to visualize trajectories\n")
})


#' @rdname surveymixr-methods
#' @export
setMethod("print", "SurveyMixr", function(x, ...) {
  show(x)
})


#' @rdname surveymixr-methods
#' @export
setMethod("summary", "SurveyMixr", function(object, ...) {
  cat("========================================\n")
  cat("Growth Mixture Model - Detailed Summary\n")
  cat("========================================\n\n")

  # Model info
  cat("MODEL SPECIFICATION\n")
  cat("-------------------\n")
  cat(sprintf("Growth model: %s\n", object@model_info$growth_model))
  cat(sprintf("Number of classes: %d\n", object@model_info$n_classes))
  cat(sprintf("Sample size: %d\n", object@model_info$n_obs))
  cat(sprintf("Time points: %d\n", object@model_info$n_times))
  cat(sprintf("Time scores: %s\n",
             paste(round(object@model_info$time_scores, 2), collapse = ", ")))

  # Survey design
  cat("\nSURVEY DESIGN\n")
  cat("-------------\n")
  cat(sprintf("Sampling weights: %s\n",
             ifelse(object@survey_design$has_weights, "Yes", "No")))
  if (object@survey_design$has_strata) {
    cat(sprintf("Stratification: %d strata\n",
               length(unique(object@survey_design$strata))))
  }
  if (object@survey_design$has_cluster) {
    cat(sprintf("Clustering: %d PSUs\n",
               length(unique(object@survey_design$cluster))))
    if (!is.null(object@survey_design$nest) && object@survey_design$has_strata) {
      cat(sprintf("Nested design: %s\n",
                 ifelse(object@survey_design$nest, "Yes", "No")))
    }
  }

  # Growth parameters
  cat("\nGROWTH PARAMETERS\n")
  cat("-----------------\n")
  for (k in 1:object@model_info$n_classes) {
    cat(sprintf("\nClass %d (n = %.1f, %.1f%%):\n", k,
               sum(object@class_assignments == k),
               object@class_proportions$weighted[k] * 100))

    gp <- object@parameters$growth_parameters[[k]]
    se <- object@standard_errors$growth_parameters[[k]]

    cat(sprintf("  Intercept: %.3f (SE = %.3f)\n", gp$intercept, se$intercept))
    cat(sprintf("  Slope: %.3f (SE = %.3f)\n", gp$slope, se$slope))

    if (!is.null(gp$quadratic)) {
      cat(sprintf("  Quadratic: %.3f (SE = %.3f)\n", gp$quadratic, se$quadratic))
    }

    cat(sprintf("  Residual SD: %.3f (SE = %.3f)\n",
               sqrt(object@parameters$residual_variance[k]),
               object@standard_errors$residual_variance[k] /
                 (2 * sqrt(object@parameters$residual_variance[k]))))
  }

  # Class proportions
  cat("\nCLASS PROPORTIONS\n")
  cat("-----------------\n")
  cat(sprintf("%-10s %12s %12s\n", "Class", "Weighted", "Unweighted"))
  for (k in 1:object@model_info$n_classes) {
    cat(sprintf("%-10d %12.3f %12.3f\n", k,
               object@class_proportions$weighted[k],
               object@class_proportions$unweighted[k]))
  }

  # Fit indices
  cat("\nFIT INDICES\n")
  cat("-----------\n")
  cat(sprintf("Log-likelihood: %.2f\n", object@fit_indices$loglik))
  cat(sprintf("Parameters: %d\n", object@fit_indices$n_params))
  cat(sprintf("AIC: %.2f\n", object@fit_indices$aic))
  cat(sprintf("BIC: %.2f\n", object@fit_indices$bic))
  cat(sprintf("aBIC: %.2f\n", object@fit_indices$abic))
  cat(sprintf("Entropy: %.3f\n", object@fit_indices$entropy))
  cat(sprintf("Average posterior prob: %.3f\n", object@fit_indices$avepp))

  # Classification quality
  cat("\nCLASSIFICATION QUALITY\n")
  cat("----------------------\n")
  cat(sprintf("%-10s %12s %12s\n", "Class", "AvePP", "OCC"))
  for (k in 1:object@model_info$n_classes) {
    cat(sprintf("%-10d %12.3f %12.2f\n", k,
               object@fit_indices$avepp_by_class[k],
               object@fit_indices$occ_by_class[k]))
  }

  # Convergence
  cat("\nCONVERGENCE\n")
  cat("-----------\n")
  cat(sprintf("Status: %s\n", ifelse(object@convergence_info$converged,
                                     "Converged", "WARNING: Not converged")))
  cat(sprintf("Iterations: %d\n", object@convergence_info$iterations))
  cat(sprintf("Random starts: %d\n", object@convergence_info$n_starts))
  cat(sprintf("Best logLik: %.2f\n", object@convergence_info$best_loglik))
  cat(sprintf("Replications: %d\n", object@convergence_info$n_replications))

  if (object@convergence_info$n_replications < 2) {
    cat("\nWARNING: Best solution not replicated. Consider increasing 'starts'.\n")
  }

  cat(sprintf("\nComputation time: %.1f seconds\n", object@computation_time))

  cat("\n========================================\n")
})


# =============================================================================
# Coef and VCov Methods
# =============================================================================

#' @rdname surveymixr-methods
#' @export
setMethod("coef", "SurveyMixr", function(object, ...) {
  # Return named vector of all parameters
  param_vec <- c()

  # Class proportions
  for (k in 1:object@model_info$n_classes) {
    param_vec[paste0("ClassProp_", k)] <- object@class_proportions$weighted[k]
  }

  # Growth parameters
  for (k in 1:object@model_info$n_classes) {
    gp <- object@parameters$growth_parameters[[k]]
    param_vec[paste0("Intercept_Class", k)] <- gp$intercept
    param_vec[paste0("Slope_Class", k)] <- gp$slope

    if (!is.null(gp$quadratic)) {
      param_vec[paste0("Quadratic_Class", k)] <- gp$quadratic
    }
  }

  # Residual variances
  for (k in 1:object@model_info$n_classes) {
    param_vec[paste0("ResidVar_Class", k)] <- object@parameters$residual_variance[k]
  }

  param_vec
})


#' @rdname surveymixr-methods
#' @export
setMethod("vcov", "SurveyMixr", function(object, ...) {
  # Return variance-covariance matrix
  object@vcov_matrix
})


# =============================================================================
# Extractor Methods
# =============================================================================

#' @rdname surveymixr-methods
#' @export
setMethod("fitted", "SurveyMixr", function(object, ...) {
  # Return fitted trajectories for each individual
  n <- object@model_info$n_obs
  time_scores <- object@model_info$time_scores
  n_times <- object@model_info$n_times

  fitted_matrix <- matrix(NA, nrow = n, ncol = n_times)

  for (i in 1:n) {
    # Class-specific fitted values weighted by posterior probs
    fitted_i <- rep(0, n_times)

    for (k in 1:object@model_info$n_classes) {
      y_pred_k <- predict_trajectory(
        time_scores,
        object@parameters$growth_parameters[[k]],
        object@model_info$growth_model
      )

      fitted_i <- fitted_i + object@posterior_probs[i, k] * y_pred_k
    }

    fitted_matrix[i, ] <- fitted_i
  }

  colnames(fitted_matrix) <- paste0("Time_", time_scores)
  fitted_matrix
})


#' @rdname surveymixr-methods
#' @export
setMethod("residuals", "SurveyMixr", function(object, ...) {
  # Can only compute if data is stored
  if (nrow(object@data) == 0) {
    stop("Residuals not available. Re-fit model with keep_data = TRUE")
  }

  # Get fitted values (N x T matrix)
  fitted_vals <- fitted(object)

  # Extract observed values from data
  # Data might be in long format, need to reshape to wide
  id_var <- object@model_info$id_var
  time_var <- object@model_info$time_var
  outcome_var <- object@model_info$outcome_var
  time_scores <- object@model_info$time_scores

  # Reshape data to wide format if needed
  if (all(c(id_var, time_var, outcome_var) %in% names(object@data))) {
    # Data is in long format - reshape to wide
    data_wide <- stats::reshape(
      object@data[, c(id_var, time_var, outcome_var)],
      idvar = id_var,
      timevar = time_var,
      v.names = outcome_var,
      direction = "wide"
    )

    # Extract just the outcome columns in the correct order
    outcome_cols <- paste0(outcome_var, ".", time_scores)
    observed <- as.matrix(data_wide[, outcome_cols, drop = FALSE])
    colnames(observed) <- paste0("Time_", time_scores)
  } else {
    # Assume data is already in wide format or extract what we can
    stop("Unable to extract outcome data. Data structure not recognized.")
  }

  # Compute residuals
  if (!identical(dim(observed), dim(fitted_vals))) {
    stop("Dimension mismatch between observed and fitted values. ",
         "Observed: ", paste(dim(observed), collapse = "x"),
         ", Fitted: ", paste(dim(fitted_vals), collapse = "x"))
  }

  residuals_matrix <- observed - fitted_vals
  residuals_matrix
})


#' @rdname surveymixr-methods
#' @export
setMethod("logLik", "SurveyMixr", function(object, ...) {
  val <- object@fit_indices$loglik
  attr(val, "df") <- object@fit_indices$n_params
  attr(val, "nobs") <- object@model_info$n_obs
  class(val) <- "logLik"
  val
})


#' @rdname surveymixr-methods
#' @export
setMethod("AIC", "SurveyMixr", function(object, ..., k = 2) {
  object@fit_indices$aic
})


#' @rdname surveymixr-methods
#' @export
setMethod("BIC", "SurveyMixr", function(object, ...) {
  object@fit_indices$bic
})


# =============================================================================
# SurveyMixrSelect Methods
# =============================================================================

#' @rdname surveymixr-methods
#' @export
setMethod("show", "SurveyMixrSelect", function(object) {
  cat("Growth Mixture Model Selection\n")
  cat("==============================\n\n")

  cat("Models compared:", paste(object@comparison_table$n_classes, collapse = ", "), "\n")
  cat("Criteria used:", paste(object@criteria, collapse = ", "), "\n")
  cat("Recommended classes:", object@recommended_classes, "\n\n")

  cat("Comparison Table:\n")
  print(object@comparison_table, row.names = FALSE)

  cat("\n---\n")
  cat("Access fitted models: object@fitted_models\n")
  cat("BLRT results: object@blrt_results\n")
})


#' @rdname surveymixr-methods
#' @export
setMethod("print", "SurveyMixrSelect", function(x, ...) {
  show(x)
})


#' @rdname surveymixr-methods
#' @export
setMethod("summary", "SurveyMixrSelect", function(object, ...) {
  show(object)

  if (length(object@blrt_results) > 0) {
    cat("\n\nBLRT Detailed Results:\n")
    cat("----------------------\n")

    for (test_name in names(object@blrt_results)) {
      blrt <- object@blrt_results[[test_name]]
      cat(sprintf("\n%s:\n", test_name))
      cat(sprintf("  Observed LRT: %.2f\n", blrt$lrt_observed))
      cat(sprintf("  Bootstrap samples: %d/%d successful\n",
                 blrt$n_bootstrap_success, blrt$n_bootstrap_total))
      cat(sprintf("  p-value: %.4f\n", blrt$p_value))
    }
  }
})


# =============================================================================
# R3StepResults Methods
# =============================================================================

#' @rdname surveymixr-methods
#' @export
setMethod("show", "R3StepResults", function(object) {
  cat("R3STEP Analysis Results\n")
  cat("=======================\n\n")

  cat("Method:", object@method, "\n")
  cat("Distal variables:", paste(object@distal_vars, collapse = ", "), "\n")
  cat("Number of classes:", ncol(object@class_means), "\n\n")

  cat("Class-Specific Means:\n")
  print(round(object@class_means, 3))

  cat("\nStandard Errors:\n")
  print(round(object@standard_errors, 3))

  cat("\nOmnibus Tests:\n")
  # Handle both single variable (flat structure) and multiple variables (nested)
  if (length(object@test_results) > 0) {
    # Check if this is a single variable with flat structure
    if ("omnibus_test" %in% names(object@test_results)) {
      # Single variable - print directly
      cat(sprintf("F(%.1f, %.1f) = %.3f, p = %.3f\n",
                  object@test_results$omnibus_test$df1,
                  object@test_results$omnibus_test$df2,
                  object@test_results$omnibus_test$statistic,
                  object@test_results$omnibus_test$p_value))

      if (!is.null(object@test_results$pairwise_tests)) {
        cat("\nPairwise Comparisons:\n")
        pairwise_df <- do.call(rbind, lapply(object@test_results$pairwise_tests, function(p) {
          data.frame(
            Comparison = paste0("Class ", p$class1, " vs Class ", p$class2),
            Diff = p$diff,
            SE = p$se,
            t = p$t,
            p = p$p,
            stringsAsFactors = FALSE
          )
        }))
        print(pairwise_df, row.names = FALSE)
      }
    } else {
      # Multiple variables - create summary table
      omnibus_df <- do.call(rbind, lapply(object@test_results, function(x) {
        data.frame(
          variable = x$variable,
          F_stat = x$omnibus_test$statistic,
          df1 = x$omnibus_test$df1,
          df2 = x$omnibus_test$df2,
          p_value = x$omnibus_test$p_value,
          stringsAsFactors = FALSE
        )
      }))
      print(omnibus_df, row.names = FALSE)

      # Check if any pairwise tests exist
      has_pairwise <- any(sapply(object@test_results, function(x) !is.null(x$pairwise)))
      if (has_pairwise) {
        cat("\n(Pairwise comparisons available, view with: r3step_result@test_results[['var']]$pairwise)\n")
      }
    }
  } else {
    cat("  No test results available\n")
  }

  cat("\n---\n")
  cat("Use summary() for detailed results including pairwise comparisons\n")
})


#' @rdname surveymixr-methods
#' @export
setMethod("print", "R3StepResults", function(x, ...) {
  show(x)
})


#' @rdname surveymixr-methods
#' @export
setMethod("summary", "R3StepResults", function(object, ...) {
  show(object)

  cat("\n\nEffect Sizes (Cohen's d):\n")
  cat("-------------------------\n")
  print(round(object@effect_sizes, 2))
})


#' Plot R3STEP Results
#'
#' Creates bar plots of class-specific means for distal variables.
#'
#' @param x An object of class \code{R3StepResults}
#' @param type Character string, currently only "means" is supported
#' @param ... Additional arguments passed to plotting functions
#'
#' @rdname surveymixr-methods
#' @export
setMethod("plot", "R3StepResults", function(x, y, type = "means", ...) {
  if (type == "means") {
    # Create bar plot of class means
    means <- x@class_means
    distal_vars <- rownames(means) %||% paste("Variable", 1:nrow(means))
    n_vars <- nrow(means)
    n_classes <- ncol(means)

    if (requireNamespace("graphics", quietly = TRUE)) {
      # Simple bar plot using base graphics
      graphics::barplot(
        t(means),
        beside = TRUE,
        legend = distal_vars,
        main = "Distal Variable Means by Class",
        xlab = "Class",
        ylab = "Mean",
        col = c("steelblue", "tomato", "seagreen", "gold")[seq_len(n_vars)],
        ...
      )
    } else {
      # Text-based output if graphics not available
      cat("R3STEP Class Means:\n")
      cat("==================\n\n")
      for (i in seq_len(n_vars)) {
        cat(sprintf("%s:\n", distal_vars[i]))
        cat(sprintf("  Class %d: %.3f\n", 1:n_classes, means[i, ]))
      }
    }
  } else {
    stop("Unknown plot type for R3StepResults. Use type = 'means'.")
  }
})



# =============================================================================
# Show Method for ConvergenceDiagnostics
# =============================================================================

#' @rdname surveymixr-methods
#' @export
setMethod("show", "ConvergenceDiagnostics", function(object) {
  cat("Convergence Diagnostics\n")
  cat("=======================\n\n")

  cat(sprintf("Number of random starts: %d\n", object@n_replications))
  cat(sprintf("Best log-likelihood: %.4f\n", object@best_loglik))

  if (nrow(object@local_maxima) > 0) {
    cat(sprintf("\nLocal maxima detected: %d\n", nrow(object@local_maxima)))
    cat("Top 5 solutions:\n")
    print(head(object@local_maxima, 5))
  }

  if (length(object@warnings) > 0) {
    cat("\nWarnings:\n")
    for (w in object@warnings) {
      cat(sprintf("  - %s\n", w))
    }
  }

  if (length(object@recommendations) > 0) {
    cat("\nRecommendations:\n")
    for (r in object@recommendations) {
      cat(sprintf("  - %s\n", r))
    }
  }
})


#' @rdname surveymixr-methods
#' @export
setMethod("print", "ConvergenceDiagnostics", function(x, ...) {
  show(x)
})


# =============================================================================
# Plot Method for SurveyMixr
# =============================================================================

#' @rdname surveymixr-methods
#' @param type Character string: "trajectories" (default), "entropy",
#'   "convergence", or "class_sizes"
#' @export
setMethod("plot", "SurveyMixr", function(x, y, type = "trajectories", ...) {
  if (type == "trajectories") {
    plot_trajectories(x, ...)
  } else if (type == "entropy") {
    plot_entropy_distribution(x, ...)
  } else if (type == "convergence") {
    plot_convergence(x, ...)
  } else if (type == "class_sizes") {
    plot_class_sizes(x, ...)
  } else {
    stop("Unknown plot type. Use: trajectories, entropy, convergence, or class_sizes")
  }
})
