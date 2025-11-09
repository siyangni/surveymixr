# Comprehensive Test Suite for surveymixr

This document describes the comprehensive test suite (`test-comprehensive.R`) that provides complete coverage for all exported functions in the surveymixr package.

## Purpose

The comprehensive test file (`test-comprehensive.R`) serves as:

1. **Complete Function Coverage**: Tests all exported functions and S4 methods
2. **Integration Testing**: Validates complete workflows from data simulation through analysis
3. **Replacement for week1-setup.R**: Provides automated testing that replaces the manual setup script

## What's Tested

### Core Estimation Functions
- `gmm_survey()` - Growth mixture model estimation
- `gmm_select()` - Model selection across class numbers
- All growth model types (linear, quadratic, cubic, etc.)

### Extraction Functions
- `extract_fit_indices()` - Extract AIC, BIC, aBIC, entropy, log-likelihood
- `extract_trajectories()` - Extract predicted trajectories with confidence intervals

### Diagnostic Functions
- `entropy()` - Classification entropy
- `class_proportions()` - Class proportions with standard errors
- `classification_quality()` - AvePP, OCC, classification error matrix
- `diagnose_convergence()` - Convergence diagnostics and replication checks

### Comparison Functions
- `compare_classes()` - Statistical comparisons between classes
- `compare_with_mplus()` - Validation against Mplus results

### Plotting Functions
- `plot_trajectories()` - Trajectory plots with confidence intervals
- `plot_class_comparison()` - Class comparison visualizations
- `plot_model_selection()` - Model selection criterion plots

### S4 Methods
All standard S4 methods are tested:
- `print()`, `show()`, `summary()`
- `coef()`, `vcov()`
- `logLik()`, `AIC()`, `BIC()`
- `fitted()`, `residuals()`
- `plot()`

### R3STEP Auxiliary Analysis
- `r3step()` - All three methods (BCH, ML, manual)
- Omnibus tests
- Pairwise comparisons
- Effect sizes

### Utility Functions
- `wide_to_long()` - Data reshaping
- `simulate_gmm_survey()` - Data simulation with various designs

### Survey Design Features
- Simple random sampling (SRS)
- Stratified sampling
- Cluster sampling
- Complex designs (stratified + cluster)
- Survey weights

### Edge Cases and Error Handling
- Small sample sizes
- Boundary solutions
- Invalid inputs
- Missing data

## Test Organization

The comprehensive test file is organized into sections:

1. **Core Estimation Functions** (Tests 1-2)
2. **Extraction Functions** (Tests 3-6)
3. **Diagnostic Functions** (Tests 7-10)
4. **Comparison Functions** (Tests 11-13)
5. **Plotting Functions** (Tests 14-17)
6. **S4 Methods** (Test 18)
7. **R3STEP Analysis** (Test 19)
8. **Utility Functions** (Tests 20-21)
9. **Survey Design Features** (Test 22)
10. **Edge Cases** (Tests 23-24)
11. **Integration Tests** (Test 25)

## Running the Tests

To run only the comprehensive tests:

```r
devtools::test(filter = "comprehensive")
```

To run all tests including comprehensive:

```r
devtools::test()
```

To check test coverage:

```r
covr::package_coverage()
```

## Replacing week1-setup.R

The `week1-setup.R` script previously performed:
- R CMD check
- Spell checking
- URL validation
- Test coverage analysis
- Documentation checks

These tasks are now better handled by:

1. **Automated Testing**: Use `devtools::test()` or `testthat::test_dir("tests/testthat")`
2. **R CMD Check**: Use `devtools::check()` or `R CMD check`
3. **Continuous Integration**: Configure CI/CD to run these automatically
4. **Coverage Reports**: Use `covr::package_coverage()`

## Expected Test Results

All tests should pass with:
- ✓ No errors
- ✓ No failures
- ⚠ Some tests may be skipped on CRAN (marked with `skip_on_cran()`)
- ⚠ Some tests requiring external software (Mplus) are skipped

## Coverage Goals

The comprehensive test suite aims for:
- **Function Coverage**: 100% of exported functions tested
- **Line Coverage**: >80% of package code
- **Branch Coverage**: >70% of decision branches
- **Integration Coverage**: Complete workflows tested end-to-end

## Maintenance

When adding new functions to the package:

1. Add corresponding tests to `test-comprehensive.R`
2. Follow the existing test structure and naming conventions
3. Include both basic functionality and edge case tests
4. Document any tests that require external dependencies

## Related Test Files

The comprehensive test file complements existing specialized test files:
- `test-basic-estimation.R` - Core estimation tests
- `test-utilities.R` - Utility function tests
- `test-diagnostics.R` - Diagnostic function tests
- `test-model-selection.R` - Model selection tests
- `test-r3step.R` - R3STEP analysis tests
- `test-convergence.R` - Convergence testing
- `test-edge-cases.R` - Edge case handling
- `test-survey-designs.R` - Survey design features
- And others...

The comprehensive test file provides broad coverage while specialized files provide deep coverage of specific functionality.
