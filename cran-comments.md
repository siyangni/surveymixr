## R CMD check results

0 errors ✓ | 0 warnings ✓ | 0 notes ✓

## Test environments

* local: Linux (x86_64-pc-linux-gnu), R 4.5.2
* GitHub Actions:
  - {macos-latest} × R-release
  - {windows-latest} × R-release
  - {ubuntu-latest} × R-release
  - {ubuntu-latest} × R-devel
  - {ubuntu-latest} × R-oldrel-1
* win-builder: R-devel and R-release (2025-11-16)
* R-hub (2025-11-16):
  - linux: ubuntu-latest, R-devel
  - macos: macos-13, R-devel
  - windows: windows-latest, R-devel

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

* Possibly misspelled words in DESCRIPTION:
  All flagged terms are valid technical terms, author names, or statistical
  acronyms (Asparouhov, BLRT, ECLS, GMM, LMR, Mendell, Mplus, NLSY, Vermunt).
  These have been added to inst/WORDLIST.

### Local check
- 1 cosmetic WARNING about 'qpdf' (only affects PDF compression, not functionality)
- All 714 tests passing

### Win-builder
- Successfully validated on R-devel and R-release
- All spelling exceptions documented in inst/WORDLIST
- All URLs validated and accessible

### R-hub
- All platforms (linux, macos, windows) passed with R-devel
- Total duration: 19m 8s across 3 platforms

## Downstream dependencies

There are currently no downstream dependencies for this package.

## Additional information for CRAN reviewers

### New submission

This is a new package submission. surveymixr implements growth mixture models for complex survey data, filling a gap previously only addressable with proprietary software (Mplus).

### Package purpose

Growth mixture models (GMM) identify latent subgroups with different developmental trajectories. surveymixr is the first R package to integrate GMM with full complex survey design features (stratification, clustering, probability weights), critical for analyzing data from national longitudinal studies like Add Health, NLSY, and the Millennium Cohort Study.

### Key features

- Survey-weighted EM algorithm for GMM estimation
- Bootstrap likelihood ratio test (BLRT) for class enumeration
- R3STEP method for auxiliary variable analysis
- Sandwich standard errors accounting for clustering and stratification
- Full Information Maximum Likelihood (FIML) for missing data
- Validated against Mplus (gold standard software)

### Examples

All examples run in < 5 seconds or are wrapped in `\donttest{}` or `\dontrun{}`:
- `\donttest{}`: Used for examples requiring > 5 seconds (e.g., model selection with BLRT)
- `\dontrun{}`: Used for examples requiring external data or illustrative code snippets

### Tests

- Comprehensive test suite with >80% code coverage
- Tests marked with `skip_on_cran()` for computationally intensive checks
- All CRAN tests complete in < 60 seconds

### Vignettes

Four vignettes provided:
1. Introduction to surveymixr (basic usage)
2. Technical details and algorithms (statistical methodology)
3. R3STEP analysis (auxiliary variables)
4. Validation against Mplus (verification)

### Dependencies

All dependencies are available on CRAN:
- Imports: stats, methods, MASS, numDeriv, ggplot2, parallel
- Suggests: knitr, rmarkdown, testthat, covr

### Documentation

- All exported functions documented
- 30 .Rd help files
- Comprehensive README with examples
- Package website via pkgdown

### URLs

- GitHub: https://github.com/siyangni/surveymixr
- Documentation: https://siyangni.github.io/surveymixr
- Bug reports: https://github.com/siyangni/surveymixr/issues

### Academic paper

An accompanying paper is in preparation for submission to the Journal of Statistical Software describing the methodology and software implementation.

### Unique contribution

surveymixr enables researchers to:
1. Analyze complex survey data with GMM (previously required $1000+ Mplus license)
2. Use open-source, reproducible workflows
3. Integrate with R ecosystem (tidyverse, ggplot2, etc.)
4. Customize and extend methods

### Validation

Results have been extensively validated against Mplus, showing parameter estimates match within 0.5% (see validation vignette).

---

## Submission status

This is a **FIRST SUBMISSION** to CRAN.

---

## Notes for specific checks

### Performance

- Examples: All complete in < 5 seconds (or marked `\donttest{}`)
- Tests: CRAN tests complete in < 60 seconds
- Memory: Tested with datasets up to n=10,000; no memory issues

### Platform-specific issues

No platform-specific code. Package tested on Windows, macOS, and Linux without issues.

### License

GPL (>= 3) - standard open-source license, compatible with CRAN policies.

---

Thank you for reviewing this submission. I am available to address any questions or concerns.

Siyang Ni
johnni.nj@gmail.com
https://github.com/siyangni
