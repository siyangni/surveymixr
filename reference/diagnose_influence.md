# Detect Influential Observations in GMM

Identifies observations that have substantial influence on parameter
estimates using survey-weighted influence metrics including Cook's
distance, DFBETAS, and leverage.

## Usage

``` r
diagnose_influence(
  object,
  measure = c("cooks", "dfbetas", "leverage", "all"),
  threshold = NULL
)
```

## Arguments

- object:

  Fitted `SurveyMixr` object (must be fitted with `keep_data = TRUE`)

- measure:

  Character string specifying influence measure: "cooks" (Cook's
  distance), "dfbetas" (parameter-specific influence), "leverage", or
  "all"

- threshold:

  Numeric threshold for flagging influential cases. If NULL, uses
  conventional cutoffs (e.g., 4/n for Cook's D)

## Value

An S4 object of class `InfluenceDiagnostics` with slots:

- influence_measures:

  Data frame with influence statistics per observation

- influential_ids:

  IDs flagged as influential

- threshold:

  Threshold used for flagging

- summary:

  Summary statistics

## Details

\*\*Note:\*\* This function requires the original data to be stored in
the fitted object. Make sure to fit your model with `keep_data = TRUE`.

\*\*Cook's Distance (Survey-Weighted):\*\*

Measures the influence of each observation on all parameter estimates
simultaneously. The survey-weighted version accounts for sampling
weights:

\$\$D_i = \frac{(\hat{\beta} - \hat{\beta}\_{(-i)})' X'WX (\hat{\beta} -
\hat{\beta}\_{(-i)})}{p \hat{\sigma}^2}\$\$

where W is the diagonal weight matrix.

\*\*DFBETAS:\*\*

Measures the influence of each observation on individual parameters:

\$\$DFBETAS\_{ij} = \frac{\hat{\beta}\_j -
\hat{\beta}\_{j(-i)}}{SE(\hat{\beta}\_{j(-i)})}\$\$

\*\*Leverage:\*\*

Identifies observations with unusual predictor patterns:

\$\$h_i = X_i (X'WX)^{-1} X_i' w_i\$\$

## References

Cook, R. D. (1977). Detection of influential observation in linear
regression. \*Technometrics\*, 19(1), 15-18.

Pfeffermann, D., & Sverchkov, M. (1999). Parametric and semi-parametric
estimation of regression models fitted to survey data. \*Sankhyā: The
Indian Journal of Statistics, Series B\*, 61(1), 166-186.

## Examples

``` r
# \donttest{
# Quick example (reduced for speed)
data(mcs_simulated)
set.seed(123)

fit <- gmm_survey(
  data = mcs_simulated,
  id = "id", time = "age", outcome = "selfcontrol",
  n_classes = 2, weights = "weight", starts = 5,
  keep_data = TRUE, verbose = FALSE
)

# Detect influential observations
influence <- diagnose_influence(fit, measure = "cooks")
print(influence)
#> 
#> Influence Diagnostics for Growth Mixture Model
#> ============================================================
#> 
#> Summary:
#>   Total observations: 25978 
#>   Total individuals: 5000 
#>   Influential cases: 5000 ( 100 %)
#> 
#> Thresholds:
#>   Cook's D: 8e-04 
#> 
#> Influential IDs (first 20):
#>    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 
#>   ... and 4980 more
#> 
# }
```
