# Reshape Data from Wide to Long

Helper function to reshape data for gmm_survey if in wide format.

## Usage

``` r
wide_to_long(data, id_var, outcome_vars, time_values = NULL)
```

## Arguments

- data:

  Data frame in wide format

- id_var:

  Character string, ID variable name

- outcome_vars:

  Character vector of outcome variable names (ordered by time)

- time_values:

  Optional numeric vector of time values (default: 0, 1, 2, ...)

## Value

Data frame in long format

## Examples

``` r
# \donttest{
# Wide format data
wide_data <- data.frame(
  id = 1:100,
  y_t0 = rnorm(100),
  y_t1 = rnorm(100),
  y_t2 = rnorm(100)
)

# Convert to long
long_data <- wide_to_long(
  data = wide_data,
  id_var = "id",
  outcome_vars = c("y_t0", "y_t1", "y_t2")
)
# }
```
