# surveymixr 0.2.0 (Development Version)

## Critical Bug Fixes (2025-11-13)

Fixed 4 critical bugs that were blocking CRAN submission and preventing core features from working:

* **class_proportions dimension mismatch**: Fixed error when not all classes have assignments by using `factor()` with explicit levels
* **r3step subscript out of bounds**: Added validation requiring person-level data (one row per individual); updated all tests and provided clear error messages
* **gmm_select parameter compatibility**: Added support for `min_classes`/`max_classes` and `run_blrt` parameters for backward compatibility
* **residuals() non-conformable arrays**: Fixed residuals method to properly reshape long-format data to wide format before computing residuals

These fixes enabled 9 previously skipped tests, reducing total skipped tests from 32 to 23.

## Known Limitations

This release has some known limitations that users should be aware of:

### Features Not Yet Implemented

* **ML method for R3STEP**: The Maximum Likelihood method for r3step is not yet implemented. Use `method = "BCH"` (recommended) or `method = "manual"` instead.
* **Time-varying covariates**: Partial implementation exists (`gmm_survey_tvc()`) but needs further testing and validation
* **Random effects**: Partial implementation exists (`gmm_survey_re()`) but requires additional development
* **Multiple imputation**: Missing data is currently handled via FIML (Full Information Maximum Likelihood). Multiple imputation methods are planned for future releases.

### Data Requirements

* **r3step requires person-level data**: The `r3step()` function requires one row per individual (person-level data). If your data is in long format, aggregate to person-level before calling r3step:
  ```r
  person_data <- my_data[!duplicated(my_data$id), ]
  r3step(fit, distal_vars = "outcome", data = person_data)
  ```

### Missing Data Handling

* **FIML assumes MAR**: Full Information Maximum Likelihood assumes data are Missing At Random (MAR). If you suspect Missing Not At Random (MNAR), conduct sensitivity analyses.
* **Monotone vs non-monotone patterns**: The `validate_survey_data()` function identifies missing data patterns, but currently all patterns are handled the same way via FIML.

### Testing Status

* **23 tests currently skipped**: Most skipped tests are for unimplemented features (ML method, external dependencies like Mplus). See test files for details.
* **Vignette updates needed**: Some vignette code examples use outdated parameter names and will be updated in the next release. See `VIGNETTE_FIXES_NEEDED.md` for details.

### Platform Notes

* **Parallel processing on Windows**: Some users may experience issues with parallel processing on Windows. If you encounter errors, set `cores = 1` for sequential processing.
* **Memory requirements**: Models with many random starts (500-1000+) and large datasets may require substantial RAM. Use `store_data = FALSE` to reduce memory footprint.

### Performance Considerations

* **BLRT is computationally intensive**: Bootstrap Likelihood Ratio Test can take hours for complex models. Consider using the faster LMR test for initial exploration.
* **Convergence with complex designs**: Models with many strata and clusters may require more random starts or adjusted convergence criteria.

See GitHub issues (https://github.com/siyangni/surveymixr/issues) for currently tracked bugs and feature requests.

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

### Random Effects Support (Phase 2.1.2)

* **Random Effects in Growth Parameters**
  - `gmm_survey_re()`: Growth mixture models with random intercepts and/or slopes
  - Individual-level variance in growth parameters within each class
  - `get_random_effects()`: Extract predicted random effects (BLUPs)
  - `variance_components()`: Extract variance-covariance matrices
  - `calculate_icc()`: Intraclass correlation coefficients
  - `plot_random_effects()`: Visualize random effects distributions
  - Full integration with survey weights
  - S4 class `SurveyMixrRE` for random effects models

### Time-Varying Covariates Enhancement (Phase 2.1.3)

* **Enhanced TVC Support**
  - `gmm_survey_tvc()`: Comprehensive time-varying covariate modeling
  - Four effect types: direct, indirect, both (within/between decomposition), interaction
  - Automatic detection of time-varying vs time-invariant variables
  - Person-mean centering for within-between effects separation
  - Lagged effects support (lag 1, 2, ...)
  - Class-specific TVC effects option
  - `extract_tvc_effects()`: Extract TVC parameter estimates
  - `test_tvc_effects()`: Wald tests for TVC significance
  - `plot_tvc_effects()`: Visualize TVC influences on trajectories
  - S4 class `SurveyMixrTVC` for TVC models

### New Vignettes

* **Categorical Outcomes Vignette** (`vignettes/categorical-outcomes.Rmd`)
  - Comprehensive guide to binary, ordinal, and count outcomes
  - Link function selection and interpretation
  - Real-world examples (smoking, health ratings, delinquency)
  - Comparison with continuous outcome approaches
  - Model selection for categorical data

* **Enhanced Model Selection Vignette** (`vignettes/model-selection-enhanced.Rmd`)
  - Complete workflow for determining optimal number of classes
  - LMR test vs BLRT comparison
  - Cross-validation strategies
  - Handling disagreement among criteria
  - Comprehensive reporting guidelines

### Coming in Version 0.3.0

* Bayes factor approximation for model selection
* Posterior predictive checks
* Additional growth model specifications (piecewise, free basis)
* Performance optimization with Rcpp
* Parallel process models
* Complete integration of placeholder implementations

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
