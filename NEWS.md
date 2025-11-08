# surveymixr 0.1.0

## Initial Release

This is the first public release of surveymixr, providing growth mixture modeling with complex survey design integration.

### Major Features

* **Core Estimation**
  - `gmm_survey()`: Growth mixture models with survey weights, clustering, and stratification
  - EM algorithm with survey-adjusted standard errors
  - Support for linear and quadratic growth models
  - Multiple random starts (500-1000+) with parallel processing
  - Convergence diagnostics and tracking

* **Model Selection**
  - `gmm_select()`: Compare models across 1-K classes
  - Bootstrap Likelihood Ratio Test (BLRT) implementation
  - Information criteria (AIC, BIC, aBIC)
  - Entropy and classification quality metrics

* **Auxiliary Variables**
  - `r3step()`: R3STEP analysis with classification uncertainty correction
  - BCH method for distal outcomes
  - Survey-adjusted tests and effect sizes

* **Diagnostics**
  - `diagnose_convergence()`: Detailed convergence analysis
  - `classification_quality()`: Entropy, AvePP, OCC metrics
  - `class_proportions()`: Weighted and unweighted estimates

* **Visualization**
  - `plot_trajectories()`: Publication-ready trajectory plots
  - `plot_model_selection()`: Fit indices comparison
  - Class-specific diagnostics plots

* **Utilities**
  - `simulate_gmm_survey()`: Data simulation with survey designs
  - `mplus_to_surveymixr()`: Convert Mplus syntax to R code
  - `wide_to_long()`: Data reshaping helper

### Documentation

* Comprehensive introductory vignette
* Example dataset: `mcs_simulated` (Millennium Cohort Study-like data)
* Academic paper draft with validation studies
* Full function documentation with examples

### Technical Details

* S4 class system for formal object definitions
* Sandwich standard errors for complex survey designs
* FIML for missing data
* Parallel processing via `parallel` package
* Extensive input validation and error handling

### Known Limitations

* Categorical outcomes (ordinal, binary) not yet fully implemented
* Random effects (individual-level variance) not yet available
* Time-varying covariates supported but not extensively tested
* Second-order models (parallel processes) not yet implemented

### Coming in Version 0.2.0

* Enhanced support for categorical outcomes
* Time-varying covariate integration
* Additional growth model specifications
* Performance optimizations
* Extended validation studies

---

## Installation

```r
# From CRAN (once published)
install.packages("surveymixr")

# Development version
devtools::install_github("siyangni/surveymixr")
```

## Getting Help

* Documentation: `help(package = "surveymixr")`
* Vignettes: `browseVignettes("surveymixr")`
* Issues: https://github.com/siyangni/surveymixr/issues

## Citation

If you use surveymixr in your research, please cite:

> Ni, S. (2025). surveymixr: An Open-Source R Package for Growth
> Mixture Modeling with Complex Survey Design. *Journal of Statistical
> Software*, XX(X), 1-XX.

---

For complete documentation and examples, see: https://siyangni.github.io/surveymixr
