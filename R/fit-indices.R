#' Compute Model Fit Indices
#'
#' @description
#' Computes information criteria (AIC, BIC, aBIC) and classification quality
#' measures (entropy) for mixture models.
#'
#' @param loglik Log-likelihood value
#' @param n_params Number of free parameters
#' @param n_obs Number of observations
#' @param posterior_probs Matrix of posterior probabilities
#' @param weights Survey weights (optional)
#'
#' @return List of fit indices
#' @keywords internal
#' @noRd
compute_fit_indices <- function(loglik, n_params, n_obs, posterior_probs,
                                weights = NULL) {

  # AIC
  aic <- -2 * loglik + 2 * n_params

  # BIC
  bic <- -2 * loglik + n_params * log(n_obs)

  # Sample-size adjusted BIC (Sclove, 1987)
  # Uses n* = (n + 2) / 24
  n_star <- (n_obs + 2) / 24
  abic <- -2 * loglik + n_params * log(n_star)

  # Entropy (Ramaswamy et al., 1993)
  # Measure of classification uncertainty
  # Ranges from 0 (high uncertainty) to 1 (perfect classification)

  if (!is.null(weights)) {
    # Weighted entropy
    entropy_val <- compute_weighted_entropy(posterior_probs, weights)
  } else {
    # Unweighted entropy
    entropy_val <- compute_entropy(posterior_probs)
  }

  # Average posterior probability (AvePP)
  # Average of maximum posterior probability per class
  n_classes <- ncol(posterior_probs)
  class_assignments <- apply(posterior_probs, 1, which.max)

  avepp_by_class <- numeric(n_classes)
  for (k in 1:n_classes) {
    in_class_k <- which(class_assignments == k)
    if (length(in_class_k) > 0) {
      avepp_by_class[k] <- mean(posterior_probs[in_class_k, k])
    } else {
      avepp_by_class[k] <- NA
    }
  }

  # Odds of Correct Classification (OCC)
  # For each class: AvePP / (1 - AvePP)
  occ_by_class <- avepp_by_class / (1 - avepp_by_class)

  # Class counts and proportions
  class_counts <- table(class_assignments)
  class_props <- prop.table(class_counts)
  smallest_class_prop <- min(class_props)

  list(
    loglik = loglik,
    aic = aic,
    bic = bic,
    abic = abic,
    entropy = entropy_val,
    avepp = mean(avepp_by_class, na.rm = TRUE),
    avepp_by_class = avepp_by_class,
    occ_by_class = occ_by_class,
    smallest_class_prop = smallest_class_prop,
    n_params = n_params,
    n_obs = n_obs
  )
}


#' Compute Entropy
#'
#' @description
#' Computes entropy measure of classification quality
#' E = 1 - sum_i sum_k (p_ik * log(p_ik)) / (N * log(K))
#'
#' @param posterior_probs Matrix of posterior probabilities (N x K)
#'
#' @return Entropy value between 0 and 1
#' @keywords internal
#' @noRd
compute_entropy <- function(posterior_probs) {

  n <- nrow(posterior_probs)
  k <- ncol(posterior_probs)

  # Avoid log(0)
  posterior_probs_safe <- pmax(posterior_probs, 1e-10)

  # Sum of p_ik * log(p_ik)
  entropy_sum <- sum(posterior_probs * log(posterior_probs_safe))

  # Normalized entropy
  entropy <- 1 + entropy_sum / (n * log(k))

  # Ensure in [0, 1]
  entropy <- pmax(0, pmin(1, entropy))

  entropy
}


#' Compute Weighted Entropy
#'
#' @description
#' Computes entropy with survey weights
#'
#' @param posterior_probs Matrix of posterior probabilities
#' @param weights Survey weights
#'
#' @return Weighted entropy value
#' @keywords internal
#' @noRd
compute_weighted_entropy <- function(posterior_probs, weights) {

  k <- ncol(posterior_probs)

  # Avoid log(0)
  posterior_probs_safe <- pmax(posterior_probs, 1e-10)

  # Weighted sum of p_ik * log(p_ik)
  entropy_sum <- sum(weights * rowSums(posterior_probs * log(posterior_probs_safe)))

  # Normalized by total weight
  total_weight <- sum(weights)
  entropy <- 1 + entropy_sum / (total_weight * log(k))

  # Ensure in [0, 1]
  entropy <- pmax(0, pmin(1, entropy))

  entropy
}


#' Entropy Function (Exported)
#'
#' @description
#' Extract entropy from a SurveyMixr object or compute from posterior
#' probabilities.
#'
#' @param object Either a \code{SurveyMixr} object or a matrix of posterior
#'   probabilities
#' @param weights Optional survey weights for weighted entropy computation
#'
#' @return Numeric entropy value between 0 and 1, where values closer to 1
#'   indicate better class separation
#'
#' @details
#' Entropy measures the certainty of classification in mixture models. It is
#' calculated as:
#' \deqn{E = 1 - \frac{\sum_i \sum_k p_{ik} \log(p_{ik})}{N \log(K)}}
#'
#' where \eqn{p_{ik}} is the posterior probability of individual i belonging
#' to class k, N is the sample size, and K is the number of classes.
#'
#' Values range from 0 (complete uncertainty, uniform classification) to 1
#' (perfect classification). Values above 0.80 generally indicate good class
#' separation.
#'
#' @references
#' Ramaswamy, V., DeSarbo, W. S., Reibstein, D. J., & Robinson, W. T. (1993).
#' An empirical pooling approach for estimating marketing mix elasticities with
#' PIMS data. \emph{Marketing Science, 12}(1), 103-124.
#'
#' @examples
#' \dontrun{
#' # From fitted model
#' entropy(fit)
#'
#' # From posterior probability matrix
#' post_probs <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
#' entropy(post_probs)
#' }
#'
#' @export
entropy <- function(object, weights = NULL) {
  UseMethod("entropy")
}

#' @rdname entropy
#' @method entropy SurveyMixr
#' @export
entropy.SurveyMixr <- function(object, weights = NULL) {
  posterior_probs <- object@posterior_probs

  if (is.null(weights)) {
    weights <- object@survey_design$weights
  }

  if (!is.null(weights)) {
    compute_weighted_entropy(posterior_probs, weights)
  } else {
    compute_entropy(posterior_probs)
  }
}

#' @rdname entropy
#' @method entropy matrix
#' @export
entropy.matrix <- function(object, weights = NULL) {
  if (!is.null(weights)) {
    compute_weighted_entropy(object, weights)
  } else {
    compute_entropy(object)
  }
}

#' @rdname entropy
#' @method entropy default
#' @export
entropy.default <- function(object, weights = NULL) {
  stop("entropy() requires a SurveyMixr object or matrix of posterior probabilities")
}
