#' Simulated Millennium Cohort Study Data
#'
#' @description
#' Simulated longitudinal data resembling the UK Millennium Cohort Study (MCS).
#' Contains self-control trajectories from ages 3 to 17 with three latent classes,
#' along with complex survey design features (stratification, clustering, weights).
#'
#' @format A data frame with 29,400 rows and 14 variables:
#' \describe{
#'   \item{id}{Individual identifier (1 to 5000)}
#'   \item{age}{Age at assessment (3, 5, 7, 11, 14, 17 years)}
#'   \item{selfcontrol}{Self-control score (continuous, higher = better)}
#'   \item{true_class}{True latent class membership (1, 2, or 3) - for validation only}
#'   \item{stratum}{Stratum indicator (1 to 4)}
#'   \item{stratum_factor}{Stratum labels: England-Advantaged, England-Disadvantaged,
#'     Scotland/Wales, Northern Ireland}
#'   \item{cluster}{Primary sampling unit (PSU) identifier (1 to 200)}
#'   \item{weight}{Sampling weight (inverse probability weight)}
#'   \item{sex}{Sex (0 = Female, 1 = Male)}
#'   \item{sex_factor}{Sex labels (Female, Male)}
#'   \item{baseline_risk}{Baseline risk score (standardized, continuous)}
#'   \item{ses}{Socioeconomic status (standardized, continuous)}
#'   \item{delinquency}{Delinquency score at age 17 (0-10, higher = more delinquent)}
#'   \item{academic_achievement}{Academic achievement score (IQ-like, mean ~100)}
#' }
#'
#' @details
#' This dataset is designed to mimic key features of the UK Millennium Cohort Study
#' for teaching and demonstration purposes. It contains:
#'
#' \strong{Three Latent Classes:}
#' \itemize{
#'   \item \strong{Class 1 (55\%):} High self-control, stable trajectory
#'   \item \strong{Class 2 (30\%):} Moderate self-control, improving trajectory
#'   \item \strong{Class 3 (15\%):} Low self-control, declining trajectory
#' }
#'
#' \strong{Survey Design:}
#' \itemize{
#'   \item Stratified by region (4 strata)
#'   \item Clustered within PSUs (200 clusters)
#'   \item Probability weights to adjust for unequal sampling
#'   \item ~12\% missing data (MAR mechanism)
#' }
#'
#' \strong{Auxiliary Variables:}
#' \itemize{
#'   \item Delinquency and academic achievement are related to latent class
#'   \item Useful for demonstrating R3STEP analysis
#'   \item Sex and SES are time-invariant predictors
#' }
#'
#' \strong{Important:} The \code{true_class} variable is included only for
#' validation and teaching. In real applications, true class membership is
#' unknown and must be estimated.
#'
#' @source
#' Simulated using \code{\link{simulate_gmm_survey}} with parameters inspired by:
#'
#' Moffitt, T. E. (2006). Life-course-persistent versus adolescence-limited
#' antisocial behavior. In D. Cicchetti & D. J. Cohen (Eds.),
#' \emph{Developmental psychopathology} (2nd ed., pp. 570-598). Wiley.
#'
#' The actual Millennium Cohort Study data can be accessed through the UK Data
#' Service: \url{https://ukdataservice.ac.uk/}
#'
#' @examples
#' \dontrun{
#' # Load data
#' data(mcs_simulated)
#'
#' # Explore structure
#' head(mcs_simulated)
#' table(mcs_simulated$true_class)
#'
#' # Visualize trajectories by true class
#' library(ggplot2)
#' ggplot(mcs_simulated, aes(x = age, y = selfcontrol, group = id,
#'                           color = factor(true_class))) +
#'   geom_line(alpha = 0.2) +
#'   facet_wrap(~true_class) +
#'   theme_minimal()
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
#'   starts = 100,  # Use more for final analysis
#'   cores = 4
#' )
#'
#' summary(fit)
#' plot(fit, type = "trajectories")
#'
#' # Compare estimated vs true classification
#' table(Estimated = fit@class_assignments,
#'       True = mcs_simulated$true_class[!duplicated(mcs_simulated$id)])
#'
#' # R3STEP analysis with distal outcomes
#' r3step_results <- r3step(
#'   gmm_object = fit,
#'   distal_vars = c("delinquency", "academic_achievement"),
#'   data = mcs_simulated[!duplicated(mcs_simulated$id), ]
#' )
#' summary(r3step_results)
#' }
#'
#' @name mcs_simulated
#' @keywords datasets
#' @aliases mcs_simulated
#' @docType data
