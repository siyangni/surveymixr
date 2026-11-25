# Plot Trajectories by Latent Class

Creates a publication-ready plot of estimated growth trajectories for
each latent class with optional confidence intervals.

## Usage

``` r
plot_trajectories(
  object,
  include_ci = TRUE,
  weighted = TRUE,
  alpha = 0.2,
  colors = NULL,
  title = NULL,
  xlab = "Time",
  ylab = "Outcome",
  legend_position = "right",
  ...
)
```

## Arguments

- object:

  A `SurveyMixr` object from
  [`gmm_survey()`](https://siyangni.github.io/surveymixr/reference/gmm_survey.md)

- include_ci:

  Logical, include confidence intervals? (default: TRUE)

- weighted:

  Logical, use weighted class proportions for subtitle? (default: TRUE)

- alpha:

  Transparency level for confidence bands (default: 0.2)

- colors:

  Optional vector of colors for classes (default: Color Brewer)

- title:

  Optional plot title

- xlab:

  X-axis label (default: "Time")

- ylab:

  Y-axis label (default: "Outcome")

- legend_position:

  Position of legend (default: "right")

- ...:

  Additional arguments (not currently used)

## Value

A ggplot2 object

## Examples

``` r
# \donttest{
data(mcs_simulated)
set.seed(123)
fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
                  outcome = "selfcontrol", n_classes = 2,
                  starts = 5, verbose = FALSE)
plot_trajectories(fit)

# }
```
