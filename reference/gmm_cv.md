# K-Fold Cross-Validation for GMM Model Selection

Performs k-fold cross-validation to evaluate and compare growth mixture
models with different numbers of classes. Properly accounts for complex
survey design by maintaining design integrity within folds.

## Usage

``` r
gmm_cv(
  data,
  id,
  time,
  outcome,
  classes = 1:5,
  k_folds = 10,
  growth_model = "linear",
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  covariates = NULL,
  stratified_cv = TRUE,
  starts = 200,
  cores = 1,
  seed = NULL,
  verbose = TRUE
)
```

## Arguments

- data:

  Data frame in long format

- id:

  Character string naming ID variable

- time:

  Character string naming time variable

- outcome:

  Character string naming outcome variable

- classes:

  Integer vector specifying number of classes to test (e.g., 1:5)

- k_folds:

  Integer number of folds (default = 10)

- growth_model:

  Character string: "linear" or "quadratic"

- strata:

  Optional character string naming stratification variable

- cluster:

  Optional character string naming cluster variable

- weights:

  Optional character string naming weight variable

- covariates:

  Optional character vector naming covariates

- stratified_cv:

  Logical; if TRUE, maintains stratum proportions in folds

- starts:

  Integer number of random starts per model

- cores:

  Integer number of CPU cores for parallel processing

- seed:

  Integer random seed for reproducibility

- verbose:

  Logical; print progress?

## Value

An S4 object of class `GMM_CrossValidation` with slots:

- cv_results:

  Data frame with metrics for each fold and class count

- summary_stats:

  Aggregated statistics across folds

- best_k:

  Recommended number of classes

- fold_assignments:

  Vector indicating fold membership for each individual

- detailed_results:

  List with full results for each fold

## Details

Cross-validation for mixture models requires special considerations:

\*\*1. Survey Design Preservation:\*\* When stratified_cv = TRUE, folds
maintain the proportion of observations from each stratum, preserving
the survey design structure.

\*\*2. Individual-Level Splitting:\*\* The data is split at the
individual level (not observation level) to keep all time points for
each person together.

\*\*3. Prediction Metrics:\*\* Multiple metrics are computed: -
Log-likelihood on held-out data - Classification accuracy (if true
classes known) - Mean squared prediction error - Weighted metrics using
survey weights

\*\*4. Label Switching:\*\* Class labels may differ across folds. The
algorithm attempts to align labels based on trajectory patterns.

## References

Merkle, E. C., You, D., & Preacher, K. (2016). Testing non-nested
structural equation models. \*Psychological Methods\*, 21(2), 151-163.

Nylund-Gibson, K., & Choi, A. Y. (2018). Ten frequently asked questions
about latent class analysis. \*Translational Issues in Psychological
Science\*, 4(4), 440-461.

## Examples

``` r
# \donttest{
data(mcs_simulated)
set.seed(123)

# Quick 2-fold CV comparing 1-2 class models (for example speed)
cv_results <- gmm_cv(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  classes = 1:2,
  k_folds = 2,
  strata = "stratum",
  cluster = "cluster",
  weights = "weight",
  stratified_cv = TRUE,
  starts = 5,
  cores = 1,
  seed = 123,
  verbose = FALSE
)
#> Warning: no non-missing arguments to min; returning Inf

print(cv_results)
#> 
#> Growth Mixture Model Cross-Validation Results
#> ============================================================
#> 
#> Setup:
#>   Folds: 2 
#>   Classes tested: 1, 2 
#> 
#> Summary by Number of Classes:
#>  Classes Log-Lik (SD) MSPE (SD)
#>        1   -Inf (NaN) Inf (NaN)
#>        2   -Inf (NaN) Inf (NaN)
#> 
#> Recommended Models:
#>   Maximum log-likelihood: 1 classes
#>   1-SE rule (parsimony): Inf classes
#> 
#> Note: Higher log-likelihood and lower MSPE indicate better fit.
#> Consider also examining information criteria and BLRT.

# For production analysis, use:
# k_folds = 10, starts = 200, classes = 1:5
# }
```
