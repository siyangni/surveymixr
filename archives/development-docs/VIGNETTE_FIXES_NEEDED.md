# Vignette Code Fixes Required

This document lists issues found in vignette code that need to be fixed before the vignettes can build successfully.

## Critical Issues

### 1. r3step-analysis.Rmd

**Issue**: Uses incorrect parameter name throughout

**Current (incorrect)**:
```r
r3_result <- r3step(gmm_fit, distal = "delinquency", method = "BCH")
```

**Should be**:
```r
r3_result <- r3step(gmm_fit, distal_vars = "delinquency", data = mcs_simulated, method = "BCH")
```

**Additional issue**: r3step requires person-level data (one row per individual), but mcs_simulated is in long format.

**Complete fix needed**:
```r
# Since mcs_simulated is in long format, create person-level data
# Assuming 'delinquency' is a time-invariant variable
person_data <- mcs_simulated[!duplicated(mcs_simulated$id), ]

r3_result <- r3step(
  gmm_object = gmm_fit,
  distal_vars = "delinquency",
  data = person_data,
  method = "BCH"
)
```

**Lines to fix**: 85, 111, 142, 157, 265, 304, 328, 402, 415, 478, 479, 500, 506

**Action**: Global search and replace in r3step-analysis.Rmd:
- Replace `distal =` with `distal_vars =`
- Add `, data = person_data` parameter
- Add code to create `person_data` before first r3step call

---

### 2. model-selection-enhanced.Rmd

**Issue**: May reference LMR in criteria but LMR might not be implemented in gmm_select

**Line 92**:
```r
criteria = c("BIC", "aBIC", "entropy", "BLRT", "LMR"),  # NEW in v0.2.0
```

**Action**: Verify if LMR is actually implemented in gmm_select. If not, remove from example or mark as TODO.

---

### 3. Data Inconsistency

**Issue**: Vignettes assume `mcs_simulated` has certain variables (delinquency, academic_achievement) that may not exist.

**Action**: Check mcs_simulated dataset structure:
```r
data(mcs_simulated)
names(mcs_simulated)
str(mcs_simulated)
```

**Recommendation**:
- Either update mcs_simulated to include these variables
- Or use variables that actually exist in the dataset
- Or simulate additional variables in vignette setup chunk

---

## Testing Recommendations

Before building vignettes, test each code chunk individually:

```r
# Test r3step vignette
library(surveymixr)
data(mcs_simulated)

# Check data structure
str(mcs_simulated)
unique_ids <- length(unique(mcs_simulated$id))
total_rows <- nrow(mcs_simulated)
cat("Dataset has", total_rows, "rows and", unique_ids, "unique individuals\n")
cat("Variables:", paste(names(mcs_simulated), collapse = ", "), "\n")

# Verify long format
if (total_rows > unique_ids) {
  cat("Data is in LONG format (multiple rows per person)\n")
} else {
  cat("Data is in WIDE format (one row per person)\n")
}

# Test if person-level extraction works
if ("ses" %in% names(mcs_simulated)) {
  person_data <- mcs_simulated[!duplicated(mcs_simulated$id), ]
  cat("Successfully extracted", nrow(person_data), "person-level observations\n")
}
```

---

## Build Testing

Cannot test vignette building without R installed, but recommended workflow:

```r
# Local testing
devtools::build_vignettes()

# Or test individual vignettes
rmarkdown::render("vignettes/r3step-analysis.Rmd")
rmarkdown::render("vignettes/model-selection-enhanced.Rmd")
```

---

## Priority

**High Priority** (will cause vignette build to fail):
1. Fix r3step parameter names in r3step-analysis.Rmd
2. Add person-level data creation in r3step-analysis.Rmd
3. Verify mcs_simulated has required variables

**Medium Priority** (may cause errors):
1. Verify LMR is implemented in gmm_select
2. Check cluster vs psu variable naming consistency

**Low Priority** (cosmetic):
1. Update comments to reflect current implementation
2. Add notes about FIML for missing data

---

## Status

- [ ] r3step-analysis.Rmd parameter fixes
- [ ] r3step-analysis.Rmd data format fixes
- [ ] model-selection-enhanced.Rmd LMR verification
- [ ] mcs_simulated dataset verification
- [ ] Test vignette building locally
- [ ] Update vignette index if needed
