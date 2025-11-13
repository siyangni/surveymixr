# Phase 1 Action Plan: CRAN Submission Readiness
## surveymixr v0.2.0 (4-6 weeks)

**Goal**: Submit package to CRAN with confidence
**Status**: v0.1.0 → v0.2.0
**Target Date**: December 20, 2025

---

## WEEK 1: Foundation & Assessment

### Day 1-2: Create Example Dataset
- [ ] Navigate to `/data-raw/`
- [ ] Run `create-mcs-simulated.R` script
- [ ] Verify `mcs_simulated.rda` created in `/data/`
- [ ] Load data and check structure: `data(mcs_simulated)`
- [ ] Verify documentation matches data
- [ ] Update all examples to use the real dataset
- [ ] Remove `\dontrun{}` from examples that now work

### Day 3: Initial R CMD Check
```r
devtools::check()
```
- [ ] Document all ERRORs, WARNINGs, NOTEs
- [ ] Create prioritized fix list
- [ ] Estimate time for each fix

### Day 4-5: Quick Wins
- [ ] Fix all spelling errors: `devtools::spell_check()`
- [ ] Check all URLs are valid
- [ ] Verify DESCRIPTION file is complete
- [ ] Update NEWS.md with v0.2.0 changes
- [ ] Run `urlchecker::url_check()`

### Day 6-7: Documentation Audit
- [ ] Check every function has:
  - [ ] Complete `@param` descriptions
  - [ ] `@return` description
  - [ ] At least one working `@examples`
  - [ ] Relevant `@seealso` references
  - [ ] `@references` to key papers
- [ ] Update any outdated information
- [ ] Add value ranges to parameters (e.g., "between 0 and 1")

---

## WEEK 2: Testing Infrastructure

### Core Test Files
Create comprehensive test coverage:

#### test-growth-models.R (Day 8-9)
```r
test_that("linear growth model works", {
  # Test with simulated data
  fit <- gmm_survey(
    data = mcs_simulated,
    id = "id",
    time = "age",
    outcome = "selfcontrol",
    n_classes = 2,
    growth_model = "linear",
    starts = 10  # Low for testing speed
  )

  expect_s4_class(fit, "SurveyMixr")
  expect_equal(fit@n_classes, 2)
  expect_true(all(!is.na(coef(fit))))
})

test_that("quadratic growth model works", {
  # Similar structure
})

test_that("free basis growth model works", {
  # Similar structure
})
```

#### test-survey-designs.R (Day 10-11)
```r
test_that("simple random sampling works", {
  # No survey design specified
})

test_that("stratified sampling works", {
  # With strata argument
})

test_that("cluster sampling works", {
  # With cluster argument
})

test_that("stratified cluster sampling works", {
  # With both strata and cluster
})

test_that("nested design works", {
  # With nest = TRUE
})

test_that("weights are applied correctly", {
  # Compare weighted vs unweighted proportions
})
```

#### test-model-selection.R (Day 12-13)
```r
test_that("gmm_select compares models correctly", {
  result <- gmm_select(
    data = mcs_simulated,
    id = "id",
    time = "age",
    outcome = "selfcontrol",
    min_classes = 1,
    max_classes = 3,
    starts = 10,
    run_blrt = FALSE  # Fast for testing
  )

  expect_s4_class(result, "SurveyMixrSelect")
  expect_equal(nrow(result@comparison_table), 3)
})

test_that("BLRT works", {
  # With run_blrt = TRUE, fewer classes for speed
})
```

#### test-r3step.R (Day 14)
```r
test_that("BCH method works", {
  # Fit model first, then r3step
})

test_that("ML method works", {
  # Test ML approach
})

test_that("manual 3-step works", {
  # Test manual approach
})
```

### Run Coverage Analysis
```r
covr::package_coverage()
```
- [ ] Target: >80% coverage
- [ ] Identify untested lines
- [ ] Add tests for critical paths

---

## WEEK 3: Vignettes

### Technical Details Vignette (3-4 days)

**File**: `vignettes/technical-details.Rmd`

**Outline**:
```markdown
---
title: "Technical Details and Algorithms"
author: "Siyang Ni"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Technical Details and Algorithms}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

## Introduction
Brief overview of growth mixture modeling and survey design features

## Statistical Framework
### 1. Growth Mixture Model
- Individual-level model
- Class-specific parameters
- Mathematical notation

### 2. Complex Survey Design
- Stratification
- Clustering
- Probability weights
- Design effects

### 3. Integration: Survey-Weighted GMM
- Modified likelihood
- Weight incorporation
- Bias reduction

## Estimation Algorithm
### 1. EM Algorithm
- E-step: Posterior probabilities with weights
- M-step: Parameter updates with weights
- Convergence criteria

### 2. Random Starts
- Why multiple starts?
- Parallel processing
- Best solution selection

### 3. Missing Data (FIML)
- Missing at random (MAR)
- Likelihood contribution
- Unbiased estimation

## Standard Errors
### 1. Sandwich Estimator
- Robust to model misspecification
- Account for clustering
- Account for stratification

### 2. Variance-Covariance Matrix
- Numerical derivatives
- Delta method
- Confidence intervals

## Bootstrap Likelihood Ratio Test (BLRT)
### 1. Why BLRT?
- Better than AIC/BIC for class enumeration
- Empirical distribution of LRT

### 2. Implementation
- Parametric bootstrap
- Degrees of freedom
- p-value calculation

### 3. Computational considerations
- Parallelization
- Bootstrap replicates (default 500)

## Model Fit Indices
### 1. Information Criteria
- AIC, BIC, aBIC
- Interpretations
- Survey-weighted versions

### 2. Entropy
- Classification quality
- Range 0-1
- Thresholds

### 3. Class Proportions
- Weighted vs unweighted
- Minimum class size considerations

## References
[Key papers: Muthén & Muthén, Asparouhov & Muthén, etc.]
```

**Implementation checklist**:
- [ ] Write each section with equations
- [ ] Add code examples demonstrating each concept
- [ ] Include visualizations
- [ ] Cross-reference to main vignette
- [ ] Build and check: `devtools::build_vignettes()`

### R3STEP Vignette (2-3 days)

**File**: `vignettes/r3step-analysis.Rmd`

**Outline**:
```markdown
---
title: "Analyzing Distal Outcomes with R3STEP"
output: rmarkdown::html_vignette
---

## Introduction
- Why distal outcomes?
- Problem with naive approaches (biased)
- Overview of 3-step methods

## The Three Steps
### Step 1: Unconditional Model
- Fit GMM without distal outcome
- Obtain class membership

### Step 2: Class Assignment
- Most likely class assignment
- Classification errors

### Step 3: Analyze Distal Outcome
- Account for classification uncertainty

## Methods Implemented

### 1. BCH Method (Recommended)
- Bolck, Croon, Hagenaars (2004)
- Survey-weighted version
- When to use

**Example**:
```r
# Step 1: Fit unconditional model
fit <- gmm_survey(...)

# Step 2+3: Analyze distal outcome
result <- r3step(fit,
                 distal = "delinquency",
                 method = "BCH")
summary(result)
plot(result)
```

### 2. ML Method
- Maximum likelihood
- Joint modeling
- More computationally intensive

### 3. Manual 3-Step
- For custom analyses
- Most flexible

## Interpreting Results
- Class-specific means
- Omnibus test (classes differ?)
- Pairwise comparisons
- Effect sizes

## Practical Examples
### Example 1: Continuous Distal Outcome
[Full worked example]

### Example 2: Binary Distal Outcome
[Full worked example]

### Example 3: Multiple Distal Outcomes
[Full worked example]

## Comparison with Traditional Approaches
[Show bias in naive methods]

## References
```

### Mplus Validation Vignette (1-2 days)

**File**: `vignettes/mplus-validation.Rmd`

**Outline**:
```markdown
---
title: "Validation Against Mplus"
output: rmarkdown::html_vignette
---

## Introduction
- Mplus as gold standard
- surveymixr replicates Mplus results
- When to use which software

## Side-by-Side Comparison

### Example 1: Basic 2-Class Model
#### Mplus Code
```mplus
[Mplus syntax]
```

#### surveymixr Code
```r
fit <- gmm_survey(...)
```

#### Results Comparison
- Parameters (within 0.001)
- Standard errors (within 0.005)
- Fit indices (identical)

### Example 2: Survey Design
[Comparison with WEIGHT, STRATIFICATION, CLUSTER]

### Example 3: R3STEP
[BCH method comparison]

## Parameter Recovery Study
- Simulate data with known parameters
- Estimate with both software
- Compare recovery

## Performance Benchmarks
- Execution time
- Memory usage
- Scaling with sample size

## When to Use Mplus vs surveymixr
**Use Mplus if:**
- You need features not in surveymixr (e.g., categorical outcomes currently)
- You have existing Mplus scripts
- You need proprietary support

**Use surveymixr if:**
- You prefer open-source R workflow
- You want reproducible scripts
- You need custom extensions
- You want integration with R ecosystem

## Conversion Utilities
```r
# Convert Mplus syntax to surveymixr
surveymixr_code <- mplus_to_surveymixr("model.inp")

# Export surveymixr to Mplus format
surveymixr_to_mplus(fit, "model.inp")
```

## References
```

---

## WEEK 4: Platform Testing & Fixes

### Multi-Platform Checks

#### Local Testing
```r
# Standard check
devtools::check()

# As CRAN (stricter)
devtools::check(args = "--as-cran")

# Check examples don't take too long
devtools::run_examples(run_donttest = TRUE)
```

#### GitHub Actions Matrix
- [ ] Verify all workflows passing
- [ ] Check on Windows
- [ ] Check on macOS
- [ ] Check on Ubuntu
- [ ] Check on R-devel
- [ ] Check on R-oldrel

#### Fix Platform-Specific Issues
- [ ] Windows: Path separators, file permissions
- [ ] macOS: Compiler flags
- [ ] Linux: Library dependencies

### Performance Optimization

#### Reduce Example Run Times
- [ ] Lower `starts` to 50 in examples
- [ ] Use smaller datasets
- [ ] Mark slow examples with `\donttest{}`
- [ ] Consider `\dontrun{}` for vignette-only code

#### Profile for Bottlenecks
```r
profvis::profvis({
  fit <- gmm_survey(...)
})
```
- [ ] Identify slow functions
- [ ] Optimize critical paths
- [ ] Consider vectorization

---

## WEEK 5: Documentation Polish

### README Enhancement
- [ ] Update badges with CRAN status (pending)
- [ ] Add "Installation" section with CRAN install
- [ ] Ensure quick start example runs perfectly
- [ ] Add "Getting Help" section
- [ ] Link to pkgdown site
- [ ] Add citation information

### CITATION File
Create `inst/CITATION`:
```r
citHeader("To cite surveymixr in publications use:")

bibentry(
  bibtype  = "Manual",
  title    = "surveymixr: Growth Mixture Models for Complex Survey Data",
  author   = person("Siyang", "Ni"),
  year     = 2025,
  note     = "R package version 0.2.0",
  url      = "https://github.com/siyangni/surveymixr",
  textVersion = paste(
    "Ni, S. (2025).",
    "surveymixr: Growth Mixture Models for Complex Survey Data.",
    "R package version 0.2.0.",
    "https://github.com/siyangni/surveymixr"
  )
)

bibentry(
  bibtype  = "Article",
  title    = "surveymixr: An R Package for Growth Mixture Modeling with Complex Survey Data",
  author   = person("Siyang", "Ni"),
  journal  = "Journal of Statistical Software",
  year     = "Forthcoming",
  note     = "Manuscript submitted for publication",
  textVersion = paste(
    "Ni, S. (Forthcoming).",
    "surveymixr: An R Package for Growth Mixture Modeling with Complex Survey Data.",
    "Journal of Statistical Software."
  )
)
```

### NEWS.md Update
```markdown
# surveymixr 0.2.0 (2025-12-XX)

## Major Changes
- Added example dataset `mcs_simulated` for reproducible examples
- Completed comprehensive test suite (>80% coverage)
- Added three vignettes: technical details, R3STEP, Mplus validation

## New Features
- None (focus on documentation and testing)

## Bug Fixes
- [List any bugs fixed]

## Documentation
- Enhanced all function documentation with examples
- Added references to key methodological papers
- Improved parameter descriptions with valid ranges

## Internal
- Expanded test coverage from X% to >80%
- Optimized example run times for CRAN compliance
- Passed R CMD check on all platforms (Windows, macOS, Linux)

## Known Limitations
- Categorical outcomes not yet fully implemented (planned for v0.3.0)
- Random effects for growth parameters not available (planned for v0.3.0)

## Acknowledgments
Thanks to [testers/reviewers] for feedback.
```

### pkgdown Site
```r
pkgdown::build_site()
```
- [ ] Check all pages render correctly
- [ ] Verify examples run
- [ ] Check navigation
- [ ] Ensure vignettes appear
- [ ] Test search functionality

---

## WEEK 6: Final Checks & Submission

### Pre-Submission Checklist

#### Package Structure
- [ ] DESCRIPTION complete and accurate
- [ ] LICENSE file present (GPL-3)
- [ ] NAMESPACE up to date (roxygen2)
- [ ] All exports intentional
- [ ] No .Rd files with \dontrun{} that should work

#### Code Quality
- [ ] No browser() or debug statements
- [ ] No commented-out code blocks
- [ ] Consistent coding style
- [ ] No hardcoded paths
- [ ] All functions documented

#### Testing
- [ ] All tests pass locally
- [ ] All tests pass on GitHub Actions
- [ ] Test coverage >80%
- [ ] No skipped tests without good reason

#### Documentation
- [ ] All exported functions documented
- [ ] All parameters described
- [ ] Examples run successfully
- [ ] Vignettes build without error
- [ ] README up to date
- [ ] NEWS.md complete

#### CRAN Compliance
- [ ] R CMD check: 0 errors, 0 warnings, 0 notes
- [ ] Example timing: all <5 seconds (or marked \donttest{})
- [ ] No non-ASCII characters
- [ ] URLs all valid
- [ ] Imports vs Suggests correct
- [ ] Version number appropriate (0.2.0)

### Create cran-comments.md
```markdown
## R CMD check results
0 errors | 0 warnings | 0 notes

## Test environments
* local: macOS 14.0, R 4.4.0
* GitHub Actions:
  - {windows-latest} x R-release
  - {macOS-latest} x R-release
  - {ubuntu-latest} x R-release
  - {ubuntu-latest} x R-devel
  - {ubuntu-latest} x R-oldrel-1

## Downstream dependencies
There are currently no downstream dependencies for this package.

## Additional notes
This is a new submission. surveymixr implements growth mixture models for
complex survey data, filling a gap previously only addressable with
proprietary software (Mplus).

The package has been thoroughly tested and validated against Mplus results.
All examples run in <5 seconds. Three comprehensive vignettes are included.
```

### Final Validation

#### Spell Check
```r
devtools::spell_check()
```

#### URL Check
```r
urlchecker::url_check()
```

#### Reverse Dependency Check
```r
# Not needed for first submission (no reverse dependencies)
```

#### Manual Review
- [ ] Install from source: `R CMD INSTALL surveymixr_0.2.0.tar.gz`
- [ ] Load package: `library(surveymixr)`
- [ ] Run examples: `example(gmm_survey)`
- [ ] Build vignettes: `browseVignettes("surveymixr")`
- [ ] Check help: `?gmm_survey`

### Submission

#### Build Package
```r
devtools::build()
# Creates surveymixr_0.2.0.tar.gz
```

#### Submit to CRAN
```r
devtools::submit_cran()
```

Or manually at: https://cran.r-project.org/submit.html

#### Post-Submission
- [ ] Monitor email for CRAN feedback
- [ ] Respond within 2 weeks to any comments
- [ ] Address issues quickly
- [ ] Re-submit if needed

---

## CONTINGENCY PLANS

### If Behind Schedule

**Priority 1 (Must-Have)**:
- Example dataset
- R CMD check passes
- Basic tests (current 3 files)
- 1 vignette (intro - already exists)

**Priority 2 (Should-Have)**:
- Technical vignette
- Expanded tests (>50% coverage)

**Priority 3 (Nice-to-Have)**:
- R3STEP vignette
- Mplus validation vignette
- >80% test coverage

### If CRAN Rejects

**Common Rejection Reasons**:
1. **Examples too slow**: Add `\donttest{}`, reduce iterations
2. **NOTES about dependencies**: Move to Suggests if optional
3. **Documentation issues**: Fix quickly and resubmit
4. **Failing tests on some platforms**: Use conditional testing

**Response Strategy**:
- Read feedback carefully
- Fix within 1 week
- Reply professionally
- Resubmit promptly

---

## DAILY CHECKLIST TEMPLATE

Use this template for daily accountability:

```markdown
## Date: ____/____/2025

### Goals Today
- [ ]
- [ ]
- [ ]

### Completed
- [ ]
- [ ]

### Blockers
-

### Tomorrow
- [ ]
- [ ]

### Notes
```

---

## SUCCESS CRITERIA

At the end of 6 weeks, you should have:

✅ **Technical Excellence**
- R CMD check passes completely
- >80% test coverage
- All examples work

✅ **Documentation Quality**
- 4 vignettes (intro + 3 new)
- All functions documented
- pkgdown site live

✅ **CRAN Readiness**
- Package builds cleanly
- cran-comments.md prepared
- Ready to submit

✅ **Confidence**
- Validated against Mplus
- Tested on multiple platforms
- Proud to release

---

## RESOURCES

### CRAN Guidelines
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html)
- [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html)

### Testing
- [testthat documentation](https://testthat.r-lib.org/)
- [covr package](https://covr.r-lib.org/)

### Documentation
- [roxygen2](https://roxygen2.r-lib.org/)
- [pkgdown](https://pkgdown.r-lib.org/)

### Helpful Packages
```r
install.packages(c(
  "devtools",
  "usethis",
  "testthat",
  "covr",
  "pkgdown",
  "urlchecker",
  "spelling"
))
```

---

## MOTIVATION

Remember: **surveymixr solves a real problem** that thousands of researchers face. Every day without this package on CRAN, researchers are:
- Paying for Mplus licenses ($$$)
- Struggling with proprietary software
- Unable to reproduce analyses
- Missing out on R's ecosystem

**Your work matters. Let's ship it! 🚀**

---

**Next Action**: Create the example dataset (2-3 hours)

```r
# Navigate to data-raw directory and run:
source("data-raw/create-mcs-simulated.R")

# Verify:
load("data/mcs_simulated.rda")
str(mcs_simulated)
```
