# Simulate Data from Growth Mixture Model with Survey Design

Generates simulated longitudinal data from a growth mixture model with
complex survey design features (stratification, clustering, weights).
Useful for testing, validation, and teaching.

## Usage

``` r
simulate_gmm_survey(
  n_individuals = 1000,
  n_times = 5,
  n_classes = 3,
  time_scores = NULL,
  class_proportions = NULL,
  growth_parameters = NULL,
  residual_sds = NULL,
  design = "stratified_cluster",
  n_strata = 4,
  n_clusters = 100,
  cluster_size = 10,
  weight_type = "inverse_prob",
  missing_rate = 0.1,
  missing_mechanism = "MCAR",
  covariates = TRUE,
  seed = NULL
)
```

## Arguments

- n_individuals:

  Number of individuals to generate (default: 1000)

- n_times:

  Number of time points (default: 5)

- n_classes:

  Number of latent classes (default: 3)

- time_scores:

  Numeric vector of time scores (default: 0:(n_times-1))

- class_proportions:

  Numeric vector of class proportions (must sum to 1)

- growth_parameters:

  List of lists, each containing intercept and slope for each class. If
  NULL, reasonable defaults are generated.

- residual_sds:

  Numeric vector of residual standard deviations by class

- design:

  Character string: "srs" (simple random sample), "stratified",
  "cluster", or "stratified_cluster" (default)

- n_strata:

  Number of strata if stratified design (default: 4)

- n_clusters:

  Number of clusters (PSUs) if cluster design (default: 100)

- cluster_size:

  Average cluster size (default: 10)

- weight_type:

  Character: "none", "inverse_prob", or "calibrated"

- missing_rate:

  Proportion of missing data (default: 0.1)

- missing_mechanism:

  Character: "MCAR" (default), "MAR", or "MNAR"

- covariates:

  Logical, include time-invariant covariates? (default: TRUE)

- seed:

  Random seed for reproducibility (default: NULL)

## Value

Data frame in long format with variables:

- id:

  Individual ID

- time:

  Time point

- outcome:

  Observed outcome value

- true_class:

  True latent class (for validation)

- stratum:

  Stratum indicator (if stratified)

- psu:

  Primary sampling unit (if clustered)

- weight:

  Sampling weight (if weighted)

- covariates:

  Additional covariates (if requested)

## Details

This function generates data following a growth mixture model:

For individual i in class k: \$\$y\_{it} = (\beta\_{0k} + u\_{0i}) +
(\beta\_{1k} + u\_{1i}) \* t + \epsilon\_{it}\$\$

where:

- \\\beta\_{0k}\\, \\\beta\_{1k}\\ are class-specific intercept and
  slope

- \\u\_{0i}\\, \\u\_{1i}\\ are random effects (optional, not yet
  implemented)

- \\\epsilon\_{it}\\ ~ N(0, \\\sigma_k^2\\) are residuals

Survey design features:

- **Stratification**: Population divided into strata, sampling within
  strata

- **Clustering**: Individuals nested within PSUs (e.g., schools,
  neighborhoods)

- **Weights**: Inverse probability weights to account for unequal
  selection probabilities

The function can generate various missing data patterns to test
robustness of analyses.

## References

Sterba, S. K. (2014). Fitting nonlinear latent growth curve models with
individually varying time points. *Structural Equation Modeling, 21*(4),
630-647.

## Examples

``` r
# Simple 3-class example
sim_data <- simulate_gmm_survey(
  n_individuals = 200,
  n_times = 4,
  n_classes = 3,
  design = "stratified_cluster",
  seed = 123
)

head(sim_data)
#>   id time   outcome true_class stratum psu    weight sex baseline_risk
#> 1  1    0  7.667486          2       3  51 1.2661718   1    -0.2085702
#> 2  1    1  9.391887          2       3  51 1.2661718   1    -0.2085702
#> 3  1    2 10.934140          2       3  51 1.2661718   1    -0.2085702
#> 4  1    3 11.703076          2       3  51 1.2661718   1    -0.2085702
#> 5  2    0        NA          2       3  55 0.8008726   0    -0.4385635
#> 6  2    1  8.448137          2       3  55 0.8008726   0    -0.4385635
#>         ses
#> 1 0.2169363
#> 2 0.2169363
#> 3 0.2169363
#> 4 0.2169363
#> 5 0.7292776
#> 6 0.7292776
table(sim_data$true_class)
#> 
#>   1   2   3 
#> 380 288 132 

# \donttest{
# Fit model to simulated data
fit <- gmm_survey(
  data = sim_data,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 3,
  strata = "stratum",
  cluster = "psu",
  weights = "weight",
  starts = 10,
  cores = 1
)
#> Validating inputs...
#> Validating survey design...
#> Warning: Survey design warnings:
#>   1 potential outliers (>3 SD from mean)
#> 
#> Run validate_survey_data() for full details.
#> Preparing data...
#>   N = 200 individuals
#>   T = 4 time points
#>   Time scores: 0, 1, 2, 3
#>   Survey weights: range = [0.32, 2.31], mean = 1.00
#>   Stratification: 4 strata
#>   Clustering: 84 clusters (PSUs)
#> 
#> Running 10 random starts with 3 classes...
#> 
#> Selecting best solution...
#>   Best logLik: -1519.2022
#>   Replicated 10 times
#>   10/10 starts converged
#> 
#> Computing survey-adjusted standard errors...
#> Computing fit indices...
#> 
#> Completed in 3.5 seconds

# Compare estimated vs true parameters
summary(fit)
#> ========================================
#> Growth Mixture Model - Detailed Summary
#> ========================================
#> 
#> MODEL SPECIFICATION
#> -------------------
#> Growth model: linear
#> Number of classes: 3
#> Sample size: 200
#> Time points: 4
#> Time scores: 0, 1, 2, 3
#> 
#> SURVEY DESIGN
#> -------------
#> Sampling weights: Yes
#> Stratification: 4 strata
#> Clustering: 84 PSUs
#> Nested design: Yes
#> 
#> GROWTH PARAMETERS
#> -----------------
#> 
#> Class 1 (n = 33.0, 15.0%):
#>   Intercept: 3.943 (SE = 0.234)
#>   Slope: -0.605 (SE = 0.146)
#>   Residual SD: 1.617 (SE = 0.350)
#> 
#> Class 2 (n = 94.0, 47.2%):
#>   Intercept: 12.057 (SE = 0.133)
#>   Slope: 0.207 (SE = 0.075)
#>   Residual SD: 1.489 (SE = 0.362)
#> 
#> Class 3 (n = 73.0, 37.8%):
#>   Intercept: 7.807 (SE = 0.177)
#>   Slope: 0.918 (SE = 0.097)
#>   Residual SD: 1.500 (SE = 0.365)
#> 
#> CLASS PROPORTIONS
#> -----------------
#> Class          Weighted   Unweighted
#> 1                 0.150        0.165
#> 2                 0.472        0.468
#> 3                 0.378        0.366
#> 
#> FIT INDICES
#> -----------
#> Log-likelihood: -1519.20
#> Parameters: 11
#> AIC: 3060.40
#> BIC: 3096.69
#> aBIC: 3061.84
#> Entropy: 0.971
#> Average posterior prob: 0.993
#> 
#> CLASSIFICATION QUALITY
#> ----------------------
#> Class             AvePP          OCC
#> 1                 1.000    930356.78
#> 2                 0.989        92.53
#> 3                 0.990        96.45
#> 
#> CONVERGENCE
#> -----------
#> Status: Converged
#> Iterations: 2
#> Random starts: 10
#> Best logLik: -1519.20
#> Replications: 10
#> 
#> Computation time: 3.5 seconds
#> 
#> ========================================
# }
```
