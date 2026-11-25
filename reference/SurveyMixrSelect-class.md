# S4 Class for Model Selection Results

The `SurveyMixrSelect` class contains results from model selection
across different numbers of latent classes.

## Slots

- `comparison_table`:

  Data frame with fit indices for each class solution

- `fitted_models`:

  List of fitted SurveyMixr objects

- `blrt_results`:

  List containing BLRT test results

- `recommended_classes`:

  Recommended number of classes based on criteria

- `criteria`:

  Character vector of criteria used
