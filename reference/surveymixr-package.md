# surveymixr: Growth Mixture Models with Complex Survey Design

The surveymixr package implements growth mixture modeling for
longitudinal data with full integration of complex survey design
features including stratification, clustering, and probability weights.

## Details

Growth mixture models identify latent classes with distinct
developmental trajectories. This package enables such analyses with
proper handling of complex survey data from studies like the Millennium
Cohort Study, Add Health, NLSY, and others.

## Key Features

- Complex survey integration (stratification, clustering, weights)

- Bootstrap Likelihood Ratio Test (BLRT) for class enumeration

- R3STEP method for auxiliary variable analysis

- Multiple random starts (500-1000+) with parallel processing

- Sandwich standard errors for survey designs

- Comprehensive convergence diagnostics

- Publication-ready visualization

## Main Functions

- [`gmm_survey`](https://siyangni.github.io/surveymixr/reference/gmm_survey.md):

  Fit growth mixture model with survey design

- [`gmm_select`](https://siyangni.github.io/surveymixr/reference/gmm_select.md):

  Model selection across class solutions

- [`r3step`](https://siyangni.github.io/surveymixr/reference/r3step.md):

  Auxiliary variable analysis with classification correction

- [`simulate_gmm_survey`](https://siyangni.github.io/surveymixr/reference/simulate_gmm_survey.md):

  Simulate data for testing and validation

- [`diagnose_convergence`](https://siyangni.github.io/surveymixr/reference/diagnose_convergence.md):

  Convergence diagnostics

- [`plot_trajectories`](https://siyangni.github.io/surveymixr/reference/plot_trajectories.md):

  Visualize growth trajectories

## Getting Started

See
[`vignette("surveymixr-intro")`](https://siyangni.github.io/surveymixr/articles/surveymixr-intro.md)
for a comprehensive introduction with examples.

Quick example:


    library(surveymixr)

    # Simulate data for demonstration
    sim_data <- simulate_gmm_survey(
      n_individuals = 500,
      n_times = 4,
      n_classes = 3
    )

    # Fit 3-class model
    fit <- gmm_survey(
      data = sim_data,
      id = "id",
      time = "time",
      outcome = "outcome",
      n_classes = 3,
      strata = "stratum",
      cluster = "psu",
      weights = "weight",
      starts = 100
    )

    summary(fit)
    plot(fit)

## References

Muthén, B. (2004). Latent variable analysis: Growth mixture modeling and
related techniques for longitudinal data. In D. Kaplan (Ed.), *Handbook
of quantitative methodology for the social sciences* (pp. 345-368). Sage
Publications.

Asparouhov, T., & Muthén, B. (2014). Auxiliary variables in mixture
modeling: Three-step approaches using Mplus. *Structural Equation
Modeling, 21*(3), 329-341.

Nylund, K. L., Asparouhov, T., & Muthén, B. O. (2007). Deciding on the
number of classes in latent class analysis and growth mixture modeling.
*Structural Equation Modeling, 14*(4), 535-569.

## See also

Useful links:

- <https://github.com/siyangni/surveymixr>

- Report bugs at <https://github.com/siyangni/surveymixr/issues>

## Author

Siyang Ni <johnni.nj@gmail.com>
