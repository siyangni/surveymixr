# Plot Model Selection Comparison

Visualizes fit indices across different numbers of classes to aid in
model selection.

## Usage

``` r
plot_model_selection(select_object, criteria = NULL, ...)
```

## Arguments

- select_object:

  A `SurveyMixrSelect` object from
  [`gmm_select()`](https://siyangni.github.io/surveymixr/reference/gmm_select.md)

- criteria:

  Character vector of criteria to plot: "BIC", "AIC", "aBIC", "entropy"
  (default: all available)

- ...:

  Additional arguments

## Value

A ggplot2 object
