# surveymixr Test Suite Analysis Report

## Executive Summary

The surveymixr test suite has **196 test assertions** across **15 test files**, covering major functionality but with significant gaps in:

1. **Advanced diagnostic functions** (0 tests)
2. **Advanced visualization functions** (minimal tests)
3. **Random effects functionality** (0 tests)
4. **Time-varying covariates** (0 tests)
5. **Interactive plotting** (0 tests)
6. **Mplus interoperability** (mostly skipped or placeholders)

### Key Metrics
- Total Test Files: 15
- Total Tests: 196 test_that blocks
- Total Exported Functions: 49
- Skip_on_cran Count: 40 (20% of tests)
- Skipped Tests Count: ~20+ with skip() or skip_on_cran()

---

## Part 1: Coverage by Source File

### WELL COVERED (>20 tests or comprehensive)

| Source File | Test File | Coverage |
|-------------|-----------|----------|
| core-em-algorithm.R | test-convergence.R, test-basic-estimation.R | Good - EM algorithm tested extensively |
| simulate.R | test-simulate.R | 4 tests - basic simulation works |
| data-validation.R | test-data-validation.R | 19 tests - comprehensive validation |
| gmm-survey.R | test-basic-estimation.R, test-comprehensive.R | Good - main estimation function |
| utilities.R | test-utilities.R | 25 tests - wide_to_long, mplus conversion |
| outcome-types.R | test-categorical-outcomes.R | 11 tests - binary/ordinal/count validation |

### MODERATELY COVERED (5-10 tests)

| Source File | Test File | Coverage |
|-------------|-----------|----------|
| gmm-select.R | test-model-selection.R, test-lmr-cv.R | 10 tests - model selection basics |
| cross-validation.R | test-lmr-cv.R | Partial - CV fold creation tested |
| plotting.R | test-comprehensive.R | 2 tests - plot_trajectories, plot_model_selection |
| plotting-interactive.R | (none) | Plot with plot() generic method only |
| r3step.R | test-r3step.R | 11 tests - BCH method tested, ML skipped |
| methods.R | test-comprehensive.R, test-basic-estimation.R | Covered through S4 methods |

### POORLY COVERED (<5 tests or 0 tests)

| Source File | Test File | Coverage | Issue |
|-------------|-----------|----------|-------|
| diagnostics-advanced.R | NONE | 0 tests | **CRITICAL**: diagnose_influence, diagnose_separation unimplemented |
| random-effects.R | NONE | 0 tests | **CRITICAL**: gmm_survey_re, get_random_effects, calculate_icc, variance_components untested |
| time-varying-covariates.R | NONE | 0 tests | **CRITICAL**: gmm_survey_tvc, extract_tvc_effects, test_tvc_effects untested |
| lmr-test.R | test-lmr-cv.R | Mostly skipped | LMR functions have placeholder/skipped tests |
| fit-indices.R | test-comprehensive.R | Indirect via extract_fit_indices | |
| plotting-interactive.R | NONE | 0 tests | plot_interactive, plot_model_selection_interactive untested |
| standard-errors.R | Indirect | Sandwich SE tested indirectly | |

---

## Part 2: Critical Functionality Under-Tested or Untested

### UNTESTED EXPORTED FUNCTIONS (with severity)

#### CRITICAL (Advanced Methods - Phase 2.1+)

| Function | Location | Impact | Test Need |
|----------|----------|--------|-----------|
| **gmm_survey_re()** | random-effects.R | Random effects in growth parameters - key feature | URGENT: Add 5-10 tests |
| **get_random_effects()** | random-effects.R | Extract random effects from fitted model | URGENT: Add tests |
| **calculate_icc()** | random-effects.R | Intraclass correlation calculation | URGENT: Add tests |
| **variance_components()** | random-effects.R | Variance-covariance matrices for random effects | URGENT: Add tests |
| **gmm_survey_tvc()** | time-varying-covariates.R | Time-varying covariates - key feature | URGENT: Add 5-10 tests |
| **extract_tvc_effects()** | time-varying-covariates.R | Extract TVC effects | URGENT: Add tests |
| **test_tvc_effects()** | time-varying-covariates.R | Test significance of TVC effects | URGENT: Add tests |

#### HIGH PRIORITY (Diagnostics)

| Function | Location | Impact | Test Need |
|----------|----------|--------|-----------|
| **diagnose_influence()** | diagnostics-advanced.R | Detect influential observations | HIGH: Add 3-5 tests |
| **diagnose_separation()** | diagnostics-advanced.R | Detect class separation issues | HIGH: Add 2-3 tests |
| **residual_diagnostics()** | diagnostics-advanced.R | Residual analysis | HIGH: Add 2-3 tests |

#### MEDIUM PRIORITY (Plotting)

| Function | Location | Impact | Test Need |
|----------|----------|--------|-----------|
| **plot_interactive()** | plotting-interactive.R | Interactive Plotly plots | MEDIUM: Add 3-4 tests |
| **plot_model_selection_interactive()** | plotting-interactive.R | Interactive model selection plot | MEDIUM: Add 1-2 tests |
| **plot_entropy_distribution()** | plotting.R | Entropy distribution plot | MEDIUM: Add 1 test |
| **plot_convergence()** | plotting.R | Convergence diagnostics plot | MEDIUM: Add 1 test |
| **plot_random_effects()** | plotting.R | Plot random effects | MEDIUM: Add 1 test |
| **plot_tvc_effects()** | plotting.R | Plot TVC effects | MEDIUM: Add 1 test |
| **plot_class_comparison()** | plotting.R | Skipped - requires covariates in @data | MEDIUM: Fix + add test |

### FUNCTIONS WITH SKIPPED/PLACEHOLDER TESTS

| Function | Test File | Status | Issue |
|----------|-----------|--------|-------|
| **lmr_test()** | test-lmr-cv.R | Multiple skip statements | Requires fitted models - placeholder tests only |
| **lmr_sequential()** | test-lmr-cv.R | Mostly skipped | Input validation tested, actual function skipped |
| **gmm_cv()** | test-lmr-cv.R | Partially tested | Fold creation tested, model fitting skipped |
| **plot_class_comparison()** | test-comprehensive.R | Skipped | "covariates not stored in @data" - known bug |
| **compare_classes()** | test-comprehensive.R | Skipped | Same issue as plot_class_comparison |
| **compare_with_mplus()** | test-comprehensive.R | Skipped | Requires Mplus installation |
| **quadratic growth model** | test-growth-models.R | Skipped | Parameter naming needs verification |
| **nonlinear growth model** | test-growth-models.R | Skipped | Not yet implemented |
| BLRT functionality | test-model-selection.R | Skipped | "computationally intensive" |

---

## Part 3: Test Organization & Quality Issues

### 3.1 Excessive skip_on_cran() Usage

**Test files with high skip_on_cran concentration:**

| File | skip_on_cran Count | test_that Count | % Skipped | Issue |
|------|--------------------|-----------------|-----------|-------|
| test-convergence.R | 14 | 14 | **100%** | ALL tests skip on CRAN - convergence testing never runs on CRAN |
| test-edge-cases.R | 15 | 18 | **83%** | Most edge case tests skip on CRAN |
| test-model-selection.R | 10 | 10 | **100%** | All model selection tests skip on CRAN |

**Problem:** These skip_on_cran directives mean:
- Convergence diagnostics never tested on CRAN
- Edge cases never tested on CRAN
- Model selection never tested on CRAN
- Users installing from CRAN see NO evidence these functions work

**Recommendation:** 
- Move skip_on_cran to outer test_that() blocks for computational tests only
- Keep basic validation tests running on CRAN
- Examples: skip_on_cran should wrap EM iterations, not input validation

### 3.2 Known Bugs Documented in Tests

**From test-comprehensive.R comments:**
```
# Tests are marked with skip() due to current bugs:
# - gmm_select: BLRT computation bug when run_blrt=FALSE
# - class_proportions: Differing number of rows error
# - r3step: Subscript out of bounds error
# - residuals method: Non-conformable arrays bug
# - compare_classes/plot_class_comparison: Covariates not stored in @data slot
```

These are significant bugs that affect user workflows but aren't tracked in GitHub issues.

### 3.3 Missing Edge Cases

**Not tested:**
- Very large sample sizes (n > 100,000)
- Very small time series (n_times = 2)
- Extreme class imbalance (e.g., 1%, 1%, 98%)
- Single class with n_classes = 1
- Perfect multicollinearity in covariates
- Negative outcomes (when not valid)
- Non-invertible variance matrices
- Empty latent classes after convergence
- Extreme weight values (0, Inf, very large)
- Missing entire time points for individuals
- Numerical precision issues (very large/small log-likelihoods)

### 3.4 Missing Integration Tests

**Not tested together:**
- Random effects + survey design
- Time-varying covariates + categorical outcomes
- R3STEP + random effects
- Model selection + random effects
- Cross-validation + time-varying covariates
- Multiple outcome types in sequence
- Plotting pipeline (simulate → fit → select → plot)

### 3.5 Test File Organization Issues

**test-comprehensive.R** (940 lines, 25 tests):
- Contains tests for multiple modules (estimation, diagnostics, extraction, etc.)
- Should be split by module for clarity
- Mixing skipped and non-skipped tests makes it hard to understand coverage

**test-utilities.R** (676 lines, 25 tests):
- Very large - should split Mplus functions into separate file
- test-simulate.R and test-utilities.R do similar things

**test-lmr-cv.R** (683 lines, 23 tests):
- Heavy reliance on skip() statements
- More placeholder tests than actual tests
- Should either implement tests or remove skips with explanation

---

## Part 4: Recommendations by Priority

### URGENT (Blocking CRAN submission quality)

1. **Fix test-convergence.R skip_on_cran issue**
   - These tests MUST run on CRAN to validate core EM algorithm
   - Move skip_on_cran inside describe blocks if needed for performance
   - Impact: HIGH - convergence is fundamental

2. **Add random effects tests**
   - gmm_survey_re() is exported but untested
   - Add 5-10 tests covering:
     - Random intercepts only
     - Random slopes only
     - Random intercepts + slopes
     - Different variance structures
     - ICC calculations
   - Add get_random_effects() tests
   - Impact: HIGH - Phase 2.1 feature

3. **Add time-varying covariates tests**
   - gmm_survey_tvc() is exported but untested
   - Add 5-10 tests covering:
     - Simple TVC
     - Multiple TVCs
     - TVC + survey design
     - test_tvc_effects() function
   - Impact: HIGH - Phase 2.2 feature

4. **Fix and test known bugs**
   - GMm_select BLRT bug
   - class_proportions rows error
   - r3step subscript error
   - residuals method non-conformable arrays
   - plot_class_comparison covariate storage
   - Estimated effort: 20-40 hours

### HIGH (Next sprint)

5. **Add diagnostics tests**
   - diagnose_influence() - 3-5 tests
   - diagnose_separation() - 2-3 tests
   - residual_diagnostics() - 2-3 tests
   - Impact: MEDIUM - important for model validation

6. **Add interactive plotting tests**
   - plot_interactive() - 3-4 tests
   - plot_model_selection_interactive() - 1-2 tests
   - plot_posterior_dist() - 1 test
   - Estimated effort: 8-12 hours

7. **Improve test-lmr-cv.R**
   - Replace skip() statements with actual tests
   - Either implement lmr_test() fully or remove skips
   - Test gmm_cv() thoroughly
   - Estimated effort: 15-20 hours

### MEDIUM (Future)

8. **Add edge case tests**
   - Create new test-edge-cases-extended.R
   - Test numerical stability
   - Test boundary conditions
   - Estimated effort: 10-15 hours

9. **Add integration tests**
   - Full workflows combining features
   - Pipeline testing (simulate → fit → select → diagnose)
   - Cross-module interactions
   - Estimated effort: 15-20 hours

10. **Reorganize test files**
    - Split test-comprehensive.R by module
    - Create test-plotting.R for all plotting
    - Create test-random-effects.R for RE functionality
    - Create test-time-varying-covariates.R for TVC
    - Create test-mplus-conversion.R for Mplus functions
    - Estimated effort: 5-10 hours

### LOW (Polish)

11. **Performance benchmarking**
    - Test suite takes too long (skip_on_cran overhead)
    - Profile slow tests
    - Consider using lighter simulated data for some tests

12. **Test documentation**
    - Add README explaining test organization
    - Document which tests are computational
    - Add expected runtime per test file

---

## Part 5: Specific Files Needing Attention

### High-Priority Source Files by Criticality

**random-effects.R (UNTESTED)**
- Status: Exported but 0 tests
- Functions affected: gmm_survey_re(), get_random_effects(), calculate_icc(), variance_components()
- Required tests: 8-12 new tests
- Action: Create test-random-effects.R

**time-varying-covariates.R (UNTESTED)**
- Status: Exported but 0 tests
- Functions affected: gmm_survey_tvc(), extract_tvc_effects(), test_tvc_effects()
- Required tests: 8-12 new tests
- Action: Create test-time-varying-covariates.R

**diagnostics-advanced.R (UNTESTED)**
- Status: Exported but 0 tests
- Functions affected: diagnose_influence(), diagnose_separation(), residual_diagnostics()
- Required tests: 6-8 new tests
- Action: Create test-diagnostics-advanced.R

**plotting-interactive.R (UNTESTED)**
- Status: Exported but 0 tests
- Functions affected: plot_interactive(), plot_model_selection_interactive(), plot_posterior_dist()
- Required tests: 4-6 new tests
- Action: Add to test-plotting.R or create dedicated file

**test-convergence.R (SKIP_ON_CRAN ISSUE)**
- Status: All 14 tests skip on CRAN (100%)
- Issue: EM algorithm convergence untested on CRAN
- Action: Refactor to have CRAN-safe tests

**test-lmr-cv.R (PLACEHOLDER TESTS)**
- Status: Many skip() and skip_on_cran() statements
- Issue: Model comparison functionality not tested
- Action: Implement actual tests or clearly document why skipped

---

## Part 6: Summary Statistics

### Current Test Coverage by Category

| Category | Test Count | Functions Covered | Functions Untested | Coverage % |
|----------|------------|-------------------|------------------|-----------|
| Core Estimation | ~30 | gmm_survey, gmm_select | | ~80% |
| Categorical Outcomes | ~11 | binary, ordinal, count | | ~100% |
| Data Validation | ~19 | validate_survey_data | | ~100% |
| Diagnostics (Basic) | ~4 | entropy, class_props, conv | | ~40% |
| Diagnostics (Advanced) | 0 | NONE | diagnose_influence, separation, residuals | **0%** |
| Plotting | ~5 | plot_traj, plot_selection | plot_interactive, plot_entropy, plot_conv, plot_RE, plot_TVC | **~30%** |
| Random Effects | 0 | NONE | gmm_survey_re, get_RE, ICC, var_comp | **0%** |
| Time-Varying Covariates | 0 | NONE | gmm_survey_tvc, extract_tvc, test_tvc | **0%** |
| Model Selection (LMR/CV) | ~8 | CV fold creation | LMR test, Sequential LMR | **~50%** |
| R3STEP | ~11 | r3step BCH | r3step ML | **~50%** |
| Utilities | ~25 | wide_to_long, simulate | Mplus conversion | **~80%** |
| **TOTAL** | **~196** | **~39** | **~15+** | **~72%** |

---

## Appendix: Test File Summary

### test-basic-estimation.R (119 lines, 4 tests)
- Tests: gmm_survey basic functionality, S4 methods
- Coverage: Minimal - only basic happy path
- Recommendation: Expand to 10-15 tests

### test-categorical-outcomes.R (303 lines, 11 tests)
- Tests: Link functions, outcome validation
- Coverage: Good for validation, but no actual estimation tests for outcome types
- Recommendation: Add fitting tests for binary/ordinal/count outcomes

### test-comprehensive.R (940 lines, 25 tests)
- Tests: Core estimation, extraction, diagnostics, plotting
- Coverage: Good but many are skipped or skip_on_cran
- Issues: Known bugs documented, too many functions in one file
- Recommendation: Split by module, fix known bugs

### test-convergence.R (486 lines, 14 tests)
- Tests: EM convergence, random starts
- Coverage: Good quality but **ALL SKIP ON CRAN**
- Issue: **CRITICAL** - 100% skip_on_cran
- Recommendation: Move skip_on_cran inside tests, not around

### test-data-validation.R (363 lines, 19 tests)
- Tests: Data quality checks
- Coverage: Comprehensive - excellent
- Recommendation: Maintain current level

### test-diagnostics.R (94 lines, 4 tests)
- Tests: Basic diagnostics (entropy, proportions, quality)
- Coverage: Minimal
- Recommendation: Expand to 10-12 tests, add advanced diagnostics

### test-edge-cases.R (571 lines, 18 tests)
- Tests: Single class, small samples, perfect separation
- Coverage: Good but mostly skip_on_cran (83%)
- Issue: Most tests not run on CRAN
- Recommendation: Reduce skip_on_cran overhead

### test-growth-models.R (218 lines, 6 tests)
- Tests: Linear, free basis models
- Coverage: Some models skipped (quadratic, nonlinear)
- Issue: Model functionality incomplete
- Recommendation: Implement/test remaining models

### test-lmr-cv.R (683 lines, 23 tests)
- Tests: LMR test, cross-validation
- Coverage: Many skipped/placeholder tests
- Issue: More skips than actual tests
- Recommendation: Refactor - either implement or document clearly

### test-missing-data.R (476 lines, 13 tests)
- Tests: FIML with MCAR, MAR, different missing rates
- Coverage: Good for missing data handling
- Recommendation: Add MNAR tests, test different mechanism combinations

### test-model-selection.R (331 lines, 10 tests)
- Tests: gmm_select, class determination
- Coverage: Moderate, but **100% skip_on_cran**
- Issue: Critical functionality never tested on CRAN
- Recommendation: Move skip_on_cran inside, make some tests CRAN-safe

### test-r3step.R (403 lines, 11 tests)
- Tests: R3STEP BCH method, ML method skipped
- Coverage: BCH method good, ML unimplemented
- Recommendation: Implement and test ML method

### test-simulate.R (71 lines, 4 tests)
- Tests: Data simulation
- Coverage: Basic - only structure tests
- Recommendation: Expand to 8-10 tests for parameter validation

### test-survey-designs.R (331 lines, 9 tests)
- Tests: SRS, stratified, cluster designs
- Coverage: Good for basic designs
- Recommendation: Add complex multi-level designs

### test-utilities.R (676 lines, 25 tests)
- Tests: wide_to_long, simulate, Mplus conversion
- Coverage: Good for simulation and reshaping
- Issue: Mix of different utilities makes file large
- Recommendation: Split Mplus functions to separate file

---

## Conclusion

The surveymixr test suite is **~72% complete** with good coverage of core functionality but significant gaps in:

1. **Advanced features (Phase 2.1+)**: Random effects and TVC untested
2. **Advanced diagnostics**: Influence, separation detection untested
3. **Visualization**: Interactive plots untested
4. **Test quality**: Over-reliance on skip_on_cran hiding gaps from CRAN
5. **Documentation**: Known bugs in comments rather than issues

**Estimated effort to reach 90% coverage**: 80-120 hours

**Critical path**:
1. Fix skip_on_cran issues in convergence/model selection tests
2. Add random effects and TVC tests
3. Fix known bugs
4. Add diagnostics tests
