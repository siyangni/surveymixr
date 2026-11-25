# Growth Mixture Models with Complex Survey Design

Fits growth mixture models for longitudinal data with full integration
of complex survey design features including stratification, clustering
(PSUs), and probability weights. Implements the EM algorithm with
sandwich standard errors for survey-adjusted inference.

## Usage

``` r
gmm_survey(
  data,
  id,
  time,
  outcome,
  n_classes = 2,
  growth_model = "linear",
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  nest = TRUE,
  outcome_type = "continuous",
  fixed_variances = FALSE,
  fixed_timescores = TRUE,
  predictors = NULL,
  distal = NULL,
  auxiliary = NULL,
  starts = 500,
  convergence = 1e-06,
  max_iter = 1000,
  cores = 1,
  verbose = TRUE,
  keep_data = FALSE,
  store_all_starts = TRUE,
  skip_validation = FALSE,
  ...
)
```

## Arguments

- data:

  Data frame in long format containing repeated measurements

- id:

  Character string specifying the individual ID variable name

- time:

  Character string specifying the time variable name

- outcome:

  Character string specifying the outcome variable name

- n_classes:

  Integer number of latent classes (default: 2)

- growth_model:

  Character string specifying growth model type: `"linear"` (default),
  `"quadratic"`, `"nonlinear"`, or `"free_basis"`

- strata:

  Character string specifying stratification variable (optional)

- cluster:

  Character string specifying cluster/PSU variable (optional)

- weights:

  Character string specifying sampling weights variable (optional)

- nest:

  Logical indicating nested clustering (default: TRUE)

- outcome_type:

  Character string: `"continuous"` (default), `"count"`, `"binary"`, or
  `"ordinal"`

- fixed_variances:

  Logical, should residual variances be constrained equal across
  classes? (default: FALSE)

- fixed_timescores:

  Logical, should time scores be equal across classes? (default: TRUE)

- predictors:

  Character vector of time-varying predictor variable names (not yet
  implemented)

- distal:

  Character vector of distal outcome variable names (use with
  [`r3step()`](https://siyangni.github.io/surveymixr/reference/r3step.md)
  function)

- auxiliary:

  Character vector of auxiliary variable names for class membership
  prediction

- starts:

  Integer number of random starts (default: 500)

- convergence:

  Numeric convergence criterion (default: 1e-6)

- max_iter:

  Integer maximum number of EM iterations (default: 1000)

- cores:

  Integer number of CPU cores for parallel processing (default: 1)

- verbose:

  Logical, print progress messages? (default: TRUE)

- keep_data:

  Logical, store data in output object? (default: FALSE)

- store_all_starts:

  Logical, store results from all random starts? (default: TRUE). When
  TRUE (recommended for research), stores all random start results for
  convergence diagnostics with
  [`diagnose_convergence()`](https://siyangni.github.io/surveymixr/reference/diagnose_convergence.md).
  When FALSE (recommended for large N \> 1000), only stores the best
  solution to reduce memory usage.

- skip_validation:

  Logical, skip automatic survey design validation? (default: FALSE).
  When FALSE (recommended), the function automatically validates survey
  design features (nested clusters, singleton strata, etc.) before
  estimation. Set to TRUE only if you've already validated your data
  with
  [`validate_survey_data`](https://siyangni.github.io/surveymixr/reference/validate_survey_data.md)
  or are certain your design is correct.

- ...:

  Additional arguments (reserved for future use)

## Value

An S4 object of class
[`SurveyMixr`](https://siyangni.github.io/surveymixr/reference/SurveyMixr-class.md)
containing:

- parameters:

  Class-specific growth parameters (means, variances)

- class_proportions:

  Weighted and unweighted class proportions

- posterior_probs:

  Posterior probabilities for each individual

- standard_errors:

  Survey-adjusted standard errors

- fit_indices:

  AIC, BIC, aBIC, entropy, log-likelihood

- convergence_info:

  Convergence diagnostics from random starts

- survey_design:

  Survey design information

## Details

This function implements growth mixture modeling with full survey design
integration, a feature combination not available in other R packages.
The implementation uses:

- EM algorithm with survey weight integration in the likelihood

- Multiple random starts to avoid local maxima

- Sandwich standard errors for stratification and clustering

- FIML for missing data

The function automatically converts data from long to wide format
internally for computational efficiency. Survey weights are normalized
to sum to the sample size.

**Reproducibility and Random Seeds:** The EM algorithm uses multiple
random starts (controlled by `starts` parameter) to avoid local maxima.
Each random start uses a different random seed for better exploration of
the parameter space. To ensure reproducibility, use
[`set.seed()`](https://rdrr.io/r/base/Random.html) before calling
`gmm_survey()`. The function will use the R random number generator
state to initialize each random start deterministically. Note that
results may vary slightly across different platforms or R versions due
to numerical precision differences.

For model selection across different numbers of classes, see
[`gmm_select`](https://siyangni.github.io/surveymixr/reference/gmm_select.md).
For analyzing auxiliary variables with classification uncertainty
correction, see
[`r3step`](https://siyangni.github.io/surveymixr/reference/r3step.md).

## References

Muthén, B. (2004). Latent variable analysis: Growth mixture modeling and
related techniques for longitudinal data. In D. Kaplan (Ed.), *Handbook
of quantitative methodology for the social sciences* (pp. 345-368). Sage
Publications.

Asparouhov, T., & Muthén, B. (2014). Auxiliary variables in mixture
modeling: Three-step approaches using Mplus. *Structural Equation
Modeling: A Multidisciplinary Journal, 21*(3), 329-341.

Lumley, T. (2010). *Complex surveys: A guide to analysis using R*. John
Wiley & Sons.

## Examples

``` r
# \donttest{
# Load simulated data
data(mcs_simulated)

# Set seed for reproducibility
set.seed(123)

# Fit 2-class model with survey design (reduced for example speed)
fit <- gmm_survey(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  n_classes = 2,
  growth_model = "linear",
  strata = "stratum",
  cluster = "cluster",
  weights = "weight",
  starts = 10,
  cores = 1,
  verbose = FALSE
)

# View results
summary(fit)
#> ========================================
#> Growth Mixture Model - Detailed Summary
#> ========================================
#> 
#> MODEL SPECIFICATION
#> -------------------
#> Growth model: linear
#> Number of classes: 2
#> Sample size: 5000
#> Time points: 6
#> Time scores: 3, 5, 7, 11, 14, 17
#> 
#> SURVEY DESIGN
#> -------------
#> Sampling weights: Yes
#> Stratification: 4 strata
#> Clustering: 200 PSUs
#> Nested design: Yes
#> 
#> GROWTH PARAMETERS
#> -----------------
#> 
#> Class 1 (n = 736.0, 14.7%):
#>   Intercept: 4.037 (SE = 0.069)
#>   Slope: -0.146 (SE = 0.006)
#>   Residual SD: 1.798 (SE = 0.285)
#> 
#> Class 2 (n = 4264.0, 85.3%):
#>   Intercept: 7.604 (SE = 0.028)
#>   Slope: 0.104 (SE = 0.002)
#>   Residual SD: 1.469 (SE = 0.344)
#> 
#> CLASS PROPORTIONS
#> -----------------
#> Class          Weighted   Unweighted
#> 1                 0.147        0.147
#> 2                 0.853        0.853
#> 
#> FIT INDICES
#> -----------
#> Log-likelihood: -49673.19
#> Parameters: 7
#> AIC: 99360.37
#> BIC: 99405.99
#> aBIC: 99383.75
#> Entropy: 0.998
#> Average posterior prob: 0.999
#> 
#> CLASSIFICATION QUALITY
#> ----------------------
#> Class             AvePP          OCC
#> 1                 0.999      1071.56
#> 2                 1.000      3827.69
#> 
#> CONVERGENCE
#> -----------
#> Status: Converged
#> Iterations: 3
#> Random starts: 10
#> Best logLik: -49673.19
#> Replications: 10
#> 
#> Computation time: 33.2 seconds
#> 
#> ========================================

# For production analysis, use more random starts:
# starts = 500, cores = parallel::detectCores() - 1
# }
```
