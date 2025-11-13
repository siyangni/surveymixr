# surveymixr: Growth Mixture Models with Complex Survey Design

<!-- badges: start -->
[![R-CMD-check](https://github.com/siyangni/surveymixr/workflows/R-CMD-check/badge.svg)](https://github.com/siyangni/surveymixr/actions)
<!-- [![CRAN status](https://www.r-pkg.org/badges/version/surveymixr)](https://CRAN.R-project.org/package=surveymixr) -->
[![codecov](https://codecov.io/gh/siyangni/surveymixr/branch/main/graph/badge.svg)](https://app.codecov.io/gh/siyangni/surveymixr)
<!-- badges: end -->

## Overview

**surveymixr** implements growth mixture modeling (GMM) for longitudinal data with full integration of complex survey design features including stratification, clustering, and probability weights. This package fills a critical gap in R's statistical capabilities by enabling analyses of large-scale longitudinal surveys (e.g., Millennium Cohort Study, Add Health, NLSY) that were previously only possible in proprietary software like Mplus.

📖 **[Read the complete User Manual](https://siyangni.github.io/surveymixr/articles/user-manual.html)** for comprehensive documentation covering all features, workflows, and best practices.

## Key Features

- **Survey Design Integration**: Proper handling of stratification, clustering (PSUs), and probability weights with sandwich standard errors
- **Bootstrap Likelihood Ratio Test (BLRT)**: Efficient parallelized implementation for optimal class enumeration
- **Multiple Random Starts**: Convergence diagnostics with tracking of local maxima (500-1000+ starts)
- **R3STEP Method**: Auxiliary variable analysis with classification uncertainty correction (BCH, ML, manual approaches)
- **Flexible Growth Models**: Linear, quadratic, nonlinear, and free basis time scores
- **Comprehensive Diagnostics**: Entropy, class proportions, classification quality, convergence tracking
- **Professional Visualization**: Publication-ready trajectory plots with confidence intervals
- **Multiple Outcome Types**: Continuous, count, binary, and ordinal outcomes

## Installation

```r
# Install from CRAN (once published)
install.packages("surveymixr")

# Or install development version from GitHub
# install.packages("devtools")
devtools::install_github("siyangni/surveymixr")
```

## Quick Start

```r
library(surveymixr)

# Load simulated Millennium Cohort Study-like data
data(mcs_simulated)

# Fit 3-class growth mixture model with complex survey design
fit <- gmm_survey(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  n_classes = 3,
  growth_model = "linear",
  strata = "stratum",
  cluster = "psu",
  weights = "weight",
  starts = 500,
  cores = 4
)

# View results
summary(fit)

# Plot trajectories
plot(fit, type = "trajectories")

# Check convergence diagnostics
diagnose_convergence(fit)
```

## Model Selection

```r
# Compare 1-5 class models with BLRT
selection <- gmm_select(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  classes = 1:5,
  strata = "stratum",
  cluster = "psu",
  weights = "weight",
  criteria = c("BIC", "BLRT", "entropy"),
  blrt_samples = 100,
  starts = 200,
  cores = 4
)

print(selection)
```

## R3STEP for Distal Outcomes

```r
# Analyze auxiliary variables with classification uncertainty correction
r3step_results <- r3step(
  gmm_object = fit,
  distal_vars = c("academic_achievement", "delinquency"),
  data = mcs_simulated,
  method = "BCH"
)

summary(r3step_results)
```

## Why surveymixr?

Existing R packages have significant limitations:

| Feature | surveymixr | lcmm | flexmix | lavaan | openmx |
|---------|-----------|------|---------|--------|---------|
| Growth mixture models | ✓ | ✓ | Partial | ✗ | ✗ |
| Complex survey design | ✓ | ✗ | ✗ | Partial | ✗ |
| Stratification + clustering | ✓ | ✗ | ✗ | ✗ | ✗ |
| Probability weights | ✓ | ✗ | ✗ | ✗ | ✗ |
| BLRT implementation | ✓ | ✗ | ✗ | ✗ | ✗ |
| R3STEP method | ✓ | ✗ | ✗ | ✗ | ✗ |
| 1000+ random starts | ✓ | ✗ | ✗ | ✗ | ✗ |

**surveymixr** is the only R package that combines growth mixture modeling with full complex survey design features.

## Documentation

### [User Manual](https://siyangni.github.io/surveymixr/articles/user-manual.html)

A comprehensive, unified guide covering:
- Getting started with installation and quick examples
- Core concepts of growth mixture models and survey design
- Model fitting, selection, and diagnostics
- Advanced features (random effects, time-varying covariates, R3STEP)
- Visualization, troubleshooting, and best practices

### Additional Vignettes

Specialized topics are covered in additional vignettes:

- Introduction to surveymixr (`vignette("surveymixr-intro")`)
- Technical Details and Algorithms (`vignette("technical-details")`)
- R3STEP Auxiliary Variable Analysis (`vignette("r3step-analysis")`)
- Validation Against Mplus (`vignette("mplus-validation")`)

After package installation, view all vignettes with:
```r
browseVignettes("surveymixr")
```

## Citation

If you use surveymixr in your research, please cite:

```
Ni, S. (2025). surveymixr: An Open-Source R Package for Growth Mixture
  Modeling with Complex Survey Design. 
```

## License

GPL-3

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
