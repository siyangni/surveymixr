# surveymixr 0.2.0 (Development Version)

## Major Enhancements

This release significantly expands surveymixr's capabilities with new outcome types, enhanced model selection methods, advanced diagnostics, and interactive visualizations.

### New Outcome Types (Phase 2.1.1)

* **Categorical Outcomes Support**
  - `gmm_survey_binary()`: Binary outcomes (0/1) with probit or logit link functions
  - `gmm_survey_ordinal()`: Ordinal outcomes with proportional odds models
  - `gmm_survey_count()`: Count outcomes with Poisson, negative binomial, and zero-inflated models
  - Full integration with complex survey designs
  - Proper likelihood computation and parameter estimation for non-continuous data

* **Link Functions**
  - `get_link_function()`: Flexible link function system
  - Support for probit, logit, log, and beta links
  - Automatic outcome type validation

### Enhanced Model Selection (Phase 2.2)

* **Lo-Mendell-Rubin Test (LMR)**
  - `lmr_test()`: Asymptotic likelihood ratio test for class enumeration
  - Much faster than BLRT (no bootstrap resampling)
  - Adjusted LMR (aLMR) for improved finite-sample performance
  - `lmr_sequential()`: Automated testing across multiple models
  - Integration with `gmm_select()` for comprehensive model comparison

* **Cross-Validation**
  - `gmm_cv()`: K-fold cross-validation for model selection
  - Proper handling of survey weights in fold creation
  - Stratified CV to maintain survey design structure
  - Individual-level splitting (keeps all time points together)
  - Multiple prediction metrics (log-likelihood, MSPE)
  - One-standard-error rule for parsimony

### Advanced Diagnostics (Phase 2.3)

* **Influence Diagnostics**
  - `diagnose_influence()`: Survey-weighted influence detection
  - Cook's distance for complex survey data
  - DFBETAS for parameter-specific influence
  - Leverage statistics
  - Automatic flagging of influential cases

* **Separation Detection**
  - `diagnose_separation()`: Detect perfect or quasi-perfect class separation
  - Entropy-based checks
  - Empty class detection
  - Recommendations for addressing separation issues

* **Residual Analysis**
  - `residual_diagnostics()`: Comprehensive residual analysis
  - Standardized residuals
  - Normality tests (Shapiro-Wilk)
  - Skewness and kurtosis
  - By-class residual diagnostics
  - Q-Q plots and autocorrelation checks

### Data Validation (Phase 2.5)

* **Comprehensive Data Validation**
  - `validate_survey_data()`: Pre-analysis data quality checks
  - Structure validation (duplicates, missing variables, data types)
  - Survey design verification (nested clusters, weight diagnostics)
  - Missing data pattern analysis (monotone vs non-monotone)
  - Outcome distribution checks (outliers, normality)
  - Covariate multicollinearity detection
  - Design effect calculation
  - Detailed diagnostic reports with actionable recommendations

* **S4 Class for Validation Results**
  - `DataValidation`: Structured validation results
  - Separate tracking of errors, warnings, and recommendations
  - Informative print methods

### Interactive Visualization (Phase 2.4)

* **Plotly Integration**
  - `plot_interactive()`: Interactive trajectory plots with hover information
  - Zoom, pan, and toggle capabilities
  - Three plot types: trajectories, individual, spaghetti
  - Customizable color palettes
  - Export to HTML for presentations

* **Enhanced Plot Types**
  - `plot_model_selection_interactive()`: Interactive model comparison
  - `plot_posterior_dist()`: Posterior probability distributions
  - Individual trajectory sampling
  - Confidence interval ribbons
  - Professional themes and layouts

### Documentation & Package Infrastructure

* **New Documentation Files**
  - `CONTRIBUTING.md`: Comprehensive contribution guidelines
  - `CODE_OF_CONDUCT.md`: Contributor Covenant Code of Conduct
  - Enhanced `cran-comments.md` for CRAN submission

* **Improved Dependencies**
  - Added `plotly` to Suggests for interactive plots
  - Added `scales` for color palette handling
  - Maintained minimal hard dependencies

### Bug Fixes

* Fixed test suite issues with design parameter capitalization
* Improved error messages and input validation
* Enhanced handling of edge cases in estimation

### Performance Improvements

* Optimized influence diagnostic calculations
* Improved memory efficiency in cross-validation
* Better handling of large datasets in validation

### Breaking Changes

* None - all changes are additive and backward compatible

### Deprecations

* None in this release

### Coming in Version 0.3.0

* Random effects in growth parameters (Phase 2.1.2)
* Enhanced time-varying covariate support (Phase 2.1.3)
* Bayes factor approximation for model selection
* Posterior predictive checks
* Additional growth model specifications (piecewise, free basis)
* Performance optimization with Rcpp
* Parallel process models

---

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
