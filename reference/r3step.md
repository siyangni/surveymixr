# R3STEP Analysis of Auxiliary Variables

Implements the R3STEP approach for analyzing relationships between
latent class membership and auxiliary (distal) variables while
accounting for classification uncertainty.

## Usage

``` r
r3step(
  gmm_object,
  distal_vars,
  data,
  method = "BCH",
  test_pairwise = TRUE,
  adjust_multiple = "none"
)
```

## Arguments

- gmm_object:

  A fitted `SurveyMixr` object from
  [`gmm_survey()`](https://siyangni.github.io/surveymixr/reference/gmm_survey.md)

- distal_vars:

  Character vector of distal variable names to analyze

- data:

  Data frame containing the distal variables (must include same ID
  variable as used in `gmm_object`)

- method:

  Character string specifying R3STEP method: `"BCH"`
  (Bolck-Croon-Hagenaars, default), `"ML"` (maximum likelihood), or
  `"manual"` (manual 3-step with correction)

- test_pairwise:

  Logical, conduct pairwise comparisons between classes? (default: TRUE)

- adjust_multiple:

  Character string for multiple testing adjustment: `"none"` (default),
  `"bonferroni"`, `"holm"`, or `"BH"`

## Value

An S4 object of class
[`R3StepResults`](https://siyangni.github.io/surveymixr/reference/R3StepResults-class.md)
containing:

- class_means:

  Matrix of class-specific means for each distal variable

- standard_errors:

  Matrix of survey-adjusted standard errors

- test_results:

  Data frame with omnibus and pairwise test results

- effect_sizes:

  Matrix of Cohen's d effect sizes (pairwise)

## Details

The R3STEP approach addresses a key challenge in mixture modeling:
naively relating class membership to auxiliary variables using
most-likely class assignment leads to biased estimates due to
classification uncertainty.

**Why R3STEP?**

Traditional approaches that use most-likely class assignment
("classify-analyze") produce biased parameter estimates and incorrect
standard errors. The R3STEP methods correct for this by incorporating
classification uncertainty into the analysis.

**Available Methods:**

- **BCH (default)**: Uses weighted regression with weights derived from
  the classification error matrix. Computationally efficient and
  recommended for most applications.

- **ML**: Simultaneous estimation of mixture model and auxiliary
  variable relationships. Most accurate but computationally intensive.

- **Manual 3-step**: Traditional 3-step approach with manual correction
  for classification error.

The function automatically accounts for complex survey design features
(weights, clustering, stratification) when computing standard errors and
test statistics.

**Interpretation:**

The output provides:

- Class-specific means (adjusted for classification error)

- Survey-adjusted standard errors

- Omnibus tests (overall class differences)

- Pairwise comparisons (if requested)

- Effect sizes (Cohen's d with survey weights)

## References

Asparouhov, T., & Muthén, B. (2014). Auxiliary variables in mixture
modeling: Three-step approaches using Mplus. *Structural Equation
Modeling: A Multidisciplinary Journal, 21*(3), 329-341.

Bolck, A., Croon, M., & Hagenaars, J. (2004). Estimating latent
structure models with categorical variables: One-step versus three-step
estimators. *Political Analysis, 12*(1), 3-27.

Vermunt, J. K. (2010). Latent class modeling with covariates: Two
improved three-step approaches. *Political Analysis, 18*(4), 450-469.

## Examples

``` r
# \donttest{
# Simulate data and fit GMM
sim_data <- simulate_gmm_survey(
  n_individuals = 300,
  n_times = 4,
  n_classes = 3,
  covariates = TRUE,
  design = "srs",
  seed = 401
)

fit <- gmm_survey(
  data = sim_data,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 3,
  starts = 10,
  cores = 1
)
#> Validating inputs...
#> Preparing data...
#>   N = 300 individuals
#>   T = 4 time points
#>   Time scores: 0, 1, 2, 3
#> 
#> Running 10 random starts with 3 classes...
#> 
#> Selecting best solution...
#>   Best logLik: -2222.9694
#>   Replicated 5 times
#>   10/10 starts converged
#> 
#> Computing survey-adjusted standard errors...
#> Computing fit indices...
#> 
#> Completed in 1.2 seconds

# R3STEP requires person-level data - aggregate
person_data <- sim_data[!duplicated(sim_data$id), c("id", "ses")]

# Analyze distal outcomes
r3step_results <- r3step(
  gmm_object = fit,
  distal_vars = "ses",
  data = person_data,
  method = "BCH"
)

summary(r3step_results)
#> R3STEP Analysis Results
#> =======================
#> 
#> Method: BCH 
#> Distal variables: ses 
#> Number of classes: 3 
#> 
#> Class-Specific Means:
#>     Class_1 Class_2 Class_3
#> ses  -0.432   -0.06  -0.445
#> 
#> Standard Errors:
#>     Class_1 Class_2 Class_3
#> ses   0.055   0.072   0.055
#> 
#> Omnibus Tests:
#> F(2.0, 727.0) = 8.413, p = 0.000
#> 
#> Pairwise Comparisons:
#>          Comparison        Diff         SE          t            p
#>  Class 1 vs Class 2 -0.37145015 0.09062845 -4.0986043 4.973728e-05
#>  Class 1 vs Class 3  0.01303708 0.07734096  0.1685663 8.661948e-01
#>  Class 2 vs Class 3  0.38448723 0.09045571  4.2505576 2.619497e-05
#> 
#> ---
#> Use summary() for detailed results including pairwise comparisons
#> 
#> 
#> Effect Sizes (Cohen's d):
#> -------------------------
#>     Class1_vs_Class2 Class1_vs_Class3 Class2_vs_Class3
#> ses            -0.42             0.01             0.43
# }
```
