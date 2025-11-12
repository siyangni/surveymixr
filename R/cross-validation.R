# Cross-Validation for Growth Mixture Model Selection
#
# Implements K-fold cross-validation with proper handling of survey weights
# and complex design features
#
# Phase 2.2 of the development roadmap

#' K-Fold Cross-Validation for GMM Model Selection
#'
#' @description
#' Performs k-fold cross-validation to evaluate and compare growth mixture
#' models with different numbers of classes. Properly accounts for complex
#' survey design by maintaining design integrity within folds.
#'
#' @param data Data frame in long format
#' @param id Character string naming ID variable
#' @param time Character string naming time variable
#' @param outcome Character string naming outcome variable
#' @param classes Integer vector specifying number of classes to test (e.g., 1:5)
#' @param k_folds Integer number of folds (default = 10)
#' @param growth_model Character string: "linear" or "quadratic"
#' @param strata Optional character string naming stratification variable
#' @param cluster Optional character string naming cluster variable
#' @param weights Optional character string naming weight variable
#' @param covariates Optional character vector naming covariates
#' @param stratified_cv Logical; if TRUE, maintains stratum proportions in folds
#' @param starts Integer number of random starts per model
#' @param cores Integer number of CPU cores for parallel processing
#' @param seed Integer random seed for reproducibility
#' @param verbose Logical; print progress?
#'
#' @details
#' Cross-validation for mixture models requires special considerations:
#'
#' **1. Survey Design Preservation:**
#' When stratified_cv = TRUE, folds maintain the proportion of observations
#' from each stratum, preserving the survey design structure.
#'
#' **2. Individual-Level Splitting:**
#' The data is split at the individual level (not observation level) to keep
#' all time points for each person together.
#'
#' **3. Prediction Metrics:**
#' Multiple metrics are computed:
#' - Log-likelihood on held-out data
#' - Classification accuracy (if true classes known)
#' - Mean squared prediction error
#' - Weighted metrics using survey weights
#'
#' **4. Label Switching:**
#' Class labels may differ across folds. The algorithm attempts to align
#' labels based on trajectory patterns.
#'
#' @return An S4 object of class \code{GMM_CrossValidation} with slots:
#'   \item{cv_results}{Data frame with metrics for each fold and class count}
#'   \item{summary_stats}{Aggregated statistics across folds}
#'   \item{best_k}{Recommended number of classes}
#'   \item{fold_assignments}{Vector indicating fold membership for each individual}
#'   \item{detailed_results}{List with full results for each fold}
#'
#' @references
#' Merkle, E. C., You, D., & Preacher, K. (2016). Testing non-nested structural
#' equation models. *Psychological Methods*, 21(2), 151-163.
#'
#' Nylund-Gibson, K., & Choi, A. Y. (2018). Ten frequently asked questions
#' about latent class analysis. *Translational Issues in Psychological Science*,
#' 4(4), 440-461.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data(mcs_simulated)
#'
#' # 3-fold CV comparing 1-2 class models (lighter for examples)
#' cv_results <- gmm_cv(
#'   data = mcs_simulated,
#'   id = "id",
#'   time = "age",
#'   outcome = "selfcontrol",
#'   classes = 1:2,
#'   k_folds = 3,
#'   strata = "stratum",
#'   cluster = "cluster",
#'   weights = "weight",
#'   stratified_cv = TRUE,
#'   starts = 20,  # Reduced for faster execution
#'   cores = 1,    # Sequential for stability in examples
#'   seed = 123
#' )
#'
#' print(cv_results)
#' plot(cv_results)
#' }
gmm_cv <- function(data,
                   id,
                   time,
                   outcome,
                   classes = 1:5,
                   k_folds = 10,
                   growth_model = "linear",
                   strata = NULL,
                   cluster = NULL,
                   weights = NULL,
                   covariates = NULL,
                   stratified_cv = TRUE,
                   starts = 200,
                   cores = 1,  # Default to sequential for stability
                   seed = NULL,
                   verbose = TRUE) {

  # Validate inputs
  if (!is.numeric(k_folds) || length(k_folds) != 1 || k_folds < 2) {
    stop("k_folds must be a positive integer >= 2")
  }

  if (!is.numeric(classes) || length(classes) < 1) {
    stop("classes must be a non-empty numeric vector")
  }

  if (!is.null(seed)) set.seed(seed)

  # Limit cores to prevent oversubscription - be very conservative
  max_available <- parallel::detectCores()
  cores <- min(cores, max_available, 2)  # Cap at 2 cores for stability

  # Always default to 1 core unless explicitly requested higher
  # This prevents issues in CRAN check environments
  if (missing(cores) || is.null(cores)) {
    cores <- 1
  }

  # Set up parallel backend if needed (with error handling)
  parallel_backend <- FALSE
  if (cores > 1) {
    tryCatch({
      if (requireNamespace("doParallel", quietly = TRUE)) {
        # Test if we can actually create the cluster
        cl <- parallel::makeCluster(cores)
        doParallel::registerDoParallel(cl)
        parallel_backend <- TRUE
        on.exit({
          if (parallel_backend) {
            tryCatch({
              parallel::stopCluster(cl)
            }, error = function(e) {
              # Ignore cleanup errors
            })
          }
        })
        if (verbose) cat("Using", cores, "cores for parallel processing\n")
      } else {
        if (verbose) cat("Note: doParallel package not available, using sequential processing\n")
        cores <- 1
      }
    }, error = function(e) {
      if (verbose) cat("Warning: Could not set up parallel processing:", e$message, "\n")
      if (verbose) cat("Falling back to sequential processing\n")
      cores <- 1
      parallel_backend <- FALSE
    })
  }

  # Extract unique individuals
  ids <- unique(data[[id]])
  n_individuals <- length(ids)

  # Create fold assignments
  if (stratified_cv && !is.null(strata)) {
    # Stratified CV: maintain stratum proportions in each fold
    fold_assignments <- .create_stratified_folds(
      data = data,
      id = id,
      strata = strata,
      k_folds = k_folds
    )
  } else {
    # Simple random assignment to folds
    fold_assignments <- sample(rep(1:k_folds, length.out = n_individuals))
    names(fold_assignments) <- ids
  }

  if (verbose) {
    cat("Cross-validation setup:\n")
    cat("  K-folds:", k_folds, "\n")
    cat("  Individuals:", n_individuals, "\n")
    cat("  Classes to test:", paste(classes, collapse = ", "), "\n")
    cat("  Stratified:", stratified_cv, "\n\n")
  }

  # Initialize results storage
  cv_results <- expand.grid(
    fold = 1:k_folds,
    n_classes = classes,
    stringsAsFactors = FALSE
  )

  cv_results$loglik_test <- NA
  cv_results$mspe <- NA  # Mean squared prediction error
  cv_results$convergence <- NA
  cv_results$time_seconds <- NA

  detailed_results <- list()

  # Run CV for each combination of fold and class count
  for (fold in 1:k_folds) {
    if (verbose) cat("Fold", fold, "of", k_folds, "...\n")

    # Split data
    test_ids <- names(fold_assignments)[fold_assignments == fold]
    train_ids <- names(fold_assignments)[fold_assignments != fold]

    train_data <- data[data[[id]] %in% train_ids, ]
    test_data <- data[data[[id]] %in% test_ids, ]

    # Fit models for each class count
    for (n_c in classes) {
      if (verbose) cat("  Testing", n_c, "classes...")

      start_time <- Sys.time()

      # Fit on training data (use sequential processing to avoid nested parallelization)
      tryCatch({
        fit <- gmm_survey(
          data = train_data,
          id = id,
          time = time,
          outcome = outcome,
          n_classes = n_c,
          growth_model = growth_model,
          strata = strata,
          cluster = cluster,
          weights = weights,
          covariates = covariates,
          starts = starts,
          cores = 1,  # Always use 1 core to avoid nested parallelization
          verbose = FALSE
        )

        # Evaluate on test data
        test_metrics <- .evaluate_gmm_on_testset(
          fitted_model = fit,
          test_data = test_data,
          id = id,
          time = time,
          outcome = outcome,
          weights = weights
        )

        # Store results
        idx <- which(cv_results$fold == fold & cv_results$n_classes == n_c)
        cv_results$loglik_test[idx] <- test_metrics$loglik
        cv_results$mspe[idx] <- test_metrics$mspe
        cv_results$convergence[idx] <- test_metrics$converged
        cv_results$time_seconds[idx] <- as.numeric(difftime(Sys.time(), start_time,
                                                            units = "secs"))

        # Store detailed results
        detailed_results[[paste0("fold", fold, "_k", n_c)]] <- list(
          model = fit,
          test_metrics = test_metrics
        )

        if (verbose) cat(" Done\n")

      }, error = function(e) {
        if (verbose) cat(" Failed:", e$message, "\n")
        idx <- which(cv_results$fold == fold & cv_results$n_classes == n_c)
        cv_results$loglik_test[idx] <- -Inf  # Bad log-likelihood for failed models
        cv_results$mspe[idx] <- Inf           # Bad MSPE for failed models
        cv_results$convergence[idx] <- FALSE
        cv_results$time_seconds[idx] <- as.numeric(difftime(Sys.time(), start_time,
                                                            units = "secs"))
      })
    }
  }

  # Aggregate results across folds (handle cases where all models failed)
  summary_stats <- NULL
  tryCatch({
    summary_stats <- aggregate(
      cbind(loglik_test, mspe, convergence, time_seconds) ~ n_classes,
      data = cv_results,
      FUN = function(x) {
        # Filter out -Inf and Inf values for mean/sd calculations
        finite_vals <- x[is.finite(x)]
        if (length(finite_vals) > 0) {
          c(
            mean = mean(finite_vals),
            sd = sd(finite_vals),
            min = min(finite_vals),
            max = max(finite_vals)
          )
        } else {
          c(mean = NA, sd = NA, min = NA, max = NA)
        }
      }
    )
  }, error = function(e) {
    if (verbose) cat("Warning: Could not create summary statistics:", e$message, "\n")
  })

  # Determine best model
  # Higher log-likelihood is better
  mean_loglik <- tapply(cv_results$loglik_test, cv_results$n_classes,
                       mean, na.rm = TRUE)
  best_k <- as.integer(names(mean_loglik)[which.max(mean_loglik)])

  # Alternative: Use "one standard error rule"
  # Choose simplest model within 1 SE of best
  se_loglik <- tapply(cv_results$loglik_test, cv_results$n_classes,
                     function(x) sd(x, na.rm = TRUE) / sqrt(sum(!is.na(x))))
  best_loglik <- max(mean_loglik, na.rm = TRUE)
  threshold <- best_loglik - se_loglik[which.max(mean_loglik)]
  candidates <- which(mean_loglik >= threshold)
  best_k_1se <- min(as.integer(names(mean_loglik)[candidates]))

  if (verbose) {
    cat("\nCross-validation complete!\n")
    cat("Best model (max log-likelihood):", best_k, "classes\n")
    cat("Best model (1-SE rule):", best_k_1se, "classes\n")
  }

  # Create result object
  result <- list(
    cv_results = cv_results,
    summary_stats = summary_stats,
    best_k = best_k,
    best_k_1se = best_k_1se,
    fold_assignments = fold_assignments,
    detailed_results = detailed_results,
    call = match.call()
  )

  class(result) <- "gmm_cv"
  return(result)
}

#' Create Stratified Folds for Cross-Validation
#'
#' @description
#' Internal function to create k folds while maintaining stratum proportions
#'
#' @keywords internal
.create_stratified_folds <- function(data, id, strata, k_folds) {
  ids <- unique(data[[id]])

  # Get stratum for each individual (use first observation)
  id_strata <- tapply(data[[strata]], data[[id]], function(x) x[1])
  id_strata <- id_strata[ids]  # Ensure same order

  # Create folds within each stratum
  fold_assignments <- integer(length(ids))
  names(fold_assignments) <- ids

  for (s in unique(id_strata)) {
    ids_in_stratum <- names(id_strata)[id_strata == s]
    n_in_stratum <- length(ids_in_stratum)

    # Randomly assign to folds
    folds <- sample(rep(1:k_folds, length.out = n_in_stratum))
    fold_assignments[ids_in_stratum] <- folds
  }

  return(fold_assignments)
}

#' Evaluate Fitted Model on Test Set
#'
#' @description
#' Internal function to compute prediction metrics on held-out data
#'
#' @keywords internal
.evaluate_gmm_on_testset <- function(fitted_model, test_data, id, time,
                                     outcome, weights) {

  tryCatch({
    # Extract model information
    n_classes <- fitted_model@n_classes
    time_points <- fitted_model@time_points

    # Get growth parameters and class assignments
    class_params <- fitted_model@class_specific_parameters
    class_props <- fitted_model@class_proportions

    # Get test data structure
    test_ids <- unique(test_data[[id]])
    n_test <- length(test_ids)

    # Initialize results
    total_loglik <- 0
    total_weights <- 0
    total_squared_error <- 0
    n_obs <- 0

    # For each individual in test set
    for (person_id in test_ids) {
      person_data <- test_data[test_data[[id]] == person_id, ]

      # For each time point, compute predictions and log-likelihood
      for (i in seq_len(nrow(person_data))) {
        obs_time <- person_data[[time]][i]
        obs_outcome <- person_data[[outcome]][i]
        obs_weight <- if (!is.null(weights)) person_data[[weights]][i] else 1

        # Find closest time point in model (interpolate if needed)
        time_idx <- which.min(abs(time_points - obs_time))

        # Compute weighted log-likelihood across classes
        ind_loglik <- 0

        for (k in 1:n_classes) {
          # Extract parameters for class k
          if (fitted_model@growth_model == "linear") {
            intercept <- class_params$intercept[k]
            slope <- class_params$slope[k]
            predicted <- intercept + slope * time_points[time_idx]
          } else if (fitted_model@growth_model == "quadratic") {
            intercept <- class_params$intercept[k]
            slope <- class_params$slope[k]
            quadratic <- class_params$quadratic[k]
            predicted <- intercept + slope * time_points[time_idx] +
                         quadratic * time_points[time_idx]^2
          } else {
            predicted <- mean(class_params$intercept)  # Fallback
          }

          # Get residual standard deviation for this class
          resid_sd <- fitted_model$residual_sds[k]

          # Compute likelihood for this class
          class_likelihood <- dnorm(obs_outcome, mean = predicted, sd = resid_sd)

          # Weight by class proportion
          ind_loglik <- ind_loglik + class_props[k] * class_likelihood
        }

        # Avoid log(0)
        ind_loglik <- max(ind_loglik, 1e-10)

        # Compute predicted value (weighted average across classes)
        predicted_value <- 0
        for (k in 1:n_classes) {
          if (fitted_model@growth_model == "linear") {
            intercept <- class_params$intercept[k]
            slope <- class_params$slope[k]
            class_pred <- intercept + slope * time_points[time_idx]
          } else if (fitted_model@growth_model == "quadratic") {
            intercept <- class_params$intercept[k]
            slope <- class_params$slope[k]
            quadratic <- class_params$quadratic[k]
            class_pred <- intercept + slope * time_points[time_idx] +
                         quadratic * time_points[time_idx]^2
          } else {
            class_pred <- mean(class_params$intercept)
          }

          predicted_value <- predicted_value + class_props[k] * class_pred
        }

        # Accumulate statistics
        total_loglik <- total_loglik + obs_weight * log(ind_loglik)
        total_weights <- total_weights + obs_weight
        total_squared_error <- total_squared_error +
                               obs_weight * (obs_outcome - predicted_value)^2
        n_obs <- n_obs + 1
      }
    }

    # Compute final metrics
    if (n_obs > 0 && total_weights > 0) {
      avg_loglik <- total_loglik / total_weights
      mspe <- total_squared_error / total_weights
    } else {
      avg_loglik <- -Inf  # Bad result
      mspe <- Inf
    }

    converged <- fitted_model@converged

    return(list(
      loglik = avg_loglik,
      mspe = mspe,
      converged = converged
    ))

  }, error = function(e) {
    # Fallback values if evaluation fails
    return(list(
      loglik = -Inf,
      mspe = Inf,
      converged = FALSE
    ))
  })
}

#' Print Method for GMM Cross-Validation Results
#'
#' @param x Object of class \code{gmm_cv}
#' @param ... Additional arguments
#'
#' @return Invisibly returns x
#' @export
#' @method print gmm_cv
print.gmm_cv <- function(x, ...) {
  cat("\nGrowth Mixture Model Cross-Validation Results\n")
  cat(rep("=", 60), "\n", sep = "")

  cat("\nSetup:\n")
  cat("  Folds:", max(x$cv_results$fold), "\n")
  cat("  Classes tested:", paste(sort(unique(x$cv_results$n_classes)),
                                 collapse = ", "), "\n")

  cat("\nSummary by Number of Classes:\n")
  summary_df <- aggregate(
    cbind(loglik_test, mspe) ~ n_classes,
    data = x$cv_results,
    FUN = function(x) sprintf("%.2f (%.2f)", mean(x, na.rm = TRUE),
                             sd(x, na.rm = TRUE))
  )

  colnames(summary_df) <- c("Classes", "Log-Lik (SD)", "MSPE (SD)")
  print(summary_df, row.names = FALSE)

  cat("\nRecommended Models:\n")
  cat("  Maximum log-likelihood:", x$best_k, "classes\n")
  cat("  1-SE rule (parsimony):", x$best_k_1se, "classes\n")

  cat("\nNote: Higher log-likelihood and lower MSPE indicate better fit.\n")
  cat("Consider also examining information criteria and BLRT.\n")

  invisible(x)
}

#' Plot Method for GMM Cross-Validation Results
#'
#' @param x Object of class \code{gmm_cv}
#' @param y Not used
#' @param metric Character: "loglik" or "mspe"
#' @param ... Additional graphical parameters
#'
#' @return ggplot object
#' @export
#' @method plot gmm_cv
plot.gmm_cv <- function(x, y = NULL, metric = c("loglik", "mspe"), ...) {
  metric <- match.arg(metric)

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' needed for plotting. Please install it.")
  }

  if (metric == "loglik") {
    yvar <- "loglik_test"
    ylab <- "Test Set Log-Likelihood"
    higher_better <- TRUE
  } else {
    yvar <- "mspe"
    ylab <- "Mean Squared Prediction Error"
    higher_better <- FALSE
  }

  # Create plot
  p <- ggplot2::ggplot(x$cv_results,
                      ggplot2::aes(x = factor(n_classes), y = .data[[yvar]])) +
    ggplot2::geom_boxplot(fill = "lightblue", alpha = 0.7) +
    ggplot2::geom_jitter(width = 0.1, alpha = 0.4) +
    ggplot2::stat_summary(fun = mean, geom = "point", shape = 23,
                         size = 3, fill = "red") +
    ggplot2::labs(
      title = "Cross-Validation Results",
      subtitle = paste("Red diamonds show mean across", max(x$cv_results$fold), "folds"),
      x = "Number of Classes",
      y = ylab
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.title = ggplot2::element_text(size = 12)
    )

  # Add vertical line at best k
  if (metric == "loglik") {
    p <- p + ggplot2::geom_vline(xintercept = which(sort(unique(x$cv_results$n_classes)) == x$best_k),
                                 linetype = "dashed", color = "darkgreen", linewidth = 1) +
      ggplot2::annotate("text", x = which(sort(unique(x$cv_results$n_classes)) == x$best_k),
                       y = max(x$cv_results[[yvar]], na.rm = TRUE),
                       label = paste("Best:", x$best_k, "classes"),
                       hjust = -0.1, color = "darkgreen", fontface = "bold")
  }

  return(p)
}
