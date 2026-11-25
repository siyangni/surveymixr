# S4 Class for Convergence Diagnostics

The `ConvergenceDiagnostics` class contains detailed convergence
information from multiple random starts.

## Slots

- `loglik_table`:

  Data frame of log-likelihoods from all starts

- `best_loglik`:

  Best (highest) log-likelihood achieved

- `n_replications`:

  Number of times best solution was replicated

- `local_maxima`:

  Data frame identifying local maxima

- `convergence_plot`:

  ggplot object showing distribution

- `warnings`:

  Character vector of convergence warnings

- `recommendations`:

  Character vector of recommendations
