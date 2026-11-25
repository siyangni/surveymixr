# Technical Details and Algorithms

## Introduction

This vignette provides technical details on the statistical methods and
algorithms implemented in `surveymixr`. It covers:

- Growth mixture modeling framework
- Complex survey design integration
- EM algorithm implementation
- Standard error computation
- Bootstrap likelihood ratio test (BLRT)
- Model fit indices

For an introduction to using the package, see
[`vignette("surveymixr-intro")`](https://siyangni.github.io/surveymixr/articles/surveymixr-intro.md).

## Statistical Framework

### Growth Mixture Models

Growth mixture models (GMMs) combine growth curve modeling with latent
class analysis to identify distinct subgroups (classes) with different
developmental trajectories (Muthén and Shedden 1999).

#### Individual-Level Model

For individual $`i`$ in class $`k`$ at time $`t`$:

``` math
y_{it} | k \sim N(\mu_{itk}, \sigma^2_k)
```

where the mean trajectory is:

``` math
\mu_{itk} = \beta_{0k} + \beta_{1k} \cdot time_{it} + \beta_{2k} \cdot time_{it}^2 + \cdots
```

#### Class Membership

The probability that individual $`i`$ belongs to class $`k`$:

``` math
P(C_i = k | \mathbf{X}_i) = \frac{\exp(\gamma_{k0} + \gamma_k^T \mathbf{X}_i)}{\sum_{j=1}^K \exp(\gamma_{j0} + \gamma_j^T \mathbf{X}_i)}
```

where $`\mathbf{X}_i`$ are time-invariant covariates (optional).

### Complex Survey Design Features

Survey data often involve:

1.  **Stratification**: Population divided into strata, samples drawn
    from each
2.  **Clustering**: Multi-stage sampling (e.g., schools, then students)
3.  **Unequal probability weights**: Some units more likely to be
    sampled

#### Survey-Weighted Likelihood

The survey-weighted log-likelihood is:

``` math
\ell_w(\theta) = \sum_{i=1}^n w_i \log f(y_i | \theta)
```

where $`w_i`$ is the survey weight for individual $`i`$.

**Key innovation**: `surveymixr` integrates survey weights directly into
the EM algorithm, unlike post-hoc weighting approaches.

### Integration: Survey-Weighted GMM

Combining GMM with survey design:

``` math
\ell_w(\theta) = \sum_{i=1}^n w_i \log \left[ \sum_{k=1}^K \pi_k \prod_{t=1}^{T_i} f(y_{it} | \theta_k) \right]
```

where: - $`w_i`$ = survey weight - $`\pi_k`$ = class proportion
(weighted) - $`\theta_k`$ = class-specific parameters - $`T_i`$ = number
of observations for individual $`i`$

## Estimation Algorithm

### EM Algorithm Overview

The Expectation-Maximization (EM) algorithm (Dempster et al. 1977)
iterates between:

1.  **E-step**: Compute posterior class probabilities
2.  **M-step**: Update parameters given posterior probabilities

#### E-Step: Posterior Probabilities

For individual $`i`$ and class $`k`$:

``` math
\tau_{ik} = \frac{w_i \pi_k \prod_{t=1}^{T_i} f(y_{it} | \theta_k)}{\sum_{j=1}^K w_i \pi_j \prod_{t=1}^{T_i} f(y_{it} | \theta_j)}
```

where $`\tau_{ik} = P(C_i = k | y_i, \theta)`$ is the posterior
probability.

#### M-Step: Parameter Updates

**Class proportions** (weighted):

``` math
\pi_k = \frac{\sum_{i=1}^n w_i \tau_{ik}}{\sum_{i=1}^n w_i}
```

**Growth parameters** (class $`k`$):

Solve weighted regression:

``` math
\hat{\beta}_k = \arg\min_{\beta_k} \sum_{i=1}^n \sum_{t=1}^{T_i} w_i \tau_{ik} (y_{it} - \mathbf{X}_{it}^T \beta_k)^2
```

**Variance** (class $`k`$):

``` math
\hat{\sigma}^2_k = \frac{\sum_{i=1}^n \sum_{t=1}^{T_i} w_i \tau_{ik} (y_{it} - \hat{y}_{it})^2}{\sum_{i=1}^n \sum_{t=1}^{T_i} w_i \tau_{ik}}
```

#### Convergence Criterion

Stop when:

``` math
|\ell_w^{(t+1)} - \ell_w^{(t)}| < \epsilon
```

Default: $`\epsilon = 10^{-6}`$

### Missing Data Handling (FIML)

`surveymixr` uses Full Information Maximum Likelihood (FIML) for missing
data under the Missing at Random (MAR) assumption.

For individual $`i`$ with observed data $`y_i^{obs}`$:

``` math
\ell_w(\theta | y_i^{obs}) = \sum_{k=1}^K w_i \tau_{ik} \log \prod_{t \in obs_i} f(y_{it} | \theta_k)
```

**Advantages**: - Uses all available data - Unbiased under MAR - No need
for imputation

### Multiple Random Starts

Local maxima are common in mixture models. `surveymixr` uses multiple
random starts:

1.  Generate `starts` (default 500) random initial parameter values
2.  Run EM from each starting point (parallelized)
3.  Select solution with highest log-likelihood
4.  Check for local maxima with
    [`diagnose_convergence()`](https://siyangni.github.io/surveymixr/reference/diagnose_convergence.md)

**Example**:

``` r

fit <- gmm_survey(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  n_classes = 3,
  starts = 500,  # Multiple random starts
  cores = 4      # Parallel processing
)

# Check for local maxima
diagnose_convergence(fit)
```

## Standard Errors

### Sandwich Estimator

`surveymixr` uses the sandwich (robust) variance estimator to account
for: - Model misspecification - Clustering - Stratification

``` math
\mathbf{V}(\hat{\theta}) = \mathbf{H}^{-1} \mathbf{J} \mathbf{H}^{-1}
```

where: - $`\mathbf{H}`$ = Hessian (observed information matrix) -
$`\mathbf{J}`$ = Outer product of score contributions (meat)

### Accounting for Survey Design

**Clustering** adjustment:

``` math
\mathbf{J} = \sum_{h=1}^H \sum_{c=1}^{C_h} \left(\sum_{i \in c} \mathbf{s}_i\right) \left(\sum_{i \in c} \mathbf{s}_i\right)^T
```

where: - $`H`$ = number of strata - $`C_h`$ = number of clusters in
stratum $`h`$ - $`\mathbf{s}_i`$ = score contribution for individual
$`i`$

**Effect**: Standard errors increase to reflect within-cluster
correlation (design effect \> 1).

### Numerical Derivatives

Since analytical derivatives are complex, `surveymixr` uses numerical
derivatives via the `numDeriv` package:

- **Hessian**: Richardson extrapolation
- **Gradient**: Central differences

**Confidence intervals**:

``` math
\hat{\theta} \pm 1.96 \times SE(\hat{\theta})
```

## Bootstrap Likelihood Ratio Test (BLRT)

The BLRT (McLachlan 1987) tests whether a $`k`$-class model fits better
than a $`(k-1)`$-class model.

### Algorithm

1.  Fit $`(k-1)`$-class model, obtain $`\hat{\theta}_{k-1}`$
2.  Fit $`k`$-class model, obtain $`\hat{\theta}_k`$
3.  Compute observed LRT statistic:
    ``` math
    LRT_{obs} = 2(\ell(\hat{\theta}_k) - \ell(\hat{\theta}_{k-1}))
    ```
4.  **Bootstrap** (repeat $`B`$ times):
    - Simulate data from $`(k-1)`$-class model
    - Fit both $`(k-1)`$ and $`k`$-class models
    - Compute $`LRT_b`$
5.  $`p`$-value = proportion of $`LRT_b > LRT_{obs}`$

**Interpretation**: - $`p < 0.05`$: Reject $`(k-1)`$ classes, favor
$`k`$ classes - $`p \geq 0.05`$: No evidence for $`k`$ classes

**Example**:

``` r

selection <- gmm_select(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  min_classes = 1,
  max_classes = 5,
  run_blrt = TRUE,
  blrt_samples = 500,  # Bootstrap replicates
  cores = 4
)

# View BLRT results
summary(selection)
```

## Model Fit Indices

### Information Criteria

**AIC** (Akaike Information Criterion):

``` math
AIC = -2\ell(\hat{\theta}) + 2p
```

**BIC** (Bayesian Information Criterion):

``` math
BIC = -2\ell(\hat{\theta}) + p \log(n)
```

**Sample-size adjusted BIC**:

``` math
aBIC = -2\ell(\hat{\theta}) + p \log\left(\frac{n+2}{24}\right)
```

where: - $`\ell(\hat{\theta})`$ = maximized log-likelihood - $`p`$ =
number of parameters - $`n`$ = sample size (effective sample size for
weighted data)

**Lower values indicate better fit**.

### Entropy

Entropy measures classification certainty (Ramaswamy et al. 1993):

``` math
E = 1 - \frac{\sum_{i=1}^n \sum_{k=1}^K \tau_{ik} \log(\tau_{ik})}{n \log(K)}
```

- Range: $`[0, 1]`$
- Higher values = better classification
- $`E > 0.8`$ is considered good
- $`E > 0.9`$ is excellent

### Average Posterior Probability (AvePP)

For each class $`k`$:

``` math
AvePP_k = \frac{\sum_{i: \arg\max_j \tau_{ij} = k} \tau_{ik}}{n_k}
```

where $`n_k`$ = number of individuals assigned to class $`k`$.

**Interpretation**: - AvePP \> 0.7 for all classes is acceptable - AvePP
\> 0.8 is good

### Odds of Correct Classification (OCC)

``` math
OCC_k = \frac{AvePP_k / (1 - AvePP_k)}{\pi_k / (1 - \pi_k)}
```

where $`\pi_k`$ = class proportion.

- OCC \> 5 indicates good classification

## Computational Efficiency

### Parallelization

Random starts are parallelized using the `parallel` package:

``` r

# Detect cores
n_cores <- parallel::detectCores() - 1

fit <- gmm_survey(
  ...,
  cores = n_cores
)
```

### Memory Management

For large datasets: - Use sparse matrices where applicable - Process
data in chunks for FIML - Limit random starts for initial exploration

### Typical Run Times

On a modern laptop (4 cores):

| n      | T   | K   | starts | Time    |
|--------|-----|-----|--------|---------|
| 1,000  | 4   | 2   | 100    | ~1 min  |
| 1,000  | 4   | 3   | 500    | ~5 min  |
| 5,000  | 6   | 3   | 500    | ~15 min |
| 10,000 | 6   | 4   | 1000   | ~45 min |

**Tips for speed**: 1. Start with fewer random starts (50-100) for
exploration 2. Use parallel processing (4+ cores) 3. Reduce to final
model with more starts (500-1000)

## Comparison with Mplus

`surveymixr` produces results consistent with Mplus:

| Feature             | surveymixr   | Mplus               |
|---------------------|--------------|---------------------|
| Parameter estimates | ✓            | ✓                   |
| Standard errors     | ✓ (sandwich) | ✓                   |
| Survey weights      | ✓            | ✓                   |
| BLRT                | ✓            | ✓                   |
| Speed               | Comparable   | Comparable          |
| Cost                | Free         | $`\$\$\$`$          |
| R integration       | Native       | Via MplusAutomation |

See
[`vignette("mplus-validation")`](https://siyangni.github.io/surveymixr/articles/mplus-validation.md)
for detailed comparisons.

## References

Dempster, Arthur P, Nan M Laird, and Donald B Rubin. 1977. “Maximum
Likelihood from Incomplete Data via the EM Algorithm.” *Journal of the
Royal Statistical Society: Series B (Methodological)* 39 (1): 1–22.

McLachlan, Geoffrey J. 1987. “On Bootstrapping the Likelihood Ratio Test
Statistic for the Number of Components in a Normal Mixture.” *Journal of
the Royal Statistical Society: Series C (Applied Statistics)* 36 (3):
318–24.

Muthén, Bengt, and Kerby Shedden. 1999. “Finite Mixture Modeling with
Mixture Outcomes Using the EM Algorithm.” *Biometrics* 55 (2): 463–69.

Ramaswamy, Venkatram, Wayne S DeSarbo, David J Reibstein, and William T
Robinson. 1993. “An Empirical Pooling Approach for Estimating Marketing
Mix Elasticities with PIMS Data.” *Marketing Science* 12 (1): 103–24.

## Session Info

``` r

sessionInfo()
#> R version 4.6.2 (2026-10-29)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 26.04.1 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.32.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] surveymixr_0.2.3
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6        jsonlite_2.0.0      dplyr_1.2.1        
#>  [4] compiler_4.6.2      tidyselect_1.2.1    parallel_4.6.2     
#>  [7] jquerylib_0.1.4     systemfonts_1.3.4   scales_1.4.0       
#> [10] textshaping_1.1.0   yaml_2.3.12         fastmap_1.2.0      
#> [13] ggplot2_4.0.4       R6_2.6.1            generics_0.1.4     
#> [16] knitr_1.52          htmlwidgets_1.6.4   tibble_3.3.1       
#> [19] desc_1.4.3          bslib_0.12.0        pillar_1.11.1      
#> [22] RColorBrewer_1.1-3  rlang_1.3.0         cachem_1.1.0       
#> [25] xfun_0.62           fs_2.1.0            sass_0.5.0         
#> [28] S7_1.0.0            otel_0.3.0          cli_3.6.6          
#> [31] pkgdown_2.2.1       magrittr_2.0.5      digest_0.6.39      
#> [34] grid_4.6.2          lifecycle_1.0.5     vctrs_0.7.3        
#> [37] evaluate_1.0.5      glue_1.8.1          farver_2.1.2       
#> [40] numDeriv_2016.8-1.1 ragg_1.5.2          rmarkdown_2.32     
#> [43] tools_4.6.2         pkgconfig_2.0.3     htmltools_0.5.9
```
