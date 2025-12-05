## Resubmission

This is a resubmission. In the previous submission, CRAN reviewers requested
the following changes, which have all been addressed:

1. **Added missing \value tags** - All .Rd files now have proper \value documentation
2. **Replaced \dontrun{} with \donttest{}** - Examples now follow CRAN guidelines
3. **Fixed invalid file URIs** - README.md no longer references excluded files
4. **Verified cat()/print() usage** - All output is within proper print/show methods

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
