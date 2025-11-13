# surveymixr Feature Addition Roadmap
## Specific New Functions and Enhancements by Domain

This document details **concrete new features** to add to surveymixr, organized by statistical/methodological domain. Each feature includes the function name, purpose, and priority.

---

## 1. OUTCOME TYPES (Priority: HIGH)

### 1.1 Binary Outcomes
**Status**: Mentioned but not fully implemented

#### New Functions
```r
gmm_survey_binary(
  data,
  id,
  time,
  outcome,
  n_classes,
  link = c("logit", "probit"),
  ...
)
```
**Purpose**: Logistic/probit growth mixture models
**Use Cases**: Substance use initiation, dropout, recidivism
**Implementation**: ~400 lines

```r
simulate_gmm_binary(
  n = 1000,
  n_classes = 2,
  time_points = 5,
  ...
)
```
**Purpose**: Simulate binary trajectory data
**Use Cases**: Testing, validation, power analysis

### 1.2 Ordinal Outcomes
```r
gmm_survey_ordinal(
  data,
  id,
  time,
  outcome,
  n_classes,
  n_levels,  # Number of ordinal categories
  link = "probit",
  ...
)
```
**Purpose**: Ordered categorical outcomes (e.g., Likert scales)
**Use Cases**: Severity ratings, educational achievement levels
**Implementation**: ~500 lines (complex thresholds)

### 1.3 Count Outcomes
```r
gmm_survey_count(
  data,
  id,
  time,
  outcome,
  n_classes,
  distribution = c("poisson", "negbin", "zip", "zinb"),
  offset = NULL,
  ...
)
```
**Purpose**: Count data with potential zero-inflation
**Use Cases**: Arrests, hospitalizations, substance use frequency
**Features**:
- Poisson regression
- Negative binomial (overdispersion)
- Zero-inflated models
- Offset for exposure time

---

## 2. MODEL SELECTION METHODS (Priority: HIGH)

### 2.1 Lo-Mendell-Rubin Test
```r
lmr_test(
  model_k,      # k-class model
  model_k_minus_1,  # (k-1)-class model
  adjusted = TRUE
)
```
**Purpose**: Asymptotic LRT for class enumeration
**Advantage**: Much faster than BLRT (no bootstrap)
**Returns**: Test statistic, p-value, recommendation

### 2.2 Bayes Factor
```r
bayes_factor(
  model1,
  model2,
  method = c("BIC", "laplace")
)

bf_interpretation(bf_value)
```
**Purpose**: Bayesian model comparison
**Returns**: BF value, evidence strength, interpretation

### 2.3 Cross-Validation
```r
cv_gmm(
  data,
  id,
  time,
  outcome,
  n_classes,
  k_folds = 10,
  repeats = 5,
  metric = c("mse", "mae", "loglik")
)
```
**Purpose**: Out-of-sample prediction accuracy
**Returns**: CV metrics, optimal model
**Implementation**: Proper survey design handling in folds

### 2.4 Elbow Detection
```r
find_elbow(
  fit_indices,
  criterion = "BIC",
  method = c("menger", "dfdt")
)

plot_elbow(
  comparison_table,
  criterion = "BIC",
  highlight_optimal = TRUE
)
```
**Purpose**: Automated elbow detection in scree plots
**Methods**: Menger curvature, derivative-based

---

## 3. DIAGNOSTIC FUNCTIONS (Priority: MEDIUM-HIGH)

### 3.1 Influential Cases
```r
influence_diagnostics(
  fitted_model,
  measures = c("cooks_d", "dfbetas", "leverage")
)

plot_influence(fitted_model)
```
**Purpose**: Identify observations influencing class assignment
**Features**: Survey-weighted Cook's D, case deletion diagnostics

### 3.2 Residual Analysis
```r
residuals.SurveyMixr(
  object,
  type = c("raw", "standardized", "studentized")
)

residual_diagnostics(
  fitted_model,
  plots = c("qq", "fitted", "autocorr")
)
```
**Purpose**: Model checking through residuals
**Plots**: Q-Q plots, residuals vs fitted, autocorrelation

### 3.3 Separation Detection
```r
diagnose_separation(
  fitted_model,
  threshold = 0.95
)
```
**Purpose**: Detect perfect/quasi-perfect class separation
**Returns**: Warnings, problematic observations, recommendations

### 3.4 Parameter Stability
```r
parameter_stability(
  fitted_model,
  bootstrap_samples = 100
)

plot_parameter_stability(result)
```
**Purpose**: Bootstrap-based parameter stability analysis
**Returns**: Parameter distributions, stability indices

### 3.5 Local Maxima Analysis (Enhancement)
```r
# Enhanced version of existing diagnose_convergence()
local_maxima_analysis(
  fitted_model,
  cluster_threshold = 0.01,
  visualize = TRUE
)
```
**Purpose**: Better identification and handling of local maxima
**Features**: Clustering of solutions, recommendations

---

## 4. ADVANCED GROWTH MODELS (Priority: MEDIUM)

### 4.1 Piecewise Growth
```r
gmm_survey_piecewise(
  data,
  id,
  time,
  outcome,
  n_classes,
  knots = c(10, 15),  # Ages where slope changes
  ...
)
```
**Purpose**: Different growth rates in different periods
**Use Cases**: Pre/post intervention, developmental periods

### 4.2 Nonlinear Growth Functions
```r
gmm_survey_nonlinear(
  data,
  id,
  time,
  outcome,
  n_classes,
  growth_function = c("exponential", "logistic", "gompertz"),
  ...
)
```
**Purpose**: Non-polynomial growth patterns
**Functions**:
- Exponential: Y = a × exp(b × time)
- Logistic: Y = a / (1 + exp(-b × (time - c)))
- Gompertz: Y = a × exp(-b × exp(-c × time))

### 4.3 Spline-Based Growth
```r
gmm_survey_spline(
  data,
  id,
  time,
  outcome,
  n_classes,
  df = 4,  # Degrees of freedom
  knots = NULL,  # Auto-select or specify
  ...
)
```
**Purpose**: Flexible smooth trajectories
**Features**: Natural splines, B-splines, penalized splines

### 4.4 Parallel Process Models
```r
gmm_survey_parallel(
  data,
  id,
  time,
  outcomes = list(
    outcome1 = list(variable = "depression", model = "linear"),
    outcome2 = list(variable = "anxiety", model = "quadratic")
  ),
  n_classes,
  correlation = TRUE,  # Cross-outcome correlations
  ...
)
```
**Purpose**: Multiple outcomes simultaneously
**Returns**: Joint class membership, cross-process correlations

---

## 5. RANDOM EFFECTS (Priority: MEDIUM-HIGH)

### 5.1 Random Intercepts and Slopes
```r
gmm_survey(
  ...,
  random = ~ 1 + time,  # Random intercept and slope
  random_var_equal = FALSE  # Allow class-specific variances
)
```
**Enhancement**: Add to existing gmm_survey()
**Returns**: Variance components, ICCs, random effect predictions

### 5.2 Extract Random Effects
```r
ranef(fitted_model)  # Random effects
coef(fitted_model, random = TRUE)  # Fixed + random
```
**Purpose**: Extract individual-level deviations

### 5.3 Variance Component Tests
```r
test_random_effects(
  fitted_model,
  component = c("intercept", "slope", "both")
)
```
**Purpose**: Test significance of random effects

---

## 6. COVARIATE METHODS (Priority: MEDIUM)

### 6.1 Time-Varying Covariates (Enhancement)
```r
gmm_survey(
  ...,
  tvc = ~ ses + peer_influence,
  tvc_effects = c("direct", "indirect", "both"),
  tvc_interactions = TRUE  # Interactions with class
)
```
**Enhancement**: Better testing and documentation
**Features**: Direct effects on Y, indirect on growth parameters

### 6.2 Covariate Selection
```r
select_covariates(
  data,
  id,
  time,
  outcome,
  n_classes,
  candidates = c("ses", "gender", "ethnicity"),
  method = c("forward", "backward", "stepwise", "lasso")
)
```
**Purpose**: Automated covariate selection
**Methods**: Traditional stepwise, regularization-based

### 6.3 Effect Decomposition
```r
decompose_effects(
  fitted_model,
  covariate = "ses",
  components = c("direct", "indirect", "total")
)
```
**Purpose**: Mediation-style effect decomposition

---

## 7. REGULARIZATION (Priority: MEDIUM)

### 7.1 LASSO Penalization
```r
gmm_survey_lasso(
  data,
  id,
  time,
  outcome,
  covariates,
  n_classes,
  lambda = "cv.min",  # Cross-validated
  alpha = 1,  # 1=LASSO, 0=Ridge
  ...
)
```
**Purpose**: Automatic variable selection
**Features**: Class-specific penalties, stability selection

### 7.2 Fused LASSO
```r
gmm_survey_fused_lasso(
  ...,
  fuse_adjacent_classes = TRUE
)
```
**Purpose**: Merge similar classes automatically
**Advantage**: Data-driven class enumeration

---

## 8. MULTILEVEL EXTENSIONS (Priority: MEDIUM-LOW)

### 8.1 Three-Level Models
```r
gmm_survey_multilevel(
  data,
  id,
  time,
  outcome,
  level2 = "school",  # Students in schools
  level3 = "district",  # Schools in districts
  n_classes,
  ...
)
```
**Purpose**: Nested data structures
**Use Cases**: Students in schools, patients in hospitals

### 8.2 Cross-Classified Models
```r
gmm_survey_crossclass(
  data,
  id,
  time,
  outcome,
  cross1 = "neighborhood",
  cross2 = "school",
  ...
)
```
**Purpose**: Non-hierarchical nesting

---

## 9. MISSING DATA (Priority: MEDIUM)

### 9.1 MNAR Sensitivity Analysis
```r
mnar_sensitivity(
  fitted_model,
  scenarios = list(
    optimistic = list(delta = -0.5),
    pessimistic = list(delta = 0.5)
  )
)
```
**Purpose**: Test robustness to MNAR assumptions
**Method**: Pattern-mixture models, delta adjustment

### 9.2 Multiple Imputation Interface
```r
gmm_survey_mi(
  imputed_data_list,  # From mice or Amelia
  id,
  time,
  outcome,
  n_classes,
  pool = TRUE,  # Combine results
  ...
)
```
**Purpose**: Work with multiply imputed datasets
**Features**: Rubin's rules for combining

### 9.3 Missing Pattern Diagnostics
```r
diagnose_missingness(
  data,
  variables = c("outcome", "covariates"),
  tests = c("mcar", "mar_vs_mnar")
)

plot_missing_patterns(data)
```
**Purpose**: Understand missing data mechanisms
**Tests**: Little's MCAR test, pattern visualization

---

## 10. SURVIVAL EXTENSIONS (Priority: LOW-MEDIUM)

### 10.1 Growth-Survival Models
```r
gmm_survey_survival(
  data,
  id,
  time,
  outcome,  # Longitudinal outcome
  event_time,  # Time to event
  event_status,  # Censoring indicator
  n_classes,
  distribution = c("exponential", "weibull", "cox"),
  ...
)
```
**Purpose**: Joint modeling of trajectories and time-to-event
**Use Cases**: Trajectories predicting mortality, dropout

### 10.2 Competing Risks
```r
gmm_survey_comprisk(
  ...,
  event_type,  # Type of event (1, 2, ...)
  risks = c("death", "dropout", "completion")
)
```
**Purpose**: Multiple event types
**Features**: Cumulative incidence, cause-specific hazards

---

## 11. CAUSAL INFERENCE (Priority: MEDIUM)

### 11.1 Propensity Score Integration
```r
gmm_survey_ps(
  data,
  id,
  time,
  outcome,
  treatment,
  confounders,
  n_classes,
  ps_method = c("logit", "grf", "gbm"),
  combine_weights = TRUE,  # Survey × PS weights
  ...
)
```
**Purpose**: Causal effect heterogeneity by class
**Features**: Double-robust estimation

### 11.2 Instrumental Variables
```r
gmm_survey_iv(
  data,
  id,
  time,
  outcome,
  endogenous,
  instruments,
  n_classes,
  ...
)
```
**Purpose**: Address endogeneity in growth models

### 11.3 Difference-in-Differences
```r
gmm_survey_did(
  data,
  id,
  time,
  outcome,
  treatment,
  treatment_time,
  n_classes,
  ...
)

# Extract class-specific treatment effects
cate(fitted_did_model)  # Conditional average treatment effects
```
**Purpose**: Treatment effect heterogeneity
**Features**: Parallel trends testing by class

---

## 12. VISUALIZATION ENHANCEMENTS (Priority: MEDIUM)

### 12.1 Interactive Plots
```r
plot_trajectories_interactive(
  fitted_model,
  type = "plotly",
  include_ci = TRUE
)
```
**Purpose**: Hover, zoom, pan capabilities
**Package**: plotly

### 12.2 Spaghetti Plots
```r
plot_spaghetti(
  fitted_model,
  n_sample = 100,  # Subsample for clarity
  alpha = 0.2,
  color_by_class = TRUE
)
```
**Purpose**: Individual trajectories overlaid

### 12.3 Sankey Diagrams
```r
plot_classification_sankey(
  model1,
  model2,
  model3  # Compare across models
)
```
**Purpose**: Cross-classification flow diagrams

### 12.4 Posterior Probability Plots
```r
plot_posterior_probs(
  fitted_model,
  type = c("histogram", "density", "boxplot"),
  by_class = TRUE
)
```
**Purpose**: Visualize classification uncertainty

### 12.5 Publication Themes
```r
plot_trajectories(
  ...,
  theme = "apa",  # APA style
  grayscale = TRUE,
  font_size = 12
)

# Or custom theme
theme_publication <- function() {
  theme_bw() +
  theme(...)
}
```
**Purpose**: Journal-ready figures

### 12.6 Model Comparison Plots
```r
plot_model_comparison(
  list(model1, model2, model3),
  criteria = c("BIC", "entropy", "AvePP"),
  layout = "grid"
)
```
**Purpose**: Side-by-side model comparison

---

## 13. DATA UTILITIES (Priority: MEDIUM)

### 13.1 Survey Design Validation
```r
validate_survey_design(
  data,
  strata,
  cluster,
  weights,
  checks = c("uniqueness", "nesting", "range", "missing")
)
```
**Purpose**: Catch common survey design errors
**Returns**: Detailed diagnostic report

### 13.2 Data Preparation
```r
prepare_gmm_data(
  data,
  id,
  time,
  outcome,
  center_time = TRUE,
  scale_outcome = FALSE,
  handle_missing = c("listwise", "fiml", "warn")
)
```
**Purpose**: Automated preprocessing

### 13.3 Wide ↔ Long Conversion (Enhancement)
```r
# Enhanced version with survey design
wide_to_long_survey(
  data_wide,
  id,
  varying,
  survey_vars = c("strata", "cluster", "weights"),
  time_varying = c("ses", "peer")
)

long_to_wide_survey(data_long, ...)
```
**Purpose**: Better handling of survey variables

### 13.4 Sample Size Planning
```r
power_gmm(
  n_classes = 3,
  class_proportions = c(0.5, 0.3, 0.2),
  effect_size = 0.3,
  time_points = 5,
  alpha = 0.05,
  power = 0.80
)
```
**Purpose**: Required sample size for given power
**Returns**: Power curves, sample size recommendations

---

## 14. EXTRACTION & REPORTING (Priority: MEDIUM)

### 14.1 Tidy Methods (broom integration)
```r
tidy(fitted_model, conf.int = TRUE)
# Returns tibble with parameters, SEs, CIs

glance(fitted_model)
# Returns one-row tibble with fit indices

augment(fitted_model)
# Returns data with fitted values, residuals, class probabilities
```
**Purpose**: Tidyverse integration

### 14.2 Parameter Extraction
```r
extract_parameters(
  fitted_model,
  parameters = c("growth", "proportions", "variances"),
  format = c("wide", "long", "matrix")
)
```
**Purpose**: Flexible parameter retrieval

### 14.3 Formatted Tables
```r
table_growth_parameters(
  fitted_model,
  output = c("gt", "kable", "flextable"),
  stars = TRUE,  # Significance stars
  format = "apa"
)

table_model_comparison(
  list(fit1, fit2, fit3),
  output = "gt"
)
```
**Purpose**: Publication-ready tables
**Packages**: gt, kableExtra, flextable

### 14.4 Automated Reports
```r
report_gmm(
  fitted_model,
  output_file = "results.html",
  include = c("summary", "plots", "diagnostics", "tables")
)
```
**Purpose**: One-command comprehensive report
**Format**: HTML, Word, PDF

---

## 15. SIMULATION & VALIDATION (Priority: MEDIUM)

### 15.1 Enhanced Simulation
```r
# Current function exists, enhance it
simulate_gmm_survey(
  n = 5000,
  n_classes = 3,
  class_proportions = c(0.5, 0.3, 0.2),
  time_points = 6,
  growth_params = list(...),
  survey_design = list(
    type = "stratified_cluster",
    n_strata = 4,
    clusters_per_stratum = 50,
    weight_cv = 0.3  # Coefficient of variation
  ),
  missing = list(
    mechanism = "MAR",
    proportion = 0.2,
    predictors = c("baseline_risk")
  ),
  outcome_type = c("continuous", "binary", "count", "ordinal"),
  seed = NULL
)
```
**Enhancement**: More flexible design options

### 15.2 Parameter Recovery Studies
```r
recovery_study(
  n_reps = 100,
  true_params,
  data_generating_function,
  estimation_function,
  metrics = c("bias", "rmse", "coverage")
)
```
**Purpose**: Validate estimation accuracy

### 15.3 Monte Carlo Power Analysis
```r
power_analysis_mc(
  n_sims = 1000,
  sample_sizes = c(500, 1000, 2000),
  n_classes = 2:5,
  effect_size = seq(0.1, 0.5, 0.1),
  alpha = 0.05
)
```
**Purpose**: Simulation-based power calculations

---

## 16. MPLUS INTEGRATION (Priority: MEDIUM)

### 16.1 Enhanced Syntax Conversion
```r
# Enhance existing functions
mplus_to_surveymixr(
  "model.inp",
  include_comments = TRUE,
  verify = TRUE  # Check for unsupported features
)

surveymixr_to_mplus(
  fitted_model,
  output_file = "model.inp",
  include_data = TRUE,
  mplus_version = "8.8"
)
```
**Enhancement**: Better error handling, more features

### 16.2 Automated Comparison
```r
compare_with_mplus(
  surveymixr_model,
  mplus_output_file = "model.out",
  tolerance = 0.01,
  parameters = c("growth", "proportions", "se"),
  plot = TRUE
)
```
**Purpose**: Automated validation

### 16.3 Batch Mplus Runner
```r
run_mplus_batch(
  input_files = c("model1.inp", "model2.inp"),
  surveymixr_equivalent = TRUE,
  compare_results = TRUE
)
```
**Purpose**: Bulk comparison studies

---

## 17. SURVEY PACKAGE INTEGRATION (Priority: LOW-MEDIUM)

### 17.1 Accept survey.design Objects
```r
gmm_survey.survey.design(
  design,  # From survey::svydesign()
  id,
  time,
  outcome,
  n_classes,
  ...
)
```
**Purpose**: Direct integration with {survey} package

### 17.2 Convert to survey.design
```r
as_survey_design(fitted_model)
```
**Purpose**: Export for survey package functions

### 17.3 srvyr Integration
```r
# Tidy survey workflow
data %>%
  as_survey_design(...) %>%
  gmm_survey(...)
```
**Purpose**: Tidyverse + survey workflow

---

## 18. ADVANCED DIAGNOSTICS (Priority: MEDIUM)

### 18.1 Posterior Predictive Checks
```r
posterior_predictive_check(
  fitted_model,
  n_sims = 1000,
  statistics = c("mean", "sd", "skew", "kurt")
)

plot_ppc(result, type = "density")
```
**Purpose**: Model-data fit assessment

### 18.2 Cross-Validation for Stability
```r
cv_stability(
  data,
  id,
  time,
  outcome,
  n_classes,
  k_folds = 10,
  metric = "classification_agreement"
)
```
**Purpose**: How stable are class assignments?

### 18.3 Sensitivity to Random Starts
```r
sensitivity_starts(
  fitted_model,
  additional_starts = 1000,
  plot = TRUE
)
```
**Purpose**: Are we at global maximum?

---

## 19. SPECIAL POPULATIONS (Priority: LOW)

### 19.1 Small Sample Methods
```r
gmm_survey_small_sample(
  ...,
  method = c("bias_correction", "bootstrapped_se", "bayesian"),
  n_bootstrap = 500
)
```
**Purpose**: Better inference with n < 200

### 19.2 Rare Class Detection
```r
gmm_survey(
  ...,
  min_class_proportion = 0.01,  # Allow very small classes
  rare_class_methods = TRUE  # Special handling
)
```
**Purpose**: Identify rare trajectories (e.g., 1-2% of sample)

---

## 20. PERFORMANCE OPTIMIZATION (Priority: MEDIUM)

### 20.1 Rcpp Implementation
```cpp
// src/em_algorithm.cpp
// Fast C++ implementation of EM algorithm
```
**Purpose**: 5-10x speedup
**Implementation**: Rcpp, RcppArmadillo

### 20.2 Parallel Processing Enhancements
```r
gmm_survey(
  ...,
  cores = "auto",  # Detect optimal
  backend = c("parallel", "future", "foreach")
)
```
**Enhancement**: Better parallelization

### 20.3 Sparse Matrix Support
```r
gmm_survey(
  ...,
  sparse = TRUE  # For very large N
)
```
**Purpose**: Memory efficiency with n > 100,000

### 20.4 Incremental EM
```r
gmm_survey_online(
  data_stream,
  id,
  time,
  outcome,
  n_classes,
  update_every = 1000  # Rows
)
```
**Purpose**: Update model as new data arrives

---

## IMPLEMENTATION PRIORITY SUMMARY

### PHASE 1 (v0.2.0): CRAN Submission
- No new features (documentation & testing)

### PHASE 2 (v0.3.0): High Priority
1. **Binary outcomes** - gmm_survey_binary()
2. **Random effects** - Enhancement to gmm_survey()
3. **LMR test** - lmr_test()
4. **Cross-validation** - cv_gmm()
5. **Influence diagnostics** - influence_diagnostics()
6. **Interactive plots** - plot_trajectories_interactive()
7. **Tidy methods** - tidy(), glance(), augment()

### PHASE 3 (v0.4.0-v0.5.0): Medium Priority
1. **Ordinal outcomes** - gmm_survey_ordinal()
2. **Count outcomes** - gmm_survey_count()
3. **Parallel process** - gmm_survey_parallel()
4. **Piecewise growth** - gmm_survey_piecewise()
5. **LASSO** - gmm_survey_lasso()
6. **Covariate selection** - select_covariates()
7. **Survey design validation** - validate_survey_design()
8. **Power analysis** - power_gmm()

### PHASE 4 (v0.6.0+): Lower Priority
1. **Survival models** - gmm_survey_survival()
2. **Multilevel models** - gmm_survey_multilevel()
3. **Causal inference** - gmm_survey_ps(), gmm_survey_did()
4. **Bayesian estimation** - gmm_survey_bayes()
5. **Rcpp optimization** - src/em_algorithm.cpp

---

## ESTIMATED IMPLEMENTATION EFFORT

| Feature | Lines of Code | Days | Priority |
|---------|---------------|------|----------|
| Binary outcomes | 400 | 5-7 | High |
| Random effects | 300 | 4-5 | High |
| LMR test | 200 | 2-3 | High |
| Cross-validation | 250 | 3-4 | High |
| Influence diagnostics | 300 | 3-4 | Medium |
| Ordinal outcomes | 500 | 7-10 | Medium |
| Count outcomes | 400 | 5-7 | Medium |
| Parallel process | 600 | 10-14 | Medium |
| LASSO | 350 | 5-7 | Medium |
| Survival models | 700 | 14-21 | Low |
| Multilevel | 800 | 14-21 | Low |
| Bayesian | 1000+ | 21-30 | Low |
| Rcpp optimization | 500 | 7-10 | Medium |

---

## CONCLUSION

This roadmap provides **50+ new features** organized by domain. Implementing even the **high-priority subset** (Phase 2-3) would make surveymixr a **comprehensive, best-in-class package** for growth mixture modeling.

**Recommendation**: Focus on **breadth** (many outcome types, diagnostics, utilities) before **depth** (cutting-edge methods like Bayesian, quantum). This maximizes impact for applied researchers.

**Next Steps**:
1. Complete Phase 1 (CRAN submission)
2. Implement Phase 2 high-priority features (v0.3.0)
3. Gather user feedback to prioritize Phase 3+
