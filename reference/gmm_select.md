# Model Selection for Growth Mixture Models

Compares growth mixture models with different numbers of latent classes
using multiple criteria including BIC, entropy, and the Bootstrap
Likelihood Ratio Test (BLRT).

## Usage

``` r
gmm_select(
  data,
  id,
  time,
  outcome,
  classes = 1:5,
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  growth_model = "linear",
  criteria = c("BIC", "BLRT", "entropy"),
  blrt_samples = 100,
  blrt_alpha = 0.05,
  starts = 200,
  cores = 1,
  verbose = TRUE,
  ...
)
```

## Arguments

- data:

  Data frame in long format

- id:

  Character string specifying individual ID variable name

- time:

  Character string specifying time variable name

- outcome:

  Character string specifying outcome variable name

- classes:

  Integer vector specifying class solutions to test (e.g., 1:5)

- strata:

  Character string specifying stratification variable (optional)

- cluster:

  Character string specifying cluster/PSU variable (optional)

- weights:

  Character string specifying sampling weights variable (optional)

- growth_model:

  Character string: "linear" (default), "quadratic", etc.

- criteria:

  Character vector of criteria to compute: "BIC" (default), "BLRT",
  "entropy", "AIC", "aBIC"

- blrt_samples:

  Integer number of bootstrap samples for BLRT (default: 100)

- blrt_alpha:

  Significance level for BLRT (default: 0.05)

- starts:

  Integer number of random starts per model (default: 200)

- cores:

  Integer number of CPU cores (default: 1)

- verbose:

  Logical, print progress? (default: TRUE)

- ...:

  Additional arguments passed to
  [`gmm_survey()`](https://siyangni.github.io/surveymixr/reference/gmm_survey.md)

## Value

An S4 object of class
[`SurveyMixrSelect`](https://siyangni.github.io/surveymixr/reference/SurveyMixrSelect-class.md)
containing:

- comparison_table:

  Data frame comparing fit across class solutions

- fitted_models:

  List of fitted `SurveyMixr` objects

- blrt_results:

  Detailed BLRT results if requested

- recommended_classes:

  Recommended number of classes

- criteria:

  Criteria used for selection

## Details

This function systematically compares mixture models with different
numbers of latent classes. Multiple criteria are available:

**Information Criteria:**

- **BIC**: Bayesian Information Criterion (lower is better)

- **AIC**: Akaike Information Criterion (lower is better)

- **aBIC**: Sample-size adjusted BIC (lower is better)

**Classification Quality:**

- **Entropy**: Classification certainty (higher is better, \>0.8
  preferred)

**Hypothesis Testing:**

- **BLRT**: Bootstrap Likelihood Ratio Test comparing K vs K-1 classes.
  Considered the gold standard for class enumeration. A significant
  p-value (\< 0.05) indicates that K classes fit better than K-1
  classes.

The BLRT implementation uses parametric bootstrap: data is generated
under the K-1 class model, and the distribution of likelihood ratio
statistics is computed empirically. This is computationally intensive
but provides the most reliable test for class enumeration.

**Practical Considerations:**

- Increase `starts` (500-1000) for final model selection

- BLRT is computationally intensive; use fewer bootstrap samples for
  initial exploration

- Smallest class should typically be \>5

- Consider substantive interpretability alongside statistical criteria

## References

Nylund, K. L., Asparouhov, T., & Muthén, B. O. (2007). Deciding on the
number of classes in latent class analysis and growth mixture modeling:
A Monte Carlo simulation study. *Structural Equation Modeling, 14*(4),
535-569.

McLachlan, G. J., & Peel, D. (2000). *Finite mixture models*. John Wiley
& Sons.

## Examples

``` r
# \donttest{
# Quick comparison of 1-2 class models (for example speed)
# Use BIC only - BLRT is very slow
data(mcs_simulated)
set.seed(123)

selection <- gmm_select(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  classes = 1:2,
  strata = "stratum",
  cluster = "cluster",
  weights = "weight",
  criteria = c("BIC", "entropy"),
  starts = 10,
  cores = 1,
  verbose = FALSE
)

# View comparison table
print(selection)
#> Growth Mixture Model Selection
#> ==============================
#> 
#> Models compared: 1, 2 
#> Criteria used: BIC, entropy 
#> Recommended classes: 2 
#> 
#> Comparison Table:
#>  n_classes    loglik       aic       bic      abic   entropy smallest_class
#>          1 -61725.93 123457.87 123477.42 123467.89       NaN         1.0000
#>          2 -49673.19  99360.37  99405.99  99383.75 0.9983132         0.1472
#>  n_params converged
#>         3      TRUE
#>         7      TRUE
#> 
#> ---
#> Access fitted models: object@fitted_models
#> BLRT results: object@blrt_results

# For production analysis, use:
# classes = 1:5, criteria = c("BIC", "BLRT", "entropy"),
# blrt_samples = 100, starts = 200, cores = parallel::detectCores() - 1
# }
```
