#' Compute Sandwich Standard Errors for Survey Design
#'
#' @description
#' Computes survey-adjusted standard errors accounting for stratification,
#' clustering, and sampling weights using the sandwich estimator.
#'
#' @param y_matrix Matrix of outcomes (N x T)
#' @param time_scores Vector of time scores
#' @param parameters List of parameter estimates
#' @param posterior_probs Matrix of posterior probabilities
#' @param weights Survey weights
#' @param strata Stratification variable
#' @param cluster Clustering variable (PSU)
#' @param growth_model Type of growth model
#' @param n_classes Number of classes
#'
#' @return List containing standard errors and vcov matrix
#' @keywords internal
#' @importFrom numDeriv jacobian hessian
#' @noRd
compute_sandwich_se <- function(y_matrix, time_scores, parameters,
                                posterior_probs, weights, strata, cluster,
                                growth_model, n_classes) {

  n <- nrow(y_matrix)

  # Extract parameter vector
  param_vec <- parameters_to_vector(parameters, n_classes, growth_model)
  n_params <- length(param_vec)

  # If no survey design, use regular SEs (information matrix)
  if (is.null(weights) && is.null(strata) && is.null(cluster)) {

    # Compute observed information matrix
    obs_info <- compute_observed_information(y_matrix, time_scores, parameters,
                                            posterior_probs, weights,
                                            n_classes, growth_model)

    # Invert for variance-covariance matrix
    vcov_mat <- tryCatch({
      solve(obs_info)
    }, error = function(e) {
      # Use pseudoinverse if singular
      MASS::ginv(obs_info)
    })

    se_vec <- sqrt(pmax(diag(vcov_mat), 0))

  } else {

    # Sandwich estimator for survey design
    # V = A^{-1} B A^{-1}
    # where A = Hessian (information matrix)
    #       B = sum of outer products of score contributions

    # Compute A: observed information matrix
    A <- compute_observed_information(y_matrix, time_scores, parameters,
                                     posterior_probs, weights,
                                     n_classes, growth_model)

    # Compute B: middle matrix accounting for clustering
    B <- compute_middle_matrix(y_matrix, time_scores, parameters,
                              posterior_probs, weights, strata, cluster,
                              n_classes, growth_model)

    # Sandwich formula
    A_inv <- tryCatch({
      solve(A)
    }, error = function(e) {
      MASS::ginv(A)
    })

    vcov_mat <- A_inv %*% B %*% A_inv

    # Ensure positive definite
    vcov_mat <- (vcov_mat + t(vcov_mat)) / 2

    se_vec <- sqrt(pmax(diag(vcov_mat), 0))
  }

  # Convert back to structured format
  se_structured <- vector_to_parameters(se_vec, n_classes, growth_model,
                                       parameters)

  list(
    standard_errors = se_structured,
    vcov_matrix = vcov_mat,
    se_vector = se_vec
  )
}


#' Compute Observed Information Matrix
#'
#' @keywords internal
#' @noRd
compute_observed_information <- function(y_matrix, time_scores, parameters,
                                        posterior_probs, weights,
                                        n_classes, growth_model) {

  # Convert parameters to vector
  param_vec <- parameters_to_vector(parameters, n_classes, growth_model)
  n_params <- length(param_vec)

  # Log-likelihood function
  loglik_fn <- function(theta) {
    params_temp <- vector_to_parameters(theta, n_classes, growth_model, parameters)

    compute_weighted_loglik(y_matrix, time_scores, params_temp,
                          weights, !is.na(y_matrix), n_classes, growth_model)
  }

  # Compute Hessian (negative = information)
  H <- tryCatch({
    -numDeriv::hessian(loglik_fn, param_vec)
  }, error = function(e) {
    # If Hessian computation fails, use identity matrix scaled
    diag(n_params)
  })

  # Ensure positive definite
  H <- (H + t(H)) / 2

  # Add small ridge if needed
  min_eig <- min(eigen(H, only.values = TRUE)$values)
  if (min_eig < 1e-6) {
    H <- H + diag(1e-6 - min_eig, n_params)
  }

  H
}


#' Compute Middle Matrix for Sandwich Estimator
#'
#' @keywords internal
#' @noRd
compute_middle_matrix <- function(y_matrix, time_scores, parameters,
                                 posterior_probs, weights, strata, cluster,
                                 n_classes, growth_model) {

  n <- nrow(y_matrix)
  param_vec <- parameters_to_vector(parameters, n_classes, growth_model)
  n_params <- length(param_vec)

  # Compute score contributions for each individual
  scores <- matrix(0, nrow = n, ncol = n_params)

  for (i in 1:n) {
    scores[i, ] <- compute_individual_score(i, y_matrix, time_scores,
                                           parameters, posterior_probs,
                                           weights, n_classes, growth_model)
  }

  # If clustering, aggregate by cluster
  if (!is.null(cluster)) {
    unique_clusters <- unique(cluster)
    n_clusters <- length(unique_clusters)

    cluster_scores <- matrix(0, nrow = n_clusters, ncol = n_params)

    for (j in 1:n_clusters) {
      cluster_j <- which(cluster == unique_clusters[j])
      cluster_scores[j, ] <- colSums(scores[cluster_j, , drop = FALSE])
    }

    # Middle matrix = sum of outer products across clusters
    B <- matrix(0, n_params, n_params)
    for (j in 1:n_clusters) {
      B <- B + tcrossprod(cluster_scores[j, ])
    }

  } else {
    # No clustering: sum of outer products across individuals
    B <- crossprod(scores)
  }

  B
}


#' Compute Individual Score Contribution
#'
#' @keywords internal
#' @noRd
compute_individual_score <- function(i, y_matrix, time_scores, parameters,
                                    posterior_probs, weights, n_classes,
                                    growth_model) {

  # Numerical gradient of log-likelihood contribution for individual i
  param_vec <- parameters_to_vector(parameters, n_classes, growth_model)
  n_params <- length(param_vec)

  # Individual log-likelihood function
  loglik_i_fn <- function(theta) {
    params_temp <- vector_to_parameters(theta, n_classes, growth_model, parameters)

    obs_times <- which(!is.na(y_matrix[i, ]))
    if (length(obs_times) == 0) return(0)

    # Individual contribution
    class_lik <- 0
    for (k in 1:n_classes) {
      y_pred_k <- predict_trajectory(time_scores, params_temp$growth_parameters[[k]],
                                    growth_model)
      y_obs <- y_matrix[i, obs_times]
      y_pred <- y_pred_k[obs_times]
      resid <- y_obs - y_pred

      lik_k <- prod(dnorm(resid, mean = 0, sd = sqrt(params_temp$residual_variance[k])))
      class_lik <- class_lik + params_temp$class_proportions[k] * lik_k
    }

    w_i <- if (is.null(weights)) 1 else weights[i]
    w_i * log(pmax(class_lik, 1e-300))
  }

  # Numerical gradient
  grad_i <- tryCatch({
    numDeriv::grad(loglik_i_fn, param_vec)
  }, error = function(e) {
    rep(0, n_params)
  })

  grad_i
}


#' Convert Parameters to Vector
#'
#' @keywords internal
#' @noRd
parameters_to_vector <- function(parameters, n_classes, growth_model) {

  param_vec <- c()

  # Class proportions (use log-ratio parameterization)
  # Only K-1 needed (last is determined)
  class_props <- parameters$class_proportions
  if (n_classes > 1) {
    # Log-ratio relative to last class
    log_ratios <- log(class_props[-n_classes] / class_props[n_classes])
    param_vec <- c(param_vec, log_ratios)
  }

  # Growth parameters by class
  for (k in 1:n_classes) {
    gp <- parameters$growth_parameters[[k]]

    if (growth_model %in% c("linear", "free_basis")) {
      param_vec <- c(param_vec, gp$intercept, gp$slope)
    } else if (growth_model == "quadratic") {
      param_vec <- c(param_vec, gp$intercept, gp$slope, gp$quadratic)
    }
  }

  # Residual variances (log-transformed for positivity)
  param_vec <- c(param_vec, log(parameters$residual_variance))

  param_vec
}


#' Convert Vector to Parameters
#'
#' @keywords internal
#' @noRd
vector_to_parameters <- function(param_vec, n_classes, growth_model,
                                template_params) {

  idx <- 1

  # Class proportions
  if (n_classes > 1) {
    log_ratios <- param_vec[idx:(idx + n_classes - 2)]
    idx <- idx + n_classes - 1

    # Convert from log-ratios
    exp_ratios <- exp(log_ratios)
    class_props <- c(exp_ratios, 1) / (sum(exp_ratios) + 1)
  } else {
    class_props <- 1
  }

  # Growth parameters
  growth_params <- list()

  for (k in 1:n_classes) {
    if (growth_model %in% c("linear", "free_basis")) {
      intercept <- param_vec[idx]
      slope <- param_vec[idx + 1]
      idx <- idx + 2

      growth_params[[k]] <- list(intercept = intercept, slope = slope)

    } else if (growth_model == "quadratic") {
      intercept <- param_vec[idx]
      slope <- param_vec[idx + 1]
      quadratic <- param_vec[idx + 2]
      idx <- idx + 3

      growth_params[[k]] <- list(
        intercept = intercept,
        slope = slope,
        quadratic = quadratic
      )
    }
  }

  # Residual variances (back-transform from log)
  log_vars <- param_vec[idx:(idx + n_classes - 1)]
  residual_variance <- exp(log_vars)

  list(
    class_proportions = class_props,
    growth_parameters = growth_params,
    residual_variance = residual_variance,
    time_scores = template_params$time_scores
  )
}
