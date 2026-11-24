## Resubmission (v0.2.3)

This is a resubmission addressing reviewer feedback from Benjamin Altmann
(2025-12-11) regarding \dontrun{} examples:

1. **Removed the random-effects placeholder API** - The five flagged
   documentation pages (calculate_icc, get_random_effects, gmm_survey_re,
   plot_random_effects, variance_components) documented a feature that was
   still under development: the underlying estimation routine errors by
   design ("Full implementation pending"), so its examples could never run
   under \donttest{}. We have removed the entire placeholder API (functions,
   class, tests, and documentation). Random-effects support will return in a
   future release once fully implemented and tested.

2. **Removed all remaining \dontrun{} from documentation** - Examples now
   either run directly, are wrapped in \donttest{} (verified to run without
   error), or are shown as commented code for features still under development
   (binary/ordinal/count outcomes, time-varying covariates). No \dontrun{}
   remains anywhere in the package. Additionally, long-running \donttest{}
   examples were sped up (fewer random starts) so the full example suite now
   runs in minutes rather than over an hour, and vignette installation
   snippets are now guarded with if (FALSE) so they cannot execute during
   package checks.

3. **Improvements to EM initialization** - Random-start initialization now
   shuffles class labels so parallel starts are not identical, improving
   the exploration of the likelihood surface.

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
