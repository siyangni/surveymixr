#!/usr/bin/env Rscript
# Publication figure for the website showcase.

suppressPackageStartupMessages({
  library(ggplot2)
  library(surveymixr)
})

traj <- read.csv("showcase/trajectories.csv", stringsAsFactors = FALSE)
obs <- read.csv("showcase/observed_sample.csv", stringsAsFactors = FALSE)
stats <- jsonlite::fromJSON("showcase/fit_stats.json")

label_levels <- c("High-stable", "Moderate-improving", "Low-declining")
short_levels <- c("High, stable", "Moderate, improving", "Low, declining")
traj$label <- factor(traj$label, levels = label_levels)
obs$label <- factor(obs$label, levels = label_levels)

pal <- c(
  "High-stable" = "#0F5C4C",
  "Moderate-improving" = "#C47A22",
  "Low-declining" = "#9B2C2C"
)

end_pts <- traj[traj$time == max(traj$time), ]
end_pts$short <- c(
  "High-stable" = "High, stable",
  "Moderate-improving" = "Improving",
  "Low-declining" = "Declining"
)[as.character(end_pts$label)]
end_pts$pct <- sprintf("%.0f%%", end_pts$weighted_prop * 100)
end_pts$lab <- paste0(end_pts$short, "  ", end_pts$pct)
# Nudge labels so High and Improving do not collide at age 17
end_pts$lab_y <- end_pts$predicted
end_pts$lab_y[end_pts$label == "High-stable"] <- end_pts$predicted[end_pts$label == "High-stable"] + 0.28
end_pts$lab_y[end_pts$label == "Moderate-improving"] <- end_pts$predicted[end_pts$label == "Moderate-improving"] - 0.32

paper <- "#F3EEE4"
ink <- "#1C1814"
muted <- "#5C5348"

p <- ggplot() +
  geom_line(
    data = obs,
    aes(x = age, y = selfcontrol, group = id, color = label),
    alpha = 0.13, linewidth = 0.38, lineend = "round"
  ) +
  geom_ribbon(
    data = traj,
    aes(x = time, ymin = lower, ymax = upper, fill = label),
    alpha = 0.28, color = NA
  ) +
  geom_line(
    data = traj,
    aes(x = time, y = predicted, color = label),
    linewidth = 1.55, lineend = "round"
  ) +
  geom_point(
    data = traj,
    aes(x = time, y = predicted, color = label),
    size = 2.15
  ) +
  geom_text(
    data = end_pts,
    aes(x = 17.35, y = lab_y, label = lab, color = label),
    hjust = 0, vjust = 0.5, size = 3.6,
    family = "Bitstream Charter", fontface = "italic"
  ) +
  scale_color_manual(values = pal, guide = "none") +
  scale_fill_manual(values = pal, guide = "none") +
  scale_x_continuous(
    breaks = c(3, 5, 7, 11, 14, 17),
    limits = c(2.6, 21.2),
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    breaks = seq(0, 12, 2),
    limits = c(0.2, 11.6),
    expand = c(0, 0)
  ) +
  labs(
    title = "Three developmental pathways of self-control",
    subtitle = sprintf(
      "Survey-weighted 3-class GMM  ·  N = %s  ·  4 strata, 80 PSUs  ·  entropy %.3f",
      format(stats$n_individuals, big.mark = ","),
      stats$entropy
    ),
    x = "Age (years)",
    y = "Self-control",
    caption = "Faint lines are observed individual series. Bold lines and ribbons are class means with 95% survey-adjusted CIs."
  ) +
  theme_minimal(base_family = "Bitstream Charter", base_size = 13) +
  theme(
    plot.background = element_rect(fill = paper, color = NA),
    panel.background = element_rect(fill = paper, color = NA),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_line(color = "#D8CFC2", linewidth = 0.35),
    plot.title = element_text(face = "bold", size = 16.5, color = ink, margin = margin(b = 4)),
    plot.subtitle = element_text(size = 10.5, color = muted, margin = margin(b = 14)),
    plot.caption = element_text(size = 8.5, color = muted, hjust = 0, margin = margin(t = 10)),
    axis.title = element_text(size = 11, color = ink),
    axis.title.y = element_text(margin = margin(r = 8)),
    axis.title.x = element_text(margin = margin(t = 8)),
    axis.text = element_text(size = 10, color = muted),
    axis.ticks.x = element_line(color = "#C4B9A8", linewidth = 0.3),
    axis.ticks.y = element_blank(),
    plot.margin = margin(16, 16, 12, 16)
  )

fit <- readRDS("showcase/fit_3class.rds")
pkg_plot <- plot_trajectories(
  fit,
  include_ci = TRUE,
  colors = unname(pal[label_levels]),
  xlab = "Age (years)",
  ylab = "Self-control",
  title = "Growth Trajectories: 3-Class Solution",
  legend_position = "right"
) +
  theme(
    plot.background = element_rect(fill = paper, color = NA),
    panel.background = element_rect(fill = paper, color = NA)
  )

dir.create("showcase", showWarnings = FALSE)

ggsave(
  "showcase/trajectories.svg", p,
  width = 10.2, height = 6.6, device = svglite::svglite
)
ggsave(
  "showcase/trajectories.png", p,
  width = 10.2, height = 6.6, dpi = 180, bg = paper
)
ggsave(
  "showcase/trajectories-package.png", pkg_plot,
  width = 9.2, height = 6.2, dpi = 160, bg = paper
)

message("Wrote showcase/trajectories.svg, trajectories.png, trajectories-package.png")
