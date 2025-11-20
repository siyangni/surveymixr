#' Growth Mixture Models with Complex Survey Design
#'
#' @description
#' Fits growth mixture models for longitudinal data with full integration of
#' complex survey design features including stratification, clustering (PSUs),
#' and probability weights. Implements the EM algorithm with sandwich standard
#' errors for survey-adjusted inference.
#'
#' @param data Data frame in long format containing repeated measurements
#' @param id Character string specifying the individual ID variable name
#' @param time Character string specifying the time variable name
#' @param outcome Character string specifying the outcome variable name
#' @param n_classes Integer number of latent classes (default: 2)
#' @param growth_model Character string specifying growth model type:
#'   \code{"linear"} (default), \code{"quadratic"}, \code{"nonlinear"},
#'   or \code{"free_basis"}
#' @param strata Character string specifying stratification variable (optional)
#' @param cluster Character string specifying cluster/PSU variable (optional)
#' @param weights Character string specifying sampling weights variable (optional)
#' @param nest Logical indicating nested clustering (default: TRUE)
#' @param outcome_type Character string: \code{"continuous"} (default),
#'   \code{"count"}, \code{"binary"}, or \code{"ordinal"}
#' @param fixed_variances Logical, should residual variances be constrained
#'   equal across classes? (default: FALSE)
#' @param fixed_timescores Logical, should time scores be equal across classes?
#'   (default: TRUE)
#' @param predictors Character vector of time-varying predictor variable names
#'   (not yet implemented)
#' @param distal Character vector of distal outcome variable names (use with
#'   \code{r3step()} function)
#' @param auxiliary Character vector of auxiliary variable names for class
#'   membership prediction
#' @param starts Integer number of random starts (default: 500)
#' @param convergence Numeric convergence criterion (default: 1e-6)
#' @param max_iter Integer maximum number of EM iterations (default: 1000)
#' @param cores Integer number of CPU cores for parallel processing (default: 1)
#' @param verbose Logical, print progress messages? (default: TRUE)
#' @param keep_data Logical, store data in output object? (default: FALSE)
#' @param store_all_starts Logical, store results from all random starts?
#'   (default: TRUE). When TRUE (recommended for research), stores all random
#'   start results for convergence diagnostics with \code{diagnose_convergence()}.
#'   When FALSE (recommended for large N > 1000), only stores the best solution
#'   to reduce memory usage.
#' @param skip_validation Logical, skip automatic survey design validation?
#'   (default: FALSE). When FALSE (recommended), the function automatically
#'   validates survey design features (nested clusters, singleton strata, etc.)
#'   before estimation. Set to TRUE only if you've already validated your data
#'   with \code{\link{validate_survey_data}} or are certain your design is correct.
#' @param ... Additional arguments (reserved for future use)
#'
#' @return An S4 object of class \code{\linkS4class{SurveyMixr}} containing:
#' \describe{
#'   \item{parameters}{Class-specific growth parameters (means, variances)}
#'   \item{class_proportions}{Weighted and unweighted class proportions}
#'   \item{posterior_probs}{Posterior probabilities for each individual}
#'   \item{standard_errors}{Survey-adjusted standard errors}
#'   \item{fit_indices}{AIC, BIC, aBIC, entropy, log-likelihood}
#'   \item{convergence_info}{Convergence diagnostics from random starts}
#'   \item{survey_design}{Survey design information}
#' }
#'
#' @details
#' This function implements growth mixture modeling with full survey design
#' integration, a feature combination not available in other R packages. The
#' implementation uses:
#' \itemize{
#'   \item EM algorithm with survey weight integration in the likelihood
#'   \item Multiple random starts to avoid local maxima
#'   \item Sandwich standard errors for stratification and clustering
#'   \item FIML for missing data
#' }
#'
#' The function automatically converts data from long to wide format internally
#' for computational efficiency. Survey weights are normalized to sum to the
#' sample size.
#'
#' \strong{Reproducibility and Random Seeds:}
#' The EM algorithm uses multiple random starts (controlled by \code{starts}
#' parameter) to avoid local maxima. Each random start uses a different random
#' seed for better exploration of the parameter space. To ensure reproducibility,
#' use \code{set.seed()} before calling \code{gmm_survey()}. The function will
#' use the R random number generator state to initialize each random start
#' deterministically. Note that results may vary slightly across different
#' platforms or R versions due to numerical precision differences.
#'
#' For model selection across different numbers of classes, see
#' \code{\link{gmm_select}}. For analyzing auxiliary variables with
#' classification uncertainty correction, see \code{\link{r3step}}.
#'
#' @references
#' Muthén, B. (2004). Latent variable analysis: Growth mixture modeling and
#' related techniques for longitudinal data. In D. Kaplan (Ed.),
#' \emph{Handbook of quantitative methodology for the social sciences}
#' (pp. 345-368). Sage Publications.
#'
#' Asparouhov, T., & Muthén, B. (2014). Auxiliary variables in mixture modeling:
#' Three-step approaches using Mplus. \emph{Structural Equation Modeling:
#' A Multidisciplinary Journal, 21}(3), 329-341.
#'
#' Lumley, T. (2010). \emph{Complex surveys: A guide to analysis using R}.
#' John Wiley & Sons.
#'
#' @examples
#' \donttest{
#' # Load simulated data
#' data(mcs_simulated)
#'
#' # Set seed for reproducibility
#' set.seed(123)
#'
#' # Fit 3-class model with survey design
#' fit <- gmm_survey(
#'   data = mcs_simulated,
#'   id = "id",
#'   time = "age",
#'   outcome = "selfcontrol",
#'   n_classes = 3,
#'   growth_model = "linear",
#'   strata = "stratum",
#'   cluster = "psu",
#'   weights = "weight",
#'   starts = 500,
#'   cores = 4
#' )
#'
#' # View results
#' summary(fit)
#' plot(fit, type = "trajectories")
#'
#' # Check convergence
#' diagnose_convergence(fit)
#' }
#'
#' @export
#' @import methods
#' @importFrom stats reshape
#' @importFrom parallel makeCluster stopCluster clusterExport parLapply
gmm_survey <- function(data,
                       id,
                       time,
                       outcome,
                       n_classes = 2,
                       growth_model = "linear",
                       strata = NULL,
                       cluster = NULL,
                       weights = NULL,
                       nest = TRUE,
                       outcome_type = "continuous",
                       fixed_variances = FALSE,
                       fixed_timescores = TRUE,
                       predictors = NULL,
                       distal = NULL,
                       auxiliary = NULL,
                       starts = 500,
                       convergence = 1e-6,
                       max_iter = 1000,
                       cores = 1,
                       verbose = TRUE,
                       keep_data = FALSE,
                       store_all_starts = TRUE,
                       skip_validation = FALSE,
                       ...) {

  # Record start time
  start_time <- Sys.time()

  # Store function call
  call <- match.call()

  # ============================================================================
  # Input Validation
  # ============================================================================
  if (verbose) message("Validating inputs...")

  if (!is.data.frame(data)) {
    stop("'data' must be a data frame")
  }

  required_vars <- c(id, time, outcome)
  missing_vars <- setdiff(required_vars, names(data))
  if (length(missing_vars) > 0) {
    stop("Variables not found in data: ", paste(missing_vars, collapse = ", "))
  }

  if (n_classes < 1) {
    stop("'n_classes' must be at least 1")
  }

  if (!growth_model %in% c("linear", "quadratic", "nonlinear", "free_basis")) {
    stop("'growth_model' must be one of: linear, quadratic, nonlinear, free_basis")
  }

  if (outcome_type != "continuous") {
    stop("Only continuous outcomes currently implemented. Other types coming soon.")
  }

  # ============================================================================
  # Survey Design Validation
  # ============================================================================
  # Auto-validate survey design unless skipped
  if (!skip_validation && (!is.null(strata) || !is.null(cluster) || !is.null(weights))) {
    if (verbose) message("Validating survey design...")

    validation <- validate_survey_data(
      data = data,
      id = id,
      time = time,
      outcome = outcome,
      strata = strata,
      cluster = cluster,
      weights = weights,
      verbose = FALSE
    )

    # Stop on errors
    if (length(validation@errors) > 0) {
      stop("Survey design validation failed. Errors:\n  ",
           paste(validation@errors, collapse = "\n  "),
           "\n\nRun validate_survey_data() for detailed diagnostics, ",
           "or set skip_validation=TRUE to bypass (not recommended).")
    }

    # Warn on warnings (show up to 3)
    if (length(validation@warnings) > 0 && verbose) {
      n_warn <- min(3, length(validation@warnings))
      warning("Survey design warnings:\n  ",
              paste(validation@warnings[1:n_warn], collapse = "\n  "),
              if (length(validation@warnings) > 3) {
                paste0("\n  ... and ", length(validation@warnings) - 3, " more warnings")
              } else {
                ""
              },
              "\n\nRun validate_survey_data() for full details.",
              call. = FALSE)
    }
  }

  # ============================================================================
  # Data Preparation
  # ============================================================================
  if (verbose) message("Preparing data...")

  # Extract relevant columns
  data_long <- data[, c(id, time, outcome,
                       strata, cluster, weights,
                       auxiliary), drop = FALSE]

  # Remove rows with missing outcome
  data_long <- data_long[!is.na(data_long[[outcome]]), ]

  # Convert to wide format for EM algorithm
  formula_wide <- as.formula(paste(id, "~", time))

  y_wide <- reshape(data_long[, c(id, time, outcome)],
                   idvar = id,
                   timevar = time,
                   direction = "wide",
                   v.names = outcome,
                   sep = "_")

  # Extract time scores
  time_vars <- grep(paste0("^", outcome, "_"), names(y_wide), value = TRUE)
  time_scores <- as.numeric(sub(paste0("^", outcome, "_"), "", time_vars))

  # Sort by time
  time_order <- order(time_scores)
  time_scores <- time_scores[time_order]
  y_wide <- y_wide[, c(id, time_vars[time_order]), drop = FALSE]

  # Convert to matrix (just outcomes)
  id_vec <- y_wide[[id]]
  y_matrix <- as.matrix(y_wide[, -1, drop = FALSE])
  rownames(y_matrix) <- id_vec

  n <- nrow(y_matrix)
  n_times <- ncol(y_matrix)

  if (verbose) {
    message(sprintf("  N = %d individuals", n))
    message(sprintf("  T = %d time points", n_times))
    message(sprintf("  Time scores: %s", paste(time_scores, collapse = ", ")))
  }

  # ============================================================================
  # Survey Design Setup
  # ============================================================================
  survey_weights <- NULL
  survey_strata <- NULL
  survey_cluster <- NULL

  if (!is.null(weights)) {
    # Match weights to wide format
    weight_data <- unique(data_long[, c(id, weights)])
    survey_weights <- weight_data[[weights]][match(id_vec, weight_data[[id]])]

    if (any(is.na(survey_weights))) {
      stop("Missing values in weights variable")
    }

    if (any(survey_weights <= 0)) {
      stop("Weights must be positive")
    }

    if (verbose) {
      message(sprintf("  Survey weights: range = [%.2f, %.2f], mean = %.2f",
                     min(survey_weights), max(survey_weights),
                     mean(survey_weights)))
    }
  }

  if (!is.null(strata)) {
    strata_data <- unique(data_long[, c(id, strata)])
    survey_strata <- strata_data[[strata]][match(id_vec, strata_data[[id]])]

    if (verbose) {
      message(sprintf("  Stratification: %d strata", length(unique(survey_strata))))
    }
  }

  if (!is.null(cluster)) {
    cluster_data <- unique(data_long[, c(id, cluster)])
    survey_cluster <- cluster_data[[cluster]][match(id_vec, cluster_data[[id]])]

    if (verbose) {
      message(sprintf("  Clustering: %d clusters (PSUs)", length(unique(survey_cluster))))
    }
  }

  # ============================================================================
  # Multiple Random Starts
  # ============================================================================
  if (verbose) {
    message(sprintf("\nRunning %d random starts with %d classes...", starts, n_classes))
  }

  # Function to run single start
  run_single_start <- function(start_num) {
    result <- tryCatch({
      em_algorithm_gmm(
        y_wide = y_matrix,
        time_scores = time_scores,
        n_classes = n_classes,
        growth_model = growth_model,
        weights = survey_weights,
        strata = survey_strata,
        cluster = survey_cluster,
        fixed_variances = fixed_variances,
        fixed_timescores = fixed_timescores,
        starting_values = NULL,  # Random initialization
        max_iter = max_iter,
        tolerance = convergence,
        verbose = FALSE
      )
    }, error = function(e) {
      return(list(loglik = -Inf, converged = FALSE, error = as.character(e)))
    })

    return(result)
  }

  # Parallel execution
  if (cores > 1 && starts > 1) {
    if (verbose) message(sprintf("  Using %d cores for parallel processing", cores))

    cl <- makeCluster(cores)
    on.exit(stopCluster(cl), add = TRUE)

    # Export necessary functions and data
    clusterExport(cl, c("em_algorithm_gmm", "e_step_gmm", "m_step_gmm",
                       "initialize_parameters_gmm", "predict_trajectory",
                       "compute_weighted_loglik", "log_sum_exp"),
                 envir = environment())

    results_all <- parLapply(cl, 1:starts, run_single_start)

  } else {
    # Sequential execution
    results_all <- lapply(1:starts, function(i) {
      if (verbose && i %% 50 == 0) {
        message(sprintf("  Completed %d/%d starts", i, starts))
      }
      run_single_start(i)
    })
  }

  # ============================================================================
  # Select Best Solution
  # ============================================================================
  if (verbose) message("\nSelecting best solution...")

  logliks <- sapply(results_all, function(x) {
    if (is.null(x$loglik)) return(-Inf)
    x$loglik
  })

  converged_flags <- sapply(results_all, function(x) {
    if (is.null(x$converged)) return(FALSE)
    x$converged
  })

  # Check if any valid results exist
  if (!any(is.finite(logliks))) {
    # Collect error messages
    errors <- sapply(results_all, function(x) {
      if (!is.null(x$error)) return(x$error) else return(NA)
    })
    unique_errors <- unique(errors[!is.na(errors)])

    error_msg <- "All random starts failed to produce valid results.\n"
    if (length(unique_errors) > 0) {
      error_msg <- paste0(error_msg, "\nErrors encountered:\n")
      for (i in seq_along(unique_errors)) {
        error_msg <- paste0(error_msg, sprintf("  %d. %s\n", i, unique_errors[i]))
      }
    }
    error_msg <- paste0(error_msg, "\nThis may indicate:\n",
                       "  - Data issues (e.g., insufficient variability)\n",
                       "  - Model specification problems\n",
                       "  - Too many latent classes for the data\n",
                       "Check your data and consider:\n",
                       "  - Reducing n_classes\n",
                       "  - Checking for missing data patterns\n",
                       "  - Verifying survey weights are valid")
    stop(error_msg)
  }

  best_loglik <- max(logliks[is.finite(logliks)])
  best_idx <- which.max(logliks)
  best_result <- results_all[[best_idx]]

  # Count replications
  replication_tolerance <- 1e-4
  n_replications <- sum(abs(logliks - best_loglik) < replication_tolerance, na.rm = TRUE)

  if (verbose) {
    message(sprintf("  Best logLik: %.4f", best_loglik))
    message(sprintf("  Replicated %d times", n_replications))
    message(sprintf("  %d/%d starts converged", sum(converged_flags), starts))
  }

  if (n_replications < 2) {
    warning("Best log-likelihood not replicated. Consider increasing 'starts'.")
  }

  # ============================================================================
  # Compute Survey-Adjusted Standard Errors
  # ============================================================================
  if (verbose) message("\nComputing survey-adjusted standard errors...")

  se_result <- compute_sandwich_se(
    y_matrix = y_matrix,
    time_scores = time_scores,
    parameters = best_result$parameters,
    posterior_probs = best_result$posterior_probs,
    weights = survey_weights,
    strata = survey_strata,
    cluster = survey_cluster,
    growth_model = growth_model,
    n_classes = n_classes
  )

  # ============================================================================
  # Compute Fit Indices
  # ============================================================================
  if (verbose) message("Computing fit indices...")

  n_params <- count_parameters(n_classes, growth_model, n_times,
                               fixed_variances, fixed_timescores)

  fit_indices <- compute_fit_indices(
    loglik = best_loglik,
    n_params = n_params,
    n_obs = n,
    posterior_probs = best_result$posterior_probs,
    weights = survey_weights
  )

  # ============================================================================
  # Class Assignments
  # ============================================================================
  class_assignments <- apply(best_result$posterior_probs, 1, which.max)

  # Class proportions (weighted and unweighted)
  if (!is.null(survey_weights)) {
    class_props_weighted <- colSums(best_result$weighted_posterior) / sum(survey_weights)
    class_props_unweighted <- colMeans(best_result$posterior_probs)
  } else {
    class_props_weighted <- colMeans(best_result$posterior_probs)
    class_props_unweighted <- class_props_weighted
  }

  # ============================================================================
  # Prepare Output
  # ============================================================================
  computation_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  if (verbose) {
    message(sprintf("\nCompleted in %.1f seconds", computation_time))
  }

  # Create S4 object
  output <- new("SurveyMixr",
    call = call,
    model_info = list(
      n_classes = n_classes,
      growth_model = growth_model,
      n_obs = n,
      n_times = n_times,
      time_scores = time_scores,
      outcome_type = outcome_type,
      fixed_variances = fixed_variances,
      fixed_timescores = fixed_timescores,
      n_parameters = n_params,
      id_var = id,
      time_var = time,
      outcome_var = outcome
    ),
    parameters = best_result$parameters,
    class_proportions = list(
      weighted = class_props_weighted,
      unweighted = class_props_unweighted
    ),
    posterior_probs = best_result$posterior_probs,
    class_assignments = as.integer(class_assignments),
    standard_errors = se_result$standard_errors,
    vcov_matrix = se_result$vcov_matrix,
    fit_indices = fit_indices,
    convergence_info = list(
      converged = best_result$converged,
      iterations = best_result$iterations,
      n_starts = starts,
      n_replications = n_replications,
      best_loglik = best_loglik
    ),
    random_starts = if (store_all_starts) {
      list(
        logliks = logliks,
        converged = converged_flags
      )
    } else {
      list()  # Empty list to satisfy S4 slot requirement
    },
    survey_design = list(
      has_weights = !is.null(weights),
      has_strata = !is.null(strata),
      has_cluster = !is.null(cluster),
      nest = nest,
      weights = survey_weights,
      strata = survey_strata,
      cluster = survey_cluster
    ),
    data = data_long,
    computation_time = computation_time
  )

  return(output)
}


#' Count Number of Parameters
#' @keywords internal
#' @noRd
count_parameters <- function(n_classes, growth_model, n_times,
                             fixed_variances, fixed_timescores) {

  # Class proportions (K-1 free parameters)
  n_prop <- n_classes - 1

  # Growth parameters per class
  if (growth_model == "linear") {
    n_growth_per_class <- 2  # intercept, slope
  } else if (growth_model == "quadratic") {
    n_growth_per_class <- 3  # intercept, slope, quadratic
  } else if (growth_model == "free_basis") {
    n_growth_per_class <- 2 + (n_times - 2)  # intercept, slope, free time scores
  } else {
    n_growth_per_class <- 2
  }

  n_growth <- n_classes * n_growth_per_class

  # Residual variances
  n_var <- if (fixed_variances) 1 else n_classes

  # Total
  n_prop + n_growth + n_var
}
