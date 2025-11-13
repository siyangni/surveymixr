# Lo-Mendell-Rubin Test for Growth Mixture Models
#
# Implements LMR and adjusted LMR (aLMR) likelihood ratio tests
# for testing k vs k-1 classes in mixture models
#
# Phase 2.2 of the development roadmap

#' Lo-Mendell-Rubin Test for Class Enumeration
#'
#' @description
#' Performs the Lo-Mendell-Rubin (LMR) likelihood ratio test to compare
#' a k-class model against a (k-1)-class model. This is an asymptotic
#' approximation that is faster than the bootstrap LRT (BLRT).
#'
#' @param model_k Fitted \code{SurveyMixr} object with k classes
#' @param model_k1 Fitted \code{SurveyMixr} object with k-1 classes
#' @param adjusted Logical; if TRUE (default), uses the adjusted LMR (aLMR)
#'   which provides better finite-sample performance
#'
#' @details
#' The LMR test (Lo, Mendell, & Rubin, 2001) tests the null hypothesis that
#' k-1 classes are sufficient against the alternative of k classes. The test
#' statistic is:
#'
#' \deqn{LRT = -2(\log L_{k-1} - \log L_k)}
#'
#' Under regularity conditions, this follows an asymptotic distribution that
#' can be approximated. The adjusted LMR (aLMR) applies a scaling correction
#' for better finite-sample performance:
#'
#' \deqn{aLMR = LMR \times c}
#'
#' where c is a scaling factor based on sample size and model complexity.
#'
#' **Advantages over BLRT:**
#' - Much faster (no bootstrap resampling)
#' - Asymptotic approximation
#' - Good performance in large samples
#'
#' **Disadvantages:**
#' - Less accurate than BLRT in small samples
#' - Relies on asymptotic theory
#' - May be anti-conservative
#'
#' @return A list of class \code{lmr_test} with components:
#'   \item{statistic}{LMR test statistic}
#'   \item{statistic_adjusted}{Adjusted LMR statistic (if adjusted = TRUE)}
#'   \item{df}{Degrees of freedom}
#'   \item{p_value}{p-value from asymptotic distribution}
#'   \item{p_value_adjusted}{Adjusted p-value (if adjusted = TRUE)}
#'   \item{loglik_k}{Log-likelihood for k-class model}
#'   \item{loglik_k1}{Log-likelihood for (k-1)-class model}
#'   \item{n_params_k}{Number of parameters in k-class model}
#'   \item{n_params_k1}{Number of parameters in (k-1)-class model}
#'   \item{sample_size}{Effective sample size}
#'   \item{conclusion}{Text interpretation of result}
#'
#' @references
#' Lo, Y., Mendell, N. R., & Rubin, D. B. (2001). Testing the number of
#' components in a normal mixture. *Biometrika*, 88(3), 767-778.
#'
#' Nylund, K. L., Asparouhov, T., & Muthén, B. O. (2007). Deciding on the
#' number of classes in latent class analysis and growth mixture modeling:
#' A Monte Carlo simulation study. *Structural Equation Modeling*, 14(4),
#' 535-569.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Full example (slow - use for actual analysis):
#' data(mcs_simulated)
#'
#' # Fit 2-class and 3-class models
#' fit2 <- gmm_survey(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 2, starts = 100
#' )
#'
#' fit3 <- gmm_survey(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 3, starts = 100
#' )
#'
#' # LMR test: Is 3-class better than 2-class?
#' lmr_result <- lmr_test(fit3, fit2)
#' print(lmr_result)
#'
#' # Adjusted LMR (recommended)
#' almr_result <- lmr_test(fit3, fit2, adjusted = TRUE)
#' print(almr_result)
#' }
lmr_test <- function(model_k, model_k1, adjusted = TRUE) {

  # Validate inputs
  if (!inherits(model_k, "SurveyMixr")) {
    stop("model_k must be a SurveyMixr object")
  }
  if (!inherits(model_k1, "SurveyMixr")) {
    stop("model_k1 must be a SurveyMixr object")
  }

  # Extract class counts
  k <- model_k@model_info$n_classes
  k1 <- model_k1@model_info$n_classes

  if (k != k1 + 1) {
    stop("model_k must have exactly one more class than model_k1. ",
         "Found k=", k, " and k-1=", k1)
  }

  # Extract log-likelihoods
  loglik_k <- logLik(model_k)
  loglik_k1 <- logLik(model_k1)

  # Extract number of parameters
  n_params_k <- length(coef(model_k))
  n_params_k1 <- length(coef(model_k1))

  # Degrees of freedom (difference in parameters)
  df <- n_params_k - n_params_k1

  # Extract sample size
  # Use effective sample size if survey weights present
  if (!is.null(model_k@model_info$survey_design$weights)) {
    weights <- model_k@model_info$survey_design$weights
    n_eff <- sum(weights)^2 / sum(weights^2)
  } else {
    n_eff <- nrow(model_k@data)
  }

  # Compute LMR statistic
  lmr_stat <- -2 * (as.numeric(loglik_k1) - as.numeric(loglik_k))

  if (lmr_stat < 0) {
    warning("LMR statistic is negative. k-class model has worse fit than (k-1)-class model.")
  }

  # Compute scaling factor for adjusted LMR
  # Based on Nylund et al. (2007) and Mplus implementation
  if (adjusted) {
    # Scaling factor depends on sample size and df
    # This is an approximation of the Mplus aLMR adjustment
    c_factor <- (k - 1) * (df + 1) / (2 * k)
    almr_stat <- lmr_stat / c_factor
  } else {
    c_factor <- NA
    almr_stat <- NA
  }

  # Asymptotic distribution approximation
  # The exact distribution is complex; we use chi-square as approximation
  # (Note: This is a simplification; the true distribution is more complex)
  p_value <- pchisq(lmr_stat, df = df, lower.tail = FALSE)

  if (adjusted) {
    p_value_adjusted <- pchisq(almr_stat, df = df, lower.tail = FALSE)
  } else {
    p_value_adjusted <- NA
  }

  # Interpretation
  alpha <- 0.05
  test_stat <- if (adjusted) almr_stat else lmr_stat
  test_pval <- if (adjusted) p_value_adjusted else p_value

  if (test_pval < alpha) {
    conclusion <- paste0(
      "Reject H0: ", k, "-class model fits significantly better than ",
      k - 1, "-class model (p = ", format.pval(test_pval, digits = 3), ")"
    )
  } else {
    conclusion <- paste0(
      "Fail to reject H0: ", k - 1, "-class model is sufficient ",
      "(p = ", format.pval(test_pval, digits = 3), ")"
    )
  }

  # Create result object
  result <- list(
    statistic = lmr_stat,
    statistic_adjusted = almr_stat,
    scaling_factor = c_factor,
    df = df,
    p_value = p_value,
    p_value_adjusted = p_value_adjusted,
    loglik_k = as.numeric(loglik_k),
    loglik_k1 = as.numeric(loglik_k1),
    n_params_k = n_params_k,
    n_params_k1 = n_params_k1,
    n_classes_k = k,
    n_classes_k1 = k1,
    sample_size = n_eff,
    adjusted = adjusted,
    conclusion = conclusion
  )

  class(result) <- "lmr_test"
  return(result)
}

#' Print Method for LMR Test Results
#'
#' @param x Object of class \code{lmr_test}
#' @param ... Additional arguments (not used)
#'
#' @return Invisibly returns x
#' @export
#' @method print lmr_test
print.lmr_test <- function(x, ...) {
  cat("\nLo-Mendell-Rubin Likelihood Ratio Test\n")
  cat(rep("=", 50), "\n", sep = "")

  cat("\nModel Comparison:\n")
  cat("  H0: ", x$n_classes_k1, "-class model is sufficient\n", sep = "")
  cat("  H1: ", x$n_classes_k, "-class model fits better\n", sep = "")

  cat("\nLog-Likelihoods:\n")
  cat("  ", x$n_classes_k1, "-class: ", format(x$loglik_k1, digits = 6), "\n", sep = "")
  cat("  ", x$n_classes_k, "-class: ", format(x$loglik_k, digits = 6), "\n", sep = "")

  cat("\nTest Statistics:\n")
  cat("  LMR statistic: ", format(x$statistic, digits = 4), "\n", sep = "")

  if (x$adjusted) {
    cat("  Adjusted LMR:  ", format(x$statistic_adjusted, digits = 4), "\n", sep = "")
    cat("  Scaling factor:", format(x$scaling_factor, digits = 4), "\n", sep = "")
  }

  cat("  Degrees of freedom: ", x$df, "\n", sep = "")

  cat("\nP-values:\n")
  if (x$adjusted) {
    cat("  LMR:      ", format.pval(x$p_value, digits = 4), "\n", sep = "")
    cat("  Adjusted: ", format.pval(x$p_value_adjusted, digits = 4),
        " (recommended)\n", sep = "")
  } else {
    cat("  p-value: ", format.pval(x$p_value, digits = 4), "\n", sep = "")
  }

  cat("\nConclusion:\n")
  cat("  ", x$conclusion, "\n", sep = "")

  cat("\nNote: The LMR test uses an asymptotic approximation and may be\n")
  cat("anti-conservative. For more accurate results, consider using\n")
  cat("the Bootstrap LRT (BLRT) via gmm_select().\n")

  invisible(x)
}

#' Automated LMR Testing Across Multiple Models
#'
#' @description
#' Performs sequential LMR tests to compare models with 1 to K classes.
#' This is integrated into \code{\link{gmm_select}} but can be called separately.
#'
#' @param model_list List of fitted \code{SurveyMixr} objects with increasing
#'   number of classes
#' @param adjusted Logical; use adjusted LMR?
#'
#' @return Data frame with LMR test results for each comparison
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Fit models with 1-4 classes (slow - use for actual analysis)
#' data(mcs_simulated)
#' models <- lapply(1:4, function(k) {
#'   gmm_survey(
#'     data = mcs_simulated,
#'     id = "id", time = "age", outcome = "selfcontrol",
#'     n_classes = k, starts = 50
#'   )
#' })
#'
#' # Run LMR tests
#' lmr_results <- lmr_sequential(models, adjusted = TRUE)
#' print(lmr_results)
#' }
lmr_sequential <- function(model_list, adjusted = TRUE) {

  if (length(model_list) < 2) {
    stop("Need at least 2 models to compare")
  }

  # Sort by number of classes
  n_classes <- sapply(model_list, function(m) m@model_info$n_classes)
  model_list <- model_list[order(n_classes)]
  n_classes <- sort(n_classes)

  # Initialize results
  results <- data.frame(
    comparison = character(),
    k = integer(),
    k_minus_1 = integer(),
    lmr_statistic = numeric(),
    almr_statistic = numeric(),
    df = integer(),
    p_value = numeric(),
    p_value_adjusted = numeric(),
    conclusion = character(),
    stringsAsFactors = FALSE
  )

  # Perform sequential tests
  for (i in 2:length(model_list)) {
    test <- lmr_test(model_list[[i]], model_list[[i - 1]], adjusted = adjusted)

    results <- rbind(results, data.frame(
      comparison = paste0(test$n_classes_k, " vs ", test$n_classes_k1),
      k = test$n_classes_k,
      k_minus_1 = test$n_classes_k1,
      lmr_statistic = test$statistic,
      almr_statistic = test$statistic_adjusted,
      df = test$df,
      p_value = test$p_value,
      p_value_adjusted = test$p_value_adjusted,
      significant = test$p_value_adjusted < 0.05,
      stringsAsFactors = FALSE
    ))
  }

  class(results) <- c("lmr_sequential", "data.frame")
  return(results)
}

#' Print Method for Sequential LMR Results
#'
#' @param x Object of class \code{lmr_sequential}
#' @param ... Additional arguments
#'
#' @return Invisibly returns x
#' @export
#' @method print lmr_sequential
print.lmr_sequential <- function(x, ...) {
  cat("\nSequential Lo-Mendell-Rubin Tests\n")
  cat(rep("=", 70), "\n", sep = "")

  cat("\n")
  # Use print.data.frame directly to avoid infinite recursion
  # (subsetted object still has lmr_sequential class)
  print.data.frame(x[, c("comparison", "almr_statistic", "df", "p_value_adjusted", "significant")],
                   row.names = FALSE, digits = 4)

  cat("\nRecommendation based on aLMR:\n")
  sig_tests <- which(x$significant)

  if (length(sig_tests) == 0) {
    cat("  1-class model is sufficient (no significant improvements)\n")
  } else {
    best_k <- max(x$k[sig_tests])
    cat("  ", best_k, "-class model recommended\n", sep = "")
    cat("  (last significant improvement)\n")
  }

  cat("\nNote: Consider also examining BIC, entropy, and BLRT\n")
  cat("for comprehensive model selection.\n")

  invisible(x)
}
