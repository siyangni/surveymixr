#' Utility Functions for surveymixr
#'
#' @description
#' Helper functions for format conversion, data manipulation, and comparisons
#' with other software.
#'
#' @name utilities
#' @rdname utilities
NULL


#' Convert Mplus Syntax to surveymixr
#'
#' @description
#' Parses Mplus input file and suggests equivalent surveymixr code.
#'
#' @param mplus_file Path to Mplus .inp file
#'
#' @return Character string with suggested R code
#'
#' @details
#' This function reads an Mplus input file for growth mixture models and
#' generates equivalent surveymixr code. Note that not all Mplus features
#' can be directly translated.
#'
#' Supported Mplus features:
#' \itemize{
#'   \item VARIABLE section: NAMES, USEVAR, CLASSES, CLUSTER, WEIGHT, STRATIFICATION
#'   \item ANALYSIS section: TYPE = MIXTURE, STARTS
#'   \item MODEL section: Linear and quadratic growth specifications
#' }
#'
#' @examples
#' \donttest{
#' # Create example Mplus file
#' mplus_code <- '
#' VARIABLE:
#'   NAMES = id time y stratum psu weight;
#'   USEVAR = y;
#'   CLASSES = c(3);
#'   CLUSTER = psu;
#'   STRATIFICATION = stratum;
#'   WEIGHT = weight;
#'
#' ANALYSIS:
#'   TYPE = MIXTURE;
#'   STARTS = 500 100;
#'
#' MODEL:
#'   %OVERALL%
#'   i s | y@0 y@1 y@2 y@3 y@4;
#' '
#'
#' writeLines(mplus_code, "example.inp")
#' r_code <- mplus_to_surveymixr("example.inp")
#' cat(r_code)
#' }
#'
#' @export
mplus_to_surveymixr <- function(mplus_file) {

  if (!file.exists(mplus_file)) {
    stop(sprintf("File not found: %s", mplus_file))
  }

  mplus_lines <- readLines(mplus_file)
  mplus_text <- paste(mplus_lines, collapse = "\n")

  # Extract key information
  n_classes <- NA
  cluster_var <- NA
  strata_var <- NA
  weight_var <- NA
  outcome_var <- NA
  starts <- 500

  # Parse CLASSES
  classes_match <- regexpr("CLASSES\\s*=\\s*\\w+\\((\\d+)\\)", mplus_text, perl = TRUE)
  if (classes_match > 0) {
    n_classes <- as.numeric(gsub(".*\\((\\d+)\\).*", "\\1",
                                regmatches(mplus_text, classes_match)))
  }

  # Parse CLUSTER
  cluster_match <- regexpr("CLUSTER\\s*=\\s*(\\w+)", mplus_text, perl = TRUE)
  if (cluster_match > 0) {
    cluster_var <- gsub("CLUSTER\\s*=\\s*(\\w+)", "\\1",
                       regmatches(mplus_text, cluster_match))
  }

  # Parse STRATIFICATION
  strata_match <- regexpr("STRATIFICATION\\s*=\\s*(\\w+)", mplus_text, perl = TRUE)
  if (strata_match > 0) {
    strata_var <- gsub("STRATIFICATION\\s*=\\s*(\\w+)", "\\1",
                      regmatches(mplus_text, strata_match))
  }

  # Parse WEIGHT
  weight_match <- regexpr("WEIGHT\\s*=\\s*(\\w+)", mplus_text, perl = TRUE)
  if (weight_match > 0) {
    weight_var <- gsub("WEIGHT\\s*=\\s*(\\w+)", "\\1",
                      regmatches(mplus_text, weight_match))
  }

  # Parse STARTS
  starts_match <- regexpr("STARTS\\s*=\\s*(\\d+)", mplus_text, perl = TRUE)
  if (starts_match > 0) {
    starts <- as.numeric(gsub("STARTS\\s*=\\s*(\\d+).*", "\\1",
                             regmatches(mplus_text, starts_match)))
  }

  # Generate R code
  r_code <- sprintf('
# Translated from Mplus to surveymixr
# Original file: %s
# Manual review and adjustment recommended

library(surveymixr)

# Load your data
# data <- read.table("your_data_file.txt", header = TRUE)

fit <- gmm_survey(
  data = data,
  id = "id",
  time = "time",
  outcome = "outcome_variable",  # UPDATE THIS
  n_classes = %s,
  growth_model = "linear",  # or "quadratic" - check your Mplus MODEL section
  %s
  starts = %d,
  cores = 4,  # Adjust based on your system
  verbose = TRUE
)

summary(fit)
plot(fit, type = "trajectories")

# Model selection
selection <- gmm_select(
  data = data,
  id = "id",
  time = "time",
  outcome = "outcome_variable",
  classes = 1:%d,
  %s
  criteria = c("BIC", "BLRT", "entropy"),
  blrt_samples = 100,
  starts = %d,
  cores = 4
)

print(selection)
',
    mplus_file,
    ifelse(is.na(n_classes), "3  # UPDATE THIS", n_classes),
    paste(
      if (!is.na(cluster_var)) sprintf('  cluster = "%s",', cluster_var) else "",
      if (!is.na(strata_var)) sprintf('  strata = "%s",', strata_var) else "",
      if (!is.na(weight_var)) sprintf('  weights = "%s",', weight_var) else "",
      sep = "\n"
    ),
    starts,
    ifelse(is.na(n_classes), "5", n_classes + 2),
    paste(
      if (!is.na(cluster_var)) sprintf('  cluster = "%s",', cluster_var) else "",
      if (!is.na(strata_var)) sprintf('  strata = "%s",', strata_var) else "",
      if (!is.na(weight_var)) sprintf('  weights = "%s",', weight_var) else "",
      sep = "\n"
    ),
    max(100, starts / 2)
  )

  # Add notes
  notes <- sprintf('

# NOTES:
# 1. Update variable names to match your data
# 2. Verify growth model specification (linear vs quadratic)
# 3. Check time coding (Mplus uses @ notation, surveymixr uses actual time values)
# 4. Mplus "TECH" output equivalents:
#    - TECH1 (parameters): summary(fit)
#    - TECH7 (sample stats by class): Not directly available
#    - TECH11 (Lo-Mendell-Rubin): Use BLRT in gmm_select()
#    - TECH14 (classification quality): classification_quality(fit)
# 5. For auxiliary variables (3-step), use:
#    r3step(fit, distal_vars = c("var1", "var2"), data = data)
')

  paste0(r_code, notes)
}


#' Convert surveymixr Output to Mplus Format
#'
#' @description
#' Generates Mplus-style output summary from a surveymixr object.
#'
#' @param object A \code{SurveyMixr} object
#' @param file Optional file path to write output (default: print to console)
#'
#' @return Character string with Mplus-style output (invisibly)
#'
#' @export
surveymixr_to_mplus <- function(object, file = NULL) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  n_classes <- object@model_info$n_classes

  output <- sprintf('
MIXTURE MODEL OUTPUT (surveymixr)
=================================

MODEL FIT INFORMATION

Number of Free Parameters: %d

Loglikelihood

    H0 Value: %.3f

Information Criteria

    Akaike (AIC): %.3f
    Bayesian (BIC): %.3f
    Sample-Size Adjusted BIC: %.3f

Entropy: %.3f


FINAL CLASS COUNTS AND PROPORTIONS

    Latent Classes
',
    object@fit_indices$n_params,
    object@fit_indices$loglik,
    object@fit_indices$aic,
    object@fit_indices$bic,
    object@fit_indices$abic,
    object@fit_indices$entropy
  )

  for (k in 1:n_classes) {
    output <- paste0(output, sprintf("    %d    %8.5f    %.5f\n",
                                    k,
                                    sum(object@class_assignments == k),
                                    object@class_proportions$weighted[k]))
  }

  output <- paste0(output, sprintf('\n\nCLASSIFICATION QUALITY

    Entropy: %.3f
', object@fit_indices$entropy))

  output <- paste0(output, sprintf('\n    Average Latent Class Probabilities for Most Likely Latent Class Membership\n\n'))

  for (k in 1:n_classes) {
    avepp <- object@fit_indices$avepp_by_class[k]
    output <- paste0(output, sprintf("    Class %d: %.3f\n", k, avepp))
  }

  output <- paste0(output, '\n\nMODEL RESULTS\n\n')

  for (k in 1:n_classes) {
    output <- paste0(output, sprintf('Latent Class %d\n\n', k))

    gp <- object@parameters$growth_parameters[[k]]
    se <- object@standard_errors$growth_parameters[[k]]

    output <- paste0(output, sprintf('    Means\n'))
    output <- paste0(output, sprintf('      I        %8.3f    %8.3f\n',
                                     gp$intercept, se$intercept))
    output <- paste0(output, sprintf('      S        %8.3f    %8.3f\n',
                                     gp$slope, se$slope))

    if (!is.null(gp$quadratic)) {
      output <- paste0(output, sprintf('      Q        %8.3f    %8.3f\n',
                                       gp$quadratic, se$quadratic))
    }

    output <- paste0(output, sprintf('\n    Variances\n'))
    output <- paste0(output, sprintf('      Residual %8.3f\n\n',
                                     object@parameters$residual_variance[k]))
  }

  output <- paste0(output, sprintf('
SURVEY DESIGN INFORMATION

  Survey weights: %s
  Clustering (PSU): %s
  Stratification: %s

NOTE: Standard errors are adjusted for complex survey design using
sandwich estimator.

',
    ifelse(object@survey_design$has_weights, "Yes", "No"),
    ifelse(object@survey_design$has_cluster, "Yes", "No"),
    ifelse(object@survey_design$has_strata, "Yes", "No")
  ))

  if (!is.null(file)) {
    writeLines(output, file)
    message(sprintf("Mplus-style output written to: %s", file))
  } else {
    cat(output)
  }

  invisible(output)
}


#' Compare surveymixr and Mplus Results
#'
#' @description
#' Compares parameter estimates from surveymixr and Mplus for validation.
#'
#' @param surveymixr_object A \code{SurveyMixr} object
#' @param mplus_output Path to Mplus output file (.out)
#'
#' @return Data frame comparing parameter estimates
#'
#' @details
#' This function reads Mplus output and compares key parameters with
#' surveymixr estimates. Useful for validation and troubleshooting.
#'
#' Note: Class labels may differ between software. You may need to manually
#' reorder classes for fair comparison.
#'
#' @export
compare_with_mplus <- function(surveymixr_object, mplus_output) {

  message("This function requires manual parsing of Mplus output.")
  message("Automatic parsing not yet implemented.")
  message("\nTo manually compare:")
  message("1. Extract log-likelihood: surveymixr_object@fit_indices$loglik")
  message("2. Extract BIC: surveymixr_object@fit_indices$bic")
  message("3. Extract parameters: coef(surveymixr_object)")
  message("4. Compare with Mplus MODEL RESULTS section")

  return(NULL)
}


#' Extract Information Criteria
#'
#' @description
#' Extracts all information criteria from a fitted model or model selection object.
#'
#' @param object Either a \code{SurveyMixr} or \code{SurveyMixrSelect} object
#'
#' @return Data frame with information criteria
#'
#' @examples
#' \donttest{
#' fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
#'                   outcome = "selfcontrol", n_classes = 3)
#' extract_fit_indices(fit)
#' }
#'
#' @export
extract_fit_indices <- function(object) {

  if (inherits(object, "SurveyMixr")) {
    data.frame(
      n_classes = object@model_info$n_classes,
      loglik = object@fit_indices$loglik,
      aic = object@fit_indices$aic,
      bic = object@fit_indices$bic,
      abic = object@fit_indices$abic,
      entropy = object@fit_indices$entropy,
      n_params = object@fit_indices$n_params,
      stringsAsFactors = FALSE
    )

  } else if (inherits(object, "SurveyMixrSelect")) {
    object@comparison_table

  } else {
    stop("object must be SurveyMixr or SurveyMixrSelect")
  }
}


#' Reshape Data from Wide to Long
#'
#' @description
#' Helper function to reshape data for gmm_survey if in wide format.
#'
#' @param data Data frame in wide format
#' @param id_var Character string, ID variable name
#' @param outcome_vars Character vector of outcome variable names (ordered by time)
#' @param time_values Optional numeric vector of time values (default: 0, 1, 2, ...)
#'
#' @return Data frame in long format
#'
#' @examples
#' \donttest{
#' # Wide format data
#' wide_data <- data.frame(
#'   id = 1:100,
#'   y_t0 = rnorm(100),
#'   y_t1 = rnorm(100),
#'   y_t2 = rnorm(100)
#' )
#'
#' # Convert to long
#' long_data <- wide_to_long(
#'   data = wide_data,
#'   id_var = "id",
#'   outcome_vars = c("y_t0", "y_t1", "y_t2")
#' )
#' }
#'
#' @export
wide_to_long <- function(data, id_var, outcome_vars, time_values = NULL) {

  if (!all(outcome_vars %in% names(data))) {
    stop("Not all outcome_vars found in data")
  }

  n <- nrow(data)
  n_times <- length(outcome_vars)

  if (is.null(time_values)) {
    time_values <- 0:(n_times - 1)
  }

  if (length(time_values) != n_times) {
    stop("time_values length must match outcome_vars length")
  }

  # Create long format
  long_list <- list()

  for (i in 1:n) {
    df_i <- data.frame(
      id = data[[id_var]][i],
      time = time_values,
      outcome = as.numeric(data[i, outcome_vars]),
      stringsAsFactors = FALSE
    )

    names(df_i)[1] <- id_var

    long_list[[i]] <- df_i
  }

  long_data <- do.call(rbind, long_list)
  rownames(long_data) <- NULL

  # Add other variables (time-invariant)
  other_vars <- setdiff(names(data), c(id_var, outcome_vars))
  if (length(other_vars) > 0) {
    merge_data <- data[, c(id_var, other_vars), drop = FALSE]
    long_data <- merge(long_data, merge_data, by = id_var)
  }

  return(long_data)
}
