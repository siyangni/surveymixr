#' S4 Class Definition for surveymixr Objects
#'
#' @description
#' The \code{SurveyMixr} class contains results from growth mixture model
#' estimation with complex survey design.
#'
#' @slot call The original function call
#' @slot model_info List containing model specifications
#' @slot parameters List of parameter estimates (class-specific growth parameters)
#' @slot class_proportions Weighted and unweighted class proportions
#' @slot posterior_probs Matrix of posterior probabilities (N x K)
#' @slot class_assignments Vector of most likely class assignments
#' @slot standard_errors List of standard errors (survey-adjusted)
#' @slot vcov_matrix Variance-covariance matrix with survey adjustment
#' @slot fit_indices List of fit statistics (logLik, AIC, BIC, aBIC, entropy)
#' @slot convergence_info List with convergence diagnostics
#' @slot random_starts List tracking all random starts
#' @slot survey_design List containing survey design information
#' @slot data Original data (optionally stored)
#' @slot computation_time Time taken for estimation
#'
#' @name SurveyMixr-class
#' @rdname SurveyMixr-class
#' @exportClass SurveyMixr
setClass("SurveyMixr",
  slots = c(
    call = "call",
    model_info = "list",
    parameters = "list",
    class_proportions = "list",
    posterior_probs = "matrix",
    class_assignments = "integer",
    standard_errors = "list",
    vcov_matrix = "matrix",
    fit_indices = "list",
    convergence_info = "list",
    random_starts = "list",
    survey_design = "list",
    data = "data.frame",
    computation_time = "numeric"
  ),
  prototype = list(
    model_info = list(),
    parameters = list(),
    class_proportions = list(),
    posterior_probs = matrix(),
    class_assignments = integer(),
    standard_errors = list(),
    vcov_matrix = matrix(),
    fit_indices = list(),
    convergence_info = list(),
    random_starts = list(),
    survey_design = list(),
    data = data.frame(),
    computation_time = numeric()
  ),
  validity = function(object) {
    errors <- character()

    # Check that essential slots are populated
    if (length(object@parameters) == 0) {
      errors <- c(errors, "parameters slot is empty")
    }

    if (nrow(object@posterior_probs) == 0) {
      errors <- c(errors, "posterior_probs matrix is empty")
    }

    # Check dimensionality consistency
    n_classes <- ncol(object@posterior_probs)
    if (length(object@class_proportions$weighted) != n_classes) {
      errors <- c(errors, "class_proportions length doesn't match number of classes")
    }

    if (length(errors) == 0) TRUE else errors
  }
)


#' S4 Class for Model Selection Results
#'
#' @description
#' The \code{SurveyMixrSelect} class contains results from model selection
#' across different numbers of latent classes.
#'
#' @slot comparison_table Data frame with fit indices for each class solution
#' @slot fitted_models List of fitted SurveyMixr objects
#' @slot blrt_results List containing BLRT test results
#' @slot recommended_classes Recommended number of classes based on criteria
#' @slot criteria Character vector of criteria used
#'
#' @name SurveyMixrSelect-class
#' @rdname SurveyMixrSelect-class
#' @exportClass SurveyMixrSelect
setClass("SurveyMixrSelect",
  slots = c(
    comparison_table = "data.frame",
    fitted_models = "list",
    blrt_results = "list",
    recommended_classes = "integer",
    criteria = "character"
  ),
  prototype = list(
    comparison_table = data.frame(),
    fitted_models = list(),
    blrt_results = list(),
    recommended_classes = integer(),
    criteria = character()
  ),
  validity = function(object) {
    errors <- character()

    # Validate recommended_classes is within range of fitted_models
    if (length(object@recommended_classes) > 0 && length(object@fitted_models) > 0) {
      max_classes <- length(object@fitted_models)
      if (any(object@recommended_classes < 1 | object@recommended_classes > max_classes)) {
        errors <- c(errors,
          sprintf("recommended_classes must be between 1 and %d", max_classes))
      }
    }

    # Validate fitted_models list structure
    if (length(object@fitted_models) > 0) {
      if (!all(sapply(object@fitted_models, function(x) inherits(x, "SurveyMixr")))) {
        errors <- c(errors, "All elements of fitted_models must be SurveyMixr objects")
      }
    }

    # Validate criteria is non-empty if comparison_table has data
    if (nrow(object@comparison_table) > 0 && length(object@criteria) == 0) {
      errors <- c(errors, "criteria must be specified when comparison_table is populated")
    }

    if (length(errors) == 0) TRUE else errors
  }
)


#' S4 Class for R3STEP Results
#'
#' @description
#' The \code{R3StepResults} class contains results from auxiliary variable
#' analysis using the R3STEP approach.
#'
#' @slot gmm_object Original SurveyMixr object
#' @slot distal_vars Character vector of distal variable names
#' @slot method R3STEP method used (BCH, ML, manual)
#' @slot class_means Matrix of class-specific means for distal variables
#' @slot standard_errors Matrix of standard errors
#' @slot test_results Data frame with omnibus and pairwise tests
#' @slot effect_sizes Matrix of effect sizes (Cohen's d)
#'
#' @name R3StepResults-class
#' @rdname R3StepResults-class
#' @exportClass R3StepResults
setClass("R3StepResults",
  slots = c(
    gmm_object = "SurveyMixr",
    distal_vars = "character",
    method = "character",
    class_means = "matrix",
    standard_errors = "matrix",
    test_results = "data.frame",
    effect_sizes = "matrix"
  ),
  prototype = list(
    gmm_object = new("SurveyMixr"),
    distal_vars = character(),
    method = character(),
    class_means = matrix(),
    standard_errors = matrix(),
    test_results = data.frame(),
    effect_sizes = matrix()
  ),
  validity = function(object) {
    errors <- character()

    # Validate method is one of the allowed values
    if (length(object@method) > 0) {
      allowed_methods <- c("BCH", "ML", "manual")
      if (!object@method %in% allowed_methods) {
        errors <- c(errors,
          sprintf("method must be one of: %s", paste(allowed_methods, collapse = ", ")))
      }
    }

    # Validate consistency between class_means and standard_errors dimensions
    if (length(object@class_means) > 0 && length(object@standard_errors) > 0) {
      if (!all(dim(object@class_means) == dim(object@standard_errors))) {
        errors <- c(errors,
          "class_means and standard_errors must have same dimensions")
      }
    }

    # Validate distal_vars matches class_means columns
    if (length(object@distal_vars) > 0 && ncol(object@class_means) > 0) {
      if (length(object@distal_vars) != ncol(object@class_means)) {
        errors <- c(errors,
          sprintf("Number of distal_vars (%d) must match class_means columns (%d)",
                  length(object@distal_vars), ncol(object@class_means)))
      }
    }

    if (length(errors) == 0) TRUE else errors
  }
)


#' S4 Class for Convergence Diagnostics
#'
#' @description
#' The \code{ConvergenceDiagnostics} class contains detailed convergence
#' information from multiple random starts.
#'
#' @slot loglik_table Data frame of log-likelihoods from all starts
#' @slot best_loglik Best (highest) log-likelihood achieved
#' @slot n_replications Number of times best solution was replicated
#' @slot local_maxima Data frame identifying local maxima
#' @slot convergence_plot ggplot object showing distribution
#' @slot warnings Character vector of convergence warnings
#' @slot recommendations Character vector of recommendations
#'
#' @name ConvergenceDiagnostics-class
#' @rdname ConvergenceDiagnostics-class
#' @exportClass ConvergenceDiagnostics
setClass("ConvergenceDiagnostics",
  slots = c(
    loglik_table = "data.frame",
    best_loglik = "numeric",
    n_replications = "integer",
    local_maxima = "data.frame",
    convergence_plot = "ANY",  # ggplot object
    warnings = "character",
    recommendations = "character"
  ),
  prototype = list(
    loglik_table = data.frame(),
    best_loglik = -Inf,
    n_replications = 0L,
    local_maxima = data.frame(),
    convergence_plot = NULL,
    warnings = character(0),
    recommendations = character(0)
  ),
  validity = function(object) {
    errors <- character()

    # Validate n_replications
    if (length(object@n_replications) > 0 && object@n_replications < 0) {
      errors <- c(errors, "n_replications must be non-negative")
    }

    # Validate best_loglik
    if (length(object@best_loglik) > 0 && is.finite(object@best_loglik) && object@best_loglik > 0) {
      errors <- c(errors, "best_loglik should be negative or -Inf")
    }

    # Validate consistency between components
    if (nrow(object@loglik_table) > 0 && object@n_replications > 0) {
      if (object@n_replications != nrow(object@loglik_table)) {
        errors <- c(errors,
          sprintf("n_replications (%d) does not match loglik_table rows (%d)",
                  object@n_replications, nrow(object@loglik_table)))
      }
    }

    if (length(errors) == 0) TRUE else errors
  }
)
