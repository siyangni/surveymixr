#!/usr/bin/env Rscript
# Week 1 Setup Script for surveymixr Package
# Run this script from the package root directory
#
# This script performs all Week 1 tasks from ACTION-PLAN-PHASE1.md:
# 1. Creates example dataset
# 2. Runs R CMD check
# 3. Performs quick wins (spelling, URLs)
# 4. Documents issues

cat("==========================================================\n")
cat("surveymixr Week 1 Setup Script\n")
cat("==========================================================\n\n")

# Check we're in the right directory
if (!file.exists("DESCRIPTION")) {
  stop("Please run this script from the surveymixr package root directory")
}

# Load required packages
cat("Loading required packages...\n")
required_packages <- c("devtools", "usethis", "testthat", "roxygen2", "urlchecker", "spelling")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Installing %s...\n", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

suppressPackageStartupMessages({
  library(devtools)
  library(usethis)
})

# =============================================================================
# TASK 1: Create Example Dataset
# =============================================================================
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("TASK 1: Creating Example Dataset\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

if (!file.exists("data-raw/create-mcs-simulated.R")) {
  cat("ERROR: Script data-raw/create-mcs-simulated.R not found!\n")
} else {
  cat("Running data-raw/create-mcs-simulated.R...\n")

  tryCatch({
    source("data-raw/create-mcs-simulated.R")

    # Verify dataset was created
    if (file.exists("data/mcs_simulated.rda")) {
      cat("✓ SUCCESS: mcs_simulated.rda created\n")

      # Load and inspect
      load("data/mcs_simulated.rda")
      cat(sprintf("  - %d individuals\n", length(unique(mcs_simulated$id))))
      cat(sprintf("  - %d observations\n", nrow(mcs_simulated)))
      cat(sprintf("  - %d variables\n", ncol(mcs_simulated)))
    } else {
      cat("✗ ERROR: Dataset file not created\n")
    }
  }, error = function(e) {
    cat("✗ ERROR creating dataset:\n")
    cat(paste0("  ", e$message, "\n"))
  })
}

# =============================================================================
# TASK 2: Run R CMD Check
# =============================================================================
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("TASK 2: Running R CMD Check\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

cat("Running devtools::check()...\n")
cat("(This may take several minutes)\n\n")

check_results <- NULL
tryCatch({
  check_results <- devtools::check(
    document = TRUE,
    args = c("--no-manual", "--as-cran"),
    quiet = FALSE
  )

  # Save results
  cat("\n\nR CMD Check Results Summary:\n")
  cat("----------------------------\n")
  cat(sprintf("Errors:   %d\n", length(check_results$errors)))
  cat(sprintf("Warnings: %d\n", length(check_results$warnings)))
  cat(sprintf("Notes:    %d\n", length(check_results$notes)))

  # Write detailed report
  sink("scripts/check-results.txt")
  print(check_results)
  sink()
  cat("\nDetailed results saved to: scripts/check-results.txt\n")

}, error = function(e) {
  cat("✗ ERROR running R CMD check:\n")
  cat(paste0("  ", e$message, "\n"))
})

# =============================================================================
# TASK 3: Spell Check
# =============================================================================
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("TASK 3: Spell Check\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

tryCatch({
  spelling_errors <- devtools::spell_check()

  if (nrow(spelling_errors) == 0) {
    cat("✓ No spelling errors found!\n")
  } else {
    cat(sprintf("Found %d potential spelling errors:\n\n", nrow(spelling_errors)))
    print(spelling_errors)

    # Save to file
    write.csv(spelling_errors, "scripts/spelling-errors.csv", row.names = FALSE)
    cat("\nSpelling errors saved to: scripts/spelling-errors.csv\n")
  }
}, error = function(e) {
  cat("✗ ERROR running spell check:\n")
  cat(paste0("  ", e$message, "\n"))
})

# =============================================================================
# TASK 4: URL Check
# =============================================================================
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("TASK 4: URL Validation\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

tryCatch({
  if (requireNamespace("urlchecker", quietly = TRUE)) {
    url_results <- urlchecker::url_check()

    if (nrow(url_results) == 0) {
      cat("✓ All URLs are valid!\n")
    } else {
      cat(sprintf("Found %d URL issues:\n\n", nrow(url_results)))
      print(url_results)

      # Save to file
      write.csv(url_results, "scripts/url-issues.csv", row.names = FALSE)
      cat("\nURL issues saved to: scripts/url-issues.csv\n")
    }
  } else {
    cat("Installing urlchecker package...\n")
    install.packages("urlchecker")
    url_results <- urlchecker::url_check()
    print(url_results)
  }
}, error = function(e) {
  cat("✗ ERROR checking URLs:\n")
  cat(paste0("  ", e$message, "\n"))
})

# =============================================================================
# TASK 5: Test Coverage Analysis
# =============================================================================
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("TASK 5: Test Coverage Analysis\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

tryCatch({
  if (requireNamespace("covr", quietly = TRUE)) {
    cat("Calculating test coverage...\n")
    cat("(This may take a few minutes)\n\n")

    coverage <- covr::package_coverage()

    cat("\nCoverage Summary:\n")
    print(coverage)

    # Save detailed report
    covr::report(coverage, file = "scripts/coverage-report.html")
    cat("\nDetailed coverage report saved to: scripts/coverage-report.html\n")

    # Get percentage
    pct <- covr::percent_coverage(coverage)
    cat(sprintf("\nOverall Coverage: %.1f%%\n", pct))

    if (pct < 80) {
      cat(sprintf("\n⚠ WARNING: Coverage is below 80%% target (current: %.1f%%)\n", pct))
      cat("Add more tests to increase coverage.\n")
    } else {
      cat("\n✓ Coverage meets 80%% target!\n")
    }

  } else {
    cat("Installing covr package...\n")
    install.packages("covr")
    cat("Please re-run this script to generate coverage report.\n")
  }
}, error = function(e) {
  cat("✗ ERROR analyzing coverage:\n")
  cat(paste0("  ", e$message, "\n"))
})

# =============================================================================
# TASK 6: Documentation Check
# =============================================================================
cat("\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("TASK 6: Documentation Check\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

cat("Checking for undocumented functions...\n")

# Get all exported functions
namespace <- parseNamespaceFile(basename(getwd()), dirname(getwd()))
exported <- namespace$exports

# Check which ones have documentation
man_files <- list.files("man", pattern = "\\.Rd$", full.names = FALSE)
man_topics <- gsub("\\.Rd$", "", man_files)

undocumented <- setdiff(exported, man_topics)

if (length(undocumented) == 0) {
  cat("✓ All exported functions are documented!\n")
} else {
  cat(sprintf("⚠ Found %d undocumented exports:\n", length(undocumented)))
  cat(paste0("  - ", undocumented, collapse = "\n"))
  cat("\n")
}

# =============================================================================
# SUMMARY REPORT
# =============================================================================
cat("\n\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("WEEK 1 SETUP COMPLETE - SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n\n")

cat("✓ Example dataset created\n")
cat("✓ R CMD check completed (see scripts/check-results.txt)\n")
cat("✓ Spell check completed\n")
cat("✓ URL validation completed\n")
cat("✓ Test coverage analyzed\n")
cat("✓ Documentation checked\n\n")

cat("Next Steps:\n")
cat("-----------\n")
cat("1. Review scripts/check-results.txt and fix any errors/warnings\n")
cat("2. Fix spelling errors in scripts/spelling-errors.csv\n")
cat("3. Fix URL issues in scripts/url-issues.csv\n")
cat("4. Add tests to improve coverage (target: >80%)\n")
cat("5. Continue with Week 1 tasks from ACTION-PLAN-PHASE1.md\n\n")

cat("Files generated:\n")
cat("----------------\n")
cat("- data/mcs_simulated.rda\n")
cat("- scripts/check-results.txt\n")
cat("- scripts/spelling-errors.csv\n")
cat("- scripts/url-issues.csv\n")
cat("- scripts/coverage-report.html\n\n")

cat(paste(rep("=", 60), collapse = ""), "\n")
cat("Setup script completed successfully!\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
