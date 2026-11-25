# Convert surveymixr Output to Mplus Format

Generates Mplus-style output summary from a surveymixr object.

## Usage

``` r
surveymixr_to_mplus(object, file = NULL)
```

## Arguments

- object:

  A `SurveyMixr` object

- file:

  Optional file path to write output (default: print to console)

## Value

Character string with Mplus-style output (returned invisibly). The
function does not print to the console by default; use
[`cat()`](https://rdrr.io/r/base/cat.html) or
[`writeLines()`](https://rdrr.io/r/base/writeLines.html) on the returned
value to display or save the output.
