# Convert Mplus Syntax to surveymixr

Parses Mplus input file and suggests equivalent surveymixr code.

## Usage

``` r
mplus_to_surveymixr(mplus_file)
```

## Arguments

- mplus_file:

  Path to Mplus .inp file

## Value

Character string with suggested R code

## Details

This function reads an Mplus input file for growth mixture models and
generates equivalent surveymixr code. Note that not all Mplus features
can be directly translated.

Supported Mplus features:

- VARIABLE section: NAMES, USEVAR, CLASSES, CLUSTER, WEIGHT,
  STRATIFICATION

- ANALYSIS section: TYPE = MIXTURE, STARTS

- MODEL section: Linear and quadratic growth specifications

## Examples

``` r
# \donttest{
# Create example Mplus file in temporary directory
mplus_code <- '
VARIABLE:
  NAMES = id time y stratum psu weight;
  USEVAR = y;
  CLASSES = c(3);
  CLUSTER = psu;
  STRATIFICATION = stratum;
  WEIGHT = weight;

ANALYSIS:
  TYPE = MIXTURE;
  STARTS = 500 100;

MODEL:
  %OVERALL%
  i s | y@0 y@1 y@2 y@3 y@4;
'

tmp_file <- tempfile(fileext = ".inp")
writeLines(mplus_code, tmp_file)
r_code <- mplus_to_surveymixr(tmp_file)
cat(r_code)
#> 
#> # Translated from Mplus to surveymixr
#> # Original file: /tmp/RtmpfpNIMt/file192d21ff48ec.inp
#> # Manual review and adjustment recommended
#> 
#> library(surveymixr)
#> 
#> # Load your data
#> # data <- read.table("your_data_file.txt", header = TRUE)
#> 
#> fit <- gmm_survey(
#>   data = data,
#>   id = "id",
#>   time = "time",
#>   outcome = "outcome_variable",  # UPDATE THIS
#>   n_classes = 3,
#>   growth_model = "linear",  # or "quadratic" - check your Mplus MODEL section
#>     cluster = "psu",
#>   strata = "stratum",
#>   weights = "weight",
#>   starts = 500,
#>   cores = 4,  # Adjust based on your system
#>   verbose = TRUE
#> )
#> 
#> summary(fit)
#> plot(fit, type = "trajectories")
#> 
#> # Model selection
#> selection <- gmm_select(
#>   data = data,
#>   id = "id",
#>   time = "time",
#>   outcome = "outcome_variable",
#>   classes = 1:5,
#>     cluster = "psu",
#>   strata = "stratum",
#>   weights = "weight",
#>   criteria = c("BIC", "BLRT", "entropy"),
#>   blrt_samples = 100,
#>   starts = 250,
#>   cores = 4
#> )
#> 
#> print(selection)
#> 
#> 
#> # NOTES:
#> # 1. Update variable names to match your data
#> # 2. Verify growth model specification (linear vs quadratic)
#> # 3. Check time coding (Mplus uses @ notation, surveymixr uses actual time values)
#> # 4. Mplus "TECH" output equivalents:
#> #    - TECH1 (parameters): summary(fit)
#> #    - TECH7 (sample stats by class): Not directly available
#> #    - TECH11 (Lo-Mendell-Rubin): Use BLRT in gmm_select()
#> #    - TECH14 (classification quality): classification_quality(fit)
#> # 5. For auxiliary variables (3-step), use:
#> #    r3step(fit, distal_vars = c("var1", "var2"), data = data)
unlink(tmp_file)  # Clean up
# }
```
