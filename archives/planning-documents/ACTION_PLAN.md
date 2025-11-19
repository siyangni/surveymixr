# ACTION PLAN: surveymixr CRAN Preparation
**Priority-Ordered Tasks for CRAN Submission**

---

## 🔴 CRITICAL - DO THESE FIRST (Blocking CRAN)

### 1. Fix Numerical Stability in EM Algorithm ⚡ URGENT
**File:** `R/core-em-algorithm.R`
**Lines:** 221-224, 410-414
**Effort:** 8-12 hours

**Problem:**
```r
# CURRENT (BROKEN):
log_lik <- sum(dnorm(..., log = TRUE))
class_densities[i, k] <- exp(log_lik)  # ← Underflows!
```

**Fix:** Keep all E-step computations in log-space, use log-sum-exp trick

**Why Critical:** Produces incorrect results with T>8 time points (common in longitudinal studies)

**Test:** Add test with T=15 time points, validate against Mplus

---

### 2. Fix Vignette Build Failures 📚
**Files:** `vignettes/r3step-analysis.Rmd`, `vignettes/mplus-validation.Rmd`
**Effort:** 2-3 hours

**Problem:** Wrong parameter names (13 locations)

**Fix:**
```r
# WRONG:
r3step(fit, distal = "delinquency", method = "BCH")

# CORRECT:
person_data <- mcs_simulated[!duplicated(mcs_simulated$id), ]
r3step(fit, distal_vars = "delinquency", data = person_data, method = "BCH")
```

**Why Critical:** Vignettes won't build → immediate CRAN rejection

**Test:** `devtools::build_vignettes()`

---

### 3. Fix Test Coverage for Core Features 🧪
**Files:** `tests/testthat/test-convergence.R`, `tests/testthat/test-model-selection.R`
**Effort:** 4-6 hours

**Problem:**
- test-convergence.R: 100% skip_on_cran (EM convergence NEVER tested!)
- test-model-selection.R: 100% skip_on_cran (Model selection NEVER tested!)

**Fix:** Add lightweight tests that run on CRAN:
- n=100, starts=10, T=3 for convergence
- 2-3 classes max for model selection
- Keep expensive tests (starts=500, BLRT) as skip_on_cran

**Why Critical:** CRAN has no evidence core features work

---

### 4. Add Tests for Untested Features 🎯
**Effort:** 20-30 hours

**Create these test files:**
```
tests/testthat/test-random-effects.R        (8-12 tests)
tests/testthat/test-time-varying-covariates.R  (8-12 tests)
tests/testthat/test-diagnostics-advanced.R  (6-8 tests)
tests/testthat/test-plotting-interactive.R  (4-6 tests)
```

**Currently:** These functions are exported but have ZERO tests:
- `gmm_survey_re()`, `get_random_effects()`, `calculate_icc()`, `variance_components()`
- `gmm_survey_tvc()`, `extract_tvc_effects()`, `test_tvc_effects()`
- `diagnose_influence()`, `diagnose_separation()`, `residual_diagnostics()`
- `plot_interactive()`, `plot_model_selection_interactive()`

**Why Critical:** No evidence these work; users will hit untested code

---

### 5. Complete S4 Class Validation 🏗️
**Files:** `R/class-definitions.R`, `R/data-validation.R`, `R/diagnostics-advanced.R`, `R/random-effects.R`, `R/time-varying-covariates.R`
**Effort:** 8-12 hours

**Missing Validation Functions:**
- SurveyMixrSelect
- R3StepResults
- ConvergenceDiagnostics (also needs prototype & show method!)
- DataValidation
- InfluenceDiagnostics
- SurveyMixrRE (also needs prototype & show method!)
- SurveyMixrTVC (also needs prototype & show method!)

**Why Critical:** Objects can be created in invalid states → runtime errors

---

## ✅ VERIFICATION (Before Submission)

### Local Checks
```r
# 1. Load and document
devtools::load_all()
devtools::document()

# 2. Run all tests (MUST PASS)
devtools::test()
# Expected: ~90% pass, <25 skip_on_cran

# 3. Build vignettes (MUST SUCCEED)
devtools::build_vignettes()
# All 7 vignettes must build without errors

# 4. R CMD check (MUST BE 0/0/0 or 0/0/1)
devtools::check()
# Expected: 0 errors, 0 warnings, 0-1 notes

# 5. Check coverage (SHOULD BE >65%)
covr::package_coverage()
# Current: 63.91%, target: 70%+

# 6. Spell check
spelling::spell_check_package()
```

### Platform Testing
```bash
# 1. Push to GitHub
git push origin main

# 2. Monitor GitHub Actions
# https://github.com/siyangni/surveymixr/actions
# Must pass: macOS, Windows, Linux × R-devel/release/oldrel

# 3. Win-builder
# In R:
devtools::check_win_devel()
devtools::check_win_release()

# 4. R-hub (optional but recommended)
rhub::check_for_cran()
```

---

## 🟠 HIGH PRIORITY (Recommended Pre-CRAN)

### 6. Fix Reproducibility Issue
**File:** `R/core-em-algorithm.R:143`
**Effort:** 2-3 hours

**Problem:**
```r
set.seed(sample.int(1e6, 1))  # Random seed defeats reproducibility!
```

**Fix:** Accept optional seed parameter, don't randomize

---

### 7. Add Input Validation
**Files:** All exported functions
**Effort:** 6-8 hours

**Add checks for:**
- Valid data types (matrix, data.frame, numeric, etc.)
- Positive integers where required
- Required columns exist
- Reasonable parameter ranges

---

### 8. Fix Unused Parameters (Misleading API)
**File:** `R/core-em-algorithm.R:29-30`
**Effort:** 2-4 hours

**Problem:** `strata` and `cluster` parameters accepted but never used

**Options:**
1. Use them in EM algorithm (principled but complex)
2. Remove and document that survey design only affects SEs

---

### 9. Fix/Document Free Basis Model
**File:** `R/core-em-algorithm.R:307-316`
**Effort:** 1 hour (error) OR 20+ hours (implement)

**Current:** Silently falls back to linear model

**Quick Fix:**
```r
} else if (growth_model == "free_basis") {
  stop("free_basis model not yet implemented. Use 'linear' or 'quadratic'.")
}
```

---

### 10. Document Partial Implementations
**Files:** `man/gmm_survey_re.Rd`, `man/gmm_survey_tvc.Rd`
**Effort:** 2-3 hours

**Add to @details:**
```
Warning: This function is currently in beta and has a partial implementation.
Testing is ongoing. Use with caution and report issues.
```

---

## 📊 SUCCESS CRITERIA

### Must Have (CRAN Acceptance)
- [ ] ✅ Vignettes build successfully
- [ ] ✅ R CMD check: 0 errors, 0 warnings, 0-1 notes
- [ ] ✅ All platforms pass CI/CD
- [ ] ✅ At least 50% of tests run on CRAN
- [ ] ✅ No numerical stability issues
- [ ] ✅ All S4 classes have validation

### Should Have (Quality)
- [ ] 🎯 Test coverage ≥70%
- [ ] 🎯 All exported functions tested
- [ ] 🎯 Reproducible results (seed handling)
- [ ] 🎯 Good input validation
- [ ] 🎯 Clear documentation of limitations

### Nice to Have (Polish)
- [ ] 💎 Performance optimizations
- [ ] 💎 Code organization improvements
- [ ] 💎 Better error messages
- [ ] 💎 Additional examples

---

## ⏱️ ESTIMATED TIMELINE

### Fast Track (Critical Only)
**Time:** 40-50 hours (~1-2 weeks full-time)
**Risk:** Medium - minimal fixes, some rough edges
**Ready:** For CRAN but with known limitations

### Recommended (Critical + High Priority)
**Time:** 60-80 hours (~2-3 weeks full-time)
**Risk:** Low - solid submission
**Ready:** For CRAN with confidence

### Comprehensive (All High + Medium)
**Time:** 80-100 hours (~3-4 weeks full-time)
**Risk:** Very Low - polished package
**Ready:** For CRAN, users, and future development

---

## 🚀 QUICK START

### Day 1: Setup
1. Pull this branch with analysis reports
2. Review `COMPREHENSIVE_REPO_ANALYSIS.md` (detailed findings)
3. Set up local R environment for testing
4. Run initial checks to establish baseline

### Day 2-3: Vignettes & Tests
1. Fix vignette code (2-3 hours)
2. Fix test skip_on_cran issues (4-6 hours)
3. Verify vignettes build
4. Verify tests pass

### Day 4-7: EM Algorithm
1. Fix numerical stability (8-12 hours)
2. Add test with T=15
3. Validate against existing tests
4. Profile performance (optional)

### Day 8-14: Testing
1. Add random effects tests (8-12 hours)
2. Add TVC tests (8-12 hours)
3. Add advanced diagnostics tests (6-8 hours)
4. Add plotting tests (4-6 hours)

### Day 15-18: S4 Classes
1. Add validation functions (6-8 hours)
2. Add prototypes (2-3 hours)
3. Add show methods (2-3 hours)
4. Test object creation/display

### Day 19-21: Final Checks
1. Run all verification steps
2. Monitor CI/CD
3. Run win-builder
4. Address any issues
5. **Submit to CRAN!**

---

## 📞 DECISION POINTS

### Decision 1: Scope
**Question:** Include partial implementations (RE, TVC) or defer to v0.3.0?

**Option A:** Include with warnings (tests required)
- Pro: More features for users
- Con: More testing burden, potential bugs

**Option B:** Remove from CRAN release, defer to v0.3.0
- Pro: Cleaner release, less risk
- Con: Reduced functionality

**Recommendation:** Include with clear warnings if tests added; otherwise defer

---

### Decision 2: Performance
**Question:** Fix performance issues now or post-CRAN?

**Option A:** Fix now (vectorize E-step)
- Pro: Better user experience
- Con: 12-16 hours additional work, some risk

**Option B:** Fix after CRAN acceptance
- Pro: Faster to submission
- Con: Users may complain about speed

**Recommendation:** Post-CRAN (v0.2.2) unless time available

---

### Decision 3: Timeline
**Question:** When to submit?

**Option A:** Fast track (1-2 weeks)
- Critical fixes only
- Some rough edges
- Quick to submission

**Option B:** Recommended (2-3 weeks)
- Critical + high priority
- Solid quality
- Confident submission

**Option C:** Comprehensive (3-4 weeks)
- All improvements
- Polished package
- Maximum quality

**Recommendation:** Option B (2-3 weeks) for best risk/reward

---

## 📋 CHECKLIST

Print this and check off as you go:

### Critical Fixes
- [ ] Numerical stability in EM fixed
- [ ] Vignette code updated (13 locations)
- [ ] Test skip_on_cran reduced (convergence, model selection)
- [ ] Random effects tests added (8-12 tests)
- [ ] Time-varying covariates tests added (8-12 tests)
- [ ] Advanced diagnostics tests added (6-8 tests)
- [ ] Interactive plotting tests added (4-6 tests)
- [ ] S4 validation functions added (7 classes)
- [ ] S4 prototypes added (5 classes)
- [ ] S4 show methods added (3 classes)

### Verification
- [ ] devtools::load_all() works
- [ ] devtools::document() runs clean
- [ ] devtools::test() passes (>90%)
- [ ] devtools::build_vignettes() succeeds
- [ ] devtools::check() returns 0/0/0 or 0/0/1
- [ ] covr::package_coverage() ≥65%
- [ ] spelling::spell_check_package() clean
- [ ] GitHub Actions all green
- [ ] Win-builder passes
- [ ] R-hub passes (optional)

### High Priority (Optional)
- [ ] Reproducibility fix (random seed)
- [ ] Input validation added
- [ ] Unused parameters fixed/documented
- [ ] Free basis model documented
- [ ] Partial implementations documented

### Ready for CRAN
- [ ] All critical fixes complete
- [ ] All verification passed
- [ ] cran-comments.md updated
- [ ] NEWS.md updated
- [ ] Confident in submission

---

## 🆘 NEED HELP?

### Resources
- **Detailed Analysis:** `COMPREHENSIVE_REPO_ANALYSIS.md`
- **Agent Reports:** In analysis section of this review
- **CRAN Policies:** https://cran.r-project.org/web/packages/policies.html
- **R Packages Book:** https://r-pkgs.org/

### Common Issues
1. **Test failures:** Check test files, may need data updates
2. **Check warnings:** Usually documentation or example issues
3. **Vignette errors:** Check package dependencies in vignette YAML
4. **Platform failures:** May need platform-specific skip()

---

**Created:** 2025-11-18
**Status:** Ready to execute
**Target:** CRAN submission in 2-3 weeks
