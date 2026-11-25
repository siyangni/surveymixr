# Entropy Function (Exported)

Extract entropy from a SurveyMixr object or compute from posterior
probabilities.

## Usage

``` r
entropy(object, weights = NULL)

# S3 method for class 'SurveyMixr'
entropy(object, weights = NULL)

# S3 method for class 'matrix'
entropy(object, weights = NULL)

# Default S3 method
entropy(object, weights = NULL)
```

## Arguments

- object:

  Either a `SurveyMixr` object or a matrix of posterior probabilities

- weights:

  Optional survey weights for weighted entropy computation

## Value

Numeric entropy value between 0 and 1, where values closer to 1 indicate
better class separation

## Details

Entropy measures the certainty of classification in mixture models. It
is calculated as: \$\$E = 1 - \frac{\sum_i \sum_k p\_{ik}
\log(p\_{ik})}{N \log(K)}\$\$

where \\p\_{ik}\\ is the posterior probability of individual i belonging
to class k, N is the sample size, and K is the number of classes.

Values range from 0 (complete uncertainty, uniform classification) to 1
(perfect classification). Values above 0.80 generally indicate good
class separation.

## References

Ramaswamy, V., DeSarbo, W. S., Reibstein, D. J., & Robinson, W. T.
(1993). An empirical pooling approach for estimating marketing mix
elasticities with PIMS data. *Marketing Science, 12*(1), 103-124.

## Examples

``` r
# \donttest{
# From a fitted model
set.seed(123)
sim_data <- simulate_gmm_survey(
  n_individuals = 100,
  n_times = 4,
  n_classes = 2,
  design = "srs",
  seed = 123
)

fit <- gmm_survey(
  data = sim_data,
  id = "id",
  time = "time",
  outcome = "outcome",
  n_classes = 2,
  starts = 5,
  cores = 1,
  verbose = FALSE
)

entropy(fit)
#> [1] 1

# Or directly from a posterior probability matrix
post_probs <- matrix(c(0.9, 0.1,
                       0.2, 0.8),
                     nrow = 2, byrow = TRUE)
entropy(post_probs)
#> [1] 0.4045382
# }
```
