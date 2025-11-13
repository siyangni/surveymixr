# Archives

This directory contains historical development artifacts that are no longer needed in the main repository but are preserved for reference.

## Directory Structure

### `development-docs/`
Historical planning and documentation files from earlier development phases:
- Action plans, roadmaps, and implementation summaries
- Bug fix and feature addition documentation
- Testing summaries and week-by-week instructions
- Example scripts used during development

These documents were useful during active development but are no longer needed now that the package is production-ready.

### `build-artifacts/` (Not tracked in git)
Temporary build outputs and check results:
- `surveymixr.Rcheck/` - R CMD check output directory
- `*.tar.gz` - Built package tarballs

These artifacts can be regenerated at any time with `R CMD build` and `R CMD check`.

**Note:** This directory exists locally but is excluded from git tracking via `.gitignore` since build artifacts should not be versioned.

## Note

These files are excluded from the R package build via `.Rbuildignore` but are kept in version control for historical reference.
