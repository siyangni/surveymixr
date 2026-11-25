# S4 Methods for SurveyMixr Objects

Standard methods for objects returned by surveymixr functions.

Creates bar plots of class-specific means for distal variables.

## Usage

``` r
# S4 method for class 'SurveyMixr'
show(object)

# S4 method for class 'SurveyMixr'
print(x, ...)

# S4 method for class 'SurveyMixr'
summary(object, ...)

# S4 method for class 'SurveyMixr'
coef(object, ...)

# S4 method for class 'SurveyMixr'
vcov(object, ...)

# S4 method for class 'SurveyMixr'
fitted(object, ...)

# S4 method for class 'SurveyMixr'
residuals(object, ...)

# S4 method for class 'SurveyMixr'
logLik(object, ...)

# S4 method for class 'SurveyMixr'
AIC(object, ..., k = 2)

# S4 method for class 'SurveyMixr'
BIC(object, ...)

# S4 method for class 'SurveyMixrSelect'
show(object)

# S4 method for class 'SurveyMixrSelect'
print(x, ...)

# S4 method for class 'SurveyMixrSelect'
summary(object, ...)

# S4 method for class 'R3StepResults'
show(object)

# S4 method for class 'R3StepResults'
print(x, ...)

# S4 method for class 'R3StepResults'
summary(object, ...)

# S4 method for class 'R3StepResults'
plot(x, y, type = "means", ...)

# S4 method for class 'ConvergenceDiagnostics'
show(object)

# S4 method for class 'ConvergenceDiagnostics'
print(x, ...)

# S4 method for class 'SurveyMixr'
plot(x, y, type = "trajectories", ...)
```

## Arguments

- object:

  A `SurveyMixr` object

- x:

  An object of class `R3StepResults`

- ...:

  Additional arguments passed to plotting functions

- k:

  Integer specifying class number (for class-specific methods)

- y:

  Not used (required for S4 plot signature)

- type:

  Character string: "trajectories" (default), "entropy", "convergence",
  or "class_sizes"

## Value

The `show`, `print`, and `plot` methods are called for their side
effects (displaying or plotting results) and return the object
invisibly. The `summary` method returns an enhanced summary of the model
invisibly. Other methods return specific values:

- `show()`:

  No return value, called for side effects (displays object summary)

- [`print()`](https://rdrr.io/r/base/print.html):

  No return value, called for side effects (prints object summary)

- [`summary()`](https://rdrr.io/r/base/summary.html):

  No return value, called for side effects (prints detailed summary)

- [`coef()`](https://rdrr.io/r/stats/coef.html):

  Named vector of all model parameters (class proportions and growth
  parameters)

- [`vcov()`](https://rdrr.io/r/stats/vcov.html):

  Variance-covariance matrix of parameter estimates

- [`fitted()`](https://rdrr.io/r/stats/fitted.values.html):

  Matrix of fitted trajectories (rows = individuals, columns = time
  points)

- [`residuals()`](https://rdrr.io/r/stats/residuals.html):

  Matrix of residuals (observed - fitted values)

- [`logLik()`](https://rdrr.io/r/stats/logLik.html):

  Log-likelihood value with attributes for degrees of freedom and sample
  size

- [`AIC()`](https://rdrr.io/r/stats/AIC.html):

  Akaike Information Criterion value

- [`BIC()`](https://rdrr.io/r/stats/AIC.html):

  Bayesian Information Criterion value

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html):

  No return value, called for side effects (generates plots)
