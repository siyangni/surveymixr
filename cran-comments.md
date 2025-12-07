## Resubmission (v0.2.2)

This is a resubmission addressing notes from the incoming pre-tests:

1. **Fixed possibly misspelled words in DESCRIPTION** - Technical terms, software 
   names, and acronyms are now properly quoted (e.g., 'GMM', 'BLRT', 'Mplus', 
   'LMR', 'NLSY', 'ECLS', 'R3STEP'). Author names used with DOI citations follow 
   standard CRAN practices.

2. **Reduced checktime** - Added `skip_on_cran()` to computationally intensive 
   tests. The full test suite runs ~18 minutes but CRAN checks should now 
   complete within the 10-minute limit. Full tests remain available via 
   `devtools::test()` for thorough local testing.

## Previous changes (v0.2.1)

1. Added missing \value tags - All .Rd files now have proper \value documentation
2. Replaced \dontrun{} with \donttest{} - Examples now follow CRAN guidelines
3. Fixed invalid file URIs - README.md no longer references excluded files
4. Verified cat()/print() usage - All output is within proper print/show methods

## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* local: Linux (x86_64-pc-linux-gnu), R 4.x.x
* GitHub Actions:
  - macOS-latest (R-release)
  - windows-latest (R-release)
  - ubuntu-latest (R-release, R-devel, R-oldrel-1)
* win-builder (R-devel, R-release)
* R-hub v2 (linux, macos, windows with R-devel)

## Downstream dependencies

There are currently no downstream dependencies for this package.
