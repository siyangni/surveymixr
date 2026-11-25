# S4 Class for R3STEP Results

The `R3StepResults` class contains results from auxiliary variable
analysis using the R3STEP approach.

## Slots

- `gmm_object`:

  Original SurveyMixr object

- `distal_vars`:

  Character vector of distal variable names

- `method`:

  R3STEP method used (BCH, ML, manual)

- `class_means`:

  Matrix of class-specific means for distal variables

- `standard_errors`:

  Matrix of standard errors

- `test_results`:

  Data frame with omnibus and pairwise tests

- `effect_sizes`:

  Matrix of effect sizes (Cohen's d)
