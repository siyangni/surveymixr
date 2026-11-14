#!/usr/bin/env Rscript
# Fit a 3-class survey-weighted GMM and export trajectories for the website
# showcase. Simulated with the package's own generator so the recovered
# pathways are visually distinct (the bundled MCS data overlaps too much
# for a clean demonstration plot).

suppressPackageStartupMessages({
  library(surveymixr)
  library(ggplot2)
  library(jsonlite)
})

dir.create("showcase", showWarnings = FALSE, recursive = TRUE)
set.seed(20250917)

demo_data <- simulate_gmm_survey(
  n_individuals = 1600,
  n_times = 6,
  n_classes = 3,
  time_scores = c(3, 5, 7, 11, 14, 17),
  class_proportions = c(0.50, 0.32, 0.18),
  growth_parameters = list(
    list(intercept = 9.10, slope = 0.035),
    list(intercept = 4.80, slope = 0.240),
    list(intercept = 4.40, slope = -0.130)
  ),
  residual_sds = c(0.70, 0.80, 0.85),
  design = "stratified_cluster",
  n_strata = 4,
  n_clusters = 80,
  weight_type = "inverse_prob",
  missing_rate = 0.08,
  missing_mechanism = "MAR",
  covariates = TRUE,
  seed = 20250917
)
names(demo_data)[names(demo_data) == "outcome"] <- "selfcontrol"
names(demo_data)[names(demo_data) == "time"] <- "age"
if ("psu" %in% names(demo_data) && !"cluster" %in% names(demo_data)) {
  names(demo_data)[names(demo_data) == "psu"] <- "cluster"
}

n_id <- length(unique(demo_data$id))
message(sprintf("Fitting 3-class GMM: %d individuals, %d rows",
                n_id, nrow(demo_data)))
print(table(demo_data$true_class[!duplicated(demo_data$id)]))

t0 <- proc.time()[["elapsed"]]
fit <- gmm_survey(
  data = demo_data,
  id = "id",
  time = "age",
  outcome = "selfcontrol",
  n_classes = 3,
  growth_model = "linear",
  strata = "stratum",
  cluster = "cluster",
  weights = "weight",
  starts = 80,
  cores = 8,
  verbose = TRUE,
  keep_data = TRUE,
  store_all_starts = FALSE
)
elapsed <- proc.time()[["elapsed"]] - t0
message(sprintf("Fit finished in %.1f seconds", elapsed))

print(fit)

n_classes <- fit@model_info$n_classes
time_scores <- fit@model_info$time_scores
growth_model <- fit@model_info$growth_model

# Build per-class trajectory table (same math as plot_trajectories)
rows <- list()
for (k in seq_len(n_classes)) {
  gp <- fit@parameters$growth_parameters[[k]]
  se <- fit@standard_errors$growth_parameters[[k]]
  y_pred <- surveymixr:::predict_trajectory(time_scores, gp, growth_model)
  y_se <- sqrt(se$intercept^2 + (time_scores * se$slope)^2)
  rows[[k]] <- data.frame(
    class_num = k,
    intercept = gp$intercept,
    slope = gp$slope,
    se_intercept = se$intercept,
    se_slope = se$slope,
    time = time_scores,
    predicted = y_pred,
    lower = y_pred - 1.96 * y_se,
    upper = y_pred + 1.96 * y_se,
    weighted_prop = fit@class_proportions$weighted[k],
    unweighted_prop = fit@class_proportions$unweighted[k],
    stringsAsFactors = FALSE
  )
}
traj <- do.call(rbind, rows)

# Label classes by developmental shape, not estimation order.
# Highest intercept → high-stable; remaining split by slope sign.
class_meta <- unique(traj[, c("class_num", "intercept", "slope",
                              "weighted_prop", "unweighted_prop")])
class_meta <- class_meta[order(-class_meta$intercept), ]
class_meta$label <- NA_character_
class_meta$label[which.max(class_meta$intercept)] <- "High-stable"
unlabeled <- which(is.na(class_meta$label))
class_meta$label[unlabeled[which.max(class_meta$slope[unlabeled])]] <- "Moderate-improving"
class_meta$label[is.na(class_meta$label)] <- "Low-declining"
class_meta$short <- c(
  "High-stable" = "High, stable",
  "Moderate-improving" = "Moderate, improving",
  "Low-declining" = "Low, declining"
)[class_meta$label]

palette <- c(
  "High-stable" = "#0F5C4C",
  "Moderate-improving" = "#C47A22",
  "Low-declining" = "#9B2C2C"
)
class_meta$color <- palette[class_meta$label]

traj$label <- class_meta$label[match(traj$class_num, class_meta$class_num)]
traj$short <- class_meta$short[match(traj$class_num, class_meta$class_num)]
traj$color <- class_meta$color[match(traj$class_num, class_meta$class_num)]
traj$legend <- sprintf(
  "%s  ·  %.0f%%",
  traj$short,
  traj$weighted_prop * 100
)

# Person-level observed series for the spaghetti layer
id_var <- fit@model_info$id_var
time_var <- fit@model_info$time_var
out_var <- fit@model_info$outcome_var
person_class <- data.frame(
  id = as.character(unique(demo_data$id)),
  class_num = as.integer(fit@class_assignments),
  stringsAsFactors = FALSE
)
obs <- demo_data[, c("id", "age", "selfcontrol")]
obs$id <- as.character(obs$id)
obs <- merge(obs, person_class, by = "id")
obs <- merge(obs, class_meta[, c("class_num", "label", "color")], by = "class_num")
set.seed(20250917)
sample_ids <- unlist(lapply(split(obs$id, obs$label), function(ids) {
  ids <- unique(ids)
  sample(ids, min(36, length(ids)))
}))
obs_sample <- obs[obs$id %in% sample_ids, ]

saveRDS(fit, "showcase/fit_3class.rds")
saveRDS(demo_data, "showcase/demo_data.rds")
write.csv(traj, "showcase/trajectories.csv", row.names = FALSE)
write.csv(obs_sample, "showcase/observed_sample.csv", row.names = FALSE)

fit_stats <- list(
  n_individuals = fit@model_info$n_obs,
  n_times = fit@model_info$n_times,
  time_scores = as.numeric(time_scores),
  growth_model = growth_model,
  entropy = unname(fit@fit_indices$entropy),
  bic = unname(fit@fit_indices$bic),
  aic = unname(fit@fit_indices$aic),
  loglik = unname(fit@fit_indices$loglik),
  n_starts = fit@convergence_info$n_starts,
  n_replications = fit@convergence_info$n_replications,
  converged = isTRUE(fit@convergence_info$converged),
  elapsed_seconds = elapsed,
  has_weights = fit@survey_design$has_weights,
  has_cluster = fit@survey_design$has_cluster,
  has_strata = fit@survey_design$has_strata,
  classes = lapply(seq_len(nrow(class_meta)), function(i) {
    list(
      class_num = class_meta$class_num[i],
      label = class_meta$label[i],
      short = unname(class_meta$short[i]),
      color = unname(class_meta$color[i]),
      intercept = class_meta$intercept[i],
      slope = class_meta$slope[i],
      weighted_prop = class_meta$weighted_prop[i],
      unweighted_prop = class_meta$unweighted_prop[i]
    )
  }),
  trajectories = traj,
  n_strata = length(unique(demo_data$stratum)),
  n_clusters = length(unique(demo_data$cluster))
)

write_json(fit_stats, "showcase/fit_stats.json", pretty = TRUE, auto_unbox = TRUE)
message("Wrote showcase/fit_3class.rds, trajectories.csv, fit_stats.json")
