# Plot Time-Varying Covariate Effects

Visualizes how TVCs influence trajectories across latent classes.

## Usage

``` r
plot_tvc_effects(
  object,
  covariate,
  type = c("effect", "trajectory", "interaction"),
  tvc_values = NULL
)
```

## Arguments

- object:

  Fitted `SurveyMixrTVC` object

- covariate:

  Name of TVC to plot

- type:

  Character: "effect" (show effect sizes), "trajectory" (show predicted
  trajectories at different TVC levels), or "interaction"

- tvc_values:

  Numeric vector of TVC values to plot (for "trajectory" type)

## Value

ggplot2 object
