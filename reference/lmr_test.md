# Lo-Mendell-Rubin Test for Class Enumeration

Performs the Lo-Mendell-Rubin (LMR) likelihood ratio test to compare a
k-class model against a (k-1)-class model. This is an asymptotic
approximation that is faster than the bootstrap LRT (BLRT).

## Usage

``` r
lmr_test(model_k, model_k1, adjusted = TRUE)
```

## Arguments

- model_k:

  Fitted `SurveyMixr` object with k classes

- model_k1:

  Fitted `SurveyMixr` object with k-1 classes

- adjusted:

  Logical; if TRUE (default), uses the adjusted LMR (aLMR) which
  provides better finite-sample performance

## Value

A list of class `lmr_test` with components:

- statistic:

  LMR test statistic

- statistic_adjusted:

  Adjusted LMR statistic (if adjusted = TRUE)

- df:

  Degrees of freedom

- p_value:

  p-value from asymptotic distribution

- p_value_adjusted:

  Adjusted p-value (if adjusted = TRUE)

- loglik_k:

  Log-likelihood for k-class model

- loglik_k1:

  Log-likelihood for (k-1)-class model

- n_params_k:

  Number of parameters in k-class model

- n_params_k1:

  Number of parameters in (k-1)-class model

- sample_size:

  Effective sample size

- conclusion:

  Text interpretation of result

## Details

The LMR test (Lo, Mendell, & Rubin, 2001) tests the null hypothesis that
k-1 classes are sufficient against the alternative of k classes. The
test statistic is:

\$\$LRT = -2(\log L\_{k-1} - \log L_k)\$\$

Under regularity conditions, this follows an asymptotic distribution
that can be approximated. The adjusted LMR (aLMR) applies a scaling
correction for better finite-sample performance:

\$\$aLMR = LMR \times c\$\$

where c is a scaling factor based on sample size and model complexity.

\*\*Advantages over BLRT:\*\* - Much faster (no bootstrap resampling) -
Asymptotic approximation - Good performance in large samples

\*\*Disadvantages:\*\* - Less accurate than BLRT in small samples -
Relies on asymptotic theory - May be anti-conservative

## References

Lo, Y., Mendell, N. R., & Rubin, D. B. (2001). Testing the number of
components in a normal mixture. \*Biometrika\*, 88(3), 767-778.

Nylund, K. L., Asparouhov, T., & Muthén, B. O. (2007). Deciding on the
number of classes in latent class analysis and growth mixture modeling:
A Monte Carlo simulation study. \*Structural Equation Modeling\*, 14(4),
535-569.

## Examples

``` r
# \donttest{
# Quick example (reduced starts for speed)
data(mcs_simulated)
set.seed(123)

# Fit 1-class and 2-class models
fit1 <- gmm_survey(
  data = mcs_simulated,
  id = "id", time = "age", outcome = "selfcontrol",
  n_classes = 1, starts = 5, verbose = FALSE
)

fit2 <- gmm_survey(
  data = mcs_simulated,
  id = "id", time = "age", outcome = "selfcontrol",
  n_classes = 2, starts = 5, verbose = FALSE
)

# LMR test: Is 2-class better than 1-class?
lmr_result <- lmr_test(fit2, fit1, adjusted = TRUE)
print(lmr_result)
#> 
#> Lo-Mendell-Rubin Likelihood Ratio Test
#> ==================================================
#> 
#> Model Comparison:
#>   H0: 1-class model is sufficient
#>   H1: 2-class model fits better
#> 
#> Log-Likelihoods:
#>   1-class: -61788.4
#>   2-class: -49783.8
#> 
#> Test Statistics:
#>   LMR statistic: 24009
#>   Adjusted LMR:  19207
#>   Scaling factor:1.25
#>   Degrees of freedom: 4
#> 
#> P-values:
#>   LMR:      < 2.2e-16
#>   Adjusted: < 2.2e-16 (recommended)
#> 
#> Conclusion:
#>   Reject H0: 2-class model fits significantly better than 1-class model (p = <2e-16)
#> 
#> Note: The LMR test uses an asymptotic approximation and may be
#> anti-conservative. For more accurate results, consider using
#> the Bootstrap LRT (BLRT) via gmm_select().

# For production analysis, use starts = 500
# }
```
