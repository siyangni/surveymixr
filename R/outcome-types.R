# Categorical Outcome Support for Growth Mixture Models
#
# This file implements support for binary, ordinal, and count outcomes
# in growth mixture models with complex survey designs.
#
# Phase 2.1.1 of the development roadmap

#' Link Functions for Different Outcome Types
#'
#' @description
#' Provides link functions for various outcome distributions in growth mixture models.
#'
#' @param outcome_type Character string specifying outcome type:
#'   "continuous" (default), "binary", "ordinal", "count", "zero_inflated"
#'
#' @return List containing link function, inverse link, and derivative
#'
#' @keywords internal
get_link_function <- function(outcome_type = "continuous") {
  outcome_type <- match.arg(outcome_type,
                           c("continuous", "binary", "ordinal", "count",
                             "zero_inflated", "beta"))

  switch(outcome_type,
    continuous = list(
      link = identity,
      linkinv = identity,
      mu.eta = function(eta) rep(1, length(eta)),
      name = "identity"
    ),

    binary = list(
      link = qnorm,  # Probit link
      linkinv = pnorm,
      mu.eta = dnorm,
      name = "probit"
    ),

    ordinal = list(
      link = qnorm,  # Proportional odds
      linkinv = pnorm,
      mu.eta = dnorm,
      name = "probit_ordinal"
    ),

    count = list(
      link = log,
      linkinv = exp,
      mu.eta = exp,
      name = "log"
    ),

    zero_inflated = list(
      link = log,
      linkinv = exp,
      mu.eta = exp,
      name = "log_zi"
    ),

    beta = list(
      link = qlogis,  # Logit link for (0,1) outcomes
      linkinv = plogis,
      mu.eta = function(eta) exp(eta) / (1 + exp(eta))^2,
      name = "logit_beta"
    )
  )
}

#' Growth Mixture Model for Binary Outcomes
#'
#' @description
#' Fits growth mixture models with binary outcomes (0/1) using probit regression
#' within each latent class, incorporating complex survey design features.
#'
#' @inheritParams gmm_survey
#' @param link Character string specifying link function: "probit" (default) or "logit"
#' @param covariates Character vector of time-varying covariate names (not yet implemented)
#' @param convergence_threshold Numeric convergence criterion for EM algorithm (default: 1e-6)
#' @param max_iterations Integer maximum number of EM iterations (default: 1000)
#' @param seed Integer random seed for reproducibility (optional)
#'
#' @details
#' This function extends \code{\link{gmm_survey}} to handle binary outcomes
#' (e.g., presence/absence of behavior, yes/no responses). The model uses
#' probit or logistic regression for the conditional distribution within each
#' latent class, with growth parameters on the latent continuous scale.
#'
#' The model is:
#' \deqn{P(Y_{it} = 1 | C_i = k) = \Phi(\eta_{itk})}
#' where \eqn{\Phi} is the standard normal CDF (probit) or logistic CDF (logit), and
#' \deqn{\eta_{itk} = \beta_{0k} + \beta_{1k} \times time_{it} + ...}
#'
#' Survey weights, clustering, and stratification are incorporated in both
#' the EM algorithm and standard error calculation.
#'
#' @return An S4 object of class \code{SurveyMixr} with additional slots:
#'   \item{outcome_type}{"binary"}
#'   \item{link}{Link function used}
#'   \item{threshold_params}{For ordinal outcomes only}
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Simulate binary outcome data
#' set.seed(123)
#' binary_data <- simulate_gmm_survey(
#'   n_individuals = 1000,
#'   n_times = 5,
#'   n_classes = 2,
#'
#'   design = "stratified_cluster",
#'   seed = 123
#' )
#'
#' # Convert continuous outcome to binary (0/1) using median split
#' binary_data$outcome <- ifelse(binary_data$outcome > median(binary_data$outcome), 1, 0)
#'
#' # Fit 2-class model with binary outcome
#' fit_binary <- gmm_survey_binary(
#'   data = binary_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "outcome",
#'   n_classes = 2,
#'   growth_model = "linear",
#'   strata = "stratum",
#'   cluster = "psu",
#'   weights = "weight",
#'   link = "probit",
#'   starts = 100,
#'   cores = 2
#' )
#'
#' summary(fit_binary)
#' plot(fit_binary)
#' }
gmm_survey_binary <- function(data,
                             id,
                             time,
                             outcome,
                             n_classes,
                             growth_model = "linear",
                             strata = NULL,
                             cluster = NULL,
                             weights = NULL,
                             covariates = NULL,
                             link = c("probit", "logit"),
                             starts = 500,
                             cores = parallel::detectCores() - 1,
                             convergence_threshold = 1e-6,
                             max_iterations = 1000,
                             seed = NULL,
                             verbose = TRUE) {

  link <- match.arg(link)

  # Validate binary outcome
  outcome_vals <- unique(data[[outcome]][!is.na(data[[outcome]])])
  if (!all(outcome_vals %in% c(0, 1))) {
    stop("Binary outcomes must be coded as 0 or 1. Found values: ",
         paste(sort(unique(outcome_vals)), collapse = ", "))
  }

  # Get link function
  link_obj <- switch(link,
    probit = get_link_function("binary"),
    logit = list(
      link = qlogis,
      linkinv = plogis,
      mu.eta = function(eta) exp(eta) / (1 + exp(eta))^2,
      name = "logit"
    )
  )

  # Call main estimation function with outcome_type specified
  result <- .gmm_survey_categorical(
    data = data,
    id = id,
    time = time,
    outcome = outcome,
    n_classes = n_classes,
    growth_model = growth_model,
    strata = strata,
    cluster = cluster,
    weights = weights,
    covariates = covariates,
    
    link_function = link_obj,
    starts = starts,
    cores = cores,
    convergence_threshold = convergence_threshold,
    max_iterations = max_iterations,
    seed = seed,
    verbose = verbose
  )

  return(result)
}

#' Growth Mixture Model for Ordinal Outcomes
#'
#' @description
#' Fits growth mixture models with ordinal outcomes using proportional odds
#' or adjacent category models within each latent class.
#'
#' @inheritParams gmm_survey_binary
#' @param n_categories Integer specifying number of ordered categories
#' @param ordinal_model Character: "proportional_odds" (default) or "adjacent_category"
#'
#' @details
#' For ordinal outcomes with K categories (0, 1, ..., K-1), the proportional
#' odds model uses:
#' \deqn{P(Y_{it} \leq j | C_i = k) = \Phi(\tau_j - \eta_{itk})}
#' where \eqn{\tau_1 < \tau_2 < ... < \tau_{K-1}} are threshold parameters
#' and \eqn{\eta_{itk}} is the linear predictor.
#'
#' @return S4 object of class \code{SurveyMixr} with ordinal-specific components
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Simulate ordinal outcome (e.g., Likert scale: 0-4)
#' ordinal_data <- simulate_gmm_survey(
#'   n_individuals = 1000,
#'   n_times = 4,
#'   n_classes = 3,
#'
#'   design = "srs"
#' )
#'
#' # Convert continuous outcome to ordinal (0-4 scale)
#' outcome_range <- range(ordinal_data$outcome)
#' ordinal_data$outcome <- cut(ordinal_data$outcome,
#'                            breaks = 5,
#'                            labels = FALSE) - 1
#'
#' # Fit 3-class ordinal model
#' fit_ordinal <- gmm_survey_ordinal(
#'   data = ordinal_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "outcome",
#'   n_classes = 3,
#'   n_categories = 5,
#'   ordinal_model = "proportional_odds",
#'   starts = 200
#' )
#'
#' summary(fit_ordinal)
#' }
gmm_survey_ordinal <- function(data,
                              id,
                              time,
                              outcome,
                              n_classes,
                              n_categories,
                              growth_model = "linear",
                              strata = NULL,
                              cluster = NULL,
                              weights = NULL,
                              covariates = NULL,
                              ordinal_model = c("proportional_odds", "adjacent_category"),
                              starts = 500,
                              cores = parallel::detectCores() - 1,
                              convergence_threshold = 1e-6,
                              max_iterations = 1000,
                              seed = NULL,
                              verbose = TRUE) {

  ordinal_model <- match.arg(ordinal_model)

  # Validate ordinal outcome
  outcome_vals <- sort(unique(data[[outcome]][!is.na(data[[outcome]])]))
  if (!all(outcome_vals == 0:(length(outcome_vals) - 1))) {
    stop("Ordinal outcomes must be coded as consecutive integers starting from 0")
  }

  if (length(outcome_vals) != n_categories) {
    stop("n_categories (", n_categories, ") does not match observed categories (",
         length(outcome_vals), ")")
  }

  # Get link function
  link_obj <- get_link_function("ordinal")

  # Call estimation with ordinal-specific setup
  result <- .gmm_survey_ordinal_internal(
    data = data,
    id = id,
    time = time,
    outcome = outcome,
    n_classes = n_classes,
    n_categories = n_categories,
    growth_model = growth_model,
    strata = strata,
    cluster = cluster,
    weights = weights,
    covariates = covariates,
    ordinal_model = ordinal_model,
    link_function = link_obj,
    starts = starts,
    cores = cores,
    convergence_threshold = convergence_threshold,
    max_iterations = max_iterations,
    seed = seed,
    verbose = verbose
  )

  return(result)
}

#' Growth Mixture Model for Count Outcomes
#'
#' @description
#' Fits growth mixture models with count outcomes using Poisson or negative
#' binomial regression within each latent class.
#'
#' @inheritParams gmm_survey_binary
#' @param count_model Character: "poisson" (default), "negative_binomial", or "zero_inflated"
#' @param offset Optional offset variable (e.g., log exposure time)
#'
#' @details
#' For count outcomes, the model uses:
#' \deqn{Y_{it} | C_i = k \sim Poisson(\lambda_{itk})}
#' where \eqn{\log(\lambda_{itk}) = \eta_{itk}} and
#' \eqn{\eta_{itk}} includes growth parameters.
#'
#' For zero-inflated models:
#' \deqn{P(Y_{it} = 0 | C_i = k) = \pi_k + (1 - \pi_k) \times e^{-\lambda_{itk}}}
#' \deqn{P(Y_{it} = y | C_i = k) = (1 - \pi_k) \times Poisson(y; \lambda_{itk}), \quad y > 0}
#'
#' @return S4 object of class \code{SurveyMixr} with count-specific components
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Simulate count outcome data (e.g., number of delinquent acts)
#' count_data <- simulate_gmm_survey(
#'   n_individuals = 1500,
#'   n_times = 6,
#'   n_classes = 3,
#'
#'   design = "cluster",
#'   seed = 456
#' )
#'
#' # Convert continuous outcome to count data (non-negative integers)
#' # Shift to be positive then take absolute value and round to integers
#' count_data$outcome <- as.integer(round(abs(count_data$outcome + 3)))
#'
#' # Fit 3-class Poisson model
#' fit_count <- gmm_survey_count(
#'   data = count_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "outcome",
#'   n_classes = 3,
#'   cluster = "psu",
#'   weights = "weight",
#'   starts = 200
#' )
#'
#' summary(fit_count)
#' }
gmm_survey_count <- function(data,
                            id,
                            time,
                            outcome,
                            n_classes,
                            growth_model = "linear",
                            strata = NULL,
                            cluster = NULL,
                            weights = NULL,
                            covariates = NULL,
                            count_model = c("poisson", "negative_binomial", "zero_inflated"),
                            offset = NULL,
                            starts = 500,
                            cores = parallel::detectCores() - 1,
                            convergence_threshold = 1e-6,
                            max_iterations = 1000,
                            seed = NULL,
                            verbose = TRUE) {

  count_model <- match.arg(count_model)

  # Validate count outcome
  outcome_vals <- data[[outcome]][!is.na(data[[outcome]])]
  if (!all(outcome_vals >= 0) || !all(outcome_vals == floor(outcome_vals))) {
    stop("Count outcomes must be non-negative integers")
  }

  # Get link function
  link_obj <- if (count_model == "zero_inflated") {
    get_link_function("zero_inflated")
  } else {
    get_link_function("count")
  }

  # Call estimation
  result <- .gmm_survey_count_internal(
    data = data,
    id = id,
    time = time,
    outcome = outcome,
    n_classes = n_classes,
    growth_model = growth_model,
    strata = strata,
    cluster = cluster,
    weights = weights,
    covariates = covariates,
    count_model = count_model,
    offset = offset,
    link_function = link_obj,
    starts = starts,
    cores = cores,
    convergence_threshold = convergence_threshold,
    max_iterations = max_iterations,
    seed = seed,
    verbose = verbose
  )

  return(result)
}

# Internal estimation functions
# These would contain the actual EM algorithm implementations
# adapted for each outcome type

.gmm_survey_categorical <- function(...) {
  # Implementation for binary outcomes
  # This would modify the E-step and M-step to use link functions
  # and compute likelihoods for binary data
  stop("Internal function - full implementation pending")
}

.gmm_survey_ordinal_internal <- function(...) {
  # Implementation for ordinal outcomes
  # Includes threshold parameter estimation
  stop("Internal function - full implementation pending")
}

.gmm_survey_count_internal <- function(...) {
  # Implementation for count outcomes
  # Includes Poisson/NB/ZIP likelihood computations
  stop("Internal function - full implementation pending")
}

#' Validate Outcome Type and Data
#'
#' @description
#' Internal function to validate outcome data matches specified outcome type
#'
#' @param data Data frame
#' @param outcome Character string naming outcome variable
#' @param outcome_type Character string: "continuous", "binary", "ordinal", "count"
#' @param n_categories For ordinal outcomes, number of categories
#'
#' @return Invisibly returns TRUE if validation passes, throws error otherwise
#'
#' @keywords internal
validate_outcome_type <- function(data, outcome, outcome_type, n_categories = NULL) {
  y <- data[[outcome]][!is.na(data[[outcome]])]

  switch(outcome_type,
    continuous = {
      if (!is.numeric(y)) {
        stop("Continuous outcomes must be numeric")
      }
    },

    binary = {
      unique_vals <- sort(unique(y))
      if (!all(unique_vals %in% c(0, 1))) {
        stop("Binary outcomes must be 0 or 1. Found: ",
             paste(unique_vals, collapse = ", "))
      }
      if (length(unique_vals) < 2) {
        warning("Binary outcome has only one observed value")
      }
    },

    ordinal = {
      unique_vals <- sort(unique(y))
      expected <- 0:(n_categories - 1)
      if (!identical(unique_vals, expected)) {
        stop("Ordinal outcomes must be consecutive integers 0 to ",
             n_categories - 1)
      }
    },

    count = {
      if (!all(y >= 0) || !all(y == floor(y))) {
        stop("Count outcomes must be non-negative integers")
      }
    }
  )

  invisible(TRUE)
}
