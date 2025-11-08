# Random Effects for Growth Mixture Models
#
# Implements individual-level random effects (random intercepts and slopes)
# in growth parameters within each latent class
#
# Phase 2.1.2 of the development roadmap

#' Growth Mixture Model with Random Effects
#'
#' @description
#' Extends \code{\link{gmm_survey}} to include random effects (individual-level
#' variance) in growth parameters. Allows for random intercepts, random slopes,
#' or both within each latent class, while maintaining survey design integration.
#'
#' @inheritParams gmm_survey
#' @param random Formula specifying random effects structure. Use standard lme4
#'   syntax: \code{~ 1} for random intercepts only, \code{~ 1 + time} for
#'   random intercepts and slopes, \code{~ 0 + time} for random slopes only.
#' @param variance_components Character string specifying variance structure:
#'   "class_specific" (default, separate variance for each class),
#'   "pooled" (common variance across classes), or
#'   "heterogeneous" (fully heterogeneous within-class variances)
#' @param correlation_structure Character string for random effects correlation:
#'   "unstructured" (default), "independent", "compound_symmetry"
#'
#' @details
#' **Model Specification:**
#'
#' For individual i in latent class k, the model with random effects is:
#'
#' \deqn{Y_{it} = (\beta_{0k} + b_{0ik}) + (\beta_{1k} + b_{1ik}) t_{it} + \epsilon_{it}}
#'
#' where:
#' - \eqn{\beta_{0k}, \beta_{1k}} are fixed effects (class-specific means)
#' - \eqn{b_{0ik}, b_{1ik}} are random effects (individual deviations)
#' - \eqn{(b_{0ik}, b_{1ik})' \sim N(0, \Psi_k)} with variance-covariance matrix \eqn{\Psi_k}
#' - \eqn{\epsilon_{it} \sim N(0, \sigma^2_k)}
#'
#' **Variance Components:**
#'
#' The variance-covariance matrix \eqn{\Psi_k} for class k:
#'
#' \deqn{\Psi_k = \begin{pmatrix}
#' \psi^2_{0k} & \psi_{01k} \\
#' \psi_{01k} & \psi^2_{1k}
#' \end{pmatrix}}
#'
#' where \eqn{\psi^2_{0k}} is variance of random intercepts,
#' \eqn{\psi^2_{1k}} is variance of random slopes, and
#' \eqn{\psi_{01k}} is their covariance.
#'
#' **Survey Weight Integration:**
#'
#' Survey weights affect both:
#' 1. Fixed effect estimation (class-specific means)
#' 2. Variance component estimation (but not random effect prediction)
#'
#' Random effects are predicted using empirical Bayes (BLUP) methods,
#' properly accounting for the survey design in the fixed effects.
#'
#' **Intraclass Correlation (ICC):**
#'
#' The ICC within each class measures correlation between observations
#' from the same individual:
#'
#' \deqn{ICC_k = \frac{\psi^2_{0k}}{\psi^2_{0k} + \sigma^2_k}}
#'
#' @return An S4 object of class \code{SurveyMixrRE} (extends \code{SurveyMixr})
#'   with additional slots:
#'   \item{random_effects}{Data frame with predicted random effects (BLUPs) for each individual}
#'   \item{variance_components}{Estimated variance-covariance matrices \eqn{\Psi_k} for each class}
#'   \item{residual_variance}{Residual variance \eqn{\sigma^2_k} for each class}
#'   \item{icc}{Intraclass correlation for each class}
#'   \item{random_formula}{Formula used for random effects}
#'
#' @references
#' Verbeke, G., & Molenberghs, G. (2000). *Linear Mixed Models for Longitudinal Data*.
#' New York: Springer.
#'
#' Muthén, B., & Asparouhov, T. (2009). Growth mixture modeling: Analysis with
#' non-Gaussian random effects. In G. Fitzmaurice, M. Davidian, G. Verbeke, &
#' G. Molenberghs (Eds.), *Longitudinal Data Analysis* (pp. 143-165). Boca Raton, FL: CRC Press.
#'
#' Hedeker, D., & Gibbons, R. D. (2006). *Longitudinal Data Analysis*.
#' Hoboken, NJ: Wiley.
#'
#' @export
#'
#' @examples
#' \donttest{
#' data(mcs_simulated)
#'
#' # Random intercepts only
#' fit_ri <- gmm_survey_re(
#'   data = mcs_simulated,
#'   id = "id",
#'   time = "age",
#'   outcome = "selfcontrol",
#'   n_classes = 3,
#'   random = ~ 1,  # Random intercepts
#'   strata = "stratum",
#'   cluster = "cluster",
#'   weights = "weight",
#'   starts = 200
#' )
#'
#' # Examine variance components
#' summary(fit_ri)
#' variance_components(fit_ri)
#'
#' # Random intercepts and slopes
#' fit_ris <- gmm_survey_re(
#'   data = mcs_simulated,
#'   id = "id",
#'   time = "age",
#'   outcome = "selfcontrol",
#'   n_classes = 3,
#'   random = ~ 1 + age,  # Random intercepts and slopes
#'   strata = "stratum",
#'   cluster = "cluster",
#'   weights = "weight",
#'   starts = 200
#' )
#'
#' # Extract predicted random effects
#' random_effs <- get_random_effects(fit_ris)
#' head(random_effs)
#'
#' # Plot random effects
#' plot_random_effects(fit_ris)
#' }
gmm_survey_re <- function(data,
                          id,
                          time,
                          outcome,
                          n_classes,
                          random = ~ 1,
                          growth_model = "linear",
                          strata = NULL,
                          cluster = NULL,
                          weights = NULL,
                          covariates = NULL,
                          variance_components = c("class_specific", "pooled", "heterogeneous"),
                          correlation_structure = c("unstructured", "independent", "compound_symmetry"),
                          starts = 500,
                          cores = parallel::detectCores() - 1,
                          convergence_threshold = 1e-6,
                          max_iterations = 1000,
                          seed = NULL,
                          verbose = TRUE) {

  variance_components <- match.arg(variance_components)
  correlation_structure <- match.arg(correlation_structure)

  # Validate random effects formula
  if (!inherits(random, "formula")) {
    stop("random must be a formula (e.g., ~ 1 or ~ 1 + time)")
  }

  # Parse random effects formula
  random_terms <- .parse_random_formula(random, time)

  if (verbose) {
    cat("\nFitting Growth Mixture Model with Random Effects\n")
    cat(rep("=", 60), "\n", sep = "")
    cat("Random effects structure:", deparse(random), "\n")
    cat("  - Random intercepts:", random_terms$has_intercept, "\n")
    cat("  - Random slopes:", random_terms$has_slope, "\n")
    cat("Variance structure:", variance_components, "\n")
    cat("Correlation structure:", correlation_structure, "\n\n")
  }

  # Call internal estimation function
  result <- .fit_gmm_re_internal(
    data = data,
    id = id,
    time = time,
    outcome = outcome,
    n_classes = n_classes,
    random_terms = random_terms,
    growth_model = growth_model,
    strata = strata,
    cluster = cluster,
    weights = weights,
    covariates = covariates,
    variance_components = variance_components,
    correlation_structure = correlation_structure,
    starts = starts,
    cores = cores,
    convergence_threshold = convergence_threshold,
    max_iterations = max_iterations,
    seed = seed,
    verbose = verbose
  )

  return(result)
}

#' Parse Random Effects Formula
#'
#' @keywords internal
.parse_random_formula <- function(random, time_var) {
  # Extract terms from formula
  terms_obj <- terms(random)
  term_labels <- attr(terms_obj, "term.labels")

  # Check for intercept
  has_intercept <- attr(terms_obj, "intercept") == 1

  # Check for slope (time variable)
  has_slope <- time_var %in% term_labels

  # Check for other variables
  other_vars <- setdiff(term_labels, time_var)

  list(
    has_intercept = has_intercept,
    has_slope = has_slope,
    other_random = other_vars,
    formula = random
  )
}

#' Internal Estimation Function for GMM with Random Effects
#'
#' @keywords internal
.fit_gmm_re_internal <- function(data, id, time, outcome, n_classes,
                                 random_terms, growth_model, strata, cluster,
                                 weights, covariates, variance_components,
                                 correlation_structure, starts, cores,
                                 convergence_threshold, max_iterations,
                                 seed, verbose) {

  # This is a placeholder for the full implementation
  # Full version would:
  # 1. Extend the EM algorithm to include random effects
  # 2. E-step: Compute posterior probabilities AND predict random effects (EBLUPs)
  # 3. M-step: Update fixed effects AND variance components
  # 4. Iterate until convergence
  # 5. Compute survey-adjusted standard errors for all parameters
  # 6. Return SurveyMixrRE object

  stop("Full implementation pending. This function requires integration with ",
       "the core EM algorithm to add random effects estimation. ",
       "See IMPLEMENTATION_SUMMARY.md for details.")
}

#' Extract Random Effects from Fitted Model
#'
#' @description
#' Extracts predicted random effects (BLUPs - Best Linear Unbiased Predictors)
#' from a fitted growth mixture model with random effects.
#'
#' @param object Fitted \code{SurveyMixrRE} object
#' @param class_assignment Character: "modal" (use most likely class, default),
#'   "weighted" (weight by posterior probabilities), or "all" (return for all classes)
#'
#' @return Data frame with columns:
#'   \item{id}{Individual ID}
#'   \item{class}{Latent class (if class_assignment != "all")}
#'   \item{intercept}{Predicted random intercept (if in model)}
#'   \item{slope}{Predicted random slope (if in model)}
#'   \item{posterior_prob}{Posterior probability of class membership}
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Fit model with random effects
#' fit <- gmm_survey_re(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 3, random = ~ 1 + age, starts = 100
#' )
#'
#' # Get random effects for modal class
#' re <- get_random_effects(fit)
#' head(re)
#'
#' # Get random effects for all classes (weighted)
#' re_all <- get_random_effects(fit, class_assignment = "all")
#' }
get_random_effects <- function(object, class_assignment = c("modal", "weighted", "all")) {

  if (!inherits(object, "SurveyMixrRE")) {
    stop("object must be a SurveyMixrRE object (fitted with gmm_survey_re)")
  }

  class_assignment <- match.arg(class_assignment)

  # Extract random effects from model object
  # This would access object@random_effects slot
  random_effects <- object@random_effects

  # Apply class assignment strategy
  if (class_assignment == "modal") {
    # Use most likely class for each individual
    # Filter to modal class assignments
  } else if (class_assignment == "weighted") {
    # Weight random effects by posterior probabilities
  } else {
    # Return all
  }

  return(random_effects)
}

#' Extract Variance Components
#'
#' @description
#' Extracts estimated variance-covariance matrices for random effects
#' and residual variances from a fitted model.
#'
#' @param object Fitted \code{SurveyMixrRE} object
#' @param class Specific class to extract (default = "all")
#' @param format Character: "matrix" (default), "vector", or "dataframe"
#'
#' @return Variance components in requested format
#'
#' @export
#'
#' @examples
#' \donttest{
#' fit <- gmm_survey_re(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 3, random = ~ 1 + age, starts = 100
#' )
#'
#' # Get all variance components
#' vc <- variance_components(fit)
#' print(vc)
#'
#' # Get for specific class
#' vc_class1 <- variance_components(fit, class = 1)
#' }
variance_components <- function(object, class = "all",
                                format = c("matrix", "vector", "dataframe")) {

  if (!inherits(object, "SurveyMixrRE")) {
    stop("object must be a SurveyMixrRE object")
  }

  format <- match.arg(format)

  # Extract from model
  psi <- object@variance_components
  sigma <- object@residual_variance

  if (class != "all") {
    psi <- psi[[class]]
    sigma <- sigma[class]
  }

  # Format output
  if (format == "dataframe") {
    # Convert to tidy data frame
    df <- data.frame(
      class = integer(),
      parameter = character(),
      estimate = numeric(),
      se = numeric()
    )
    # Populate...
    return(df)
  } else if (format == "vector") {
    # Vectorize variance components
    return(list(psi_vector = as.vector(psi), sigma = sigma))
  } else {
    # Return as matrices
    return(list(psi = psi, sigma = sigma))
  }
}

#' Calculate Intraclass Correlation
#'
#' @description
#' Computes the intraclass correlation coefficient (ICC) for each latent class,
#' measuring the proportion of total variance due to individual differences.
#'
#' @param object Fitted \code{SurveyMixrRE} object
#' @param type Character: "unconditional" (default, marginal ICC) or
#'   "conditional" (conditional on covariates)
#'
#' @details
#' The unconditional ICC for class k is:
#'
#' \deqn{ICC_k = \frac{\psi^2_{0k}}{\psi^2_{0k} + \sigma^2_k}}
#'
#' where \eqn{\psi^2_{0k}} is the random intercept variance and
#' \eqn{\sigma^2_k} is the residual variance.
#'
#' **Interpretation:**
#' - ICC = 0: No clustering (all variance is residual)
#' - ICC = 1: Perfect clustering (all variance is between individuals)
#' - Typical range: 0.1-0.5 for longitudinal data
#'
#' @return Numeric vector of ICC values for each class
#'
#' @export
#'
#' @examples
#' \donttest{
#' fit <- gmm_survey_re(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 3, random = ~ 1, starts = 100
#' )
#'
#' # Calculate ICC for each class
#' icc_vals <- calculate_icc(fit)
#' print(icc_vals)
#' }
calculate_icc <- function(object, type = c("unconditional", "conditional")) {

  if (!inherits(object, "SurveyMixrRE")) {
    stop("object must be a SurveyMixrRE object")
  }

  type <- match.arg(type)

  # Extract variance components
  psi <- object@variance_components  # List of matrices for each class
  sigma <- object@residual_variance  # Vector of residual variances

  n_classes <- object@model_info$n_classes

  icc <- numeric(n_classes)

  for (k in 1:n_classes) {
    # Extract random intercept variance (first diagonal element)
    psi_0k <- psi[[k]][1, 1]
    sigma_k <- sigma[k]

    # Calculate ICC
    icc[k] <- psi_0k / (psi_0k + sigma_k)
  }

  names(icc) <- paste0("Class_", 1:n_classes)

  return(icc)
}

#' Plot Random Effects Distributions
#'
#' @description
#' Visualizes the distribution of predicted random effects for each latent class.
#'
#' @param object Fitted \code{SurveyMixrRE} object
#' @param type Character: "density", "qq", "caterpillar", or "scatter"
#' @param which Character: "intercept", "slope", or "both"
#'
#' @return ggplot2 object
#'
#' @export
#'
#' @examples
#' \donttest{
#' fit <- gmm_survey_re(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 3, random = ~ 1 + age, starts = 100
#' )
#'
#' # Density plots of random intercepts
#' plot_random_effects(fit, type = "density", which = "intercept")
#'
#' # QQ plots to check normality
#' plot_random_effects(fit, type = "qq", which = "both")
#'
#' # Caterpillar plot with confidence intervals
#' plot_random_effects(fit, type = "caterpillar", which = "slope")
#'
#' # Scatter plot of intercepts vs slopes
#' plot_random_effects(fit, type = "scatter")
#' }
plot_random_effects <- function(object,
                                type = c("density", "qq", "caterpillar", "scatter"),
                                which = c("intercept", "slope", "both")) {

  if (!inherits(object, "SurveyMixrRE")) {
    stop("object must be a SurveyMixrRE object")
  }

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' required for plotting")
  }

  type <- match.arg(type)
  which <- match.arg(which)

  # Extract random effects
  re <- get_random_effects(object, class_assignment = "modal")

  # Create plot based on type
  if (type == "density") {
    p <- .plot_re_density(re, which)
  } else if (type == "qq") {
    p <- .plot_re_qq(re, which)
  } else if (type == "caterpillar") {
    p <- .plot_re_caterpillar(re, which)
  } else {  # scatter
    p <- .plot_re_scatter(re)
  }

  return(p)
}

#' Internal: Density Plot of Random Effects
#'
#' @keywords internal
.plot_re_density <- function(re, which) {
  # Create density plots for random effects by class
  # Would use ggplot2 to create overlaid densities
  stop("Plotting function - full implementation pending")
}

#' Internal: QQ Plot of Random Effects
#'
#' @keywords internal
.plot_re_qq <- function(re, which) {
  # Create QQ plots to assess normality of random effects
  stop("Plotting function - full implementation pending")
}

#' Internal: Caterpillar Plot of Random Effects
#'
#' @keywords internal
.plot_re_caterpillar <- function(re, which) {
  # Create caterpillar plots showing individual random effects with CI
  stop("Plotting function - full implementation pending")
}

#' Internal: Scatter Plot of Random Effects
#'
#' @keywords internal
.plot_re_scatter <- function(re) {
  # Scatter plot of random intercepts vs slopes
  stop("Plotting function - full implementation pending")
}

#' Define SurveyMixrRE S4 Class
#'
#' @description
#' S4 class for growth mixture models with random effects,
#' extends SurveyMixr class
#'
#' @slot random_effects Data frame of predicted random effects (BLUPs)
#' @slot variance_components List of variance-covariance matrices for each class
#' @slot residual_variance Vector of residual variances for each class
#' @slot icc Vector of intraclass correlations for each class
#' @slot random_formula Formula specifying random effects structure
#'
#' @keywords internal
#' @export
setClass("SurveyMixrRE",
  contains = "SurveyMixr",
  slots = list(
    random_effects = "data.frame",
    variance_components = "list",
    residual_variance = "numeric",
    icc = "numeric",
    random_formula = "formula"
  )
)
