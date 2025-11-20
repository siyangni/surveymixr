#' Model Selection for Growth Mixture Models
#'
#' @description
#' Compares growth mixture models with different numbers of latent classes using
#' multiple criteria including BIC, entropy, and the Bootstrap Likelihood Ratio
#' Test (BLRT).
#'
#' @param data Data frame in long format
#' @param id Character string specifying individual ID variable name
#' @param time Character string specifying time variable name
#' @param outcome Character string specifying outcome variable name
#' @param classes Integer vector specifying class solutions to test (e.g., 1:5)
#' @param strata Character string specifying stratification variable (optional)
#' @param cluster Character string specifying cluster/PSU variable (optional)
#' @param weights Character string specifying sampling weights variable (optional)
#' @param growth_model Character string: "linear" (default), "quadratic", etc.
#' @param criteria Character vector of criteria to compute: "BIC" (default),
#'   "BLRT", "entropy", "AIC", "aBIC"
#' @param blrt_samples Integer number of bootstrap samples for BLRT (default: 100)
#' @param blrt_alpha Significance level for BLRT (default: 0.05)
#' @param starts Integer number of random starts per model (default: 200)
#' @param cores Integer number of CPU cores (default: 1)
#' @param verbose Logical, print progress? (default: TRUE)
#' @param ... Additional arguments passed to \code{gmm_survey()}
#'
#' @return An S4 object of class \code{\linkS4class{SurveyMixrSelect}} containing:
#' \describe{
#'   \item{comparison_table}{Data frame comparing fit across class solutions}
#'   \item{fitted_models}{List of fitted \code{SurveyMixr} objects}
#'   \item{blrt_results}{Detailed BLRT results if requested}
#'   \item{recommended_classes}{Recommended number of classes}
#'   \item{criteria}{Criteria used for selection}
#' }
#'
#' @details
#' This function systematically compares mixture models with different numbers
#' of latent classes. Multiple criteria are available:
#'
#' \strong{Information Criteria:}
#' \itemize{
#'   \item \strong{BIC}: Bayesian Information Criterion (lower is better)
#'   \item \strong{AIC}: Akaike Information Criterion (lower is better)
#'   \item \strong{aBIC}: Sample-size adjusted BIC (lower is better)
#' }
#'
#' \strong{Classification Quality:}
#' \itemize{
#'   \item \strong{Entropy}: Classification certainty (higher is better, >0.8 preferred)
#' }
#'
#' \strong{Hypothesis Testing:}
#' \itemize{
#'   \item \strong{BLRT}: Bootstrap Likelihood Ratio Test comparing K vs K-1 classes.
#'     Considered the gold standard for class enumeration. A significant p-value
#'     (< 0.05) indicates that K classes fit better than K-1 classes.
#' }
#'
#' The BLRT implementation uses parametric bootstrap: data is generated under
#' the K-1 class model, and the distribution of likelihood ratio statistics is
#' computed empirically. This is computationally intensive but provides the most
#' reliable test for class enumeration.
#'
#' \strong{Practical Considerations:}
#' \itemize{
#'   \item Increase \code{starts} (500-1000) for final model selection
#'   \item BLRT is computationally intensive; use fewer bootstrap samples for
#'     initial exploration
#'   \item Smallest class should typically be >5% of sample
#'   \item Consider substantive interpretability alongside statistical criteria
#' }
#'
#' @references
#' Nylund, K. L., Asparouhov, T., & Muthén, B. O. (2007). Deciding on the number
#' of classes in latent class analysis and growth mixture modeling: A Monte Carlo
#' simulation study. \emph{Structural Equation Modeling, 14}(4), 535-569.
#'
#' McLachlan, G. J., & Peel, D. (2000). \emph{Finite mixture models}.
#' John Wiley & Sons.
#'
#' @examples
#' \donttest{
#' # Compare 1-5 class models
#' selection <- gmm_select(
#'   data = mcs_simulated,
#'   id = "id",
#'   time = "age",
#'   outcome = "selfcontrol",
#'   classes = 1:5,
#'   strata = "stratum",
#'   cluster = "psu",
#'   weights = "weight",
#'   criteria = c("BIC", "BLRT", "entropy"),
#'   blrt_samples = 100,
#'   starts = 200,
#'   cores = 4
#' )
#'
#' # View comparison table
#' print(selection)
#'
#' # Extract best model
#' best_fit <- selection@fitted_models[[3]]  # If 3 classes optimal
#' }
#'
#' @export
#' @importFrom parallel makeCluster stopCluster clusterExport parLapply
gmm_select <- function(data,
                       id,
                       time,
                       outcome,
                       classes = 1:5,
                       strata = NULL,
                       cluster = NULL,
                       weights = NULL,
                       growth_model = "linear",
                       criteria = c("BIC", "BLRT", "entropy"),
                       blrt_samples = 100,
                       blrt_alpha = 0.05,
                       starts = 200,
                       cores = 1,
                       verbose = TRUE,
                       ...) {

  # Handle deprecated/convenience parameters from ...
  dots <- list(...)

  # Support min_classes/max_classes for convenience
  if ("min_classes" %in% names(dots) || "max_classes" %in% names(dots)) {
    min_k <- if ("min_classes" %in% names(dots)) dots$min_classes else 1
    max_k <- if ("max_classes" %in% names(dots)) dots$max_classes else 5
    classes <- min_k:max_k
    if (verbose) {
      message("Using classes ", min_k, ":", max_k,
              " (from min_classes/max_classes parameters)")
    }
  }

  # Support run_blrt parameter for backward compatibility
  if ("run_blrt" %in% names(dots) && !dots$run_blrt) {
    criteria <- setdiff(criteria, "BLRT")
    if (verbose) {
      message("BLRT disabled via run_blrt=FALSE parameter")
    }
  }

  if (verbose) {
    message("========================================")
    message("Growth Mixture Model Selection")
    message("========================================")
    message(sprintf("Testing %d class solutions: %s",
                   length(classes),
                   paste(classes, collapse = ", ")))
    message(sprintf("Criteria: %s", paste(criteria, collapse = ", ")))
    message("========================================\n")
  }

  # Fit models for each class solution
  fitted_models <- list()
  fit_table <- data.frame(
    n_classes = integer(),
    loglik = numeric(),
    aic = numeric(),
    bic = numeric(),
    abic = numeric(),
    entropy = numeric(),
    smallest_class = numeric(),
    n_params = integer(),
    converged = logical(),
    stringsAsFactors = FALSE
  )

  for (k in classes) {
    if (verbose) {
      message(sprintf("Fitting %d-class model...", k))
    }

    fit_k <- tryCatch({
      gmm_survey(
        data = data,
        id = id,
        time = time,
        outcome = outcome,
        n_classes = k,
        growth_model = growth_model,
        strata = strata,
        cluster = cluster,
        weights = weights,
        starts = starts,
        cores = cores,
        verbose = FALSE,
        ...
      )
    }, error = function(e) {
      warning(sprintf("Failed to fit %d-class model: %s", k, e$message))
      return(NULL)
    })

    if (!is.null(fit_k)) {
      fitted_models[[as.character(k)]] <- fit_k

      # Extract fit indices
      fit_info <- fit_k@fit_indices

      fit_table <- rbind(fit_table, data.frame(
        n_classes = k,
        loglik = fit_info$loglik,
        aic = fit_info$aic,
        bic = fit_info$bic,
        abic = fit_info$abic,
        entropy = fit_info$entropy,
        smallest_class = fit_info$smallest_class_prop,
        n_params = fit_info$n_params,
        converged = fit_k@convergence_info$converged,
        stringsAsFactors = FALSE
      ))

      if (verbose) {
        message(sprintf("  LogLik: %.2f | BIC: %.2f | Entropy: %.3f",
                       fit_info$loglik, fit_info$bic, fit_info$entropy))
      }
    }
  }

  if (nrow(fit_table) == 0) {
    stop("No models converged successfully")
  }

  # ============================================================================
  # Bootstrap Likelihood Ratio Test (BLRT)
  # ============================================================================
  blrt_results <- list()

  if ("BLRT" %in% criteria && max(classes) > 1) {
    if (verbose) {
      message("\n========================================")
      message("Computing Bootstrap LRT...")
      message("========================================")
    }

    # Compare each K vs K-1
    for (k in classes[classes > 1]) {
      if (as.character(k) %in% names(fitted_models) &&
          as.character(k - 1) %in% names(fitted_models)) {

        if (verbose) {
          message(sprintf("\nBLRT: %d vs %d classes (%d bootstrap samples)",
                         k, k - 1, blrt_samples))
        }

        blrt_k <- compute_blrt(
          fit_k = fitted_models[[as.character(k)]],
          fit_k1 = fitted_models[[as.character(k - 1)]],
          data = data,
          id = id,
          time = time,
          outcome = outcome,
          n_bootstrap = blrt_samples,
          growth_model = growth_model,
          strata = strata,
          cluster = cluster,
          weights = weights,
          starts = max(50, starts / 4),  # Fewer starts for bootstrap
          cores = cores,
          verbose = verbose
        )

        blrt_results[[paste0(k, "_vs_", k - 1)]] <- blrt_k

        # Add to fit table
        fit_table$blrt_pval[fit_table$n_classes == k] <- blrt_k$p_value

        if (verbose) {
          message(sprintf("  BLRT p-value: %.4f %s",
                         blrt_k$p_value,
                         if (blrt_k$p_value < blrt_alpha) "(significant)" else ""))
        }
      }
    }
  }

  # ============================================================================
  # Determine Recommended Number of Classes
  # ============================================================================
  recommended <- determine_optimal_classes(fit_table, criteria, blrt_alpha)

  if (verbose) {
    message("\n========================================")
    message("Model Selection Summary")
    message("========================================")
    message(sprintf("Recommended number of classes: %d", recommended))
    message("\nFit comparison table:")
    print(fit_table)
  }

  # Create output object
  output <- new("SurveyMixrSelect",
    comparison_table = fit_table,
    fitted_models = fitted_models,
    blrt_results = blrt_results,
    recommended_classes = as.integer(recommended),
    criteria = criteria
  )

  return(output)
}


#' Compute Bootstrap Likelihood Ratio Test
#'
#' @keywords internal
#' @noRd
compute_blrt <- function(fit_k, fit_k1, data, id, time, outcome,
                        n_bootstrap, growth_model, strata, cluster, weights,
                        starts, cores, verbose) {

  k <- fit_k@model_info$n_classes
  k1 <- fit_k1@model_info$n_classes

  # Observed LRT statistic
  loglik_k <- fit_k@fit_indices$loglik
  loglik_k1 <- fit_k1@fit_indices$loglik
  lrt_obs <- 2 * (loglik_k - loglik_k1)

  if (verbose) {
    message(sprintf("  Observed LRT statistic: %.2f", lrt_obs))
    message("  Generating bootstrap samples...")
  }

  # Bootstrap: generate data under H0 (k-1 classes) and compute LRT distribution
  bootstrap_lrt <- numeric(n_bootstrap)

  for (b in 1:n_bootstrap) {
    if (verbose && b %% 20 == 0) {
      message(sprintf("    Bootstrap sample %d/%d", b, n_bootstrap))
    }

    # Generate data under k-1 class model
    data_boot <- generate_data_from_fit(fit_k1, data, id, time, outcome)

    # Fit both k-1 and k class models to bootstrap data
    fit_boot_k1 <- tryCatch({
      gmm_survey(
        data = data_boot,
        id = id,
        time = time,
        outcome = outcome,
        n_classes = k1,
        growth_model = growth_model,
        strata = strata,
        cluster = cluster,
        weights = weights,
        starts = starts,
        cores = 1,  # No nested parallelization
        verbose = FALSE
      )
    }, error = function(e) NULL)

    fit_boot_k <- tryCatch({
      gmm_survey(
        data = data_boot,
        id = id,
        time = time,
        outcome = outcome,
        n_classes = k,
        growth_model = growth_model,
        strata = strata,
        cluster = cluster,
        weights = weights,
        starts = starts,
        cores = 1,
        verbose = FALSE
      )
    }, error = function(e) NULL)

    # Compute LRT for bootstrap sample
    if (!is.null(fit_boot_k) && !is.null(fit_boot_k1)) {
      loglik_boot_k <- fit_boot_k@fit_indices$loglik
      loglik_boot_k1 <- fit_boot_k1@fit_indices$loglik
      bootstrap_lrt[b] <- 2 * (loglik_boot_k - loglik_boot_k1)
    } else {
      bootstrap_lrt[b] <- NA
    }
  }

  # Remove failed bootstrap samples
  bootstrap_lrt <- bootstrap_lrt[!is.na(bootstrap_lrt)]

  if (length(bootstrap_lrt) < n_bootstrap * 0.5) {
    warning(sprintf("More than 50%% of bootstrap samples failed for %d vs %d classes",
                   k, k1))
  }

  # Compute p-value
  p_value <- mean(bootstrap_lrt >= lrt_obs)

  list(
    k = k,
    k1 = k1,
    lrt_observed = lrt_obs,
    lrt_bootstrap = bootstrap_lrt,
    p_value = p_value,
    n_bootstrap_success = length(bootstrap_lrt),
    n_bootstrap_total = n_bootstrap
  )
}


#' Generate Data from Fitted Model
#'
#' @keywords internal
#' @noRd
generate_data_from_fit <- function(fit, original_data, id, time, outcome) {

  # Extract parameters
  params <- fit@parameters
  n_classes <- fit@model_info$n_classes
  time_scores <- fit@model_info$time_scores
  growth_model <- fit@model_info$growth_model

  # Get original data structure
  data_template <- original_data[, c(id, time, outcome,
                                     names(fit@survey_design))]

  # Generate class assignments based on class proportions
  n <- length(unique(data_template[[id]]))
  class_props <- params$class_proportions
  class_assignments <- sample(1:n_classes, size = n, replace = TRUE,
                              prob = class_props)

  # Generate outcomes for each individual
  unique_ids <- unique(data_template[[id]])
  new_data_list <- list()

  for (i in 1:n) {
    id_i <- unique_ids[i]
    class_i <- class_assignments[i]

    # Get times for this individual from original data
    times_i <- data_template[[time]][data_template[[id]] == id_i]

    # Predict trajectory
    y_pred <- predict_trajectory(times_i, params$growth_parameters[[class_i]],
                                growth_model)

    # Add residual noise
    sigma <- sqrt(params$residual_variance[class_i])
    y_new <- y_pred + rnorm(length(times_i), 0, sigma)

    # Create data frame for this individual
    df_i <- data.frame(
      id = id_i,
      time = times_i,
      outcome = y_new
    )
    names(df_i) <- c(id, time, outcome)

    new_data_list[[i]] <- df_i
  }

  # Combine
  new_data <- do.call(rbind, new_data_list)

  # Add back survey design variables
  survey_vars <- setdiff(names(data_template), c(id, time, outcome))
  if (length(survey_vars) > 0) {
    survey_info <- unique(data_template[, c(id, survey_vars)])
    new_data <- merge(new_data, survey_info, by = id)
  }

  new_data
}


#' Determine Optimal Number of Classes
#'
#' @keywords internal
#' @noRd
determine_optimal_classes <- function(fit_table, criteria, blrt_alpha = 0.05) {

  votes <- numeric(nrow(fit_table))

  # BIC: lowest value
  if ("BIC" %in% criteria) {
    votes[which.min(fit_table$bic)] <- votes[which.min(fit_table$bic)] + 1
  }

  # AIC: lowest value
  if ("AIC" %in% criteria) {
    votes[which.min(fit_table$aic)] <- votes[which.min(fit_table$aic)] + 1
  }

  # aBIC: lowest value
  if ("aBIC" %in% criteria) {
    votes[which.min(fit_table$abic)] <- votes[which.min(fit_table$abic)] + 1
  }

  # Entropy: highest value (but only if > 0.6)
  if ("entropy" %in% criteria) {
    good_entropy <- !is.na(fit_table$entropy) & fit_table$entropy > 0.6
    if (any(good_entropy, na.rm = TRUE)) {
      best_entropy <- which.max(fit_table$entropy * good_entropy)
      votes[best_entropy] <- votes[best_entropy] + 0.5  # Half vote
    }
  }

  # BLRT: last significant test
  if ("BLRT" %in% criteria && "blrt_pval" %in% names(fit_table)) {
    # Find highest K where BLRT is significant
    significant <- which(fit_table$blrt_pval < blrt_alpha & !is.na(fit_table$blrt_pval))
    if (length(significant) > 0) {
      best_blrt <- max(significant)
      votes[best_blrt] <- votes[best_blrt] + 2  # Strong vote for BLRT
    }
  }

  # Return class with most votes
  if (max(votes) == 0) {
    # Default to BIC if no clear winner
    return(fit_table$n_classes[which.min(fit_table$bic)])
  } else {
    return(fit_table$n_classes[which.max(votes)])
  }
}
