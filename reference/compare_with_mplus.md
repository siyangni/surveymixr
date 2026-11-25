# Compare surveymixr and Mplus Results

Compares parameter estimates from surveymixr and Mplus for validation.

## Usage

``` r
compare_with_mplus(surveymixr_object, mplus_output)
```

## Arguments

- surveymixr_object:

  A `SurveyMixr` object

- mplus_output:

  Path to Mplus output file (.out)

## Value

Data frame comparing parameter estimates

## Details

This function reads Mplus output and compares key parameters with
surveymixr estimates. Useful for validation and troubleshooting.

Note: Class labels may differ between software. You may need to manually
reorder classes for fair comparison.
