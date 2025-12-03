# Interactive Plotting with Plotly
#
# Provides interactive visualization capabilities for growth mixture models
# using plotly for enhanced exploration and presentation
#
# Phase 2.4 of the development roadmap

#' Create Interactive Trajectory Plot
#'
#' @description
#' Generates an interactive plotly visualization of growth trajectories
#' with hover information, zoom capabilities, and customization options.
#'
#' @param object Fitted \code{SurveyMixr} object
#' @param type Character: "trajectories" (default), "individual", or "spaghetti"
#' @param interactive Logical; if TRUE, returns plotly object; if FALSE, returns ggplot
#' @param show_ci Logical; show confidence intervals?
#' @param show_points Logical; show individual observed points?
#' @param n_individuals For "individual" plots, number of individuals to show per class
#' @param color_palette Character vector of colors or name of palette
#' @param title Optional plot title
#' @param ... Additional arguments passed to plotting functions
#'
#' @details
#' Creates interactive visualizations with the following features:
#'
#' **Hover Information:**
#' - Class label and proportion
#' - Parameter estimates (intercept, slope)
#' - Confidence intervals
#' - Individual IDs (for individual plots)
#'
#' **Interactivity:**
#' - Zoom and pan
#' - Toggle classes on/off
#' - Download as PNG
#' - Customizable layout
#'
#' **Plot Types:**
#' - **trajectories**: Class-specific mean trajectories with CI
#' - **individual**: Sample of individual trajectories within each class
#' - **spaghetti**: All individual trajectories overlaid
#'
#' @return If \code{interactive = TRUE}, a \code{plotly} object; otherwise a \code{ggplot} object
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Quick example (reduced for speed)
#' data(mcs_simulated)
#' set.seed(123)
#'
#' fit <- gmm_survey(
#'   data = mcs_simulated,
#'   id = "id", time = "age", outcome = "selfcontrol",
#'   n_classes = 2, starts = 5, verbose = FALSE
#' )
#'
#' if (requireNamespace("plotly", quietly = TRUE)) {
#'   # Interactive trajectory plot
#'   p <- plot_interactive(fit, type = "trajectories")
#'
#'   # Save to HTML file (use tempfile to avoid leaving files)
#'   if (requireNamespace("htmlwidgets", quietly = TRUE)) {
#'     tmp_html <- tempfile(fileext = ".html")
#'     htmlwidgets::saveWidget(p, tmp_html)
#'     unlink(tmp_html)  # Clean up
#'   }
#' }
#' }
plot_interactive <- function(object,
                            type = c("trajectories", "individual", "spaghetti"),
                            interactive = TRUE,
                            show_ci = TRUE,
                            show_points = FALSE,
                            n_individuals = 10,
                            color_palette = NULL,
                            title = NULL,
                            ...) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  type <- match.arg(type)

  # Check if plotly is available
  if (interactive && !requireNamespace("plotly", quietly = TRUE)) {
    warning("Package 'plotly' not available. Returning ggplot object instead.")
    interactive <- FALSE
  }

  # Create base ggplot
  if (type == "trajectories") {
    p <- .plot_trajectories_ggplot(object, show_ci, show_points, color_palette)
  } else if (type == "individual") {
    p <- .plot_individual_ggplot(object, n_individuals, color_palette)
  } else {  # spaghetti
    p <- .plot_spaghetti_ggplot(object, n_individuals, color_palette)
  }

  # Add title if provided
  if (!is.null(title)) {
    p <- p + ggplot2::labs(title = title)
  }

  # Convert to plotly if interactive
  if (interactive) {
    p <- plotly::ggplotly(p, tooltip = c("x", "y", "colour"))

    # Enhance layout
    p <- plotly::layout(p,
      hovermode = "closest",
      font = list(size = 12),
      legend = list(
        orientation = "v",
        x = 1.02,
        y = 1
      )
    )
  }

  return(p)
}

#' Internal: Create Trajectory ggplot
#'
#' @keywords internal
.plot_trajectories_ggplot <- function(object, show_ci, show_points, color_palette) {

  # Extract trajectories for all classes
  n_classes <- object@model_info$n_classes
  traj_list <- lapply(1:n_classes, function(k) {
    extract_trajectories(object, class = k)
  })
  traj_data <- do.call(rbind, traj_list)

  # Get colors
  n_classes <- object@model_info$n_classes
  if (is.null(color_palette)) {
    colors <- scales::hue_pal()(n_classes)
  } else if (length(color_palette) == 1) {
    # Named palette
    colors <- scales::brewer_pal(palette = color_palette)(n_classes)
  } else {
    colors <- color_palette[1:n_classes]
  }

  # Create plot
  p <- ggplot2::ggplot(traj_data, ggplot2::aes(x = time, y = predicted,
                                               color = factor(class),
                                               fill = factor(class),
                                               group = class)) +
    ggplot2::geom_line(linewidth = 1.2) +
    ggplot2::scale_color_manual(
      values = colors,
      name = "Latent Class",
      labels = paste0("Class ", 1:n_classes, " (",
                     round(object@class_proportions$weighted * 100, 1), "%)")
    ) +
    ggplot2::scale_fill_manual(values = colors, guide = "none") +
    ggplot2::labs(
      x = "Time",
      y = "Outcome",
      title = "Growth Trajectories by Latent Class"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5),
      legend.position = "right"
    )

  # Add confidence intervals
  if (show_ci && all(c("ci_lower", "ci_upper") %in% names(traj_data))) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(ymin = ci_lower, ymax = ci_upper),
      alpha = 0.2,
      color = NA
    )
  }

  # Add observed points (optional)
  if (show_points) {
    obs_data <- object@data
    obs_data$class <- apply(object@posterior_probs, 1, which.max)

    p <- p + ggplot2::geom_point(
      data = obs_data,
      ggplot2::aes(x = .data[[object@model_info$time_var]],
                  y = .data[[object@model_info$outcome_var]],
                  color = factor(class)),
      alpha = 0.1,
      size = 0.5,
      inherit.aes = FALSE
    )
  }

  return(p)
}

#' Internal: Create Individual Trajectory Plot
#'
#' @keywords internal
.plot_individual_ggplot <- function(object, n_individuals, color_palette) {

  # Sample individuals from each class
  class_assignment <- apply(object@posterior_probs, 1, which.max)
  data <- object@data
  data$class <- class_assignment[match(data[[object@model_info$id_var]],
                                       unique(data[[object@model_info$id_var]]))]

  # Sample n_individuals per class
  sampled_ids <- unlist(lapply(1:object@model_info$n_classes, function(k) {
    ids_in_class <- unique(data$id[data$class == k])
    if (length(ids_in_class) > n_individuals) {
      sample(ids_in_class, n_individuals)
    } else {
      ids_in_class
    }
  }))

  plot_data <- data[data[[object@model_info$id_var]] %in% sampled_ids, ]

  # Get colors
  n_classes <- object@model_info$n_classes
  if (is.null(color_palette)) {
    colors <- scales::hue_pal()(n_classes)
  } else {
    colors <- color_palette[1:n_classes]
  }

  # Create plot
  p <- ggplot2::ggplot(plot_data,
                      ggplot2::aes(x = .data[[object@model_info$time_var]],
                                  y = .data[[object@model_info$outcome_var]],
                                  group = .data[[object@model_info$id_var]],
                                  color = factor(class))) +
    ggplot2::geom_line(alpha = 0.5) +
    ggplot2::geom_point(alpha = 0.3, size = 1) +
    ggplot2::facet_wrap(~ class, labeller = ggplot2::label_both) +
    ggplot2::scale_color_manual(values = colors, guide = "none") +
    ggplot2::labs(
      x = "Time",
      y = "Outcome",
      title = paste0("Individual Trajectories (", n_individuals, " per class)")
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5),
      strip.text = ggplot2::element_text(face = "bold")
    )

  return(p)
}

#' Internal: Create Spaghetti Plot
#'
#' @keywords internal
.plot_spaghetti_ggplot <- function(object, n_individuals, color_palette) {

  # Sample individuals across all classes
  all_ids <- unique(object@data[[object@model_info$id_var]])
  if (length(all_ids) > n_individuals * object@model_info$n_classes) {
    sampled_ids <- sample(all_ids, n_individuals * object@model_info$n_classes)
  } else {
    sampled_ids <- all_ids
  }

  plot_data <- object@data[object@data[[object@model_info$id_var]] %in% sampled_ids, ]

  # Add class assignment
  class_assignment <- apply(object@posterior_probs, 1, which.max)
  plot_data$class <- class_assignment[match(plot_data[[object@model_info$id_var]],
                                            unique(object@data[[object@model_info$id_var]]))]

  # Get colors
  n_classes <- object@model_info$n_classes
  if (is.null(color_palette)) {
    colors <- scales::hue_pal()(n_classes)
  } else {
    colors <- color_palette[1:n_classes]
  }

  # Create plot
  p <- ggplot2::ggplot(plot_data,
                      ggplot2::aes(x = .data[[object@model_info$time_var]],
                                  y = .data[[object@model_info$outcome_var]],
                                  group = .data[[object@model_info$id_var]],
                                  color = factor(class))) +
    ggplot2::geom_line(alpha = 0.3) +
    ggplot2::scale_color_manual(
      values = colors,
      name = "Latent Class",
      labels = paste0("Class ", 1:n_classes)
    ) +
    ggplot2::labs(
      x = "Time",
      y = "Outcome",
      title = "Spaghetti Plot: Individual Trajectories"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5),
      legend.position = "right"
    )

  # Add class means
  n_classes <- object@model_info$n_classes
  traj_list <- lapply(1:n_classes, function(k) {
    extract_trajectories(object, class = k)
  })
  traj_data <- do.call(rbind, traj_list)
  p <- p + ggplot2::geom_line(
    data = traj_data,
    ggplot2::aes(x = time, y = predicted, color = factor(class), group = class),
    linewidth = 1.5,
    alpha = 1
  )

  return(p)
}

#' Create Interactive Model Selection Plot
#'
#' @description
#' Interactive visualization of model selection criteria across different
#' numbers of classes.
#'
#' @param object Object of class \code{SurveyMixrSelect}
#' @param criteria Character vector of criteria to plot: "AIC", "BIC", "aBIC", "entropy", "BLRT"
#' @param interactive Logical; create plotly object?
#'
#' @return plotly or ggplot object
#'
#' @export
plot_model_selection_interactive <- function(object,
                                            criteria = c("BIC", "aBIC", "entropy"),
                                            interactive = TRUE) {

  if (!inherits(object, "SurveyMixrSelect")) {
    stop("object must be a SurveyMixrSelect object")
  }

  if (interactive && !requireNamespace("plotly", quietly = TRUE)) {
    warning("Package 'plotly' not available. Returning ggplot object instead.")
    interactive <- FALSE
  }

  # Extract fit indices
  fit_data <- object@fit_indices

  # Create separate plots for each criterion
  plots <- list()

  for (crit in criteria) {
    if (!(crit %in% names(fit_data))) {
      warning("Criterion '", crit, "' not found in results")
      next
    }

    # Determine if lower is better
    lower_better <- crit %in% c("AIC", "BIC", "aBIC")

    plot_df <- data.frame(
      n_classes = fit_data$n_classes,
      value = fit_data[[crit]]
    )

    p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = n_classes, y = value)) +
      ggplot2::geom_line(color = "steelblue", linewidth = 1) +
      ggplot2::geom_point(size = 3, color = "steelblue") +
      ggplot2::scale_x_continuous(breaks = fit_data$n_classes) +
      ggplot2::labs(
        x = "Number of Classes",
        y = crit,
        title = paste(crit, "by Number of Classes")
      ) +
      ggplot2::theme_minimal()

    # Mark best model
    if (lower_better) {
      best_idx <- which.min(plot_df$value)
    } else {
      best_idx <- which.max(plot_df$value)
    }

    p <- p + ggplot2::geom_point(
      data = plot_df[best_idx, ],
      ggplot2::aes(x = n_classes, y = value),
      size = 5,
      color = "darkgreen",
      shape = 18
    )

    plots[[crit]] <- p
  }

  # Combine plots
  if (length(plots) > 1 && requireNamespace("patchwork", quietly = TRUE)) {
    combined <- patchwork::wrap_plots(plots, ncol = 2)
  } else if (length(plots) == 1) {
    combined <- plots[[1]]
  } else {
    combined <- plots
  }

  # Convert to plotly if requested
  if (interactive && !is.list(combined)) {
    combined <- plotly::ggplotly(combined)
  }

  return(combined)
}

#' Create Interactive Posterior Probability Distribution Plot
#'
#' @description
#' Visualizes the distribution of posterior probabilities for class membership
#'
#' @param object Fitted \code{SurveyMixr} object
#' @param interactive Logical; create plotly object?
#'
#' @return plotly or ggplot object
#'
#' @export
plot_posterior_dist <- function(object, interactive = TRUE) {

  if (!inherits(object, "SurveyMixr")) {
    stop("object must be a SurveyMixr object")
  }

  # Get posterior probabilities
  posterior <- object@posterior_probs
  n_classes <- ncol(posterior)

  # Reshape to long format
  post_long <- data.frame(
    prob = as.vector(posterior),
    class = factor(rep(1:n_classes, each = nrow(posterior)))
  )

  # Create plot
  p <- ggplot2::ggplot(post_long, ggplot2::aes(x = prob, fill = class)) +
    ggplot2::geom_histogram(bins = 50, alpha = 0.7, position = "identity") +
    ggplot2::facet_wrap(~ class, ncol = 1, labeller = ggplot2::label_both) +
    ggplot2::scale_fill_brewer(palette = "Set2", guide = "none") +
    ggplot2::labs(
      x = "Posterior Probability",
      y = "Count",
      title = "Distribution of Posterior Class Membership Probabilities"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5),
      strip.text = ggplot2::element_text(face = "bold")
    )

  # Convert to plotly if requested
  if (interactive) {
    if (!requireNamespace("plotly", quietly = TRUE)) {
      warning("Package 'plotly' not available. Returning ggplot object instead.")
    } else {
      p <- plotly::ggplotly(p)
    }
  }

  return(p)
}
