# Troubleshooting Guide for surveymixr

This guide helps you diagnose and resolve common issues when using the `surveymixr` package.

## Table of Contents

1. [Convergence Issues](#convergence-issues)
2. [Standard Error Issues](#standard-error-issues)
3. [Model Selection Issues](#model-selection-issues)
4. [Performance and Memory Issues](#performance-and-memory-issues)
5. [Classification Issues](#classification-issues)
6. [R3STEP Issues](#r3step-issues)
7. [Survey Design Issues](#survey-design-issues)
8. [Common Error Messages](#common-error-messages)

---

## Convergence Issues

### Issue: Model Won't Converge

**Symptoms:**
- Model runs until maximum iterations
- Log-likelihood changes very little between iterations
- Warning: "Did not converge within max iterations"

**Solutions:**

1. **Increase random starts**
   ```r
   # Increase from default 500 to 1000+
   gmm_survey(..., starts = 1000)
   ```

2. **Increase maximum iterations**
   ```r
   gmm_survey(..., maxit = 1000)
   ```

3. **Simplify the model**
   - Reduce number of classes
   - Use simpler growth model (linear instead of quadratic)
   - Remove covariates initially

4. **Check for class separation**
   ```r
   diagnose_separation(fit)
   ```
   If separation is poor, classes may be too similar.

5. **Check data quality**
   ```r
   validate_survey_data(data)
   ```

6. **Try different starting values**
   ```r
   gmm_survey(..., fix_starts = FALSE)  # Random starting values each time
   ```

---

## Standard Error Issues

### Issue: NA or Very Large Standard Errors

**Symptoms:**
- Standard errors are `NA`
- Standard errors are extremely large (e.g., > 1000)
- "Non-positive definite matrix" warning

**Solutions:**

1. **Check survey design specification**
   - Ensure `strata` nests `cluster`
   - Verify clusters are correctly identified
   - Check for single-PSU strata

2. **Increase sample size**
   - Complex survey designs need larger samples
   - Minimum N > 200-300 for stable SEs

3. **Check for singularity issues**
   ```r
   diagnose_influence(fit)
   ```
   Remove or investigate influential cases.

4. **Simplify covariance structure**
   ```r
   # Use simpler random effects structure
   gmm_survey_re(..., re_params = "intercept")
   ```

5. **Check for perfect prediction**
   - Some parameters may be at boundaries
   - Consider reducing model complexity

---

## Model Selection Issues

### Issue: Can't Decide on Number of Classes

**Symptoms:**
- Different criteria suggest different solutions
- BLRT is non-significant but entropy is good
- BIC keeps decreasing with more classes

**Solutions:**

1. **Use multiple criteria together**
   ```r
   # Focus on convergence of evidence, not single criterion
   plot(selection)  # Visualize all criteria
   ```

2. **Consider substantive interpretation**
   - Do classes make theoretical sense?
   - Can you name each class meaningfully?
   - Are class proportions reasonable (>5%)?

3. **Check classification quality**
   ```r
   classification_quality(fit)
   ```
   - Entropy > 0.70 is good
   - Average posterior probability > 0.80 is good

4. **LMR vs BLRT**
   - Use LMR for quick exploration (faster)
   - Use BLRT for final decisions (more accurate)
   - With large N, both should agree

5. **Bootstrap Likelihood Ratio Test (BLRT)**
   ```r
   gmm_select(..., criteria = "BLRT", blrt_samples = 100)
   ```
   - More reliable than LMR for small samples
   - Takes 10-100x longer

---

## Performance and Memory Issues

### Issue: Running Out of Memory

**Symptoms:**
- R crashes or freezes
- "Cannot allocate vector of size..." error
- System becomes unresponsive

**Solutions:**

1. **Don't store full dataset in results**
   ```r
   gmm_survey(..., store_data = FALSE)  # Saves memory
   ```

2. **Reduce random starts**
   ```r
   # Use fewer starts for initial exploration
   gmm_survey(..., starts = 200)  # Instead of 500+
   ```

3. **Sequential processing**
   ```r
   gmm_survey(..., cores = 1)  # Lower memory footprint
   ```

4. **Subset data during exploration**
   ```r
   # Work with subset while refining model
   data_subset <- data[data$id %in% unique(data$id)[1:1000], ]
   ```

5. **Monitor memory usage**
   ```r
   library(profvis)
   profvis({ fit <- gmm_survey(...) })
   ```

### Issue: Too Slow

**Solutions:**

1. **Use parallel processing**
   ```r
   gmm_survey(..., cores = detectCores() - 1)
   ```

2. **Fewer BLRT samples**
   ```r
   gmm_select(..., blrt_samples = 50)  # Instead of 100+
   ```

3. **Increase tolerance (slightly)**
   ```r
   gmm_survey(..., tol = 1e-5)  # Default is 1e-6
   ```

4. **Use LMR instead of BLRT for exploration**
   ```r
   # LMR is 10-100x faster
   lmr_sequential(...)
   ```

5. **Consider model complexity**
   - Simpler models fit faster
   - Linear growth is faster than quadratic
   - Fewer classes = faster

---

## Classification Issues

### Issue: Poor Classification Quality

**Symptoms:**
- Entropy < 0.60
- Average posterior probability < 0.70
- Many individuals have uncertain classification (posterior near 0.33 for 3 classes)

**Solutions:**

1. **Check if number of classes is correct**
   ```r
   # Try 2 classes
   fit_2class <- gmm_survey(..., n_classes = 2)
   classification_quality(fit_2class)

   # Try 4 classes
   fit_4class <- gmm_survey(..., n_classes = 4)
   classification_quality(fit_4class)
   ```

2. **Add covariates**
   - Covariates can improve class separation
   - But may change class interpretation

3. **Check for boundary classes**
   - Class with < 5% of sample may be unnecessary
   - Consider merging similar classes

4. **Check data quality**
   - Insufficient measurement occasions?
   - High measurement error?

---

## R3STEP Issues

### Issue: "Error: Column not found"

**Symptoms:**
- Error: "delinquency" not found in data
- Data format mismatch

**Solutions:**

1. **Ensure variables exist in data**
   ```r
   # Check what variables are available
   names(person_data)
   ```

2. **Create person-level data correctly**
   ```r
   # Extract one row per person
   person_data <- long_data[!duplicated(long_data$id), ]
   ```

3. **Check variable types**
   ```r
   # Binary distal needs to be 0/1
   # Categorical needs to be factor
   str(person_data$distal_var)
   ```

### Issue: "Invalid distal outcome type"

**Symptoms:**
- R3STEP doesn't recognize outcome type
- Need to specify distal_type

**Solutions:**

```r
# Specify type explicitly
r3_result <- r3step(
  gmm_object = fit,
  distal_vars = "high_delinquency",
  data = person_data,
  distal_type = "binary",  # "continuous", "binary", "ordinal"
  method = "BCH"
)
```

---

## Survey Design Issues

### Issue: "Strata must nest clusters"

**Symptoms:**
- Error about nesting structure
- Standard errors seem wrong

**Solutions:**

1. **Check nesting structure**
   ```r
   # Verify each cluster belongs to only one stratum
   with(data, table(stratum, cluster))
   if (any(table(stratum, cluster) > 1)) {
     stop("Clusters must be completely nested in strata")
   }
   ```

2. **Check for singleton strata**
   ```r
   # Some strata may have only 1 cluster
   # Consider collapsing small strata
   ```

3. **Ensure each stratum has >= 2 PSUs**
   ```r
   strata_counts <- table(data$stratum)
   if (any(strata_counts < 2)) {
     warning("Some strata have < 2 PSUs - SEs may be unstable")
   }
   ```

### Issue: Weights Don't Sum to Population Size

**Symptoms:**
- Warning about weight scaling
- Estimates seem off

**Solutions:**

`surveymixr` normalizes weights automatically. Check:

1. **Are weights correct?**
   ```r
   # Check weight distribution
   summary(data$weight)
   ```

2. **Missing weights**
   - If missing for some cases, those cases are excluded
   - Better to have weight = 1 than NA

3. **Extreme weights**
   - Check CV of weights
   - CV > 5 may indicate issues

---

## Common Error Messages

### "subscript out of bounds"

**Cause:** Trying to access a class that doesn't exist

**Solution:**
```r
# Check number of classes
fit@n_classes

# Access results properly
fit@parameters$means  # Not fit@parameters$means[[4]] if only 3 classes
```

### "non-conformable arguments"

**Cause:** Dimension mismatch in matrix operations

**Solutions:**
- Check that input data is correctly formatted
- Ensure ID variable uniquely identifies individuals
- Verify no duplicate time points per person

### "NA/NaN/Inf in foreign function call"

**Cause:** Numerical instability

**Solutions:**
- Check for extreme values in data
- Standardize variables if needed
- Increase random starts
- Simplify model

### "object 'X' not found"

**Cause:** Variable not in data

**Solutions:**
```r
# Check for typos
names(data)  # Verify exact variable names
# R is case-sensitive!
```

### "argument is of length zero"

**Cause:** Empty results or failed computation

**Solutions:**
- Check if model converged
- Verify sufficient sample size
- Ensure enough time points per person

### "cannot allocate vector of size"

**Cause:** Memory issues

**Solutions:**
- See "Performance and Memory Issues" above
- Close other applications
- Use subset of data
- Restart R with more memory

---

## Getting More Help

### Diagnostic Functions

```r
# Check convergence quality
diagnose_convergence(fit)

# Check for influential cases
diagnose_influence(fit)

# Check class separation
diagnose_separation(fit)

# Check classification quality
classification_quality(fit)

# Residual diagnostics
residual_diagnostics(fit)
```

### Where to Get Help

1. **Check documentation**
   ```r
   ?gmm_survey
   vignette("user-manual")
   ```

2. **Check examples**
   ```r
   example(gmm_survey)
   ```

3. **GitHub Issues**
   - Report bugs: https://github.com/siyangni/surveymixr/issues
   - Search existing issues

4. **CRAN page** (when available)
   - Check for known issues
   - Review package NEWS

---

## Preventing Issues

### Before Analysis

1. **Validate data**
   ```r
   validate_survey_data(data)
   ```

2. **Check measurement schedule**
   ```r
   # Check time points per person
   table(data$id, data$time)
   ```

3. **Check missing data**
   - FIML handles missing automatically
   - But check missing patterns

### During Analysis

1. **Start simple**
   - 2-3 classes first
   - Linear growth before quadratic

2. **Increase complexity gradually**
   - Add classes one at a time
   - Add covariates sequentially

3. **Always check convergence**
   - Multiple random starts
   - Check for local maxima

### Before Publication

1. **Replicate analysis**
   - Set seed for reproducibility
   - Test on subset of data

2. **Check robustness**
   - Different starting values
   - Different numbers of starts
   - With and without survey design

3. **Document everything**
   - Seed used
   - Number of random starts
   - Convergence criteria met
   - Model selection approach

---

*Last updated: 2025-11-19*
