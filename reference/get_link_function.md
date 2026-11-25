# Link Functions for Different Outcome Types

Provides link functions for various outcome distributions in growth
mixture models.

## Usage

``` r
get_link_function(outcome_type = "continuous")
```

## Arguments

- outcome_type:

  Character string specifying outcome type: "continuous" (default),
  "binary", "ordinal", "count", "zero_inflated"

## Value

List containing link function, inverse link, and derivative
