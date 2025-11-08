#!/usr/bin/env Rscript
# Pre-CRAN Submission Checklist
# Final checks before submitting to CRAN
#
# Run this script from package root directory

cat("==============================================================\n")
cat("surveymixr Pre-Submission Checklist\n")
cat("==============================================================\n\n")

# Check we're in the right directory
if (!file.exists("DESCRIPTION")) {
  stop("Please run this script from the surveymixr package root directory")
}

library(tools)

checklist <- list()

# ==============================================================================
# 1. PACKAGE METADATA
# ==============================================================================

cat("Checking package metadata...\n")

desc <- read.dcf("DESCRIPTION")

# Version
version <- desc[1, "Version"]
cat(sprintf("  Version: %s\n", version))
checklist$version <- list(
  status = grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version),
  message = ifelse(
    grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version),
    "Version format correct",
    "Version should be X.Y.Z format"
  )
)

# License
license <- desc[1, "License"]
cat(sprintf("  License: %s\n", license))
checklist$license <- list(
  status = nzchar(license),
  message = ifelse(nzchar(license), "License specified", "License missing")
)

# URL and BugReports
has_url <- "URL" %in% colnames(desc) && nzchar(desc[1, "URL"])
has_bugreports <- "BugReports" %in% colnames(desc) && nzchar(desc[1, "BugReports"])

checklist$urls <- list(
  status = has_url && has_bugreports,
  message = sprintf("URL: %s, BugReports: %s",
                   ifelse(has_url, "✓", "✗"),
                   ifelse(has_bugreports, "✓", "✗"))
)

cat("\n")

# ==============================================================================
# 2. REQUIRED FILES
# ==============================================================================

cat("Checking required files...\n")

required_files <- c(
  "DESCRIPTION" = TRUE,
  "NAMESPACE" = TRUE,
  "README.md" = TRUE,
  "NEWS.md" = TRUE,
  "LICENSE" = TRUE,
  "inst/CITATION" = TRUE,
  "cran-comments.md" = TRUE,
  ".Rbuildignore" = TRUE
)

for (file in names(required_files)) {
  exists <- file.exists(file)
  cat(sprintf("  %s: %s\n", file, ifelse(exists, "✓", "✗")))
  checklist[[paste0("file_", file)]] <- list(
    status = exists,
    message = ifelse(exists, sprintf("%s exists", file), sprintf("%s missing", file))
  )
}

cat("\n")

# ==============================================================================
# 3. DOCUMENTATION
# ==============================================================================

cat("Checking documentation...\n")

# Check all exported functions have documentation
namespace <- parseNamespaceFile(basename(getwd()), dirname(getwd()))
exports <- namespace$exports

man_files <- list.files("man", pattern = "\\.Rd$")
man_topics <- gsub("\\.Rd$", "", man_files)

undocumented <- setdiff(exports, man_topics)

checklist$documentation <- list(
  status = length(undocumented) == 0,
  message = ifelse(
    length(undocumented) == 0,
    "All exports documented",
    sprintf("%d undocumented exports: %s", length(undocumented), paste(undocumented, collapse = ", "))
  )
)

cat(sprintf("  Exported functions: %d\n", length(exports)))
cat(sprintf("  Documented: %d\n", length(intersect(exports, man_topics))))
if (length(undocumented) > 0) {
  cat(sprintf("  Undocumented: %s\n", paste(undocumented, collapse = ", ")))
}

# Check vignettes
vignettes <- list.files("vignettes", pattern = "\\.Rmd$")
cat(sprintf("  Vignettes: %d\n", length(vignettes)))

checklist$vignettes <- list(
  status = length(vignettes) >= 1,
  message = sprintf("%d vignette(s) found", length(vignettes))
)

cat("\n")

# ==============================================================================
# 4. EXAMPLES
# ==============================================================================

cat("Checking examples...\n")

# Check that not all examples are \dontrun
dontrun_count <- 0
runnable_count <- 0

for (rd_file in list.files("man", pattern = "\\.Rd$", full.names = TRUE)) {
  content <- paste(readLines(rd_file), collapse = "\n")

  if (grepl("\\\\examples", content)) {
    if (grepl("\\\\dontrun", content) && !grepl("\\\\donttest", content)) {
      # Check if ALL examples are dontrun
      examples_section <- sub(".*\\\\examples\\{(.*)\\}.*", "\\1", content)
      if (grepl("^[[:space:]]*\\\\dontrun", examples_section)) {
        dontrun_count <- dontrun_count + 1
      } else {
        runnable_count <- runnable_count + 1
      }
    } else {
      runnable_count <- runnable_count + 1
    }
  }
}

cat(sprintf("  Runnable examples: %d\n", runnable_count))
cat(sprintf("  All dontrun: %d\n", dontrun_count))

checklist$examples <- list(
  status = runnable_count > 0,
  message = sprintf("%d functions with runnable examples", runnable_count)
)

cat("\n")

# ==============================================================================
# 5. TESTS
# ==============================================================================

cat("Checking tests...\n")

test_files <- list.files("tests/testthat", pattern = "^test-.*\\.R$")
cat(sprintf("  Test files: %d\n", length(test_files)))

checklist$tests <- list(
  status = length(test_files) >= 3,
  message = sprintf("%d test files", length(test_files))
)

# Try to get coverage (if covr installed)
if (requireNamespace("covr", quietly = TRUE)) {
  cat("  Calculating coverage... (this may take a few minutes)\n")

  tryCatch({
    coverage <- covr::package_coverage()
    pct <- covr::percent_coverage(coverage)
    cat(sprintf("  Coverage: %.1f%%\n", pct))

    checklist$coverage <- list(
      status = pct >= 70,
      message = sprintf("Coverage: %.1f%%", pct)
    )
  }, error = function(e) {
    cat("  Coverage calculation failed\n")
    checklist$coverage <- list(
      status = FALSE,
      message = "Coverage could not be calculated"
    )
  })
} else {
  cat("  Install 'covr' to check test coverage\n")
}

cat("\n")

# ==============================================================================
# 6. R CMD CHECK
# ==============================================================================

cat("Running R CMD check...\n")
cat("(This may take several minutes)\n\n")

check_result <- tryCatch({
  devtools::check(
    document = TRUE,
    args = c("--as-cran", "--no-manual"),
    quiet = FALSE
  )
}, error = function(e) {
  list(errors = "Check failed", warnings = character(), notes = character())
})

cat("\n")
cat(sprintf("  Errors: %d\n", length(check_result$errors)))
cat(sprintf("  Warnings: %d\n", length(check_result$warnings)))
cat(sprintf("  Notes: %d\n", length(check_result$notes)))

checklist$rcmdcheck <- list(
  status = length(check_result$errors) == 0 && length(check_result$warnings) == 0,
  message = sprintf("Errors: %d, Warnings: %d, Notes: %d",
                   length(check_result$errors),
                   length(check_result$warnings),
                   length(check_result$notes))
)

if (length(check_result$errors) > 0) {
  cat("\nErrors:\n")
  for (err in check_result$errors) {
    cat(sprintf("  - %s\n", err))
  }
}

if (length(check_result$warnings) > 0) {
  cat("\nWarnings:\n")
  for (warn in check_result$warnings) {
    cat(sprintf("  - %s\n", warn))
  }
}

cat("\n")

# ==============================================================================
# 7. SPELL CHECK
# ==============================================================================

cat("Running spell check...\n")

spelling_errors <- devtools::spell_check()

cat(sprintf("  Potential spelling errors: %d\n", nrow(spelling_errors)))

checklist$spelling <- list(
  status = nrow(spelling_errors) == 0,
  message = sprintf("%d spelling issues", nrow(spelling_errors))
)

if (nrow(spelling_errors) > 0 && nrow(spelling_errors) <= 10) {
  print(spelling_errors)
}

cat("\n")

# ==============================================================================
# 8. URL CHECK
# ==============================================================================

cat("Checking URLs...\n")

if (requireNamespace("urlchecker", quietly = TRUE)) {
  url_results <- urlchecker::url_check()

  cat(sprintf("  Invalid URLs: %d\n", nrow(url_results)))

  checklist$urls_valid <- list(
    status = nrow(url_results) == 0,
    message = sprintf("%d invalid URLs", nrow(url_results))
  )

  if (nrow(url_results) > 0 && nrow(url_results) <= 5) {
    print(url_results)
  }
} else {
  cat("  Install 'urlchecker' to validate URLs\n")
}

cat("\n")

# ==============================================================================
# 9. EXAMPLE DATA
# ==============================================================================

cat("Checking example data...\n")

data_files <- list.files("data", pattern = "\\.rda$")
cat(sprintf("  Data files: %d\n", length(data_files)))

checklist$data <- list(
  status = length(data_files) >= 1,
  message = sprintf("%d data files", length(data_files))
)

# Check data documentation
if (file.exists("R/data.R")) {
  cat("  ✓ Data documentation exists (R/data.R)\n")
} else {
  cat("  ✗ Data documentation missing (R/data.R)\n")
}

cat("\n")

# ==============================================================================
# 10. BUILD PACKAGE
# ==============================================================================

cat("Building package tarball...\n")

tarball <- tryCatch({
  devtools::build(quiet = TRUE)
}, error = function(e) {
  NULL
})

if (!is.null(tarball)) {
  cat(sprintf("  ✓ Built: %s\n", tarball))
  cat(sprintf("  Size: %.2f MB\n", file.size(tarball) / 1024^2))

  checklist$build <- list(
    status = TRUE,
    message = "Package builds successfully"
  )
} else {
  cat("  ✗ Build failed\n")

  checklist$build <- list(
    status = FALSE,
    message = "Package build failed"
  )
}

cat("\n")

# ==============================================================================
# FINAL CHECKLIST
# ==============================================================================

cat("==============================================================\n")
cat("FINAL CHECKLIST SUMMARY\n")
cat("==============================================================\n\n")

all_passed <- TRUE

for (item_name in names(checklist)) {
  item <- checklist[[item_name]]
  status_symbol <- ifelse(item$status, "✓", "✗")
  cat(sprintf("%s %s\n", status_symbol, item$message))

  if (!item$status) {
    all_passed <- FALSE
  }
}

cat("\n")

if (all_passed) {
  cat("==============================================================\n")
  cat("🎉 ALL CHECKS PASSED! READY FOR CRAN SUBMISSION 🎉\n")
  cat("==============================================================\n\n")

  cat("Next steps:\n")
  cat("1. Review cran-comments.md\n")
  cat("2. Submit via: devtools::submit_cran()\n")
  cat("   OR manually at: https://cran.r-project.org/submit.html\n")
  cat("3. Monitor email for CRAN feedback\n")
  cat("4. Respond to reviewers within 2 weeks\n\n")
} else {
  cat("==============================================================\n")
  cat("⚠  ISSUES FOUND - FIX BEFORE SUBMISSION\n")
  cat("==============================================================\n\n")

  cat("Address the items marked with ✗ above before submitting to CRAN.\n\n")
}

# Save detailed report
report_file <- "scripts/pre-submission-report.txt"
sink(report_file)
cat("surveymixr Pre-Submission Report\n")
cat("=================================\n\n")
cat(sprintf("Generated: %s\n\n", Sys.time()))

for (item_name in names(checklist)) {
  item <- checklist[[item_name]]
  cat(sprintf("[%s] %s\n", ifelse(item$status, "PASS", "FAIL"), item$message))
}

if (all_passed) {
  cat("\n✓ READY FOR CRAN SUBMISSION\n")
} else {
  cat("\n✗ FIX ISSUES BEFORE SUBMISSION\n")
}
sink()

cat(sprintf("Detailed report saved to: %s\n", report_file))
