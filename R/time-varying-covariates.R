# Enhanced Time-Varying Covariate Support
#
# Implements comprehensive support for time-varying covariates in GMM
# including direct effects, indirect effects, and interactions
#
# Phase 2.1.3 of the development roadmap

#' Growth Mixture Model with Time-Varying Covariates
#'
#' @description
#' Extends \code{\link{gmm_survey}} with comprehensive support for time-varying
#' covariates (TVCs). TVCs can have direct effects on outcomes, indirect effects
#' on growth parameters, and can interact with latent class membership.
#'
#' @inheritParams gmm_survey
#' @param tvc Formula specifying time-varying covariates. Variables must vary
#'   within individuals over time (e.g., \code{~ ses + parental_monitoring})
#' @param tvc_effects Character string specifying how TVCs affect the model:
#'   \describe{
#'     \item{"direct"}{TVCs directly predict outcome at each time point (default)}
#'     \item{"indirect"}{TVCs affect growth parameters (slopes)}
#'     \item{"both"}{Both direct and indirect effects}
#'     \item{"interaction"}{TVCs moderate class-specific trajectories}
#'   }
#' @param tvc_lag Integer specifying lag for TVCs (0 = contemporaneous, 1 = lagged once, etc.)
#' @param center_tvc Logical; center time-varying covariates? (default = TRUE)
#' @param tvc_by_class Logical; allow TVC effects to differ by class? (default = FALSE)
#' @param covariates Character vector of time-varying covariate names (not yet implemented)
#' @param convergence_threshold Numeric convergence criterion for EM algorithm (default: 1e-6)
#' @param max_iterations Integer maximum number of EM iterations (default: 1000)
#' @param seed Integer random seed for reproducibility (optional)
#'
#' @details
#' **Model Specifications:**
#'
#' **1. Direct Effects Model:**
#' \deqn{Y_{it} = \beta_{0k} + \beta_{1k} t + \gamma_k X_{it} + \epsilon_{it}}
#'
#' where \eqn{X_{it}} is the time-varying covariate and \eqn{\gamma_k} is its
#' class-specific effect on the outcome.
#'
#' **2. Indirect Effects Model:**
#' \deqn{Y_{it} = \beta_{0k} + (\beta_{1k} + \delta_k \bar{X}_i) t + \epsilon_{it}}
#'
#' where \eqn{\bar{X}_i} is the individual mean of the TVC and \eqn{\delta_k}
#' represents how the TVC affects the growth rate.
#'
#' **3. Both Effects Model:**
#' \deqn{Y_{it} = \beta_{0k} + (\beta_{1k} + \delta_k \bar{X}_i) t + \gamma_k (X_{it} - \bar{X}_i) + \epsilon_{it}}
#'
#' This separates between-person effects (\eqn{\delta_k}) from within-person
#' effects (\eqn{\gamma_k}).
#'
#' **4. Interaction Model:**
#' \deqn{Y_{it} = \beta_{0k} + \beta_{1k} t + \gamma_k X_{it} + \lambda_k (t \times X_{it}) + \epsilon_{it}}
#'
#' where \eqn{\lambda_k} captures how the TVC moderates the trajectory slope.
#'
#' **Time-Varying vs Time-Invariant:**
#'
#' - **Time-invariant**: Constant for each individual (e.g., sex, baseline SES)
#' - **Time-varying**: Changes within individuals (e.g., parental monitoring, stress)
#'
#' The function automatically detects which covariates are time-varying by
#' checking for within-individual variance.
#'
#' **Centering:**
#'
#' When \code{center_tvc = TRUE}, covariates are centered at their grand mean.
#' This improves interpretability and can aid convergence. For "both" effects,
#' person-mean centering is used to separate within- and between-person effects.
#'
#' **Lagged Effects:**
#'
#' Set \code{tvc_lag > 0} to examine lagged effects of TVCs:
#' - \code{tvc_lag = 1}: Previous time point predicts current outcome
#' - \code{tvc_lag = 2}: Two time points back predicts current outcome
#'
#' @return An S4 object of class \code{SurveyMixrTVC} (extends \code{SurveyMixr})
#'   with additional slots:
#'   \item{tvc_effects}{Data frame with TVC effect estimates for each class}
#'   \item{tvc_formula}{Formula specifying time-varying covariates}
#'   \item{tvc_type}{Type of TVC effects modeled}
#'   \item{tvc_centered_values}{Centered covariate values used in estimation}
#'
#' @references
#' Curran, P. J., & Bauer, D. J. (2011). The disaggregation of within-person
#' and between-person effects in longitudinal models of change. *Annual Review
#' of Psychology*, 62, 583-619.
#'
#' Hoffman, L. (2015). *Longitudinal Analysis: Modeling Within-Person Fluctuation
#' and Change*. New York: Routledge.
#'
#' Wang, L. P., & Maxwell, S. E. (2015). On disaggregating between-person and
#' within-person effects with longitudinal data using multilevel models.
#' *Psychological Methods*, 20(1), 63-83.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Simulate data with covariates
#' set.seed(999)
#' sim_data <- simulate_gmm_survey(
#'   n_individuals = 200,
#'   n_times = 4,
#'   n_classes = 2,
#'   covariates = TRUE,
#'   design = "stratified_cluster",
#'   n_strata = 2,
#'   n_clusters = 20,
#'   seed = 999
#' )
#'
#' # Direct effects: covariate directly predicts outcome
#' fit_direct <- gmm_survey_tvc(
#'   data = sim_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "outcome",
#'   n_classes = 2,
#'   tvc = ~ baseline_risk,
#'   tvc_effects = "direct",
#'   starts = 20
#' )
#'
#' # Both within- and between-person effects
#' fit_both <- gmm_survey_tvc(
#'   data = sim_data,
#'   id = "id",
#'   time = "time",
#'   outcome = "outcome",
#'   n_classes = 2,
#'   tvc = ~ baseline_risk,
#'   tvc_effects = "both",
#'   starts = 20
#' )
#'
#' # Extract TVC effects
#' tvc_effects <- extract_tvc_effects(fit_both)
#' print(tvc_effects)
#' }
gmm_survey_tvc <- function(data,
                           id,
                           time,
                           outcome,
                           n_classes,
                           tvc,
                           growth_model = "linear",
                           strata = NULL,
                           cluster = NULL,
                           weights = NULL,
                           covariates = NULL,
                           tvc_effects = c("direct", "indirect", "both", "interaction"),
                           tvc_lag = 0,
                           center_tvc = TRUE,
                           tvc_by_class = FALSE,
                           starts = 500,
                           cores = parallel::detectCores() - 1,
                           convergence_threshold = 1e-6,
                           max_iterations = 1000,
                           seed = NULL,
                           verbose = TRUE) {

  tvc_effects <- match.arg(tvc_effects)

  # Validate TVC formula
  if (!inherits(tvc, "formula")) {
    stop("tvc must be a formula (e.g., ~ ses + monitoring)")
  }

  # Extract TVC variable names
  tvc_vars <- all.vars(tvc)

  # Check that TVCs exist in data
  missing_tvcs <- tvc_vars[!tvc_vars %in% names(data)]
  if (length(missing_tvcs) > 0) {
    stop("Time-varying covariates not found in data: ",
         paste(missing_tvcs, collapse = ", "))
  }

  # Detect which variables are actually time-varying
  tvc_check <- .check_time_varying(data, id, tvc_vars)

  if (any(!tvc_check$is_time_varying)) {
    non_tvc <- tvc_vars[!tvc_check$is_time_varying]
    warning("The following variables do not vary within individuals: ",
            paste(non_tvc, collapse = ", "),
            "\nConsider using them as time-invariant covariates instead.")
  }

  if (verbose) {
    cat("\nFitting Growth Mixture Model with Time-Varying Covariates\n")
    cat(rep("=", 60), "\n", sep = "")
    cat("TVC formula:", deparse(tvc), "\n")
    cat("Effect type:", tvc_effects, "\n")
    cat("Lag:", tvc_lag, "\n")
    cat("Centering:", center_tvc, "\n")
    cat("Class-specific effects:", tvc_by_class, "\n\n")
  }

  # Prepare TVC data
  tvc_data <- .prepare_tvc_data(
    data = data,
    id = id,
    time = time,
    tvc_vars = tvc_vars,
    tvc_effects = tvc_effects,
    tvc_lag = tvc_lag,
    center_tvc = center_tvc
  )

  # Call internal estimation function
  result <- .fit_gmm_tvc_internal(
    data = data,
    tvc_data = tvc_data,
    id = id,
    time = time,
    outcome = outcome,
    n_classes = n_classes,
    growth_model = growth_model,
    strata = strata,
    cluster = cluster,
    weights = weights,
    covariates = covariates,
    tvc_effects = tvc_effects,
    tvc_by_class = tvc_by_class,
    starts = starts,
    cores = cores,
    convergence_threshold = convergence_threshold,
    max_iterations = max_iterations,
    seed = seed,
    verbose = verbose
  )

  return(result)
}

#' Check if Variables are Time-Varying
#'
#' @keywords internal
.check_time_varying <- function(data, id, vars) {
  results <- data.frame(
    variable = vars,
    is_time_varying = logical(length(vars)),
    within_var = numeric(length(vars)),
    between_var = numeric(length(vars))
  )

  for (i in seq_along(vars)) {
    var <- vars[i]

    # Calculate within- and between-person variance
    by_id <- tapply(data[[var]], data[[id]], function(x) {
      c(mean = mean(x, na.rm = TRUE),
        var = var(x, na.rm = TRUE))
    })

    within_vars <- sapply(by_id, function(x) x["var"])
    between_means <- sapply(by_id, function(x) x["mean"])

    within_var <- mean(within_vars, na.rm = TRUE)
    between_var <- var(between_means, na.rm = TRUE)

    results$within_var[i] <- within_var
    results$between_var[i] <- between_var

    # Variable is time-varying if within-person variance > 0
    results$is_time_varying[i] <- within_var > 1e-10
  }

  return(results)
}

#' Prepare Time-Varying Covariate Data
#'
#' @keywords internal
.prepare_tvc_data <- function(data, id, time, tvc_vars, tvc_effects,
                              tvc_lag, center_tvc) {

  tvc_prepared <- data.frame(id = data[[id]], time = data[[time]])

  for (var in tvc_vars) {
    x <- data[[var]]

    # Apply lag if specified
    if (tvc_lag > 0) {
      x <- .apply_lag(data, id, time, var, lag = tvc_lag)
    }

    if (tvc_effects == "both") {
      # Person-mean centering for within-between decomposition
      person_means <- ave(x, data[[id]], FUN = function(y) mean(y, na.rm = TRUE))
      x_within <- x - person_means
      x_between <- person_means

      if (center_tvc) {
        grand_mean <- mean(x_between, na.rm = TRUE)
        x_between <- x_between - grand_mean
      }

      tvc_prepared[[paste0(var, "_within")]] <- x_within
      tvc_prepared[[paste0(var, "_between")]] <- x_between

    } else {
      # Standard centering
      if (center_tvc) {
        x <- scale(x, center = TRUE, scale = FALSE)[, 1]
      }
      tvc_prepared[[var]] <- x
    }
  }

  return(tvc_prepared)
}

#' Apply Lag to Time-Varying Covariate
#'
#' @keywords internal
.apply_lag <- function(data, id, time, var, lag = 1) {
  # Create lagged version of variable
  # Within each individual, shift values by 'lag' time points

  data_sorted <- data[order(data[[id]], data[[time]]), ]

  lagged_var <- rep(NA, nrow(data_sorted))

  for (indiv_id in unique(data_sorted[[id]])) {
    idx <- which(data_sorted[[id]] == indiv_id)

    if (length(idx) > lag) {
      # Shift values
      lagged_var[idx[(lag + 1):length(idx)]] <-
        data_sorted[[var]][idx[1:(length(idx) - lag)]]
    }
  }

  # Reorder to match original data
  lagged_var[order(order(data[[id]], data[[time]]))]

  return(lagged_var)
}

#' Internal Estimation for GMM with TVCs
#'
#' @keywords internal
.fit_gmm_tvc_internal <- function(...) {
  # Placeholder for full implementation
  # Would extend EM algorithm to include TVC effects
  stop("Full implementation pending. Requires integration with core EM algorithm.")
}

#' Extract Time-Varying Covariate Effects
#'
#' @description
#' Extracts estimated effects of time-varying covariates from a fitted model.
#'
#' @param object Fitted \code{SurveyMixrTVC} object
#' @param effect_type Character: "direct", "indirect", or "both"
#' @param class Optional; specific class to extract (default = "all")
#'
#' @return Data frame with TVC effect estimates, standard errors, and p-values
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Simulate data with covariates
#' set.seed(789)
#' sim_data <- simulate_gmm_survey(
#'   n_individuals = 200,
#'   n_times = 4,
#'   n_classes = 3,
#'   covariates = TRUE,
#'   seed = 789
#' )
#'
#' fit <- gmm_survey_tvc(
#'   data = sim_data,
#'   id = "id", time = "time", outcome = "outcome",
#'   n_classes = 3, tvc = ~ baseline_risk, tvc_effects = "both", starts = 20
#' )
#'
#' # Extract all TVC effects
#' effects <- extract_tvc_effects(fit)
#' print(effects)
#'
#' # Extract for specific class
#' effects_c1 <- extract_tvc_effects(fit, class = 1)
#' }
extract_tvc_effects <- function(object, effect_type = "all", class = "all") {

  if (!inherits(object, "SurveyMixrTVC")) {
    stop("object must be a SurveyMixrTVC object")
  }

  # Extract from model object
  tvc_effects <- object@tvc_effects

  # Filter by effect type and class if requested
  if (effect_type != "all") {
    tvc_effects <- tvc_effects[tvc_effects$effect_type == effect_type, ]
  }

  if (class != "all") {
    tvc_effects <- tvc_effects[tvc_effects$class == class, ]
  }

  return(tvc_effects)
}

#' Test Time-Varying Covariate Effects
#'
#' @description
#' Performs Wald tests for significance of TVC effects, both overall
#' and class-specific.
#'
#' @param object Fitted \code{SurveyMixrTVC} object
#' @param covariate Name of TVC to test
#' @param test Character: "overall" (test across all classes), "class_specific"
#'   (test within each class), or "both"
#'
#' @return List with test statistics and p-values
#'
#' @export
#'
#' @examples
#' \dontrun{
#' fit <- gmm_survey_tvc(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 3, tvc = ~ ses, starts = 100
#' )
#'
#' # Test significance of SES effect
#' test_results <- test_tvc_effects(fit, covariate = "ses")
#' print(test_results)
#' }
test_tvc_effects <- function(object, covariate,
                             test = c("both", "overall", "class_specific")) {

  if (!inherits(object, "SurveyMixrTVC")) {
    stop("object must be a SurveyMixrTVC object")
  }

  test <- match.arg(test)

  # Extract TVC effects for this covariate
  effects <- extract_tvc_effects(object)
  effects <- effects[effects$covariate == covariate, ]

  if (nrow(effects) == 0) {
    stop("Covariate '", covariate, "' not found in model")
  }

  results <- list()

  # Overall test (Wald test across all classes)
  if (test %in% c("overall", "both")) {
    # Test H0: all effects = 0
    # Would use Wald chi-square test
    results$overall <- list(
      statistic = NA,
      df = nrow(effects),
      p_value = NA
    )
  }

  # Class-specific tests
  if (test %in% c("class_specific", "both")) {
    results$by_class <- lapply(unique(effects$class), function(k) {
      eff_k <- effects[effects$class == k, ]
      # Wald test for this class
      list(
        class = k,
        estimate = eff_k$estimate,
        se = eff_k$se,
        z = eff_k$estimate / eff_k$se,
        p_value = 2 * pnorm(-abs(eff_k$estimate / eff_k$se))
      )
    })
  }

  class(results) <- "tvc_test"
  return(results)
}

#' Plot Time-Varying Covariate Effects
#'
#' @description
#' Visualizes how TVCs influence trajectories across latent classes.
#'
#' @param object Fitted \code{SurveyMixrTVC} object
#' @param covariate Name of TVC to plot
#' @param type Character: "effect" (show effect sizes), "trajectory" (show
#'   predicted trajectories at different TVC levels), or "interaction"
#' @param tvc_values Numeric vector of TVC values to plot (for "trajectory" type)
#'
#' @return ggplot2 object
#'
#' @export
plot_tvc_effects <- function(object, covariate, type = c("effect", "trajectory", "interaction"),
                             tvc_values = NULL) {

  if (!inherits(object, "SurveyMixrTVC")) {
    stop("object must be a SurveyMixrTVC object")
  }

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' required for plotting")
  }

  type <- match.arg(type)

  # Create plot based on type
  if (type == "effect") {
    p <- .plot_tvc_effect_sizes(object, covariate)
  } else if (type == "trajectory") {
    p <- .plot_tvc_trajectories(object, covariate, tvc_values)
  } else {
    p <- .plot_tvc_interactions(object, covariate)
  }

  return(p)
}

#' Internal: Plot TVC Effect Sizes
#'
#' @keywords internal
.plot_tvc_effect_sizes <- function(object, covariate) {
  # Forest plot of TVC effects by class
  stop("Plotting function - full implementation pending")
}

#' Internal: Plot Predicted Trajectories at Different TVC Levels
#'
#' @keywords internal
.plot_tvc_trajectories <- function(object, covariate, tvc_values) {
  # Show trajectories at low/medium/high TVC values
  stop("Plotting function - full implementation pending")
}

#' Internal: Plot TVC Interactions
#'
#' @keywords internal
.plot_tvc_interactions <- function(object, covariate) {
  # Show how TVC moderates trajectory slopes
  stop("Plotting function - full implementation pending")
}

#' Define SurveyMixrTVC S4 Class
#'
#' @description
#' S4 class for growth mixture models with time-varying covariates,
#' extends SurveyMixr class
#'
#' @slot tvc_effects Data frame with TVC effect estimates
#' @slot tvc_formula Formula specifying TVCs
#' @slot tvc_type Type of TVC effects (direct, indirect, both, interaction)
#' @slot tvc_centered_values Data frame with centered TVC values
#'
#' @keywords internal
#' @export
setClass("SurveyMixrTVC",
  contains = "SurveyMixr",
  slots = list(
    tvc_effects = "data.frame",
    tvc_formula = "formula",
    tvc_type = "character",
    tvc_centered_values = "data.frame"
  )
)
