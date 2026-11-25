# Classification Quality Metrics

Computes detailed classification quality metrics including average
posterior probabilities, entropy, and odds of correct classification.

## Usage

``` r
classification_quality(object)
```

## Arguments

- object:

  A `SurveyMixr` object

## Value

List containing classification quality metrics

## Details

Classification quality metrics assess how well individuals are assigned
to latent classes:

- **Entropy**: Overall classification certainty (0-1, higher better)

- **AvePP**: Average posterior probability of assigned class

- **OCC**: Odds of correct classification (AvePP / (1 - AvePP))

- **mcaAvePP**: Minimum classification accuracy based on AvePP

**Guidelines:**

- Entropy \> 0.80: Excellent separation

- Entropy 0.60-0.80: Good separation

- Entropy \< 0.60: Poor separation, consider fewer classes

- AvePP \> 0.90 for each class indicates reliable classification

- OCC \> 5 is desirable

## References

Clark, S. L., & Muthén, B. (2009). Relating latent class analysis
results to variables not included in the analysis. Unpublished
manuscript.

## Examples

``` r
# \donttest{
data(mcs_simulated)
set.seed(123)
fit <- gmm_survey(data = mcs_simulated, id = "id", time = "age",
                  outcome = "selfcontrol", n_classes = 2,
                  starts = 5, verbose = FALSE)

classification_quality(fit)
#> $entropy
#> [1] 0.9984752
#> 
#> $avepp_overall
#> [1] 0.9994075
#> 
#> $occ_overall
#> [1] 1686.626
#> 
#> $summary_by_class
#>   class     avepp      occ       mca n_assigned
#> 1     1 0.9997337 3754.428 0.9998414       4264
#> 2     2 0.9990812 1087.358 0.9984583        736
#> 
#> $class_error_matrix
#>                  True_1       True_2
#> Assigned_1 0.9997337188 0.0002662812
#> Assigned_2 0.0009188154 0.9990811846
#> 
# }
```
