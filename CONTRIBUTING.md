# Contributing to surveymixr

Thank you for your interest in contributing to surveymixr! This document provides guidelines for contributing to the package.

## Code of Conduct

This project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on GitHub with:

- A clear, descriptive title
- A minimal reproducible example (reprex)
- Your session info (`sessionInfo()`)
- Expected vs actual behavior
- Any error messages

**Example:**

```r
# Minimal reproducible example
library(surveymixr)
data(mcs_simulated)

# Code that produces the bug
fit <- gmm_survey(
  data = mcs_simulated,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  n_classes = 3
)
# Error message here...
```

### Suggesting Features

Feature requests are welcome! Please:

1. Check existing issues to avoid duplicates
2. Describe the feature and its use case
3. Provide examples of how it would work
4. Consider whether it fits the package scope (growth mixture models + survey design)

### Contributing Code

#### Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/surveymixr.git
   cd surveymixr
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Development Setup

```r
# Install development dependencies
install.packages("devtools")
install.packages("testthat")
install.packages("roxygen2")
install.packages("covr")

# Load the package
devtools::load_all()

# Run tests
devtools::test()

# Check package
devtools::check()
```

#### Code Style

- Follow the [tidyverse style guide](https://style.tidyverse.org/)
- Use meaningful variable names
- Comment complex algorithms
- Keep functions focused (single responsibility principle)

**Example:**

```r
# Good
calculate_entropy <- function(posterior_probs) {
  # Calculate classification entropy
  # Higher values indicate more uncertainty
  log_probs <- log(posterior_probs + 1e-10)  # Avoid log(0)
  entropy <- -sum(posterior_probs * log_probs, na.rm = TRUE)
  return(entropy)
}

# Avoid
calc_e <- function(pp) {
  lp <- log(pp + 1e-10)
  e <- -sum(pp * lp, na.rm = TRUE)
  return(e)
}
```

#### Documentation

All exported functions must have complete documentation:

```r
#' Calculate Classification Entropy
#'
#' Computes the entropy of posterior class membership probabilities.
#' Higher values indicate greater classification uncertainty.
#'
#' @param posterior_probs Numeric matrix of posterior probabilities
#'   (rows = individuals, columns = classes)
#' @param method Character string specifying entropy calculation method.
#'   Options: "standard" (default), "relative", "normalized"
#'
#' @return Numeric value representing entropy. For "standard" method,
#'   ranges from 0 (perfect classification) to log(K) where K is the
#'   number of classes.
#'
#' @export
#' @examples
#' # Perfect classification (low entropy)
#' probs1 <- matrix(c(1, 0, 0, 0, 1, 0), ncol = 3, byrow = TRUE)
#' calculate_entropy(probs1)  # Should be 0
#'
#' # Uncertain classification (high entropy)
#' probs2 <- matrix(c(0.33, 0.33, 0.34), ncol = 3)
#' calculate_entropy(probs2)  # Should be close to log(3)
calculate_entropy <- function(posterior_probs, method = "standard") {
  # Implementation...
}
```

#### Testing

- Write tests for all new features
- Aim for >80% code coverage
- Test edge cases and error conditions
- Use descriptive test names

**Example:**

```r
# tests/testthat/test-entropy.R
test_that("entropy is 0 for perfect classification", {
  probs <- matrix(c(1, 0, 0, 0, 1, 0), ncol = 3, byrow = TRUE)
  expect_equal(calculate_entropy(probs), 0)
})

test_that("entropy increases with uncertainty", {
  perfect <- matrix(c(1, 0, 0), ncol = 3)
  uncertain <- matrix(c(0.5, 0.3, 0.2), ncol = 3)
  expect_true(calculate_entropy(uncertain) > calculate_entropy(perfect))
})

test_that("entropy handles edge cases", {
  # Single observation
  expect_silent(calculate_entropy(matrix(c(1, 0, 0), ncol = 3)))

  # Near-zero probabilities
  small_probs <- matrix(c(0.98, 0.01, 0.01), ncol = 3)
  expect_true(is.finite(calculate_entropy(small_probs)))
})
```

#### Workflow

1. Make your changes
2. Document your code (`devtools::document()`)
3. Write tests
4. Run checks:
   ```r
   devtools::test()        # Run tests
   devtools::check()       # R CMD check
   covr::package_coverage() # Coverage
   ```
5. Commit with clear messages:
   ```bash
   git add .
   git commit -m "Add entropy calculation with multiple methods

   - Implemented standard, relative, and normalized entropy
   - Added comprehensive tests with edge cases
   - Updated documentation with examples
   - Closes #123"
   ```
6. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
7. Open a pull request on GitHub

### Pull Request Guidelines

Your PR should:

- **Have a clear title** describing the change
- **Reference related issues** (e.g., "Closes #123")
- **Pass all checks** (R CMD check, tests, coverage)
- **Include documentation** for new features
- **Update NEWS.md** with your changes
- **Be focused** - one feature/fix per PR

**PR Template:**

```markdown
## Description
Brief description of what this PR does.

## Motivation and Context
Why is this change needed? What problem does it solve?
Fixes #(issue number)

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## How Has This Been Tested?
- [ ] Added new tests
- [ ] All existing tests pass
- [ ] Tested on multiple platforms
- [ ] Validated against Mplus (if applicable)

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have commented my code where needed
- [ ] I have updated the documentation
- [ ] I have added tests
- [ ] All tests pass locally
- [ ] R CMD check passes with 0 errors/warnings/notes
- [ ] I have updated NEWS.md
```

## Development Priorities

Based on the [development roadmap](ROADMAP.md), current priorities are:

### Phase 1: CRAN Readiness (v0.2.0)
- Bug fixes and edge case handling
- Performance optimization
- Documentation improvements
- Test coverage expansion

### Phase 2: Feature Completeness (v0.3.0-v0.5.0)
- Categorical outcomes (binary, ordinal, count)
- Random effects in growth parameters
- Enhanced model selection (LMR test, cross-validation)
- Time-varying covariates
- Advanced diagnostics

### Phase 3: Advanced Methods (v0.6.0+)
- Multilevel mixture models
- Bayesian estimation
- Causal inference integration
- Machine learning methods

## Areas Where Help Is Needed

Contributions are especially welcome in:

1. **Testing**: Expanding test coverage, edge cases, validation studies
2. **Documentation**: Vignettes, tutorials, examples
3. **Performance**: Optimization, profiling, Rcpp implementation
4. **Features**: Implementing items from the roadmap
5. **Bug fixes**: Addressing open issues
6. **Validation**: Comparing results with Mplus/other software

## Code Review Process

1. **Automated checks** run on all PRs (CI/CD via GitHub Actions)
2. **Maintainer review** typically within 1 week
3. **Feedback and iteration** as needed
4. **Merge** when approved and all checks pass

## Recognition

Contributors are recognized in:

- `DESCRIPTION` file (for substantial contributions)
- `NEWS.md` (for all contributions)
- GitHub contributors page
- Package citation (for major contributions)

## Questions?

- Open an issue for general questions
- Email maintainer for sensitive matters: johnni.nj@gmail.com
- Join discussions on GitHub Discussions (if enabled)

## License

By contributing, you agree that your contributions will be licensed under GPL (>= 3), the same license as the package.

## Resources

- [R Packages book](https://r-pkgs.org/) by Hadley Wickham
- [Writing R Extensions](https://cran.r-project.org/doc/manuals/R-exts.html) (CRAN manual)
- [Tidyverse style guide](https://style.tidyverse.org/)
- [testthat documentation](https://testthat.r-lib.org/)
- [roxygen2 documentation](https://roxygen2.r-lib.org/)

## Acknowledgments

Thank you for contributing to surveymixr! Your efforts help make complex survey analysis accessible to the research community.
