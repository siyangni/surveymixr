#' surveymixr: Growth Mixture Models with Complex Survey Design
#'
#' @description
#' The surveymixr package implements growth mixture modeling for longitudinal
#' data with full integration of complex survey design features including
#' stratification, clustering, and probability weights.
#'
#' @details
#' Growth mixture models identify latent classes with distinct developmental
#' trajectories. This package enables such analyses with proper handling of
#' complex survey data from studies like the Millennium Cohort Study, Add Health,
#' NLSY, and others.
#'
#' @section Key Features:
#' \itemize{
#'   \item Complex survey integration (stratification, clustering, weights)
#'   \item Bootstrap Likelihood Ratio Test (BLRT) for class enumeration
#'   \item R3STEP method for auxiliary variable analysis
#'   \item Multiple random starts (500-1000+) with parallel processing
#'   \item Sandwich standard errors for survey designs
#'   \item Comprehensive convergence diagnostics
#'   \item Publication-ready visualization
#' }
#'
#' @section Main Functions:
#' \describe{
#'   \item{\code{\link{gmm_survey}}}{Fit growth mixture model with survey design}
#'   \item{\code{\link{gmm_select}}}{Model selection across class solutions}
#'   \item{\code{\link{r3step}}}{Auxiliary variable analysis with classification correction}
#'   \item{\code{\link{simulate_gmm_survey}}}{Simulate data for testing and validation}
#'   \item{\code{\link{diagnose_convergence}}}{Convergence diagnostics}
#'   \item{\code{\link{plot_trajectories}}}{Visualize growth trajectories}
#' }
#'
#' @section Getting Started:
#' See \code{vignette("surveymixr-intro")} for a comprehensive introduction
#' with examples.
#'
#' Quick example:
#' \preformatted{
#' library(surveymixr)
#' data(mcs_simulated)
#'
#' # Fit 3-class model
#' fit <- gmm_survey(
#'   data = mcs_simulated,
#'   id = "id",
#'   time = "age",
#'   outcome = "selfcontrol",
#'   n_classes = 3,
#'   strata = "stratum",
#'   cluster = "cluster",
#'   weights = "weight",
#'   starts = 500
#' )
#'
#' summary(fit)
#' plot(fit)
#' }
#'
#' @author Your Name \email{your.email@@example.com}
#'
#' @references
#' Muthén, B. (2004). Latent variable analysis: Growth mixture modeling and
#' related techniques for longitudinal data. In D. Kaplan (Ed.),
#' \emph{Handbook of quantitative methodology for the social sciences}
#' (pp. 345-368). Sage Publications.
#'
#' Asparouhov, T., & Muthén, B. (2014). Auxiliary variables in mixture modeling:
#' Three-step approaches using Mplus. \emph{Structural Equation Modeling, 21}(3),
#' 329-341.
#'
#' Nylund, K. L., Asparouhov, T., & Muthén, B. O. (2007). Deciding on the number
#' of classes in latent class analysis and growth mixture modeling.
#' \emph{Structural Equation Modeling, 14}(4), 535-569.
#'
#' @docType package
#' @name surveymixr-package
#' @aliases surveymixr
#' @keywords package
#' @importFrom stats as.formula kmeans p.adjust pf pt rbinom reshape rnorm runif weighted.mean dnorm
"_PACKAGE"

# Suppress R CMD check notes about ggplot2 NSE variables
utils::globalVariables(c(
  "value", "percent", "loglik", "converged", "max_pp", "n_classes",
  "time", "predicted", "lower", "upper"
))
