# Validate Survey Data for GMM Analysis

Comprehensive validation of data structure, survey design elements, and
suitability for growth mixture modeling. Provides detailed diagnostics
and warnings about potential issues.

## Usage

``` r
validate_survey_data(
  data,
  id,
  time,
  outcome,
  strata = NULL,
  cluster = NULL,
  weights = NULL,
  covariates = NULL,
  min_observations = 2,
  check_weights = TRUE,
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

- strata:

  Optional character string naming stratification variable

- cluster:

  Optional character string naming cluster/PSU variable

- weights:

  Optional character string naming weight variable

- covariates:

  Optional character vector naming covariate variables

- min_observations:

  Minimum number of observations per individual (default = 2)

- check_weights:

  Logical; perform detailed weight diagnostics?

- verbose:

  Logical; print detailed output?

## Value

An S4 object of class `DataValidation` with slots:

- is_valid:

  Logical; overall validation status

- errors:

  Character vector of critical errors

- warnings:

  Character vector of warnings

- info:

  List of diagnostic information

- recommendations:

  Character vector of recommended actions

## Details

The validation checks include:

\*\*Data Structure:\*\* - All required variables present - Correct data
types - No duplicate ID-time combinations - Sufficient observations per
individual

\*\*Survey Design:\*\* - Clusters nested within strata - Weights are
positive and non-missing - Suspicious weight patterns (e.g., all
identical) - Design effects

\*\*Missingness:\*\* - Missing data patterns (MCAR, MAR, MNAR
indicators) - Proportion missing by variable - Monotone vs non-monotone
patterns

\*\*Statistical Properties:\*\* - Outcome distribution (normality,
outliers) - Time score distribution - Covariate distributions -
Multicollinearity among covariates

## Examples

``` r
# \donttest{
data(mcs_simulated)

# Validate data before analysis
validation <- validate_survey_data(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  strata = "stratum",
  cluster = "cluster",
  weights = "weight",
  verbose = TRUE
)
#> 
#> ======================================================================
#> DATA VALIDATION FOR GROWTH MIXTURE MODELING
#> ======================================================================
#> 
#> 1. Checking data structure...
#> 2. Checking survey design...
#> 3. Checking survey weights...
#> 4. Checking missing data patterns...
#> 5. Checking outcome distribution...
#> 6. Checking time variable...
#> 
#> ======================================================================
#> VALIDATION SUMMARY
#> ======================================================================
#> 
#> Overall Status: PASSED 
#> 
#> WARNINGS (review recommended):
#>   1. 262 potential outliers (>3 SD from mean)
#> 
#> RECOMMENDATIONS:
#>   1. Non-monotone missingness - verify FIML assumptions
#>   2. Examine outliers - may indicate data errors or require robust methods
#> 
#> Data Overview:
#>   Individuals: 5000 
#>   Observations: 30000 
#>   Time points: 6 
#>   Missing outcome: 13.4 %
#>   Design effect: 0.2 
#> 
#> ======================================================================

print(validation)
#> 
#> ======================================================================
#> VALIDATION SUMMARY
#> ======================================================================
#> 
#> Overall Status: PASSED 
#> 
#> WARNINGS (review recommended):
#>   1. 262 potential outliers (>3 SD from mean)
#> 
#> RECOMMENDATIONS:
#>   1. Non-monotone missingness - verify FIML assumptions
#>   2. Examine outliers - may indicate data errors or require robust methods
#> 
#> Data Overview:
#>   Individuals: 5000 
#>   Observations: 30000 
#>   Time points: 6 
#>   Missing outcome: 13.4 %
#>   Design effect: 0.2 
#> 
#> ======================================================================

# Check if data is valid for analysis
if (validation@is_valid) {
  cat("Data is ready for GMM analysis\n")
} else {
  cat("Please address errors before proceeding:\n")
  cat(validation@errors, sep = "\n")
}
#> Data is ready for GMM analysis
# }
```
