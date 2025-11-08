#!/usr/bin/env Rscript
# Documentation Enhancement Script
# Part of Week 5 tasks (ACTION-PLAN-PHASE1.md)
#
# This script systematically improves package documentation:
# 1. Checks for missing documentation elements
# 2. Validates @examples
# 3. Adds cross-references (@seealso)
# 4. Checks parameter descriptions
# 5. Validates @references
# 6. Updates README
#
# Run from package root directory

cat("==============================================================\n")
cat("surveymixr Documentation Enhancement Script\n")
cat("==============================================================\n\n")

# Check we're in the right directory
if (!file.exists("DESCRIPTION")) {
  stop("Please run this script from the surveymixr package root directory")
}

library(tools)

# ==============================================================================
# 1. CHECK FOR MISSING DOCUMENTATION ELEMENTS
# ==============================================================================

cat("Checking documentation completeness...\n\n")

# Get all R files
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)

missing_docs <- list()

for (r_file in r_files) {
  content <- readLines(r_file)

  # Check for @param without descriptions
  param_lines <- grep("^#' @param", content, value = TRUE)
  for (line in param_lines) {
    # Extract parameter name and check for description
    param_name <- sub("^#' @param ([^ ]+).*", "\\1", line)
    description <- sub("^#' @param [^ ]+ ", "", line)

    if (nchar(trimws(description)) < 10) {
      if (is.null(missing_docs[[r_file]])) {
        missing_docs[[r_file]] <- list()
      }
      missing_docs[[r_file]]$short_param_desc <- c(
        missing_docs[[r_file]]$short_param_desc,
        sprintf("  - @param %s: description too short", param_name)
      )
    }
  }

  # Check for @return
  if (!any(grepl("^#' @return", content))) {
    exported <- any(grepl("^#' @export", content))
    if (exported) {
      if (is.null(missing_docs[[r_file]])) {
        missing_docs[[r_file]] <- list()
      }
      missing_docs[[r_file]]$missing_return <- "  - Missing @return documentation"
    }
  }

  # Check for @examples
  if (!any(grepl("^#' @examples", content))) {
    exported <- any(grepl("^#' @export", content))
    if (exported) {
      if (is.null(missing_docs[[r_file]])) {
        missing_docs[[r_file]] <- list()
      }
      missing_docs[[r_file]]$missing_examples <- "  - Missing @examples"
    }
  }

  # Check for @seealso
  if (!any(grepl("^#' @seealso", content))) {
    exported <- any(grepl("^#' @export", content))
    if (exported) {
      if (is.null(missing_docs[[r_file]])) {
        missing_docs[[r_file]] <- list()
      }
      missing_docs[[r_file]]$missing_seealso <- "  - Consider adding @seealso cross-references"
    }
  }
}

# Report findings
if (length(missing_docs) > 0) {
  cat("⚠ Documentation issues found:\n\n")
  for (file in names(missing_docs)) {
    cat(sprintf("%s:\n", file))
    for (issue_type in names(missing_docs[[file]])) {
      issues <- missing_docs[[file]][[issue_type]]
      for (issue in issues) {
        cat(sprintf("%s\n", issue))
      }
    }
    cat("\n")
  }

  # Save to file
  sink("scripts/documentation-issues.txt")
  cat("Documentation Issues\n")
  cat("===================\n\n")
  for (file in names(missing_docs)) {
    cat(sprintf("%s:\n", file))
    for (issue_type in names(missing_docs[[file]])) {
      issues <- missing_docs[[file]][[issue_type]]
      for (issue in issues) {
        cat(sprintf("%s\n", issue))
      }
    }
    cat("\n")
  }
  sink()

  cat("Details saved to: scripts/documentation-issues.txt\n\n")
} else {
  cat("✓ No documentation issues found!\n\n")
}

# ==============================================================================
# 2. VALIDATE @examples
# ==============================================================================

cat("Validating @examples sections...\n\n")

library(roxygen2)

# This requires actually running roxygen2 and checking examples
# For now, we'll just check that examples exist

example_check <- data.frame(
  file = character(),
  function_name = character(),
  has_example = logical(),
  has_dontrun = logical(),
  has_donttest = logical(),
  stringsAsFactors = FALSE
)

for (r_file in r_files) {
  content <- readLines(r_file)

  # Find function definitions
  func_lines <- grep("^[a-zA-Z_][a-zA-Z0-9_.]* <- function", content)

  for (func_line in func_lines) {
    func_name <- sub("^([a-zA-Z_][a-zA-Z0-9_.]*) <-.*", "\\1", content[func_line])

    # Look backwards for roxygen comments
    roxygen_start <- func_line - 1
    while (roxygen_start > 0 && grepl("^#'", content[roxygen_start])) {
      roxygen_start <- roxygen_start - 1
    }
    roxygen_start <- roxygen_start + 1

    roxygen_block <- content[roxygen_start:(func_line - 1)]

    has_example <- any(grepl("^#' @examples", roxygen_block))
    has_dontrun <- any(grepl("\\\\dontrun", roxygen_block))
    has_donttest <- any(grepl("\\\\donttest", roxygen_block))

    example_check <- rbind(example_check, data.frame(
      file = r_file,
      function_name = func_name,
      has_example = has_example,
      has_dontrun = has_dontrun,
      has_donttest = has_donttest,
      stringsAsFactors = FALSE
    ))
  }
}

# Report
exported_without_examples <- example_check[!example_check$has_example, ]
if (nrow(exported_without_examples) > 0) {
  cat(sprintf("⚠ %d functions missing @examples:\n", nrow(exported_without_examples)))
  print(exported_without_examples[, c("file", "function_name")])
  cat("\n")
}

all_dontrun <- example_check[example_check$has_example & example_check$has_dontrun & !example_check$has_donttest, ]
if (nrow(all_dontrun) > 0) {
  cat(sprintf("⚠ %d functions have all examples in \\dontrun{}:\n", nrow(all_dontrun)))
  cat("Consider moving some to \\donttest{} or making them runnable\n")
  print(all_dontrun[, c("file", "function_name")])
  cat("\n")
}

# Save summary
write.csv(example_check, "scripts/example-check.csv", row.names = FALSE)
cat("Example check saved to: scripts/example-check.csv\n\n")

# ==============================================================================
# 3. CHECK FOR CROSS-REFERENCES
# ==============================================================================

cat("Analyzing cross-reference opportunities...\n\n")

# Common function pairs that should reference each other
cross_ref_suggestions <- list(
  "gmm_survey" = c("gmm_select", "r3step", "simulate_gmm_survey"),
  "gmm_select" = c("gmm_survey", "plot_model_selection"),
  "r3step" = c("gmm_survey"),
  "plot_trajectories" = c("gmm_survey", "plot_model_selection"),
  "diagnose_convergence" = c("gmm_survey", "classification_quality"),
  "classification_quality" = c("entropy", "class_proportions"),
  "simulate_gmm_survey" = c("gmm_survey", "wide_to_long")
)

# Check if cross-references exist
for (func in names(cross_ref_suggestions)) {
  r_file <- Sys.glob(sprintf("R/*%s*.R", func))[1]

  if (!is.na(r_file) && file.exists(r_file)) {
    content <- paste(readLines(r_file), collapse = "\n")

    missing_refs <- c()
    for (ref_func in cross_ref_suggestions[[func]]) {
      if (!grepl(ref_func, content)) {
        missing_refs <- c(missing_refs, ref_func)
      }
    }

    if (length(missing_refs) > 0) {
      cat(sprintf("%s could reference: %s\n", func, paste(missing_refs, collapse = ", ")))
    }
  }
}
cat("\n")

# ==============================================================================
# 4. CHECK PARAMETER DESCRIPTIONS
# ==============================================================================

cat("Checking parameter description quality...\n\n")

# Parameters that should include value ranges
params_needing_ranges <- c(
  "n_classes" = "positive integer",
  "starts" = "positive integer, typically 50-1000",
  "convergence" = "small positive number, e.g., 1e-6",
  "max_iter" = "positive integer",
  "entropy" = "numeric value between 0 and 1",
  "alpha" = "numeric value between 0 and 1"
)

for (param_name in names(params_needing_ranges)) {
  # Search for @param entries
  for (r_file in r_files) {
    content <- readLines(r_file)
    param_lines <- grep(sprintf("^#' @param %s ", param_name), content, value = TRUE)

    for (line in param_lines) {
      expected_range <- params_needing_ranges[[param_name]]

      # Check if range/constraint is mentioned
      if (!grepl("between|range|positive|negative|integer|numeric", line, ignore.case = TRUE)) {
        cat(sprintf("⚠ %s: @param %s should specify range/type (%s)\n",
                   basename(r_file), param_name, expected_range))
      }
    }
  }
}
cat("\n")

# ==============================================================================
# 5. VALIDATE @references
# ==============================================================================

cat("Checking for @references citations...\n\n")

# Key papers that should be cited
key_papers <- c(
  "Muthén" = "mixture model|growth mixture|GMM methodology",
  "Vermunt" = "latent class|R3STEP|auxiliary",
  "Asparouhov" = "survey|weight|complex design",
  "Bolck" = "BCH|R3STEP",
  "Nylund" = "model selection|BLRT|entropy"
)

files_needing_refs <- list()

for (r_file in r_files) {
  content <- paste(readLines(r_file), collapse = " ")

  # Check if file discusses topics requiring citation
  for (author in names(key_papers)) {
    pattern <- key_papers[[author]]
    if (grepl(pattern, content, ignore.case = TRUE)) {
      # Check if there's a @references section
      if (!grepl("@references", content)) {
        if (is.null(files_needing_refs[[r_file]])) {
          files_needing_refs[[r_file]] <- c()
        }
        files_needing_refs[[r_file]] <- c(files_needing_refs[[r_file]], author)
      }
    }
  }
}

if (length(files_needing_refs) > 0) {
  cat("⚠ Files that might benefit from @references:\n\n")
  for (file in names(files_needing_refs)) {
    authors <- unique(files_needing_refs[[file]])
    cat(sprintf("%s: Consider citing %s\n", basename(file), paste(authors, collapse = ", ")))
  }
  cat("\n")
}

# ==============================================================================
# 6. README UPDATE SUGGESTIONS
# ==============================================================================

cat("Checking README...\n\n")

if (file.exists("README.md")) {
  readme_content <- paste(readLines("README.md"), collapse = "\n")

  readme_checks <- list(
    "Installation section" = grepl("## Installation|# Installation", readme_content),
    "Example usage" = grepl("## Example|# Example|## Usage|# Usage", readme_content),
    "Citation information" = grepl("## Citation|# Citation|cite|citing", readme_content, ignore.case = TRUE),
    "Bug reports link" = grepl("issues|bug|report", readme_content, ignore.case = TRUE),
    "License information" = grepl("License|GPL", readme_content),
    "Badges (build status)" = grepl("badge|status|CRAN|codecov", readme_content, ignore.case = TRUE)
  )

  missing_readme <- names(readme_checks)[!unlist(readme_checks)]

  if (length(missing_readme) > 0) {
    cat("⚠ README could be enhanced with:\n")
    for (item in missing_readme) {
      cat(sprintf("  - %s\n", item))
    }
    cat("\n")
  } else {
    cat("✓ README includes all recommended sections\n\n")
  }
} else {
  cat("⚠ README.md not found!\n\n")
}

# ==============================================================================
# SUMMARY REPORT
# ==============================================================================

cat("==============================================================\n")
cat("DOCUMENTATION ENHANCEMENT SUMMARY\n")
cat("==============================================================\n\n")

cat("Files generated:\n")
cat("  - scripts/documentation-issues.txt\n")
cat("  - scripts/example-check.csv\n\n")

cat("Next steps:\n")
cat("  1. Review documentation-issues.txt and fix missing elements\n")
cat("  2. Add @examples to functions missing them\n")
cat("  3. Add @seealso cross-references between related functions\n")
cat("  4. Add @references to key methodological papers\n")
cat("  5. Update parameter descriptions with ranges/constraints\n")
cat("  6. Enhance README with any missing sections\n\n")

cat("After making changes, run:\n")
cat("  devtools::document()\n")
cat("  devtools::check()\n\n")

cat("==============================================================\n")
