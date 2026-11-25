# Residual Diagnostics for GMM

Computes and analyzes residuals for growth mixture models, including
standardized residuals, Q-Q plots, and autocorrelation checks.

## Usage

``` r
residual_diagnostics(
  object,
  type = c("pearson", "deviance", "standardized"),
  by_class = TRUE
)
```

## Arguments

- object:

  Fitted `SurveyMixr` object

- type:

  Character: "pearson" (default), "deviance", or "standardized"

- by_class:

  Logical; compute residuals separately for each class?

## Value

List with residual diagnostics
