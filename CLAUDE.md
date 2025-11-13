# CLAUDE.md - AI Assistant Guide for surveymixr

This document provides comprehensive guidance for AI assistants working on the surveymixr R package. It covers codebase structure, development workflows, conventions, and best practices.

## Package Overview

**surveymixr** is an R package implementing growth mixture modeling (GMM) for longitudinal data with full integration of complex survey design features. It fills a critical gap by enabling rigorous analyses of large-scale longitudinal surveys (e.g., Millennium Cohort Study, Add Health, NLSY) that were previously only possible in proprietary software like Mplus.

- **Language**: R (>= 4.0.0)
- **License**: GPL (>= 3)
- **Current Version**: 0.2.0 (development)
- **Lines of Code**: ~9,358 lines across 20 R files
- **Documentation**: pkgdown website at https://siyangni.github.io/surveymixr/

## Repository Structure

```
surveymixr/
├── R/                          # Source code (20 files, ~9,358 lines)
│   ├── class-definitions.R     # S4 class definitions
│   ├── core-em-algorithm.R     # EM algorithm implementation
│   ├── gmm-survey.R           # Main estimation functions
│   ├── outcome-types.R        # Binary, ordinal, count outcomes
│   ├── random-effects.R       # Random effects in growth models
│   ├── r3step.R               # R3STEP auxiliary variable analysis
│   ├── diagnostics*.R         # Model diagnostics
│   ├── plotting*.R            # Visualization functions
│   ├── lmr-test.R            # Lo-Mendell-Rubin test
│   ├── cross-validation.R     # K-fold CV for model selection
│   ├── gmm-select.R          # Model selection wrapper
│   ├── simulate.R            # Data simulation
│   ├── data-validation.R     # Pre-analysis validation
│   └── methods.R             # S4 and S3 methods
│
├── tests/testthat/            # Comprehensive test suite (14 files)
│   ├── test-basic-estimation.R
│   ├── test-categorical-outcomes.R
│   ├── test-comprehensive.R
│   ├── test-convergence.R
│   ├── test-data-validation.R
│   ├── test-diagnostics.R
│   ├── test-edge-cases.R
│   └── ...
│
├── vignettes/                 # Long-form documentation (8 files)
│   ├── user-manual.Rmd       # Comprehensive user guide (primary)
│   ├── surveymixr-intro.Rmd  # Quick introduction
│   ├── technical-details.Rmd  # Algorithms and methods
│   ├── r3step-analysis.Rmd   # R3STEP methodology
│   ├── categorical-outcomes.Rmd
│   ├── model-selection-enhanced.Rmd
│   └── mplus-validation.Rmd
│
├── man/                       # Generated documentation (roxygen2)
├── data/                      # Included datasets (mcs_simulated)
├── data-raw/                  # Data generation scripts
├── inst/                      # Installed files
├── scripts/                   # Development scripts
├── paper/                     # Research paper materials
├── archives/                  # Archived development docs
├── docs/                      # pkgdown generated website
│
├── .github/workflows/         # CI/CD automation
│   ├── R-CMD-check.yaml      # Multi-platform R CMD check
│   ├── test-coverage.yaml    # Code coverage with codecov
│   └── pkgdown.yaml          # Auto-deploy documentation
│
├── DESCRIPTION               # Package metadata and dependencies
├── NAMESPACE                 # Exported functions (auto-generated)
├── _pkgdown.yml             # Documentation website config
├── README.md                # GitHub landing page
├── NEWS.md                  # Version history and changes
├── CONTRIBUTING.md          # Contribution guidelines
├── CODE_OF_CONDUCT.md       # Community standards
├── cran-comments.md         # CRAN submission notes
└── .Rbuildignore            # Files excluded from build
```

## Core Architecture

### S4 Object-Oriented Design

The package uses S4 classes for robust, validated data structures:

**Main Result Classes:**
- `SurveyMixr`: Base class for GMM results (continuous outcomes)
- `SurveyMixrRE`: Random effects extensions
- `SurveyMixrTVC`: Time-varying covariate models
- `SurveyMixrSelect`: Model selection results

**Diagnostic Classes:**
- `ConvergenceDiagnostics`: Tracking random starts and convergence
- `InfluenceDiagnostics`: Survey-weighted influence detection
- `DataValidation`: Pre-analysis data quality checks
- `R3StepResults`: Auxiliary variable analysis results

All S4 classes include:
- Slot definitions with type validation
- Validity checking methods
- Show/print methods for user-friendly output
- Proper inheritance relationships

### Key Functions by Category

**Core Estimation** (R/gmm-survey.R, R/outcome-types.R):
- `gmm_survey()`: Main function for continuous outcomes
- `gmm_survey_binary()`: Binary outcomes (0/1)
- `gmm_survey_ordinal()`: Ordinal outcomes
- `gmm_survey_count()`: Count outcomes (Poisson, NB, ZIP)
- `gmm_survey_re()`: Random effects in growth parameters
- `gmm_survey_tvc()`: Time-varying covariates

**Model Selection** (R/gmm-select.R, R/lmr-test.R, R/cross-validation.R):
- `gmm_select()`: Wrapper for comparing multiple models
- `lmr_test()` / `lmr_sequential()`: Lo-Mendell-Rubin test
- `gmm_cv()`: K-fold cross-validation with survey weights

**Diagnostics** (R/diagnostics.R, R/diagnostics-advanced.R):
- `diagnose_convergence()`: Convergence quality assessment
- `diagnose_influence()`: Influential case detection
- `diagnose_separation()`: Class separation issues
- `residual_diagnostics()`: Residual analysis
- `classification_quality()`: Entropy, class proportions

**R3STEP Method** (R/r3step.R):
- `r3step()`: Auxiliary variable analysis with classification uncertainty correction
- Supports BCH, ML, and manual approaches

**Visualization** (R/plotting.R, R/plotting-interactive.R):
- `plot()`: Generic S4 method with multiple types
- `plot_trajectories()`: Class-specific growth curves
- `plot_interactive()`: Plotly-based interactive plots
- `plot_model_selection()`: Compare fit indices
- `plot_class_comparison()`: Side-by-side comparisons

**Data Preparation** (R/data-validation.R):
- `validate_survey_data()`: Comprehensive pre-analysis checks
- `wide_to_long()`: Data restructuring

**Simulation** (R/simulate.R):
- `simulate_gmm_survey()`: Generate test data
- Used extensively in tests and examples

### EM Algorithm Implementation

The core estimation uses an Expectation-Maximization (EM) algorithm (R/core-em-algorithm.R):

1. **E-step**: Calculate posterior class probabilities
2. **M-step**: Update parameters (growth curves, mixing proportions)
3. **Survey weights**: Integrated throughout estimation
4. **Standard errors**: Sandwich estimator for complex surveys
5. **Multiple random starts**: 500-1000+ starts to avoid local maxima
6. **Convergence**: Tracked via log-likelihood changes and parameter stability

## Development Workflows

### Standard R Package Development

Follow standard R package development practices:

```r
# Load package for interactive development
devtools::load_all()

# Generate documentation from roxygen2 comments
devtools::document()

# Run all tests
devtools::test()

# Run R CMD check (must pass with 0 errors, 0 warnings, 0 notes)
devtools::check()

# Check code coverage
covr::package_coverage()

# Build documentation website
pkgdown::build_site()
```

### Git Workflow

1. **Branch naming**: Use descriptive feature branches
   - Current branch: `claude/claude-md-mhxvvqs5bteavt45-01KuELGYFuU9u9aN6viENFh2`
   - Pattern: `feature/description` or `fix/issue-name`

2. **Commit messages**: Follow conventional commits style
   ```
   Add entropy calculation with multiple methods

   - Implemented standard, relative, and normalized entropy
   - Added comprehensive tests with edge cases
   - Updated documentation with examples
   - Closes #123
   ```

3. **Pull requests**: See CONTRIBUTING.md for PR template and requirements

4. **CI/CD**: GitHub Actions automatically run on push/PR:
   - R CMD check on multiple platforms (Ubuntu, macOS, Windows)
   - Multiple R versions (devel, release, oldrel-1)
   - Code coverage reporting to codecov.io
   - Automatic pkgdown deployment to GitHub Pages

### Testing Strategy

**Comprehensive test coverage** in tests/testthat/:

```r
# Test file naming: test-{feature}.R
# Example: test-basic-estimation.R

test_that("entropy is 0 for perfect classification", {
  probs <- matrix(c(1, 0, 0, 0, 1, 0), ncol = 3, byrow = TRUE)
  expect_equal(calculate_entropy(probs), 0)
})
```

**Coverage targets**:
- Aim for >80% code coverage
- Test edge cases, error conditions, and parameter validation
- Use descriptive test names
- Include integration tests for main workflows

**Key test files**:
- `test-basic-estimation.R`: Core GMM functionality
- `test-categorical-outcomes.R`: Binary, ordinal, count models
- `test-convergence.R`: EM algorithm and random starts
- `test-edge-cases.R`: Boundary conditions and unusual inputs
- `test-comprehensive.R`: Full integration tests

### Documentation Standards

**roxygen2 documentation** is mandatory for all exported functions:

```r
#' Calculate Classification Entropy
#'
#' Computes the entropy of posterior class membership probabilities.
#' Higher values indicate greater classification uncertainty.
#'
#' @param posterior_probs Numeric matrix of posterior probabilities
#'   (rows = individuals, columns = classes)
#' @param method Character string specifying entropy calculation method.
#'   Options: "standard" (default), "relative", "normalized"
#'
#' @return Numeric value representing entropy. For "standard" method,
#'   ranges from 0 (perfect classification) to log(K) where K is the
#'   number of classes.
#'
#' @details
#' The entropy measure quantifies classification uncertainty. Perfect
#' classification (all posterior probabilities = 0 or 1) yields entropy = 0.
#' Maximum uncertainty (equal probabilities across classes) yields entropy = log(K).
#'
#' @examples
#' # Perfect classification (low entropy)
#' probs1 <- matrix(c(1, 0, 0, 0, 1, 0), ncol = 3, byrow = TRUE)
#' calculate_entropy(probs1)  # Returns 0
#'
#' # Uncertain classification (high entropy)
#' probs2 <- matrix(c(0.33, 0.33, 0.34), ncol = 3)
#' calculate_entropy(probs2)  # Returns ~1.099 (close to log(3))
#'
#' @export
#' @seealso \code{\link{classification_quality}} for related diagnostics
```

**Key documentation elements**:
- Clear, concise title
- Detailed description of what the function does
- `@param` for every parameter with type and valid values
- `@return` describing output structure and content
- `@details` for algorithm details, mathematical formulas
- `@examples` with working, meaningful examples
- `@export` for user-facing functions
- `@seealso` for related functions
- Cross-references to other documentation

**Vignettes** (vignettes/):
- **user-manual.Rmd**: Comprehensive guide (primary documentation)
- Other vignettes cover specialized topics
- Use real examples with the included `mcs_simulated` dataset
- Include code, output, and plots
- Explain both "how" and "why"

### Code Style

Follow the [tidyverse style guide](https://style.tidyverse.org/):

**Naming conventions**:
- Functions: `snake_case` (e.g., `calculate_entropy`, `gmm_survey`)
- Variables: `snake_case` (e.g., `posterior_probs`, `n_classes`)
- Classes: `PascalCase` (e.g., `SurveyMixr`, `InfluenceDiagnostics`)
- Constants: `UPPER_SNAKE_CASE` (rare in R)

**Code organization**:
- Keep functions focused (single responsibility principle)
- Use meaningful variable names (avoid `x`, `tmp`, `data1`)
- Comment complex algorithms and non-obvious code
- Limit line length to 80 characters
- Use spaces around operators (`x + y`, not `x+y`)
- Indent with 2 spaces (not tabs)

**Good example**:
```r
calculate_entropy <- function(posterior_probs, method = "standard") {
  # Validate input
  if (!is.matrix(posterior_probs)) {
    stop("posterior_probs must be a matrix")
  }

  # Calculate standard entropy
  # Avoid log(0) by adding small constant
  log_probs <- log(posterior_probs + 1e-10)
  entropy <- -sum(posterior_probs * log_probs, na.rm = TRUE)

  # Apply method-specific adjustments
  if (method == "normalized") {
    n_classes <- ncol(posterior_probs)
    max_entropy <- log(n_classes)
    entropy <- entropy / max_entropy
  }

  return(entropy)
}
```

**Bad example** (avoid):
```r
calc_e <- function(pp, m = "s") {
  lp <- log(pp + 1e-10)
  e <- -sum(pp * lp, na.rm = T)
  if (m == "n") e <- e / log(ncol(pp))
  return(e)
}
```

## Key Conventions and Patterns

### Survey Design Integration

**Always respect survey design features**:

1. **Stratification** (`strata` parameter):
   - Defines sampling strata
   - Used in standard error calculation

2. **Clustering** (`cluster` parameter):
   - Defines primary sampling units (PSUs)
   - Accounts for intra-cluster correlation

3. **Probability weights** (`weights` parameter):
   - Sampling weights for representative estimates
   - Used in M-step of EM algorithm
   - Normalized internally

**Implementation pattern**:
```r
gmm_survey(
  data = my_data,
  id = "person_id",
  time = "wave",
  outcome = "depression",
  n_classes = 3,
  strata = "stratum",      # Stratification variable
  cluster = "psu",         # Primary sampling unit
  weights = "weight",      # Sampling weights
  starts = 500,
  cores = 4
)
```

### Parallelization

**Bootstrap and random starts use parallel processing**:
- `cores` parameter: Number of CPU cores to use
- Uses `parallel` and `doParallel` packages
- Default: `detectCores() - 1`
- Set to 1 for sequential execution (debugging)

**Example**:
```r
# Use 4 cores for parallel BLRT
selection <- gmm_select(
  data = data,
  classes = 1:5,
  blrt_samples = 100,
  cores = 4  # Parallel processing
)
```

### Random Starts Strategy

**Critical for avoiding local maxima**:
- Default: 500 starts for production, 200 for model selection
- More complex models need more starts (1000+)
- Track best log-likelihood across all starts
- Store convergence info for all starts
- Warn if multiple local maxima found

**Convergence diagnostics**:
```r
fit <- gmm_survey(..., starts = 500)
diagnose_convergence(fit)
# Shows: best LL, # local maxima, parameter stability
```

### Handling Missing Data

**Current approach**:
- Listwise deletion (complete case analysis)
- Future: Multiple imputation and FIML

**Best practices**:
- Check missing patterns with `validate_survey_data()`
- Document missing data handling in analysis
- Consider sensitivity analyses

### Outcome Type Validation

**Different outcome types require different models**:

```r
# Automatic validation
validate_outcome_type(outcome_var, type = "continuous")
validate_outcome_type(outcome_var, type = "binary")     # 0/1 only
validate_outcome_type(outcome_var, type = "ordinal")    # Ordered categories
validate_outcome_type(outcome_var, type = "count")      # Non-negative integers
```

**Link functions**:
- Binary: probit (default) or logit
- Ordinal: cumulative logit (proportional odds)
- Count: log (Poisson, negative binomial)

## Common Tasks and How-Tos

### Adding a New Function

1. **Write the function** in appropriate R/ file:
   ```r
   #' Function Title
   #'
   #' @param x Description
   #' @return Description
   #' @export
   my_new_function <- function(x) {
     # Implementation
   }
   ```

2. **Add tests** in tests/testthat/:
   ```r
   # tests/testthat/test-my-feature.R
   test_that("my_new_function works correctly", {
     result <- my_new_function(input)
     expect_equal(result, expected)
   })
   ```

3. **Generate documentation**:
   ```r
   devtools::document()  # Updates NAMESPACE and man/
   ```

4. **Run checks**:
   ```r
   devtools::test()
   devtools::check()
   ```

5. **Update NEWS.md** with changes

### Modifying Core EM Algorithm

**Location**: R/core-em-algorithm.R

**Critical considerations**:
- Maintain backward compatibility
- Update tests extensively
- Validate against Mplus results
- Document algorithmic changes in vignettes/technical-details.Rmd
- Profile performance for large datasets

**Testing checklist**:
- [ ] Basic estimation still works
- [ ] Survey weights properly integrated
- [ ] Convergence diagnostics accurate
- [ ] Standard errors correct
- [ ] Multiple random starts stable
- [ ] Matches Mplus output (if applicable)

### Adding a New Outcome Type

1. **Create estimation function** in R/outcome-types.R:
   ```r
   gmm_survey_newtype <- function(...) {
     # Validate outcome
     # Implement link function
     # Call core EM with appropriate likelihood
   }
   ```

2. **Add validation** in R/data-validation.R:
   ```r
   validate_outcome_type(..., type = "newtype")
   ```

3. **Write comprehensive tests** in tests/testthat/test-categorical-outcomes.R

4. **Document** with examples and add vignette if complex

5. **Update** _pkgdown.yml to include in documentation structure

### Updating Documentation Website

**Automatic deployment**: Pushing to main triggers GitHub Action

**Manual build**:
```r
pkgdown::build_site()
# Check docs/ directory locally
# Push to deploy
```

**Configuration**: Edit _pkgdown.yml for structure changes

### Running CRAN Checks

**Before CRAN submission**:

```r
# Local check
devtools::check()  # Must pass with 0 errors, 0 warnings, 0 notes

# Check on multiple platforms (GitHub Actions)
# Ensure all platforms pass

# Check reverse dependencies
devtools::revdep_check()  # If package has dependents

# Spell check
spelling::spell_check_package()

# Update cran-comments.md with test results
```

**Common issues**:
- Undocumented exported functions → Add roxygen2 docs
- Long-running examples → Use `\donttest{}` or `\dontrun{}`
- Large package size → Check for unnecessary files
- License compatibility → Ensure GPL-compatible dependencies

## Troubleshooting Common Issues

### EM Algorithm Convergence Issues

**Symptom**: Model doesn't converge or finds local maxima

**Solutions**:
1. Increase random starts: `starts = 1000`
2. Increase iteration limit: `maxit = 1000`
3. Check for class separation: `diagnose_separation(fit)`
4. Simplify model (reduce classes or covariates)
5. Check data quality: `validate_survey_data(data)`
6. Try different starting values strategy

### Standard Error Calculation Problems

**Symptom**: NA or unreasonably large standard errors

**Solutions**:
1. Check survey design specification (strata, cluster, weights)
2. Verify cluster nesting: strata must nest clusters
3. Increase sample size (may be too small for complex design)
4. Check for model misspecification
5. Use `diagnose_influence()` to find problematic cases

### Test Failures

**Symptom**: `devtools::test()` fails

**Debug process**:
```r
# Run specific test file
testthat::test_file("tests/testthat/test-basic-estimation.R")

# Run single test
testthat::test_that("specific test name", {
  # Copy test code here
})

# Check for environment issues
devtools::load_all()  # Reload package
rm(list = ls())       # Clear environment
```

**Common causes**:
- Outdated test expectations (update after intentional changes)
- Platform-specific differences (numeric precision)
- Random seed issues (set seed in tests)
- Missing test dependencies (add to DESCRIPTION Suggests)

### R CMD Check Warnings/Notes

**Common issues and fixes**:

1. **"no visible binding for global variable"**:
   - Solution: Use `.data$var` or declare globals with `utils::globalVariables()`

2. **"Undocumented code objects"**:
   - Solution: Add roxygen2 documentation or don't export

3. **"Examples take too long"**:
   - Solution: Wrap in `\donttest{}` or reduce complexity

4. **"Non-standard file/directory found"**:
   - Solution: Add to .Rbuildignore

### Memory Issues with Large Datasets

**Symptoms**: R crashes or runs out of memory

**Solutions**:
1. Use `store_data = FALSE` to avoid storing full dataset
2. Reduce number of random starts
3. Use sequential processing (`cores = 1`) for lower memory footprint
4. Profile memory usage: `profmem::profmem()`
5. Consider data subsetting for initial exploration

## Package Dependencies

### Imports (Required)

From DESCRIPTION:
```
stats       # Core statistical functions
methods     # S4 class system
MASS        # mvrnorm, robust statistics
numDeriv    # Numerical derivatives for SEs
ggplot2     # Plotting
parallel    # Parallel processing
doParallel  # Parallel backend
```

### Suggests (Optional)

```
knitr       # Vignette building
rmarkdown   # Vignette rendering
testthat    # Testing framework
covr        # Code coverage
plotly      # Interactive plots
htmlwidgets # Interactive widget export
patchwork   # Combining ggplot2 plots
scales      # Scale functions for plotting
```

**Dependency policy**:
- Minimize new dependencies (CRAN preference)
- Prefer base R when feasible
- Document why each dependency is needed
- Use Suggests for optional features

## Performance Considerations

### Computational Bottlenecks

1. **EM iterations**: Most time-consuming part
   - Profile with `Rprof()` or `profvis::profvis()`
   - Consider Rcpp for critical loops (future)

2. **Random starts**: Scales linearly with `starts` parameter
   - Use parallelization: `cores = detectCores() - 1`
   - Balance between thorough search and computation time

3. **Bootstrap tests**: BLRT requires fitting many models
   - Consider LMR test as faster alternative
   - Use fewer `blrt_samples` for initial exploration

### Memory Usage

- Posterior probability matrix: N × K (can be large)
- Survey design objects: Store cluster/strata info
- Random starts: Store results for diagnostics
- Use `store_data = FALSE` when memory constrained

### Optimization Strategies

```r
# Fast exploration (fewer starts, faster criteria)
gmm_select(
  classes = 1:5,
  starts = 100,      # Fewer starts
  criteria = "BIC",  # Skip slow BLRT
  cores = 8
)

# Production analysis (thorough)
gmm_select(
  classes = 1:5,
  starts = 500,
  criteria = c("BIC", "BLRT", "entropy"),
  blrt_samples = 100,
  cores = 8
)
```

## Security and Safety

### User Input Validation

**Always validate user inputs**:

```r
my_function <- function(data, n_classes, ...) {
  # Type checking
  if (!is.data.frame(data)) {
    stop("data must be a data.frame")
  }

  # Range checking
  if (n_classes < 1 || n_classes > 20) {
    stop("n_classes must be between 1 and 20")
  }

  # Required columns
  if (!all(c("id", "time", "outcome") %in% names(data))) {
    stop("data must contain id, time, and outcome columns")
  }

  # Proceed with validated inputs
}
```

### Data Privacy

- **Never log or display sensitive data** in error messages or warnings
- Use generic identifiers in examples
- Simulated data only for package datasets

### Reproducibility

**Set seeds for random operations**:
```r
# In functions with random components
if (!is.null(seed)) {
  set.seed(seed)
}

# In tests
set.seed(123)
test_that("random function is reproducible", {
  result1 <- random_function(seed = 123)
  result2 <- random_function(seed = 123)
  expect_equal(result1, result2)
})
```

## Future Development Roadmap

Based on NEWS.md and CONTRIBUTING.md:

### Phase 2 (v0.2.0-0.5.0) - Feature Completeness

- [x] Categorical outcomes (binary, ordinal, count)
- [x] Enhanced model selection (LMR, CV)
- [x] Advanced diagnostics (influence, separation, residuals)
- [x] Data validation framework
- [x] Interactive visualization
- [ ] Random effects (partial implementation, needs expansion)
- [ ] Time-varying covariates (partial implementation)

### Phase 3 (v0.6.0+) - Advanced Methods

- [ ] Multilevel mixture models
- [ ] Bayesian estimation
- [ ] Causal inference integration
- [ ] Machine learning methods (ensemble approaches)
- [ ] Multiple imputation for missing data
- [ ] FIML estimation

### Infrastructure

- [ ] Rcpp implementation for speed
- [ ] Parallel backend improvements
- [ ] Memory optimization
- [ ] Extended Mplus compatibility

## Resources and References

### R Package Development

- [R Packages book](https://r-pkgs.org/) by Hadley Wickham & Jenny Bryan
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/R-exts.html) (CRAN official)
- [Tidyverse style guide](https://style.tidyverse.org/)
- [roxygen2 documentation](https://roxygen2.r-lib.org/)
- [testthat documentation](https://testthat.r-lib.org/)

### Growth Mixture Modeling

- Muthén & Muthén (2017): Mplus User's Guide
- Asparouhov & Muthén (2014): [Auxiliary Variables in Mixture Modeling](https://doi.org/10.1080/10705511.2014.915181)
- Vermunt (2010): [Latent Class Modeling with Covariates](https://doi.org/10.1111/j.1467-985X.2009.00626.x)

### Complex Survey Design

- Lumley (2010): Complex Surveys: A Guide to Analysis Using R
- survey package documentation

### Package-Specific Documentation

- **User Manual**: https://siyangni.github.io/surveymixr/articles/user-manual.html (PRIMARY)
- **Technical Details**: https://siyangni.github.io/surveymixr/articles/technical-details.html
- **Function Reference**: https://siyangni.github.io/surveymixr/reference/index.html
- **GitHub Repository**: https://github.com/siyangni/surveymixr
- **Issue Tracker**: https://github.com/siyangni/surveymixr/issues

## Contact and Support

- **Maintainer**: Siyang Ni <johnni.nj@gmail.com>
- **Bug Reports**: Open issue at https://github.com/siyangni/surveymixr/issues
- **Contributing**: See CONTRIBUTING.md
- **Code of Conduct**: See CODE_OF_CONDUCT.md

## Final Notes for AI Assistants

### Key Principles

1. **Maintain R package standards**: This is a CRAN-bound package requiring strict adherence to R packaging conventions

2. **Comprehensive testing**: All changes need corresponding tests with >80% coverage target

3. **Documentation is critical**: Incomplete documentation blocks CRAN submission

4. **Backward compatibility**: Avoid breaking changes; deprecate properly if needed

5. **Survey design integrity**: Never compromise survey design features; they are the package's core value proposition

6. **Scientific rigor**: This is methodological software - correctness trumps convenience

### Before Making Changes

- [ ] Read relevant section of this CLAUDE.md
- [ ] Check existing code patterns in similar functions
- [ ] Review CONTRIBUTING.md guidelines
- [ ] Understand the statistical/methodological implications
- [ ] Plan tests before implementation

### After Making Changes

- [ ] Write/update roxygen2 documentation
- [ ] Add/update tests
- [ ] Run `devtools::document()`
- [ ] Run `devtools::test()`
- [ ] Run `devtools::check()` (must pass cleanly)
- [ ] Update NEWS.md
- [ ] Update vignettes if needed
- [ ] Check code coverage: `covr::package_coverage()`

### When Stuck

1. Check existing implementations of similar features
2. Review technical-details.Rmd vignette for algorithms
3. Consult R Packages book for package development questions
4. Check GitHub issues for related discussions
5. Review Mplus documentation for methodological questions

### Communication Style

When working with users:
- Be precise about statistical concepts
- Explain "why" not just "how"
- Provide reproducible examples
- Reference documentation locations
- Acknowledge limitations honestly

---

**Document Version**: 1.0
**Last Updated**: 2025-11-13
**Next Review**: When major package changes occur

This document is maintained to help AI assistants effectively contribute to surveymixr development while maintaining the package's high standards for code quality, documentation, and scientific rigor.
