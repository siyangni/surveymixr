# Week 1 Setup Instructions - Run Locally

Since R is not available in the remote environment, you'll need to run these tasks **on your local machine** where R is installed.

---

## Prerequisites

Make sure you have R installed (version ≥ 4.0.0) and the following packages:

```r
install.packages(c(
  "devtools",
  "usethis",
  "testthat",
  "roxygen2",
  "urlchecker",
  "spelling",
  "covr",
  "knitr",
  "rmarkdown"
))
```

---

## Quick Start: Automated Script

The easiest way to complete Week 1 tasks is to run the automated setup script:

### Step 1: Clone or Navigate to Package

```bash
cd /path/to/surveymixr
```

### Step 2: Run Setup Script

```r
# From R console in package root directory
source("scripts/week1-setup.R")
```

This script will:
- ✓ Create the `mcs_simulated` example dataset
- ✓ Run R CMD check and save results
- ✓ Run spell check and identify errors
- ✓ Validate all URLs
- ✓ Calculate test coverage
- ✓ Check for undocumented functions

**Output files** (in `scripts/` directory):
- `check-results.txt` - Full R CMD check output
- `spelling-errors.csv` - Spelling issues to fix
- `url-issues.csv` - Invalid URLs to fix
- `coverage-report.html` - Test coverage details

---

## Manual Approach: Step-by-Step

If you prefer to run tasks individually:

### Task 1: Create Example Dataset (~5 minutes)

```r
# Navigate to package root
setwd("path/to/surveymixr")

# Run dataset creation script
source("data-raw/create-mcs-simulated.R")

# Verify dataset created
load("data/mcs_simulated.rda")
str(mcs_simulated)
```

**Expected output**:
- File: `data/mcs_simulated.rda`
- ~5,000 individuals, ~30,000 observations

---

### Task 2: Run R CMD Check (~10-15 minutes)

```r
library(devtools)

# Run comprehensive check
check_results <- check(
  document = TRUE,
  args = c("--no-manual", "--as-cran")
)

# Review results
print(check_results)
```

**Expected**: 0 errors, 0 warnings, minimal notes

**Action**: Document any issues found

---

### Task 3: Spell Check (~5 minutes)

```r
library(spelling)

# Check spelling
spelling_errors <- devtools::spell_check()

# Review errors
print(spelling_errors)

# If legitimate technical terms, add to WORDLIST
# spelling::update_wordlist()
```

**Action**: Fix spelling errors or add technical terms to wordlist

---

### Task 4: URL Validation (~2 minutes)

```r
library(urlchecker)

# Check all URLs in documentation
url_issues <- url_check()

# Review issues
print(url_issues)
```

**Action**: Fix broken links, update URLs

---

### Task 5: Test Coverage Analysis (~10 minutes)

```r
library(covr)

# Calculate coverage
coverage <- package_coverage()

# View summary
print(coverage)

# Generate detailed HTML report
report(coverage, file = "scripts/coverage-report.html")

# Get percentage
percent_coverage(coverage)
```

**Target**: >80% coverage

**Action**: Add tests where coverage is low (see new test files in `tests/testthat/`)

---

### Task 6: Documentation Completeness

```r
# Check for undocumented exports
library(roxygen2)

# List exported functions
exports <- parseNamespaceFile(
  basename(getwd()),
  dirname(getwd())
)$exports

# List documented topics
man_files <- list.files("man", pattern = "\\.Rd$")
documented <- gsub("\\.Rd$", "", man_files)

# Find undocumented
undocumented <- setdiff(exports, documented)
print(undocumented)
```

**Action**: Document any missing exports

---

## New Test Files Added

Three new comprehensive test files have been created in `tests/testthat/`:

### 1. `test-growth-models.R`
Tests for different growth model specifications:
- Linear growth
- Quadratic growth
- Free basis growth
- Nonlinear growth
- Models with covariates
- Model comparisons

### 2. `test-survey-designs.R`
Tests for complex survey designs:
- Simple random sampling (SRS)
- Stratified sampling
- Cluster sampling
- Stratified cluster sampling
- Nested designs
- Probability weighting
- Design effect on standard errors

### 3. `test-model-selection.R`
Tests for model selection procedures:
- `gmm_select()` functionality
- BLRT implementation
- Information criteria (AIC, BIC, aBIC)
- Entropy calculations
- Model comparison plots
- Parallel processing

**To run these tests**:

```r
library(testthat)

# Run all tests
devtools::test()

# Run specific file
test_file("tests/testthat/test-growth-models.R")
test_file("tests/testthat/test-survey-designs.R")
test_file("tests/testthat/test-model-selection.R")
```

---

## Vignette Template Created

A template for the technical details vignette has been created at:
`vignettes/technical-details.Rmd`

**Sections included**:
- Statistical framework
- EM algorithm details
- Standard error computation
- BLRT implementation
- Model fit indices
- Computational efficiency

**To build vignette**:

```r
devtools::build_vignettes()

# Or build entire package with vignettes
devtools::build(vignettes = TRUE)
```

**Action**: Fill in any remaining content, add examples, polish mathematical notation

---

## Expected Timeline

| Task | Time | Priority |
|------|------|----------|
| Create dataset | 5 min | HIGH |
| R CMD check | 15 min | HIGH |
| Fix check issues | 1-3 hours | HIGH |
| Spell check | 5 min | MEDIUM |
| URL check | 2 min | MEDIUM |
| Test coverage | 10 min | MEDIUM |
| Add new tests | 2-4 hours | HIGH |
| Complete vignette | 3-5 hours | MEDIUM |

**Total estimated time**: 8-15 hours over Week 1

---

## Troubleshooting

### Error: Package won't load

```r
# Rebuild documentation
devtools::document()

# Clean and reload
devtools::clean_vignettes()
devtools::load_all()
```

### Error: Dataset creation fails

Check that `simulate_gmm_survey()` function works:

```r
# Test simulation function
test_data <- simulate_gmm_survey(
  n_individuals = 100,
  n_times = 3,
  n_classes = 2,
  design = "SRS"
)
str(test_data)
```

### Error: Tests fail

Run tests individually to identify issues:

```r
# Load package
devtools::load_all()

# Run one test at a time
testthat::test_file("tests/testthat/test-basic-estimation.R")
```

### R CMD check takes too long

Reduce example run times:

- Add `\donttest{}` around slow examples
- Reduce `starts` parameter to 10-50 in examples
- Use smaller simulated datasets

---

## Next Steps After Week 1

Once all Week 1 tasks are complete:

1. **Week 2**: Expand test coverage
   - Add remaining test files
   - Target >80% coverage
   - Test edge cases

2. **Week 3**: Complete vignettes
   - Technical details vignette
   - R3STEP vignette
   - Mplus validation vignette

3. **Week 4**: Platform testing
   - Test on Windows, macOS, Linux
   - Fix platform-specific issues
   - Optimize performance

4. **Week 5**: Documentation polish
   - Update README
   - Create CITATION file
   - Enhance function documentation

5. **Week 6**: Final checks & submission
   - Run final R CMD check
   - Create `cran-comments.md`
   - Submit to CRAN!

---

## Getting Help

If you encounter issues:

1. Check the package documentation: `?function_name`
2. Review existing tests for examples
3. Consult [R Packages book](https://r-pkgs.org/)
4. Check [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html)
5. Ask for help (provide error messages and context)

---

## Quick Reference Commands

```r
# Essential development commands
devtools::load_all()          # Load package for testing
devtools::document()          # Update documentation
devtools::test()              # Run all tests
devtools::check()             # Run R CMD check
devtools::build()             # Build package tarball
devtools::install()           # Install package locally

# Coverage and quality
covr::package_coverage()      # Test coverage
devtools::spell_check()       # Spelling
urlchecker::url_check()       # URLs

# Vignettes
devtools::build_vignettes()   # Build vignettes
browseVignettes("surveymixr") # View vignettes
```

---

## Success Criteria for Week 1

At the end of Week 1, you should have:

- [x] `data/mcs_simulated.rda` created
- [x] R CMD check passing (or documented issues)
- [x] All spelling errors fixed
- [x] All URLs valid
- [x] Test coverage calculated (baseline established)
- [x] New test files reviewed and ready to expand
- [x] Vignette template ready to complete

**Ready for Week 2**: Expanding test coverage to >80%

---

**Questions?** Refer to ACTION-PLAN-PHASE1.md for detailed week-by-week tasks.

**Good luck! 🚀**
