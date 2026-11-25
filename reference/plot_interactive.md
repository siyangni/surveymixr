# Create Interactive Trajectory Plot

Generates an interactive plotly visualization of growth trajectories
with hover information, zoom capabilities, and customization options.

## Usage

``` r
plot_interactive(
  object,
  type = c("trajectories", "individual", "spaghetti"),
  interactive = TRUE,
  show_ci = TRUE,
  show_points = FALSE,
  n_individuals = 10,
  color_palette = NULL,
  title = NULL,
  ...
)
```

## Arguments

- object:

  Fitted `SurveyMixr` object

- type:

  Character: "trajectories" (default), "individual", or "spaghetti"

- interactive:

  Logical; if TRUE, returns plotly object; if FALSE, returns ggplot

- show_ci:

  Logical; show confidence intervals?

- show_points:

  Logical; show individual observed points?

- n_individuals:

  For "individual" plots, number of individuals to show per class

- color_palette:

  Character vector of colors or name of palette

- title:

  Optional plot title

- ...:

  Additional arguments passed to plotting functions

## Value

If `interactive = TRUE`, a `plotly` object; otherwise a `ggplot` object

## Details

Creates interactive visualizations with the following features:

\*\*Hover Information:\*\* - Class label and proportion - Parameter
estimates (intercept, slope) - Confidence intervals - Individual IDs
(for individual plots)

\*\*Interactivity:\*\* - Zoom and pan - Toggle classes on/off - Download
as PNG - Customizable layout

\*\*Plot Types:\*\* - \*\*trajectories\*\*: Class-specific mean
trajectories with CI - \*\*individual\*\*: Sample of individual
trajectories within each class - \*\*spaghetti\*\*: All individual
trajectories overlaid

## Examples

``` r
# \donttest{
# Quick example (reduced for speed)
data(mcs_simulated)
set.seed(123)

fit <- gmm_survey(
  data = mcs_simulated,
  id = "id", time = "age", outcome = "selfcontrol",
  n_classes = 2, starts = 5, verbose = FALSE
)

if (requireNamespace("plotly", quietly = TRUE)) {
  # Interactive trajectory plot
  p <- plot_interactive(fit, type = "trajectories")

  # Save to HTML file (use tempfile to avoid leaving files)
  if (requireNamespace("htmlwidgets", quietly = TRUE)) {
    tmp_html <- tempfile(fileext = ".html")
    htmlwidgets::saveWidget(p, tmp_html)
    unlink(tmp_html)  # Clean up
  }
}
# }
```
