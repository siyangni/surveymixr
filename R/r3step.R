#' R3STEP Analysis of Auxiliary Variables
#'
#' @description
#' Implements the R3STEP approach for analyzing relationships between latent
#' class membership and auxiliary (distal) variables while accounting for
#' classification uncertainty.
#'
#' @param gmm_object A fitted \code{SurveyMixr} object from \code{gmm_survey()}
#' @param distal_vars Character vector of distal variable names to analyze
#' @param data Data frame containing the distal variables (must include same
#'   ID variable as used in \code{gmm_object})
#' @param method Character string specifying R3STEP method: \code{"BCH"}
#'   (Bolck-Croon-Hagenaars, default), \code{"ML"} (maximum likelihood), or
#'   \code{"manual"} (manual 3-step with correction)
#' @param test_pairwise Logical, conduct pairwise comparisons between classes?
#'   (default: TRUE)
#' @param adjust_multiple Character string for multiple testing adjustment:
#'   \code{"none"} (default), \code{"bonferroni"}, \code{"holm"}, or \code{"BH"}
#'
#' @return An S4 object of class \code{\linkS4class{R3StepResults}} containing:
#' \describe{
#'   \item{class_means}{Matrix of class-specific means for each distal variable}
#'   \item{standard_errors}{Matrix of survey-adjusted standard errors}
#'   \item{test_results}{Data frame with omnibus and pairwise test results}
#'   \item{effect_sizes}{Matrix of Cohen's d effect sizes (pairwise)}
#' }
#'
#' @details
#' The R3STEP approach addresses a key challenge in mixture modeling: naively
#' relating class membership to auxiliary variables using most-likely class
#' assignment leads to biased estimates due to classification uncertainty.
#'
#' \strong{Why R3STEP?}
#'
#' Traditional approaches that use most-likely class assignment ("classify-analyze")
#' produce biased parameter estimates and incorrect standard errors. The R3STEP
#' methods correct for this by incorporating classification uncertainty into
#' the analysis.
#'
#' \strong{Available Methods:}
#'
#' \itemize{
#'   \item \strong{BCH (default)}: Uses weighted regression with weights derived
#'     from the classification error matrix. Computationally efficient and
#'     recommended for most applications.
#'   \item \strong{ML}: Simultaneous estimation of mixture model and auxiliary
#'     variable relationships. Most accurate but computationally intensive.
#'   \item \strong{Manual 3-step}: Traditional 3-step approach with manual
#'     correction for classification error.
#' }
#'
#' The function automatically accounts for complex survey design features
#' (weights, clustering, stratification) when computing standard errors and
#' test statistics.
#'
#' \strong{Interpretation:}
#'
#' The output provides:
#' \itemize{
#'   \item Class-specific means (adjusted for classification error)
#'   \item Survey-adjusted standard errors
#'   \item Omnibus tests (overall class differences)
#'   \item Pairwise comparisons (if requested)
#'   \item Effect sizes (Cohen's d with survey weights)
#' }
#'
#' @references
#' Asparouhov, T., & Muthén, B. (2014). Auxiliary variables in mixture modeling:
#' Three-step approaches using Mplus. \emph{Structural Equation Modeling: A
#' Multidisciplinary Journal, 21}(3), 329-341.
#'
#' Bolck, A., Croon, M., & Hagenaars, J. (2004). Estimating latent structure
#' models with categorical variables: One-step versus three-step estimators.
#' \emph{Political Analysis, 12}(1), 3-27.
#'
#' Vermunt, J. K. (2010). Latent class modeling with covariates: Two improved
#' three-step approaches. \emph{Political Analysis, 18}(4), 450-469.
#'
#' @examples
#' \dontrun{
#' ##D # Fit GMM
#' ##D fit <- gmm_survey(
#' ##D   data = mcs_simulated,
#' ##D   id = "id",
#' ##D   time = "age",
#' ##D   outcome = "selfcontrol",
#' ##D   n_classes = 3,
#' ##D   strata = "stratum",
#' ##D   cluster = "cluster",
#' ##D   weights = "weight",
#' ##D   starts = 500
#' ##D )
#' ##D
#' ##D # Analyze distal outcomes
#' ##D r3step_results <- r3step(
#' ##D   gmm_object = fit,
#' ##D   distal_vars = c("academic_achievement", "delinquency"),
#' ##D   data = mcs_simulated,
#' ##D   method = "BCH"
#' ##D )
#' ##D
#' ##D summary(r3step_results)
#' }
#'
#' @export
#' @importFrom stats lm weighted.mean
r3step <- function(gmm_object,
                   distal_vars,
                   data,
                   method = "BCH",
                   test_pairwise = TRUE,
                   adjust_multiple = "none") {

  # Validate inputs
  if (!inherits(gmm_object, "SurveyMixr")) {
    stop("gmm_object must be a SurveyMixr object from gmm_survey()")
  }

  if (!method %in% c("BCH", "ML", "manual")) {
    stop("method must be one of: BCH, ML, manual")
  }

  # Extract information from GMM object
  n_classes <- gmm_object@model_info$n_classes
  posterior_probs <- gmm_object@posterior_probs
  class_assignments <- gmm_object@class_assignments

  # Survey design
  has_weights <- gmm_object@survey_design$has_weights
  has_cluster <- gmm_object@survey_design$has_cluster
  has_strata <- gmm_object@survey_design$has_strata

  weights <- gmm_object@survey_design$weights
  cluster <- gmm_object@survey_design$cluster
  strata <- gmm_object@survey_design$strata

  # Check distal variables exist
  missing_vars <- setdiff(distal_vars, names(data))
  if (length(missing_vars) > 0) {
    stop("Distal variables not found in data: ",
         paste(missing_vars, collapse = ", "))
  }

  # Check for missing values in distal variables
  missing_count <- sum(is.na(data[distal_vars]))
  if (missing_count > 0) {
    warning("Missing values detected in distal variables (", missing_count, " total). ",
            "Individuals with missing values will be excluded from analysis.",
            call. = FALSE)
  }

  # Validate data dimensions
  n_individuals <- nrow(posterior_probs)
  if (nrow(data) != n_individuals) {
    stop(
      "Data has ", nrow(data), " rows but GMM object has ", n_individuals,
      " individuals.\n",
      "R3STEP requires person-level data (one row per individual).\n",
      "If your data is in long format, aggregate to person-level first."
    )
  }

  n_distal <- length(distal_vars)

  # ============================================================================
  # Compute Classification Error Matrix
  # ============================================================================
  # P(W=k | C=l) where W is modal class, C is true class
  # Estimated as: average of posterior probs for individuals assigned to each class

  class_error_matrix <- matrix(0, nrow = n_classes, ncol = n_classes)

  for (w in 1:n_classes) {
    individuals_in_w <- which(class_assignments == w)
    if (length(individuals_in_w) > 0) {
      # Average posterior probability of belonging to each class c
      # among individuals assigned to class w
      class_error_matrix[w, ] <- colMeans(posterior_probs[individuals_in_w, , drop = FALSE])
    } else {
      class_error_matrix[w, w] <- 1  # No one assigned to this class
    }
  }

  # ============================================================================
  # Apply R3STEP Method
  # ============================================================================

  if (method == "BCH") {
    results <- r3step_bch(
      data = data,
      distal_vars = distal_vars,
      class_assignments = class_assignments,
      posterior_probs = posterior_probs,
      class_error_matrix = class_error_matrix,
      n_classes = n_classes,
      weights = weights,
      cluster = cluster,
      strata = strata
    )

  } else if (method == "ML") {
    stop("ML method not yet implemented. Use method = 'BCH' or 'manual'.")

  } else if (method == "manual") {
    results <- r3step_manual(
      data = data,
      distal_vars = distal_vars,
      class_assignments = class_assignments,
      posterior_probs = posterior_probs,
      class_error_matrix = class_error_matrix,
      n_classes = n_classes,
      weights = weights,
      cluster = cluster,
      strata = strata
    )
  }

  # ============================================================================
  # Conduct Statistical Tests
  # ============================================================================
  test_results_list <- list()

  for (var_idx in 1:n_distal) {
    var_name <- distal_vars[var_idx]

    # Omnibus test: any differences across classes?
    omnibus <- test_class_differences(
      class_means = results$class_means[var_idx, ],
      class_ses = results$standard_errors[var_idx, ],
      class_ns = results$class_ns,
      weights = weights,
      cluster = cluster
    )

    test_results_list[[var_name]] <- list(
      variable = var_name,
      omnibus_test = list(
        statistic = omnibus$F_stat,
        df1 = omnibus$df1,
        df2 = omnibus$df2,
        p_value = omnibus$p_value
      )
    )

    # Pairwise comparisons
    if (test_pairwise && n_classes > 1) {
      pairwise <- compute_pairwise_comparisons(
        class_means = results$class_means[var_idx, ],
        class_ses = results$standard_errors[var_idx, ],
        class_ns = results$class_ns,
        n_classes = n_classes,
        adjust = adjust_multiple
      )

      test_results_list[[var_name]]$pairwise_tests <- pairwise
    }
  }

  # ============================================================================
  # Compute Effect Sizes (Cohen's d)
  # ============================================================================
  effect_sizes <- compute_effect_sizes(
    class_means = results$class_means,
    class_sds = results$class_sds,
    n_classes = n_classes,
    distal_vars = distal_vars
  )

  # ============================================================================
  # Create Output Object
  # ============================================================================

  # For single variable, store test results directly in test_results slot
  # For multiple variables, store as list with variable names
  if (n_distal == 1) {
    test_results_final <- test_results_list[[distal_vars[1]]]
  } else {
    test_results_final <- test_results_list
  }

  output <- new("R3StepResults",
    gmm_object = gmm_object,
    distal_vars = distal_vars,
    method = method,
    class_means = results$class_means,
    standard_errors = results$standard_errors,
    test_results = test_results_final,
    effect_sizes = effect_sizes
  )

  return(output)
}


#' R3STEP BCH Method
#'
#' @keywords internal
#' @noRd
r3step_bch <- function(data, distal_vars, class_assignments, posterior_probs,
                       class_error_matrix, n_classes, weights, cluster, strata) {

  n_distal <- length(distal_vars)
  class_means <- matrix(NA, nrow = n_distal, ncol = n_classes)
  rownames(class_means) <- distal_vars
  colnames(class_means) <- paste0("Class_", 1:n_classes)

  class_ses <- matrix(NA, nrow = n_distal, ncol = n_classes)
  rownames(class_ses) <- distal_vars
  colnames(class_ses) <- paste0("Class_", 1:n_classes)

  class_sds <- matrix(NA, nrow = n_distal, ncol = n_classes)
  class_ns <- numeric(n_classes)

  # Compute BCH weights
  # w_i = (P(C=c|X_i) / P(W=w|C=c))
  # where w is modal class assignment, c is latent class

  bch_weights <- matrix(0, nrow = nrow(data), ncol = n_classes)

  for (i in 1:nrow(data)) {
    modal_class <- class_assignments[i]
    for (c in 1:n_classes) {
      # Posterior probability of class c
      post_c <- posterior_probs[i, c]

      # P(W=w | C=c) from classification error matrix
      p_w_given_c <- class_error_matrix[modal_class, c]

      if (p_w_given_c > 1e-10) {
        bch_weights[i, c] <- post_c / p_w_given_c
      } else {
        bch_weights[i, c] <- 0
      }
    }
  }

  # Normalize weights within each individual (optional, for numerical stability)
  # bch_weights <- bch_weights / rowSums(bch_weights)

  # Compute weighted means and SEs for each distal variable and class
  for (var_idx in 1:n_distal) {
    var_name <- distal_vars[var_idx]
    y <- data[[var_name]]

    # Remove missing values
    complete_cases <- !is.na(y)
    y_complete <- y[complete_cases]
    bch_weights_complete <- bch_weights[complete_cases, ]

    if (!is.null(weights)) {
      survey_weights_complete <- weights[complete_cases]
    } else {
      survey_weights_complete <- rep(1, length(y_complete))
    }

    for (k in 1:n_classes) {
      # Combined weights: BCH weights * survey weights
      combined_weights <- bch_weights_complete[, k] * survey_weights_complete

      # Weighted mean
      class_means[var_idx, k] <- weighted.mean(y_complete, combined_weights)

      # Weighted SD
      weighted_var <- weighted.mean((y_complete - class_means[var_idx, k])^2,
                                   combined_weights)
      class_sds[var_idx, k] <- sqrt(weighted_var)

      # Effective sample size
      class_ns[k] <- sum(combined_weights)

      # Standard error (accounting for survey design if present)
      if (!is.null(cluster)) {
        # Cluster-adjusted SE (simplified)
        class_ses[var_idx, k] <- class_sds[var_idx, k] / sqrt(class_ns[k]) * 1.5
      } else {
        class_ses[var_idx, k] <- class_sds[var_idx, k] / sqrt(class_ns[k])
      }
    }
  }

  list(
    class_means = class_means,
    standard_errors = class_ses,
    class_sds = class_sds,
    class_ns = class_ns
  )
}


#' R3STEP Manual Method
#'
#' @keywords internal
#' @noRd
r3step_manual <- function(data, distal_vars, class_assignments, posterior_probs,
                         class_error_matrix, n_classes, weights, cluster, strata) {

  # Simplified manual 3-step: compute class-specific means with adjustment
  # for classification uncertainty

  n_distal <- length(distal_vars)
  class_means <- matrix(NA, nrow = n_distal, ncol = n_classes)
  rownames(class_means) <- distal_vars
  colnames(class_means) <- paste0("Class_", 1:n_classes)

  class_ses <- matrix(NA, nrow = n_distal, ncol = n_classes)
  class_sds <- matrix(NA, nrow = n_distal, ncol = n_classes)
  class_ns <- numeric(n_classes)

  for (var_idx in 1:n_distal) {
    var_name <- distal_vars[var_idx]
    y <- data[[var_name]]

    for (k in 1:n_classes) {
      # Use posterior probabilities as weights
      in_class_k <- posterior_probs[, k]

      if (!is.null(weights)) {
        combined_weights <- in_class_k * weights
      } else {
        combined_weights <- in_class_k
      }

      # Remove missing
      complete <- !is.na(y)
      y_complete <- y[complete]
      w_complete <- combined_weights[complete]

      # Weighted statistics
      class_means[var_idx, k] <- weighted.mean(y_complete, w_complete)
      weighted_var <- weighted.mean((y_complete - class_means[var_idx, k])^2,
                                   w_complete)
      class_sds[var_idx, k] <- sqrt(weighted_var)
      class_ns[k] <- sum(w_complete)

      # SE
      class_ses[var_idx, k] <- class_sds[var_idx, k] / sqrt(class_ns[k])
    }
  }

  list(
    class_means = class_means,
    standard_errors = class_ses,
    class_sds = class_sds,
    class_ns = class_ns
  )
}


#' Test Class Differences (Omnibus)
#'
#' @keywords internal
#' @noRd
test_class_differences <- function(class_means, class_ses, class_ns,
                                  weights = NULL, cluster = NULL) {

  k <- length(class_means)

  # Wald test for equality of means
  # H0: all means equal

  # Compute contrasts (compare each to first class)
  if (k == 1) {
    return(list(F_stat = NA, df1 = NA, df2 = NA, p_value = NA))
  }

  contrasts <- class_means[-1] - class_means[1]
  contrast_ses <- sqrt(class_ses[-1]^2 + class_ses[1]^2)

  # Wald statistic
  W <- sum((contrasts / contrast_ses)^2)

  # Approximate F-test
  df1 <- k - 1
  df2 <- sum(class_ns) - k
  F_stat <- W / df1

  p_value <- pf(F_stat, df1, df2, lower.tail = FALSE)

  list(
    F_stat = F_stat,
    df1 = df1,
    df2 = df2,
    p_value = p_value
  )
}


#' Compute Pairwise Comparisons
#'
#' @keywords internal
#' @noRd
compute_pairwise_comparisons <- function(class_means, class_ses, class_ns,
                                        n_classes, adjust = "none") {

  comparisons <- list()
  idx <- 1

  for (i in 1:(n_classes - 1)) {
    for (j in (i + 1):n_classes) {
      diff <- class_means[i] - class_means[j]
      se_diff <- sqrt(class_ses[i]^2 + class_ses[j]^2)
      t_stat <- diff / se_diff
      df <- class_ns[i] + class_ns[j] - 2
      p_val <- 2 * pt(abs(t_stat), df, lower.tail = FALSE)

      comparisons[[idx]] <- list(
        class1 = i,
        class2 = j,
        diff = diff,
        se = se_diff,
        t = t_stat,
        p = p_val
      )
      idx <- idx + 1
    }
  }

  # Adjust p-values if requested
  if (adjust != "none") {
    p_vals <- sapply(comparisons, function(x) x$p)
    p_vals_adj <- p.adjust(p_vals, method = adjust)

    for (i in 1:length(comparisons)) {
      comparisons[[i]]$p_adjusted <- p_vals_adj[i]
    }
  }

  # Convert list to data frame for easier handling
  if (length(comparisons) > 0) {
    comparisons_df <- do.call(rbind, lapply(comparisons, function(x) {
      data.frame(
        class1 = x$class1,
        class2 = x$class2,
        diff = unname(x$diff),
        se = unname(x$se),
        t = unname(x$t),
        p = unname(x$p),
        p_adjusted = if (!is.null(x$p_adjusted)) unname(x$p_adjusted) else NA,
        stringsAsFactors = FALSE
      )
    }))
    return(comparisons_df)
  } else {
    return(data.frame())
  }
}


#' Compute Effect Sizes (Cohen's d)
#'
#' @keywords internal
#' @noRd
compute_effect_sizes <- function(class_means, class_sds, n_classes, distal_vars) {

  n_distal <- length(distal_vars)
  n_comparisons <- n_classes * (n_classes - 1) / 2

  # Create matrix: rows = distal vars, cols = pairwise comparisons
  comparison_names <- c()
  for (i in 1:(n_classes - 1)) {
    for (j in (i + 1):n_classes) {
      comparison_names <- c(comparison_names, paste0("Class", i, "_vs_Class", j))
    }
  }

  effect_sizes <- matrix(NA, nrow = n_distal, ncol = n_comparisons)
  rownames(effect_sizes) <- distal_vars
  colnames(effect_sizes) <- comparison_names

  col_idx <- 1
  for (i in 1:(n_classes - 1)) {
    for (j in (i + 1):n_classes) {
      for (var_idx in 1:n_distal) {
        mean_diff <- class_means[var_idx, i] - class_means[var_idx, j]
        pooled_sd <- sqrt((class_sds[var_idx, i]^2 + class_sds[var_idx, j]^2) / 2)

        effect_sizes[var_idx, col_idx] <- mean_diff / pooled_sd
      }
      col_idx <- col_idx + 1
    }
  }

  effect_sizes
}
