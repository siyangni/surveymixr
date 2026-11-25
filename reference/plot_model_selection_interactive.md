# Create Interactive Model Selection Plot

Interactive visualization of model selection criteria across different
numbers of classes.

## Usage

``` r
plot_model_selection_interactive(
  object,
  criteria = c("BIC", "aBIC", "entropy"),
  interactive = TRUE
)
```

## Arguments

- object:

  Object of class `SurveyMixrSelect`

- criteria:

  Character vector of criteria to plot: "AIC", "BIC", "aBIC", "entropy",
  "BLRT"

- interactive:

  Logical; create plotly object?

## Value

plotly or ggplot object
