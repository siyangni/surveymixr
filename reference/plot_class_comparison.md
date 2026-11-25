# Plot Class Comparison for a Variable

Creates density plots or boxplots comparing classes on a specific
variable.

## Usage

``` r
plot_class_comparison(object, variable, type = "density", ...)
```

## Arguments

- object:

  A `SurveyMixr` object

- variable:

  Character string, name of variable to compare (must be in original
  data)

- type:

  Character: "density" (default) or "boxplot"

- ...:

  Additional arguments

## Value

A ggplot2 object
