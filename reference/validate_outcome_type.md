# Validate Outcome Type and Data

Internal function to validate outcome data matches specified outcome
type

## Usage

``` r
validate_outcome_type(data, outcome, outcome_type, n_categories = NULL)
```

## Arguments

- data:

  Data frame

- outcome:

  Character string naming outcome variable

- outcome_type:

  Character string: "continuous", "binary", "ordinal", "count"

- n_categories:

  For ordinal outcomes, number of categories

## Value

Invisibly returns TRUE if validation passes, throws error otherwise
