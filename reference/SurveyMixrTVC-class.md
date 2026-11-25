# Define SurveyMixrTVC S4 Class

S4 class for growth mixture models with time-varying covariates, extends
SurveyMixr class

## Slots

- `tvc_effects`:

  Data frame with TVC effect estimates

- `tvc_formula`:

  Formula specifying TVCs

- `tvc_type`:

  Type of TVC effects (direct, indirect, both, interaction)

- `tvc_centered_values`:

  Data frame with centered TVC values
