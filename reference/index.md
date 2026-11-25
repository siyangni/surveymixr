# Package index

## Core Estimation Functions

Main functions for fitting growth mixture models

- [`gmm_survey()`](https://siyangni.github.io/surveymixr/reference/gmm_survey.md)
  : Growth Mixture Models with Complex Survey Design
- [`gmm_survey_binary()`](https://siyangni.github.io/surveymixr/reference/gmm_survey_binary.md)
  : Growth Mixture Model for Binary Outcomes
- [`gmm_survey_ordinal()`](https://siyangni.github.io/surveymixr/reference/gmm_survey_ordinal.md)
  : Growth Mixture Model for Ordinal Outcomes
- [`gmm_survey_count()`](https://siyangni.github.io/surveymixr/reference/gmm_survey_count.md)
  : Growth Mixture Model for Count Outcomes
- [`gmm_survey_tvc()`](https://siyangni.github.io/surveymixr/reference/gmm_survey_tvc.md)
  : Growth Mixture Model with Time-Varying Covariates

## Model Selection

Functions for determining optimal number of classes

- [`gmm_select()`](https://siyangni.github.io/surveymixr/reference/gmm_select.md)
  : Model Selection for Growth Mixture Models
- [`gmm_cv()`](https://siyangni.github.io/surveymixr/reference/gmm_cv.md)
  : K-Fold Cross-Validation for GMM Model Selection
- [`lmr_test()`](https://siyangni.github.io/surveymixr/reference/lmr_test.md)
  : Lo-Mendell-Rubin Test for Class Enumeration
- [`lmr_sequential()`](https://siyangni.github.io/surveymixr/reference/lmr_sequential.md)
  : Automated LMR Testing Across Multiple Models

## Auxiliary Variable Analysis

R3STEP and classification uncertainty correction

- [`r3step()`](https://siyangni.github.io/surveymixr/reference/r3step.md)
  : R3STEP Analysis of Auxiliary Variables

## Advanced Diagnostics

Model diagnostics and quality assessment

- [`diagnose_convergence()`](https://siyangni.github.io/surveymixr/reference/diagnose_convergence.md)
  : Convergence Diagnostics for Growth Mixture Models
- [`diagnose_influence()`](https://siyangni.github.io/surveymixr/reference/diagnose_influence.md)
  : Detect Influential Observations in GMM
- [`diagnose_separation()`](https://siyangni.github.io/surveymixr/reference/diagnose_separation.md)
  : Detect Separation in Latent Classes
- [`residual_diagnostics()`](https://siyangni.github.io/surveymixr/reference/residual_diagnostics.md)
  : Residual Diagnostics for GMM
- [`classification_quality()`](https://siyangni.github.io/surveymixr/reference/classification_quality.md)
  : Classification Quality Metrics
- [`entropy()`](https://siyangni.github.io/surveymixr/reference/entropy.md)
  : Entropy Function (Exported)
- [`class_proportions()`](https://siyangni.github.io/surveymixr/reference/class_proportions.md)
  : Class Proportions with Confidence Intervals
- [`compare_classes()`](https://siyangni.github.io/surveymixr/reference/compare_classes.md)
  : Compare Classes on a Variable

## Visualization Functions

Plotting and interactive visualization

- [`plot_trajectories()`](https://siyangni.github.io/surveymixr/reference/plot_trajectories.md)
  : Plot Trajectories by Latent Class
- [`plot_interactive()`](https://siyangni.github.io/surveymixr/reference/plot_interactive.md)
  : Create Interactive Trajectory Plot
- [`plot_model_selection()`](https://siyangni.github.io/surveymixr/reference/plot_model_selection.md)
  : Plot Model Selection Comparison
- [`plot_model_selection_interactive()`](https://siyangni.github.io/surveymixr/reference/plot_model_selection_interactive.md)
  : Create Interactive Model Selection Plot
- [`plot_class_comparison()`](https://siyangni.github.io/surveymixr/reference/plot_class_comparison.md)
  : Plot Class Comparison for a Variable
- [`plot_posterior_dist()`](https://siyangni.github.io/surveymixr/reference/plot_posterior_dist.md)
  : Create Interactive Posterior Probability Distribution Plot
- [`plot_tvc_effects()`](https://siyangni.github.io/surveymixr/reference/plot_tvc_effects.md)
  : Plot Time-Varying Covariate Effects

## Extractors & Accessors

Extract parameters and predictions from fitted models

- [`extract_fit_indices()`](https://siyangni.github.io/surveymixr/reference/extract_fit_indices.md)
  : Extract Information Criteria
- [`extract_trajectories()`](https://siyangni.github.io/surveymixr/reference/extract_trajectories.md)
  : Extract Trajectories by Class
- [`extract_tvc_effects()`](https://siyangni.github.io/surveymixr/reference/extract_tvc_effects.md)
  : Extract Time-Varying Covariate Effects

## Data Preparation & Validation

Helper functions for data manipulation

- [`validate_survey_data()`](https://siyangni.github.io/surveymixr/reference/validate_survey_data.md)
  : Validate Survey Data for GMM Analysis
- [`wide_to_long()`](https://siyangni.github.io/surveymixr/reference/wide_to_long.md)
  : Reshape Data from Wide to Long

## Simulation & Testing

Data simulation for testing and validation

- [`simulate_gmm_survey()`](https://siyangni.github.io/surveymixr/reference/simulate_gmm_survey.md)
  : Simulate Data from Growth Mixture Model with Survey Design
- [`test_tvc_effects()`](https://siyangni.github.io/surveymixr/reference/test_tvc_effects.md)
  : Test Time-Varying Covariate Effects

## Software Integration

Integration with Mplus and other software

- [`mplus_to_surveymixr()`](https://siyangni.github.io/surveymixr/reference/mplus_to_surveymixr.md)
  : Convert Mplus Syntax to surveymixr
- [`surveymixr_to_mplus()`](https://siyangni.github.io/surveymixr/reference/surveymixr_to_mplus.md)
  : Convert surveymixr Output to Mplus Format
- [`compare_with_mplus()`](https://siyangni.github.io/surveymixr/reference/compare_with_mplus.md)
  : Compare surveymixr and Mplus Results

## Example Data

Included datasets for examples

- [`mcs_simulated`](https://siyangni.github.io/surveymixr/reference/mcs_simulated.md)
  : Simulated Millennium Cohort Study Data

## S4 Classes

Object-oriented class definitions

- [`SurveyMixr-class`](https://siyangni.github.io/surveymixr/reference/SurveyMixr-class.md)
  : S4 Class Definition for surveymixr Objects
- [`SurveyMixrTVC-class`](https://siyangni.github.io/surveymixr/reference/SurveyMixrTVC-class.md)
  : Define SurveyMixrTVC S4 Class
- [`SurveyMixrSelect-class`](https://siyangni.github.io/surveymixr/reference/SurveyMixrSelect-class.md)
  : S4 Class for Model Selection Results
- [`R3StepResults-class`](https://siyangni.github.io/surveymixr/reference/R3StepResults-class.md)
  : S4 Class for R3STEP Results
- [`ConvergenceDiagnostics-class`](https://siyangni.github.io/surveymixr/reference/ConvergenceDiagnostics-class.md)
  : S4 Class for Convergence Diagnostics
- [`InfluenceDiagnostics-class`](https://siyangni.github.io/surveymixr/reference/InfluenceDiagnostics-class.md)
  : Define InfluenceDiagnostics S4 Class
- [`DataValidation-class`](https://siyangni.github.io/surveymixr/reference/DataValidation-class.md)
  : Define DataValidation S4 Class

## S4 Methods

Generic methods for surveymixr objects

- [`show(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`print(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`summary(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`coef(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`vcov(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`fitted(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`residuals(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`logLik(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`AIC(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`BIC(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`show(`*`<SurveyMixrSelect>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`print(`*`<SurveyMixrSelect>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`summary(`*`<SurveyMixrSelect>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`show(`*`<R3StepResults>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`print(`*`<R3StepResults>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`summary(`*`<R3StepResults>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`plot(`*`<R3StepResults>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`show(`*`<ConvergenceDiagnostics>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`print(`*`<ConvergenceDiagnostics>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  [`plot(`*`<SurveyMixr>`*`)`](https://siyangni.github.io/surveymixr/reference/surveymixr-methods.md)
  : S4 Methods for SurveyMixr Objects
- [`show(`*`<DataValidation>`*`)`](https://siyangni.github.io/surveymixr/reference/show-DataValidation-method.md)
  : Print Method for DataValidation
- [`show(`*`<InfluenceDiagnostics>`*`)`](https://siyangni.github.io/surveymixr/reference/show-InfluenceDiagnostics-method.md)
  : Print Method for Influence Diagnostics

## S3 Methods

Print and plot methods for specific objects

- [`plot(`*`<gmm_cv>`*`)`](https://siyangni.github.io/surveymixr/reference/plot.gmm_cv.md)
  : Plot Method for GMM Cross-Validation Results
- [`print(`*`<gmm_cv>`*`)`](https://siyangni.github.io/surveymixr/reference/print.gmm_cv.md)
  : Print Method for GMM Cross-Validation Results
- [`print(`*`<lmr_sequential>`*`)`](https://siyangni.github.io/surveymixr/reference/print.lmr_sequential.md)
  : Print Method for Sequential LMR Results
- [`print(`*`<lmr_test>`*`)`](https://siyangni.github.io/surveymixr/reference/print.lmr_test.md)
  : Print Method for LMR Test Results

## Internal

Package infrastructure

- [`surveymixr-package`](https://siyangni.github.io/surveymixr/reference/surveymixr-package.md)
  [`surveymixr`](https://siyangni.github.io/surveymixr/reference/surveymixr-package.md)
  : surveymixr: Growth Mixture Models with Complex Survey Design
- [`plotting`](https://siyangni.github.io/surveymixr/reference/plotting.md)
  : Plotting Functions for surveymixr
- [`utilities`](https://siyangni.github.io/surveymixr/reference/utilities.md)
  : Utility Functions for surveymixr
