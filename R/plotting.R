#' Plotting Functions for surveymixr
#'
#' @description
#' Visualization functions for growth mixture models
#'
#' @name plotting
#' @rdname plotting
NULL


#' Plot Trajectories by Latent Class
#'
#' @description
#' Creates a publication-ready plot of estimated growth trajectories for each
#' latent class with optional confidence intervals.
#'
#' @param object A \code{SurveyMixr} object from \code{gmm_survey()}
#' @param include_ci Logical, include confidence intervals? (default: TRUE)
#' @param weighted Logical, use weighted class proportions for subtitle?
#'   (default: TRUE)
#' @param alpha Transparency level for confidence bands (default: 0.2)
#' @param colors Optional vector of colors for classes (default: Color Brewer)
#' @param title Optional plot title
#' @param xlab X-axis label (default: "Time")
#' @param ylab Y-axis label (default: "Outcome")
#' @param legend_position Position of legend (default: "right")
#' @param ... Additional arguments (not currently used)
#'
#' @return A ggplot2 object
#'
#' @examples
#' \donttest{
#' fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
#'                   outcome = "selfcontrol", n_classes = 3)
#' plot_trajectories(fit)
#' }
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon labs theme_minimal
#' @importFrom ggplot2 scale_color_brewer theme element_text
plot_trajectories <- function(object,
                              include_ci = TRUE,
                              weighted = TRUE,
                              alpha = 0.2,
                              colors = NULL,
                              title = NULL,
                              xlab = "Time",
                              ylab = "Outcome",
                              legend_position = "right",
                              ...) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  n_classes <- object@model_info$n_classes
  time_scores <- object@model_info$time_scores
  growth_model <- object@model_info$growth_model

  # Create data for plotting
  plot_data <- data.frame()

  for (k in 1:n_classes) {
    # Predicted trajectory
    y_pred <- predict_trajectory(
      time_scores,
      object@parameters$growth_parameters[[k]],
      growth_model
    )

    # Standard errors for confidence intervals
    if (include_ci) {
      # Simplified CI: use parameter SEs to construct pointwise CIs
      # This is approximate - full CI would require delta method
      gp <- object@parameters$growth_parameters[[k]]
      se <- object@standard_errors$growth_parameters[[k]]

      if (growth_model == "linear") {
        # y = intercept + slope * time
        # Var(y) = Var(int) + time^2 * Var(slope) + 2*time*Cov(int,slope)
        # Simplified: ignore covariance
        y_se <- sqrt(se$intercept^2 + (time_scores * se$slope)^2)
      } else {
        # Simplified SE
        y_se <- rep(se$intercept, length(time_scores))
      }

      y_lower <- y_pred - 1.96 * y_se
      y_upper <- y_pred + 1.96 * y_se
    } else {
      y_lower <- y_pred
      y_upper <- y_pred
    }

    # Class proportion for label
    if (weighted) {
      class_prop <- object@class_proportions$weighted[k]
    } else {
      class_prop <- object@class_proportions$unweighted[k]
    }

    class_label <- sprintf("Class %d (%.1f%%)", k, class_prop * 100)

    df_k <- data.frame(
      time = time_scores,
      predicted = y_pred,
      lower = y_lower,
      upper = y_upper,
      class = class_label,
      class_num = k,
      stringsAsFactors = FALSE
    )

    plot_data <- rbind(plot_data, df_k)
  }

  # Create plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = time, y = predicted,
                                                color = class, fill = class))

  # Add confidence intervals
  if (include_ci) {
    p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper),
                                   alpha = alpha, color = NA)
  }

  # Add trajectory lines
  p <- p + ggplot2::geom_line(linewidth = 1.2)

  # Styling
  if (!is.null(colors)) {
    p <- p + ggplot2::scale_color_manual(values = colors) +
             ggplot2::scale_fill_manual(values = colors)
  } else {
    p <- p + ggplot2::scale_color_brewer(palette = "Set1") +
             ggplot2::scale_fill_brewer(palette = "Set1")
  }

  # Labels
  if (is.null(title)) {
    title <- sprintf("Growth Trajectories: %d-Class Solution", n_classes)
  }

  p <- p + ggplot2::labs(
    title = title,
    subtitle = sprintf("Growth model: %s | Entropy: %.3f",
                      growth_model, object@fit_indices$entropy),
    x = xlab,
    y = ylab,
    color = "Latent Class",
    fill = "Latent Class"
  )

  # Theme
  p <- p + ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = legend_position,
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray30")
    )

  return(p)
}


#' Plot Class Comparison for a Variable
#'
#' @description
#' Creates density plots or boxplots comparing classes on a specific variable.
#'
#' @param object A \code{SurveyMixr} object
#' @param variable Character string, name of variable to compare (must be in
#'   original data)
#' @param type Character: "density" (default) or "boxplot"
#' @param ... Additional arguments
#'
#' @return A ggplot2 object
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_density facet_wrap
plot_class_comparison <- function(object, variable, type = "density", ...) {

  if (nrow(object@data) == 0) {
    stop("Data not available. Re-fit model with keep_data = TRUE")
  }

  if (!variable %in% names(object@data)) {
    stop(sprintf("Variable '%s' not found in data", variable))
  }

  # Prepare data
  plot_df <- data.frame(
    value = object@data[[variable]],
    class = factor(object@class_assignments),
    stringsAsFactors = FALSE
  )

  # Remove missing
  plot_df <- plot_df[!is.na(plot_df$value), ]

  if (type == "density") {
    p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = value, fill = class)) +
      ggplot2::geom_density(alpha = 0.5) +
      ggplot2::facet_wrap(~class, ncol = 1) +
      ggplot2::scale_fill_brewer(palette = "Set1") +
      ggplot2::labs(
        title = sprintf("Distribution of %s by Class", variable),
        x = variable,
        y = "Density"
      ) +
      ggplot2::theme_minimal()

  } else if (type == "boxplot") {
    p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = class, y = value, fill = class)) +
      ggplot2::geom_boxplot() +
      ggplot2::scale_fill_brewer(palette = "Set1") +
      ggplot2::labs(
        title = sprintf("Distribution of %s by Class", variable),
        x = "Class",
        y = variable
      ) +
      ggplot2::theme_minimal()

  } else {
    stop("type must be 'density' or 'boxplot'")
  }

  return(p)
}


#' Plot Entropy Distribution
#'
#' @description
#' Visualizes the distribution of maximum posterior probabilities to assess
#' classification quality.
#'
#' @param object A \code{SurveyMixr} object
#' @param ... Additional arguments
#'
#' @return A ggplot2 object
#'
#' @keywords internal
#' @importFrom ggplot2 ggplot aes geom_histogram geom_vline
plot_entropy_distribution <- function(object, ...) {

  max_post_probs <- apply(object@posterior_probs, 1, max)

  plot_df <- data.frame(
    max_pp = max_post_probs,
    class = factor(object@class_assignments)
  )

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = max_pp, fill = class)) +
    ggplot2::geom_histogram(bins = 30, alpha = 0.7, color = "black") +
    ggplot2::geom_vline(xintercept = 0.8, linetype = "dashed", color = "red") +
    ggplot2::facet_wrap(~class, ncol = 1) +
    ggplot2::scale_fill_brewer(palette = "Set1") +
    ggplot2::labs(
      title = "Classification Quality: Maximum Posterior Probabilities",
      subtitle = sprintf("Entropy = %.3f | Values > 0.8 indicate good separation",
                        object@fit_indices$entropy),
      x = "Maximum Posterior Probability",
      y = "Frequency"
    ) +
    ggplot2::theme_minimal()

  return(p)
}


#' Plot Convergence Diagnostics
#'
#' @description
#' Visualizes the distribution of log-likelihoods from random starts to
#' identify local maxima.
#'
#' @param object A \code{SurveyMixr} object
#' @param ... Additional arguments
#'
#' @return A ggplot2 object
#'
#' @keywords internal
#' @importFrom ggplot2 ggplot aes geom_histogram geom_vline annotate
plot_convergence <- function(object, ...) {

  logliks <- object@random_starts$logliks
  logliks_finite <- logliks[is.finite(logliks)]

  if (length(logliks_finite) == 0) {
    stop("No valid log-likelihoods to plot")
  }

  best_loglik <- object@convergence_info$best_loglik
  n_replications <- object@convergence_info$n_replications

  plot_df <- data.frame(
    loglik = logliks_finite,
    converged = object@random_starts$converged[is.finite(logliks)]
  )

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = loglik, fill = converged)) +
    ggplot2::geom_histogram(bins = 30, alpha = 0.7, color = "black") +
    ggplot2::geom_vline(xintercept = best_loglik, linetype = "dashed",
                       color = "red", linewidth = 1) +
    ggplot2::annotate("text", x = best_loglik, y = Inf,
                     label = sprintf("Best LogLik\n%.2f\n(%d replications)",
                                   best_loglik, n_replications),
                     vjust = 1.5, hjust = -0.1, color = "red", size = 3.5) +
    ggplot2::labs(
      title = "Convergence Diagnostics: Distribution of Log-Likelihoods",
      subtitle = sprintf("%d random starts | %d converged",
                        length(logliks), sum(plot_df$converged)),
      x = "Log-Likelihood",
      y = "Frequency",
      fill = "Converged"
    ) +
    ggplot2::theme_minimal()

  return(p)
}


#' Plot Class Sizes
#'
#' @description
#' Bar plot showing the proportion of individuals in each class.
#'
#' @param object A \code{SurveyMixr} object
#' @param weighted Logical, use weighted proportions? (default: TRUE)
#' @param ... Additional arguments
#'
#' @return A ggplot2 object
#'
#' @keywords internal
#' @importFrom ggplot2 ggplot aes geom_col geom_hline geom_text coord_flip
plot_class_sizes <- function(object, weighted = TRUE, ...) {

  if (weighted && object@survey_design$has_weights) {
    props <- object@class_proportions$weighted
    subtitle <- "Survey-weighted proportions"
  } else {
    props <- object@class_proportions$unweighted
    subtitle <- "Unweighted proportions"
  }

  plot_df <- data.frame(
    class = factor(paste0("Class ", 1:length(props))),
    proportion = props,
    percent = props * 100
  )

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = class, y = percent, fill = class)) +
    ggplot2::geom_col(alpha = 0.8, color = "black") +
    ggplot2::geom_hline(yintercept = 5, linetype = "dashed", color = "red") +
    ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f%%", percent)),
                      vjust = -0.5, size = 4) +
    ggplot2::scale_fill_brewer(palette = "Set1") +
    ggplot2::labs(
      title = "Latent Class Proportions",
      subtitle = subtitle,
      x = "Class",
      y = "Percentage (%)",
      caption = "Red line indicates 5% threshold"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none")

  return(p)
}


#' Plot Model Selection Comparison
#'
#' @description
#' Visualizes fit indices across different numbers of classes to aid in
#' model selection.
#'
#' @param select_object A \code{SurveyMixrSelect} object from \code{gmm_select()}
#' @param criteria Character vector of criteria to plot: "BIC", "AIC", "aBIC",
#'   "entropy" (default: all available)
#' @param ... Additional arguments
#'
#' @return A ggplot2 object
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_line geom_point facet_wrap scale_y_continuous
plot_model_selection <- function(select_object, criteria = NULL, ...) {

  if (!inherits(select_object, "SurveyMixrSelect")) {
    stop("select_object must be a SurveyMixrSelect object")
  }

  comp_table <- select_object@comparison_table

  if (is.null(criteria)) {
    criteria <- c("bic", "aic", "abic", "entropy")
    criteria <- criteria[criteria %in% names(comp_table)]
  } else {
    criteria <- tolower(criteria)
  }

  # Reshape data for plotting
  plot_data <- data.frame()

  for (crit in criteria) {
    if (crit %in% names(comp_table)) {
      df_crit <- data.frame(
        n_classes = comp_table$n_classes,
        value = comp_table[[crit]],
        criterion = toupper(crit),
        stringsAsFactors = FALSE
      )
      plot_data <- rbind(plot_data, df_crit)
    }
  }

  # Normalize for better visualization (each criterion on 0-1 scale)
  plot_data_norm <- data.frame()
  for (crit in unique(plot_data$criterion)) {
    df_crit <- plot_data[plot_data$criterion == crit, ]

    # For entropy, higher is better (no transformation)
    # For IC, lower is better (invert for visualization)
    if (crit == "ENTROPY") {
      df_crit$value_norm <- df_crit$value
      df_crit$better <- "Higher"
    } else {
      # Normalize IC: (max - value) / (max - min)
      val_range <- max(df_crit$value) - min(df_crit$value)
      if (val_range > 0) {
        df_crit$value_norm <- (max(df_crit$value) - df_crit$value) / val_range
      } else {
        df_crit$value_norm <- 0.5
      }
      df_crit$better <- "Lower"
    }

    plot_data_norm <- rbind(plot_data_norm, df_crit)
  }

  # Plot
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = n_classes, y = value)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 3, color = "darkblue") +
    ggplot2::facet_wrap(~criterion, scales = "free_y", ncol = 2) +
    ggplot2::scale_x_continuous(breaks = unique(plot_data$n_classes)) +
    ggplot2::labs(
      title = "Model Selection: Fit Indices Across Class Solutions",
      subtitle = sprintf("Recommended: %d classes",
                        select_object@recommended_classes),
      x = "Number of Classes",
      y = "Fit Index Value"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "bold", size = 11),
      plot.title = ggplot2::element_text(face = "bold", size = 14)
    )

  return(p)
}
