#' Log-Sum-Exp Trick for Numerical Stability
#'
#' @description
#' Computes log(sum(exp(x))) in a numerically stable way by avoiding underflow.
#' Uses the identity: log(sum(exp(x))) = max(x) + log(sum(exp(x - max(x))))
#'
#' @param log_x Vector of log-probabilities
#' @return Scalar, the log of the sum of exponentials
#' @keywords internal
#' @noRd
log_sum_exp <- function(log_x) {
  # Handle edge cases
  if (length(log_x) == 0) return(-Inf)
  if (all(is.infinite(log_x) & log_x < 0)) return(-Inf)

  # Use max-trick for numerical stability
  max_log_x <- max(log_x[is.finite(log_x)])

  # If all values are -Inf except one, return that value
  if (all(is.infinite(log_x[log_x != max_log_x]) & log_x[log_x != max_log_x] < 0)) {
    return(max_log_x)
  }

  # Standard log-sum-exp computation
  max_log_x + log(sum(exp(log_x - max_log_x)))
}


#' Core EM Algorithm for Growth Mixture Models with Survey Weights
#'
#' @description
#' Internal function implementing the EM algorithm for growth mixture models
#' with complex survey design integration.
#'
#' @param y_wide Matrix of outcomes in wide format (N x T)
#' @param time_scores Vector of time scores (length T)
#' @param n_classes Number of latent classes
#' @param growth_model Type of growth model ("linear", "quadratic", "free_basis")
#' @param weights Survey weights (length N)
#' @param strata Stratification variable (length N)
#' @param cluster Clustering variable (PSU) (length N)
#' @param fixed_variances Logical, class-invariant residual variances?
#' @param fixed_timescores Logical, class-invariant time scores?
#' @param starting_values List of starting values (optional)
#' @param max_iter Maximum EM iterations
#' @param tolerance Convergence tolerance
#' @param verbose Print progress messages?
#'
#' @return List containing parameter estimates and posterior probabilities
#' @keywords internal
#' @noRd
em_algorithm_gmm <- function(y_wide,
                              time_scores,
                              n_classes,
                              growth_model = "linear",
                              weights = NULL,
                              strata = NULL,
                              cluster = NULL,
                              fixed_variances = FALSE,
                              fixed_timescores = TRUE,
                              starting_values = NULL,
                              max_iter = 1000,
                              tolerance = 1e-6,
                              verbose = FALSE) {

  # Setup
  n <- nrow(y_wide)
  n_times <- ncol(y_wide)

  # Default weights if not provided
  if (is.null(weights)) {
    weights <- rep(1, n)
  }
  weights <- weights / sum(weights) * n  # Normalize to sum to N

  # Initialize missing data pattern matrix
  r_matrix <- !is.na(y_wide)  # Response indicator matrix

  # Initialize parameters
  if (is.null(starting_values)) {
    params <- initialize_parameters_gmm(y_wide, time_scores, n_classes,
                                        growth_model, weights)
  } else {
    params <- starting_values
  }

  # EM iterations
  loglik_old <- -Inf
  converged <- FALSE

  for (iter in 1:max_iter) {

    # =========================================================================
    # E-STEP: Compute posterior probabilities
    # =========================================================================
    e_step_result <- e_step_gmm(y_wide, time_scores, params, weights,
                                r_matrix, n_classes, growth_model)

    posterior_probs <- e_step_result$posterior_probs
    weighted_posterior <- e_step_result$weighted_posterior

    # =========================================================================
    # M-STEP: Update parameters
    # =========================================================================
    params <- m_step_gmm(y_wide, time_scores, weighted_posterior,
                        posterior_probs, weights, r_matrix,
                        n_classes, growth_model,
                        fixed_variances, fixed_timescores)

    # =========================================================================
    # Compute log-likelihood (weighted)
    # =========================================================================
    loglik_new <- compute_weighted_loglik(y_wide, time_scores, params,
                                          weights, r_matrix, n_classes,
                                          growth_model)

    # Check convergence
    if (is.finite(loglik_old)) {
      rel_change <- abs((loglik_new - loglik_old) / (abs(loglik_old) + 1e-10))
    } else {
      rel_change <- Inf  # First iteration, no convergence yet
    }

    if (verbose && iter %% 10 == 0) {
      message(sprintf("Iteration %d: LogLik = %.4f, Rel. Change = %.6f",
                     iter, loglik_new, rel_change))
    }

    if (is.finite(rel_change) && rel_change < tolerance) {
      converged <- TRUE
      if (verbose) {
        message(sprintf("Converged after %d iterations", iter))
      }
      break
    }

    loglik_old <- loglik_new
  }

  # Warning if not converged
  if (!converged) {
    warning(sprintf("EM algorithm did not converge after %d iterations", max_iter))
  }

  # Return results
  list(
    parameters = params,
    posterior_probs = posterior_probs,
    weighted_posterior = weighted_posterior,
    loglik = loglik_new,
    iterations = iter,
    converged = converged
  )
}


#' Initialize Parameters for GMM
#'
#' @keywords internal
#' @noRd
initialize_parameters_gmm <- function(y_wide, time_scores, n_classes,
                                      growth_model, weights) {

  n <- nrow(y_wide)
  n_times <- ncol(y_wide)

  # Use k-means on available data for initial class assignment
  y_mean_per_person <- rowMeans(y_wide, na.rm = TRUE)

  # Weighted k-means approximation via sampling
  set.seed(sample.int(1e6, 1))  # Random seed for this start
  kmeans_result <- kmeans(y_mean_per_person[!is.na(y_mean_per_person)],
                         centers = n_classes,
                         nstart = 20)

  # Initialize class proportions (uniform with small perturbation)
  class_props <- rep(1/n_classes, n_classes) + rnorm(n_classes, 0, 0.01)
  class_props <- pmax(class_props, 0.01)  # Ensure positive
  class_props <- class_props / sum(class_props)

  # Initialize growth parameters by class
  growth_params <- list()

  for (k in 1:n_classes) {
    # Simple linear regression for each class
    if (growth_model == "linear") {
      # Intercept and slope
      growth_params[[k]] <- list(
        intercept = rnorm(1, mean(y_mean_per_person, na.rm = TRUE),
                         sd(y_mean_per_person, na.rm = TRUE) * 0.5),
        slope = rnorm(1, 0, 0.1)
      )
    } else if (growth_model == "quadratic") {
      growth_params[[k]] <- list(
        intercept = rnorm(1, mean(y_mean_per_person, na.rm = TRUE),
                         sd(y_mean_per_person, na.rm = TRUE) * 0.5),
        slope = rnorm(1, 0, 0.1),
        quadratic = rnorm(1, 0, 0.01)
      )
    } else if (growth_model == "free_basis") {
      growth_params[[k]] <- list(
        intercept = rnorm(1, mean(y_mean_per_person, na.rm = TRUE),
                         sd(y_mean_per_person, na.rm = TRUE) * 0.5),
        slope = rnorm(1, 0, 0.1)
      )
    }
  }

  # Initialize residual variance(s)
  overall_var <- var(as.vector(y_wide), na.rm = TRUE)
  residual_variance <- rep(overall_var * 0.5, n_classes)

  list(
    class_proportions = class_props,
    growth_parameters = growth_params,
    residual_variance = residual_variance,
    time_scores = time_scores
  )
}


#' E-Step: Compute Posterior Probabilities
#'
#' @description
#' Computes posterior class probabilities using Bayes' theorem.
#' All computations done in log-space for numerical stability.
#'
#' @keywords internal
#' @noRd
e_step_gmm <- function(y_wide, time_scores, params, weights, r_matrix,
                       n_classes, growth_model) {

  n <- nrow(y_wide)

  # Compute log class-specific densities (stay in log-space throughout!)
  log_class_densities <- matrix(-Inf, nrow = n, ncol = n_classes)

  for (k in 1:n_classes) {
    # Predicted trajectory for class k
    y_pred_k <- predict_trajectory(time_scores, params$growth_parameters[[k]],
                                  growth_model)

    # Log-likelihood for each person in class k (handling missing data)
    for (i in 1:n) {
      obs_times <- which(r_matrix[i, ])
      if (length(obs_times) > 0) {
        y_obs <- y_wide[i, obs_times]
        y_pred <- y_pred_k[obs_times]
        resid <- y_obs - y_pred

        # Normal log-density (STAY IN LOG-SPACE - no exp()!)
        # Sum of log-densities across observed time points
        log_class_densities[i, k] <- sum(dnorm(resid, mean = 0,
                                               sd = sqrt(params$residual_variance[k]),
                                               log = TRUE))
      } else {
        # No data for this person: log(1) = 0 (uniform density)
        log_class_densities[i, k] <- 0
      }
    }
  }

  # Posterior probabilities (Bayes' theorem) - all in log-space
  # log P(k|y_i) = log[P(y_i|k) * P(k)] - log[sum_k P(y_i|k) * P(k)]
  #              = log P(y_i|k) + log P(k) - log_sum_exp[log P(y_i|k) + log P(k)]

  log_class_props <- log(pmax(params$class_proportions, 1e-300))
  log_numerator <- sweep(log_class_densities, 2, log_class_props, "+")

  # Compute log denominator using log-sum-exp for numerical stability
  log_denominator <- apply(log_numerator, 1, log_sum_exp)

  # Log posterior probabilities
  log_posterior <- sweep(log_numerator, 1, log_denominator, "-")

  # Convert to probability scale only at the very end
  posterior_probs <- exp(log_posterior)

  # Handle any remaining numerical issues (shouldn't happen with log-sum-exp, but be safe)
  posterior_probs[!is.finite(posterior_probs)] <- 1 / n_classes
  posterior_probs <- sweep(posterior_probs, 1, rowSums(posterior_probs), "/")

  # Weighted posterior probabilities (for M-step with survey weights)
  weighted_posterior <- sweep(posterior_probs, 1, weights, "*")

  list(
    posterior_probs = posterior_probs,
    weighted_posterior = weighted_posterior
  )
}


#' M-Step: Update Parameters
#'
#' @keywords internal
#' @noRd
m_step_gmm <- function(y_wide, time_scores, weighted_posterior, posterior_probs,
                       weights, r_matrix, n_classes, growth_model,
                       fixed_variances, fixed_timescores) {

  n <- nrow(y_wide)
  n_times <- ncol(y_wide)

  # Update class proportions (weighted)
  class_props <- colSums(weighted_posterior) / sum(weights)
  class_props <- pmax(class_props, 1e-10)  # Avoid zero
  class_props <- class_props / sum(class_props)

  # Update growth parameters for each class
  growth_params <- list()

  for (k in 1:n_classes) {
    # Weighted least squares for class k
    w_k <- weighted_posterior[, k]

    # Stack all observations
    y_vec <- as.vector(t(y_wide))
    time_vec <- rep(time_scores, each = n)
    w_vec <- rep(w_k, times = n_times)
    r_vec <- as.vector(t(r_matrix))

    # Keep only observed data
    keep <- r_vec == 1
    y_fit <- y_vec[keep]
    time_fit <- time_vec[keep]
    w_fit <- w_vec[keep]

    # Fit growth model
    if (growth_model == "linear") {
      # y = intercept + slope * time
      X <- cbind(1, time_fit)
      beta <- solve(t(X * w_fit) %*% X + diag(1e-6, ncol(X))) %*%
              (t(X * w_fit) %*% y_fit)

      growth_params[[k]] <- list(
        intercept = beta[1],
        slope = beta[2]
      )

    } else if (growth_model == "quadratic") {
      # y = intercept + slope * time + quadratic * time^2
      X <- cbind(1, time_fit, time_fit^2)
      beta <- solve(t(X * w_fit) %*% X + diag(1e-6, ncol(X))) %*%
              (t(X * w_fit) %*% y_fit)

      growth_params[[k]] <- list(
        intercept = beta[1],
        slope = beta[2],
        quadratic = beta[3]
      )

    } else if (growth_model == "free_basis") {
      # Simplified: still use linear for now, would need more complex estimation
      X <- cbind(1, time_fit)
      beta <- solve(t(X * w_fit) %*% X + diag(1e-6, ncol(X))) %*%
              (t(X * w_fit) %*% y_fit)

      growth_params[[k]] <- list(
        intercept = beta[1],
        slope = beta[2]
      )
    }
  }

  # Update residual variances
  residual_variance <- numeric(n_classes)

  for (k in 1:n_classes) {
    y_pred_k <- predict_trajectory(time_scores, growth_params[[k]], growth_model)
    w_k <- weighted_posterior[, k]

    ss_resid <- 0
    n_obs <- 0

    for (i in 1:n) {
      obs_times <- which(r_matrix[i, ])
      if (length(obs_times) > 0) {
        resid <- y_wide[i, obs_times] - y_pred_k[obs_times]
        ss_resid <- ss_resid + w_k[i] * sum(resid^2)
        n_obs <- n_obs + w_k[i] * length(obs_times)
      }
    }

    residual_variance[k] <- max(ss_resid / n_obs, 1e-6)  # Avoid zero variance
  }

  # If fixed variances across classes
  if (fixed_variances) {
    residual_variance <- rep(mean(residual_variance), n_classes)
  }

  list(
    class_proportions = class_props,
    growth_parameters = growth_params,
    residual_variance = residual_variance,
    time_scores = time_scores
  )
}


#' Predict Trajectory from Growth Parameters
#'
#' @keywords internal
#' @noRd
predict_trajectory <- function(time_scores, growth_params, growth_model) {

  if (growth_model == "linear") {
    y_pred <- growth_params$intercept + growth_params$slope * time_scores

  } else if (growth_model == "quadratic") {
    y_pred <- growth_params$intercept +
              growth_params$slope * time_scores +
              growth_params$quadratic * time_scores^2

  } else if (growth_model == "free_basis") {
    # Simplified
    y_pred <- growth_params$intercept + growth_params$slope * time_scores

  } else {
    stop("Unknown growth model type")
  }

  y_pred
}


#' Compute Weighted Log-Likelihood
#'
#' @description
#' Computes the weighted log-likelihood for the mixture model.
#' All computations done in log-space for numerical stability.
#'
#' @keywords internal
#' @noRd
compute_weighted_loglik <- function(y_wide, time_scores, params, weights,
                                    r_matrix, n_classes, growth_model) {

  n <- nrow(y_wide)
  loglik <- 0

  for (i in 1:n) {
    obs_times <- which(r_matrix[i, ])

    if (length(obs_times) == 0) {
      next  # No data for this person
    }

    # Compute log-likelihood contribution from each class (stay in log-space!)
    log_class_lik <- numeric(n_classes)

    for (k in 1:n_classes) {
      y_pred_k <- predict_trajectory(time_scores, params$growth_parameters[[k]],
                                    growth_model)
      y_obs <- y_wide[i, obs_times]
      y_pred <- y_pred_k[obs_times]
      resid <- y_obs - y_pred

      # Log-density for class k (STAY IN LOG-SPACE!)
      log_lik_k <- sum(dnorm(resid, mean = 0,
                            sd = sqrt(params$residual_variance[k]),
                            log = TRUE))

      # log[pi_k * f(y_i | k)] = log(pi_k) + log f(y_i | k)
      log_class_lik[k] <- log(pmax(params$class_proportions[k], 1e-300)) + log_lik_k
    }

    # log(sum_k pi_k * f(y_i | k)) using log-sum-exp trick
    log_mixture_lik <- log_sum_exp(log_class_lik)

    # Weighted contribution to log-likelihood
    loglik <- loglik + weights[i] * log_mixture_lik
  }

  loglik
}
