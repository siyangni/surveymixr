# Testing surveymixr Locally

This guide explains how to test the package before publishing to CRAN.

## Prerequisites

You need R (≥ 4.0.0) and the following packages:

```r
install.packages(c("devtools", "testthat", "roxygen2", "knitr", "rmarkdown"))
```

## Quick Start: 3 Ways to Test

### Method 1: Load Package in Development Mode (Fastest)

```r
# Navigate to package directory
setwd("/home/user/surveymixr")

# Load package without installing
devtools::load_all()

# Now you can use all functions
test_data <- simulate_gmm_survey(
  n_individuals = 100,
  n_times = 4,
  n_classes = 2,
  seed = 123
)

fit <- gmm_survey(
  data = test_data,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 2,
  starts = 20,
  verbose = TRUE
)

summary(fit)
plot(fit)
```

### Method 2: Install Package Locally

```r
# From R console
setwd("/home/user/surveymixr")

# Generate documentation
devtools::document()

# Install the package
devtools::install()

# Now load and use like any R package
library(surveymixr)

# Test it
test_data <- simulate_gmm_survey(n_individuals = 100, n_times = 4, n_classes = 2)
fit <- gmm_survey(test_data, "id", "time", "outcome", n_classes = 2, starts = 20)
```

### Method 3: Run Automated Test Script

```bash
# From terminal
cd /home/user/surveymixr
Rscript test-package.R
```

This script automatically:
- Installs dependencies
- Loads the package
- Runs basic functionality tests
- Creates test plots
- Reports any errors

## Step-by-Step Testing Guide

### Step 1: Generate Documentation

```r
setwd("/home/user/surveymixr")
devtools::document()
```

This creates `.Rd` files in `man/` directory from Roxygen2 comments.

### Step 2: Run Unit Tests

```r
devtools::test()
```

This runs all tests in `tests/testthat/`.

### Step 3: Check Package (CRAN-style)

```r
devtools::check()
```

This runs comprehensive checks including:
- Documentation completeness
- Code syntax
- Example execution
- Test suite
- CRAN policy compliance

**Expected output:**
```
── R CMD check results ── surveymixr 0.1.0 ────
Duration: 2m 30s

0 errors ✓ | 0 warnings ✓ | 0 notes ✓
```

### Step 4: Build Package

```r
# Build source package
devtools::build()

# Build binary package
devtools::build(binary = TRUE)
```

### Step 5: Install and Load

```r
devtools::install()
library(surveymixr)
```

## Testing Individual Components

### Test Data Simulation

```r
devtools::load_all()

# Simple simulation
sim1 <- simulate_gmm_survey(
  n_individuals = 200,
  n_times = 5,
  n_classes = 3,
  seed = 42
)

head(sim1)
table(sim1$true_class)

# With complex survey design
sim2 <- simulate_gmm_survey(
  n_individuals = 500,
  n_times = 4,
  n_classes = 2,
  design = "stratified_cluster",
  n_strata = 4,
  n_clusters = 50,
  seed = 123
)

table(sim2$stratum)
length(unique(sim2$psu))
```

### Test Basic Estimation

```r
# Fit 2-class model
fit2 <- gmm_survey(
  data = sim1,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 2,
  starts = 50,
  cores = 2,
  verbose = TRUE
)

# Check convergence
fit2@convergence_info$converged
fit2@convergence_info$n_replications

# View results
summary(fit2)
coef(fit2)
```

### Test Model Selection

```r
# Compare 1-4 classes (quick test)
selection <- gmm_select(
  data = sim1,
  id = "id",
  time = "time",
  outcome = "outcome",
  classes = 1:4,
  criteria = c("BIC", "entropy"),
  starts = 30,
  cores = 2,
  verbose = TRUE
)

print(selection)
```

### Test R3STEP

```r
# Fit 3-class model
fit3 <- gmm_survey(
  data = sim2,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 3,
  starts = 50,
  keep_data = TRUE  # Required for R3STEP
)

# Get unique rows (one per individual) with covariates
unique_data <- sim2[!duplicated(sim2$id), ]

# Add the covariates if they exist
if ("ses" %in% names(sim2)) {
  r3_results <- r3step(
    gmm_object = fit3,
    distal_vars = c("ses", "baseline_risk"),
    data = unique_data,
    method = "BCH"
  )

  summary(r3_results)
}
```

### Test Plotting

```r
# Trajectory plot
p1 <- plot_trajectories(fit3, include_ci = TRUE)
print(p1)

# Save to file
ggsave("trajectories.png", p1, width = 8, height = 6)

# Convergence plot
plot(fit3, type = "convergence")

# Model selection plot
if (exists("selection")) {
  p2 <- plot_model_selection(selection)
  print(p2)
}
```

### Test Diagnostics

```r
# Convergence diagnostics
diag <- diagnose_convergence(fit3, plot = TRUE)
print(diag)

# Classification quality
qual <- classification_quality(fit3)
print(qual$summary_by_class)

# Class proportions with CIs
props <- class_proportions(fit3, weighted = TRUE)
print(props)

# Entropy
ent <- entropy(fit3)
cat(sprintf("Entropy: %.3f\n", ent))
```

## Troubleshooting

### Issue: "there is no package called 'surveymixr'"

**Solution:** Use `devtools::load_all()` instead of `library(surveymixr)`, or run `devtools::install()` first.

### Issue: "could not find function 'X'"

**Solution:**
```r
devtools::document()  # Regenerate documentation
devtools::load_all()  # Reload package
```

### Issue: "Error in checkNamespace(package)"

**Solution:** Install missing dependencies:
```r
deps <- devtools::dev_package_deps()
install.packages(deps$package[deps$diff != 0])
```

### Issue: Tests fail with "object 'X' not found"

**Solution:** The package may not be fully loaded. Run:
```r
devtools::load_all()
devtools::test()
```

### Issue: "namespace 'surveymixr' is already loaded"

**Solution:** Restart R session or:
```r
detach("package:surveymixr", unload = TRUE)
devtools::load_all()
```

## Performance Testing

Test with realistic parameters:

```r
# Generate larger dataset
big_data <- simulate_gmm_survey(
  n_individuals = 1000,
  n_times = 6,
  n_classes = 3,
  seed = 999
)

# Time the estimation
system.time({
  fit_big <- gmm_survey(
    data = big_data,
    id = "id",
    time = "time",
    outcome = "outcome",
    n_classes = 3,
    starts = 100,
    cores = 4,
    verbose = TRUE
  )
})

# Expected: ~2-5 minutes with 100 starts on 4 cores
```

## Creating Example Data

The package needs the `mcs_simulated` dataset. Generate it:

```r
source("data-raw/create-mcs-simulated.R")

# This will create data/mcs_simulated.rda
# Then you can use it with:
data(mcs_simulated)
```

## Pre-CRAN Checklist

Before submitting to CRAN:

- [ ] `devtools::check()` passes with 0 errors, 0 warnings, 0 notes
- [ ] `devtools::test()` all tests pass
- [ ] Documentation complete (`devtools::document()`)
- [ ] Vignettes build successfully (`devtools::build_vignettes()`)
- [ ] Example data created and documented
- [ ] NEWS.md updated
- [ ] README.md accurate
- [ ] DESCRIPTION file complete
- [ ] All examples run (set `\dontrun{}` appropriately)
- [ ] Spell check (`devtools::spell_check()`)
- [ ] Test on multiple platforms (Windows, Mac, Linux)
- [ ] Check reverse dependencies (none initially)

## Getting Help

If you encounter issues:

1. Check R version: `R.version.string` (need ≥ 4.0.0)
2. Update devtools: `install.packages("devtools")`
3. Check package status: `devtools::dev_sitrep()`
4. View detailed errors: `devtools::check(error_on = "note")`

## Interactive Development Workflow

Typical workflow while developing:

```r
# 1. Edit code in R/*.R files

# 2. Reload package
devtools::load_all()

# 3. Test your changes
test_data <- simulate_gmm_survey(100, 4, 2)
fit <- gmm_survey(test_data, "id", "time", "outcome", n_classes = 2, starts = 10)

# 4. Run tests
devtools::test()

# 5. Update documentation
devtools::document()

# 6. Full check
devtools::check()

# 7. Repeat!
```

## Additional Resources

- **R Packages book**: https://r-pkgs.org/
- **devtools cheatsheet**: https://www.rstudio.com/resources/cheatsheets/
- **CRAN policies**: https://cran.r-project.org/web/packages/policies.html
- **Writing R Extensions**: https://cran.r-project.org/doc/manuals/R-exts.html
