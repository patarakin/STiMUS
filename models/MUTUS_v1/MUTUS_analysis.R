# =====================================================================
# MUTUS v1.0 — analysis of the BehaviorSpace experiments E0–E5
# File version: A4 (for MUTUS v1.0)
#
# How to run
#   1. Put this file into the folder with the BehaviorSpace tables, e.g.
#        MUTUS_v1.0 E1_ladder-table.csv  (any name containing "E1_ladder"
#        and ending in "table.csv" is found)
#   2. Choose the experiments in section 0 (EXPERIMENTS) and press Source
#      in RStudio (or source("MUTUS_analysis.R")).
#   3. Results are written next to the tables:
#        <exp>_check.txt     checksums and session info
#        <exp>_summary.csv   cell means and standard errors
#        <exp>_net.csv       E1, E2: NODF and modularity per run vs null model
#        <exp>_windows.csv   E3, E4: networks in 50-tick windows
#        e4_renewals.csv     E4: all renewals
#        e1_effects.csv      E1: main effect of each mechanism
#        e5_src.csv          E5: standardised regression coefficients
#        e5_contrast.csv     E5: robustness of the meadow–wiki contrasts
#        fig_<exp>_*.png     figures
#
# Packages: dplyr, tidyr, ggplot2, vegan, igraph (parallel is part of R)
#   install.packages(c("dplyr", "tidyr", "ggplot2", "vegan", "igraph"))
#
# History: A1 reading, checks, windows (E3); A2 figures (E3);
#          A3 renewal (E4); A4 English, all experiments E0–E5.
# =====================================================================


# ---------------------------------------------------------------------
# 0. SETTINGS
# ---------------------------------------------------------------------
EXPERIMENTS  <- c("E0", "E1", "E2", "E3", "E4", "E5")   # which ones to analyse
DO_NET       <- TRUE    # E1, E2: NODF / Q per run vs null model (slowest step)
DO_WINDOWS   <- TRUE    # E3, E4: networks in time windows (minutes)
DO_FIGURES   <- TRUE
NSIM_NODF    <- 49      # null matrices per run for NODF (99 for the final paper)
NSIM_Q       <- 19      # null matrices per run for modularity
NSIM_WINDOW  <- 19      # null matrices per window
WINDOW_WIDTH <- 50
RUN_LENGTH   <- 150


# ---------------------------------------------------------------------
# 1. Folder and packages
# ---------------------------------------------------------------------
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2)
  library(vegan); library(igraph); library(parallel)
})

local({                                   # working folder = folder of this file
  f <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (is.null(f) && requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) f <- rstudioapi::getSourceEditorContext()$path
  if (!is.null(f) && nzchar(f)) setwd(dirname(normalizePath(f)))
})
message("Folder: ", getwd())

CORES <- if (.Platform$OS.type == "windows") 1 else max(1, detectCores() - 1)
pmap_rows <- function(n, FUN) do.call(rbind, mclapply(seq_len(n), FUN, mc.cores = CORES,
                                                      mc.set.seed = TRUE))


# ---------------------------------------------------------------------
# 2. Reading BehaviorSpace tables and string reporters
# ---------------------------------------------------------------------
read_bs_table <- function(path) {          # 6 header lines, then one row per run/step
  d <- read.csv(path, skip = 6, check.names = FALSE, stringsAsFactors = FALSE)
  mutate(d, across(ends_with("?"), ~ .x %in% c("true", TRUE)))
}

parse_records <- function(s, cols) {       # "a:b:c;..." -> data.frame
  if (is.na(s) || s == "")
    return(setNames(as.data.frame(matrix(nrow = 0, ncol = length(cols))), cols))
  x <- do.call(rbind, strsplit(strsplit(s, ";", fixed = TRUE)[[1]], ":", fixed = TRUE))
  x <- as.data.frame(x, stringsAsFactors = FALSE); names(x) <- cols
  type.convert(x, as.is = TRUE)
}
parse_web       <- function(s) {           # web-edgelist -> weighted matrix
  e <- parse_records(s, c("f", "r", "n"))
  if (nrow(e) == 0) return(matrix(0, 0, 0))
  unclass(xtabs(n ~ f + r, data = e))
}
parse_sequence  <- function(s) parse_records(s, c("tick", "f", "r"))
parse_resources <- function(s)
  parse_records(s, c("id", "cluster", "complexity", "x", "y", "quality", "vitality"))
parse_skills    <- function(s) parse_records(s, c("id", "skill0", "skill"))
parse_renewals  <- function(s)
  parse_records(s, c("tick", "slot", "parent", "author", "old", "new"))

# Complexity of the visited resource at the moment of each visit.
# A renewal at tick u applies to visits at ticks t > u (visits precede renewals).
complexity_at_visit <- function(sq, rt, s_ren = NULL) {
  cx <- rt$complexity[match(sq$r, rt$id)]
  if (is.null(s_ren) || is.na(s_ren) || s_ren == "") return(cx)
  rr <- parse_renewals(s_ren)
  for (k in unique(rr$slot)) {
    rk <- rr[rr$slot == k, ]; rk <- rk[order(rk$tick), ]
    v  <- which(sq$r == k)
    if (length(v) == 0) next
    j  <- findInterval(sq$tick[v] - 0.5, rk$tick)
    cx[v] <- ifelse(j == 0, rk$old[1], rk$new[pmax(j, 1)])
  }
  cx
}


# ---------------------------------------------------------------------
# 3. Network metrics vs curveball null model (fixed row and column sums)
# ---------------------------------------------------------------------
binary_nonempty <- function(W) {
  M <- (W > 0) * 1
  M[rowSums(M) > 0, colSums(M) > 0, drop = FALSE]
}
q_louvain <- function(M) modularity(cluster_louvain(graph_from_biadjacency_matrix(M)))

z_metrics <- function(M, nsim_nodf = NSIM_NODF, nsim_q = NSIM_Q) {
  if (nrow(M) < 3 || ncol(M) < 3)
    return(c(NODF = NA, NODF_null = NA, z_NODF = NA, Q = NA, Q_null = NA, z_Q = NA,
             links = sum(M), n_f = nrow(M), n_r = ncol(M)))
  nm <- simulate(nullmodel(M, "curveball"), nsim = max(nsim_nodf, nsim_q), thin = 100)
  n0 <- nestednodf(M)$statistic["NODF"]
  nn <- apply(nm[, , seq_len(nsim_nodf), drop = FALSE], 3,
              function(X) nestednodf(X)$statistic["NODF"])
  q0 <- q_louvain(M)
  qn <- apply(nm[, , seq_len(nsim_q), drop = FALSE], 3, q_louvain)
  c(NODF = unname(n0), NODF_null = mean(nn), z_NODF = unname((n0 - mean(nn)) / sd(nn)),
    Q = q0, Q_null = mean(qn), z_Q = (q0 - mean(qn)) / sd(qn),
    links = sum(M), n_f = nrow(M), n_r = ncol(M))
}


# ---------------------------------------------------------------------
# 4. Time windows (E3, E4)
# ---------------------------------------------------------------------
window_matrix <- function(sq, t0, t1) {
  w <- sq[sq$tick >= t0 & sq$tick < t1, ]
  if (nrow(w) == 0) return(matrix(0, 0, 0))
  binary_nonempty(unclass(table(w$f, w$r)))
}
run_windows <- function(s_seq, s_res, s_ren = NULL) {
  sq <- parse_sequence(s_seq)
  sq$complexity <- complexity_at_visit(sq, parse_resources(s_res), s_ren)
  do.call(rbind, lapply(seq(0, RUN_LENGTH - WINDOW_WIDTH, by = WINDOW_WIDTH), function(t0) {
    in_w <- sq$tick >= t0 & sq$tick < t0 + WINDOW_WIDTH
    c(window = t0,
      z_metrics(window_matrix(sq, t0, t0 + WINDOW_WIDTH), NSIM_WINDOW, NSIM_WINDOW),
      visits = sum(in_w), complexity = mean(sq$complexity[in_w]))
  }))
}


# ---------------------------------------------------------------------
# 5. Experiment registry: table name and design variables (KEY)
# ---------------------------------------------------------------------
SWITCHES <- c("trait-matching?", "feedback?", "adaptive-foraging?",
              "trait-development?", "renewal?")
E5_PARS  <- c("mutualism-strength", "regeneration-rate", "adaptation-rate",
              "visit-cost", "activity-mean")
REG <- list(
  E0 = list(pattern = "E0_demo",        key = c("world-type", "[step]")),
  E1 = list(pattern = "E1_ladder",      key = c("world-type", SWITCHES)),
  E2 = list(pattern = "E2_radius",      key = c("world-type", "perception-radius",
                                                "adaptive-foraging?")),
  E3 = list(pattern = "E3_development", key = c("world-type", "perception-radius",
                                                "skill-growth")),
  E4 = list(pattern = "E4_renewal",     key = c("world-type", "perception-radius",
                                                "skill-growth", "renewal?")),
  E5 = list(pattern = "E5_sensitivity", key = c("world-type", E5_PARS)))

SCALARS <- c("share-active-foragers", "share-alive-resources", "mean-energy", "mean-quality",
             "mean-skill", "skill-gain", "fail-rate", "service-rate", "share-in-band",
             "share-too-easy", "cross-cluster-share", "mean-gain-per-visit", "unique-links",
             "connectance-obs", "effective-diet", "visit-diet", "renewal-count",
             "share-renewed", "mean-complexity", "mean-complexity-alive",
             "skill-complexity-gap")

LADDER <- function(d) {                    # cumulative ladder M0 ... M5a (E1)
  s <- as.matrix(d[, SWITCHES]) * 1
  code <- apply(s, 1, paste, collapse = "")
  c("00000" = "M0", "10000" = "M1", "11000" = "M2", "11100" = "M3",
    "11110" = "M4", "11111" = "M5a")[code]
}

th <- theme_minimal(base_size = 11) +
      theme(panel.grid.minor = element_blank(), legend.position = "bottom")
WORLD_COL <- c(meadow = "#4E8F3A", wiki = "#3A5F8F")
save_fig <- function(p, file, w, h) {
  ggsave(file, p, width = w, height = h, dpi = 300, bg = "white"); message("  ", file)
}
f_out <- function(e, x) paste0(tolower(e), "_", x)
long_summary <- function(summ, key, metrics) summ |>
  select(all_of(key), ends_with("_mean"), ends_with("_se")) |>
  pivot_longer(-all_of(key), names_to = c("metric", ".value"),
               names_pattern = "^(.*)_(mean|se)$") |>
  filter(metric %in% metrics) |>
  mutate(metric = factor(metric, levels = metrics))


# ---------------------------------------------------------------------
# 6. Common steps: read, check, summary
# ---------------------------------------------------------------------
load_experiment <- function(e) {
  f <- list.files(pattern = paste0(REG[[e]]$pattern, ".*table\\.csv$"))
  if (length(f) == 0) { message(e, ": no table found, skipped"); return(NULL) }
  if (length(f) > 1) stop(e, ": several tables match: ", paste(f, collapse = ", "))
  message(e, ": ", f)
  d <- read_bs_table(f)
  attr(d, "file") <- f
  d
}

check_experiment <- function(e, d) {
  last <- if (e == "E0") d[d$`[step]` == max(d$`[step]`), ] else d
  chk <- c(sprintf("table: %s", attr(d, "file")),
           sprintf("rows: %d", nrow(d)),
           sprintf("sum unique-links%s: %d", if (e == "E0") " (last step)" else "",
                   sum(last$`unique-links`)),
           sprintf("mean share-alive-resources%s: %.6f", if (e == "E0") " (last step)" else "",
                   mean(last$`share-alive-resources`)))
  if ("skill-gain" %in% names(d))
    chk <- c(chk, sprintf("mean skill-gain: %.6f", round(mean(d$`skill-gain`), 9) + 0))
  if (all(c("share-in-band", "share-too-easy") %in% names(d))) {
    tm <- if ("trait-matching?" %in% names(d)) d$`trait-matching?` else TRUE
    ok <- abs(d$`share-in-band` + d$`share-too-easy` + d$`fail-rate` - 1) < 1e-9
    chk <- c(chk, sprintf("band + easy + fail = 1 (trait matching on): %s", all(ok[tm])))
  }
  writeLines(c(chk, "", capture.output(sessionInfo())), f_out(e, "check.txt"))
  cat(paste0("  ", chk), sep = "\n")
}

summarise_experiment <- function(e, d) {
  key <- REG[[e]]$key
  m   <- intersect(SCALARS, names(d))
  s <- d |>
    group_by(across(all_of(key))) |>
    summarise(n = n(), across(all_of(m), list(mean = ~ mean(.x, na.rm = TRUE),
                                             se = ~ sd(.x, na.rm = TRUE) / sqrt(n()))),
              .groups = "drop")
  if (e == "E1") s <- mutate(s, level = LADDER(s), .after = all_of(key))
  write.csv(s, f_out(e, "summary.csv"), row.names = FALSE)
  s
}

net_experiment <- function(e, d) {         # whole-run network per run (E1, E2)
  key <- REG[[e]]$key
  t0 <- Sys.time(); RNGkind("L'Ecuyer-CMRG"); set.seed(2026)
  net <- pmap_rows(nrow(d), function(i)
    data.frame(run = d$`[run number]`[i], d[i, key],
               t(z_metrics(binary_nonempty(parse_web(d$`web-edgelist`[i])))),
               check.names = FALSE, row.names = NULL))
  write.csv(net, f_out(e, "net.csv"), row.names = FALSE)
  message("  ", f_out(e, "net.csv"), ": ",
          round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " min")
  net
}

windows_experiment <- function(e, d) {     # time windows (E3, E4)
  key <- REG[[e]]$key
  t0 <- Sys.time(); RNGkind("L'Ecuyer-CMRG"); set.seed(2026)
  win <- pmap_rows(nrow(d), function(i)
    data.frame(run = d$`[run number]`[i], d[i, key],
               run_windows(d$`visit-sequence`[i], d$`resource-traits`[i],
                           if ("renewal-list" %in% names(d)) d$`renewal-list`[i]),
               check.names = FALSE, row.names = NULL))
  write.csv(win, f_out(e, "windows.csv"), row.names = FALSE)
  message("  ", f_out(e, "windows.csv"), ": ",
          round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " min")
  win
}

cell_mean <- function(x, key, v) x |>     # mean and SE of one column per cell
  group_by(across(all_of(key))) |>
  summarise(m = mean(.data[[v]], na.rm = TRUE),
            se = sd(.data[[v]], na.rm = TRUE) / sqrt(sum(!is.na(.data[[v]]))),
            .groups = "drop")


# ---------------------------------------------------------------------
# 7. Experiment-specific analyses and figures
# ---------------------------------------------------------------------

# 7.0 E0 — time course of one semester
analyse_E0 <- function(d, summ) {
  if (!DO_FIGURES) return(invisible())
  mets <- c("share-active-foragers", "share-alive-resources", "mean-quality",
            "mean-skill", "fail-rate", "share-too-easy", "skill-complexity-gap",
            "unique-links")
  p <- long_summary(summ, REG$E0$key, mets) |>
    ggplot(aes(`[step]`, mean, colour = `world-type`, fill = `world-type`)) +
    geom_ribbon(aes(ymin = mean - se, ymax = mean + se), colour = NA, alpha = 0.2) +
    geom_line() +
    facet_wrap(~ metric, scales = "free_y", ncol = 4) +
    scale_colour_manual(values = WORLD_COL, name = NULL) +
    scale_fill_manual(values = WORLD_COL, name = NULL) +
    labs(x = "Tick", y = NULL) + th
  save_fig(p, "fig_e0_timecourse.png", 11, 5.5)
}

# 7.1 E1 — model ladder and main effects of each mechanism
analyse_E1 <- function(d, summ, net) {
  m <- intersect(c("fail-rate", "share-active-foragers", "share-alive-resources",
                   "mean-quality", "unique-links", "share-too-easy", "skill-gain",
                   "cross-cluster-share"), names(d))
  # main effect = mean(switch on) - mean(switch off) over the whole factorial
  eff <- do.call(rbind, lapply(split(d, d$`world-type`), function(dw)
    do.call(rbind, lapply(SWITCHES, function(sw)
      data.frame(world = dw$`world-type`[1], mechanism = sw, metric = m,
                 effect = sapply(m, function(v) mean(dw[[v]][dw[[sw]]]) -
                                                  mean(dw[[v]][!dw[[sw]]])),
                 row.names = NULL)))))
  write.csv(eff, "e1_effects.csv", row.names = FALSE)
  if (!DO_FIGURES) return(invisible())

  lev <- c("M0", "M1", "M2", "M3", "M4", "M5a")
  lad <- long_summary(filter(summ, !is.na(level)), c(REG$E1$key, "level"),
                      c("fail-rate", "share-active-foragers", "share-alive-resources",
                        "mean-quality", "unique-links", "share-too-easy"))
  if (!is.null(net)) {
    netl <- net |> mutate(level = LADDER(net)) |> filter(!is.na(level)) |>
      pivot_longer(c(z_NODF, z_Q), names_to = "metric", values_to = "v") |>
      group_by(`world-type`, level, metric) |>
      summarise(mean = mean(v, na.rm = TRUE), se = sd(v, na.rm = TRUE) / sqrt(n()),
                .groups = "drop")
    lad <- bind_rows(mutate(lad, metric = as.character(metric)), netl)
  }
  p <- ggplot(lad, aes(factor(level, levels = lev), mean, colour = `world-type`,
                       group = `world-type`)) +
    geom_errorbar(aes(ymin = mean - se, ymax = mean + se), width = 0.15) +
    geom_line() + geom_point(size = 1.8) +
    facet_wrap(~ metric, scales = "free_y", ncol = 4) +
    scale_colour_manual(values = WORLD_COL, name = NULL) +
    labs(x = "Model level", y = NULL) + th
  save_fig(p, "fig_e1_ladder.png", 11, 6)

  p2 <- ggplot(eff, aes(effect, mechanism, fill = world)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_vline(xintercept = 0, colour = "grey50") +
    facet_wrap(~ metric, scales = "free_x", ncol = 4) +
    scale_fill_manual(values = WORLD_COL, name = NULL) +
    labs(x = "Main effect (mean on − mean off)", y = NULL) + th
  save_fig(p2, "fig_e1_effects.png", 11, 6)
}

# 7.2 E2 — perception radius
analyse_E2 <- function(d, summ, net) {
  if (!DO_FIGURES) return(invisible())
  key <- REG$E2$key
  r <- long_summary(summ, key, c("share-active-foragers", "share-alive-resources",
                                 "mean-quality", "fail-rate", "cross-cluster-share",
                                 "unique-links"))
  if (!is.null(net)) {
    nl <- bind_rows(cell_mean(net, key, "z_NODF") |> mutate(metric = "z_NODF"),
                    cell_mean(net, key, "z_Q")    |> mutate(metric = "z_Q")) |>
      rename(mean = m)
    r <- bind_rows(mutate(r, metric = as.character(metric)), nl)
  }
  p <- ggplot(r, aes(`perception-radius`, mean,
                     colour = ifelse(`adaptive-foraging?`, "M3", "M2"))) +
    geom_errorbar(aes(ymin = mean - se, ymax = mean + se), width = 0.3) +
    geom_line() + geom_point(size = 1.4) +
    facet_grid(metric ~ `world-type`, scales = "free_y") +
    scale_colour_manual(values = c(M2 = "#9A9A9A", M3 = "#C0392B"), name = NULL) +
    labs(x = "Perception radius", y = NULL) + th
  save_fig(p, "fig_e2_radius.png", 7.5, 12)
}

# 7.3 E3 — learning (dose-response and windows)
analyse_E3 <- function(d, summ, win) {
  if (!DO_FIGURES) return(invisible())
  key <- REG$E3$key
  p <- long_summary(summ, key, c("skill-gain", "share-too-easy", "fail-rate",
                                 "share-alive-resources", "mean-quality",
                                 "share-active-foragers")) |>
    ggplot(aes(`skill-growth`, mean, colour = factor(`perception-radius`))) +
    geom_errorbar(aes(ymin = mean - se, ymax = mean + se), width = 0.003) +
    geom_line() + geom_point(size = 1.5) +
    facet_grid(metric ~ `world-type`, scales = "free_y") +
    scale_colour_manual(values = c(`3` = "#C9A227", `6` = "#7A7A7A", `12` = "#5B2A86"),
                        name = "Perception radius") +
    labs(x = "Learning rate (skill-growth)", y = NULL) + th
  save_fig(p, "fig_e3_dose_response.png", 7, 11)
  if (!is.null(win)) windows_figure(win, key, "skill-growth", "fig_e3_windows.png")

  dd <- do.call(rbind, lapply(which(d$`skill-growth` > 0 & d$`perception-radius` == 6),
    function(i) { k <- parse_skills(d$`forager-skills`[i])
      data.frame(d[i, key], skill0 = k$skill0, gain = k$skill - k$skill0,
                 check.names = FALSE, row.names = NULL) }))
  p3 <- ggplot(dd, aes(skill0, gain, colour = `world-type`)) +
    geom_point(alpha = 0.15, size = 0.7) +
    geom_smooth(method = "loess", formula = y ~ x, se = FALSE, linewidth = 0.8) +
    facet_wrap(~ `skill-growth`, nrow = 1, labeller = label_both) +
    scale_colour_manual(values = WORLD_COL, name = NULL) +
    labs(x = "Initial skill", y = "Skill gain in 150 ticks",
         title = "Perception radius 6") + th
  save_fig(p3, "fig_e3_who_learns.png", 10, 3.8)
}

# windows figure for E3 / E4: complexity of visited resources, z(NODF), z(Q)
windows_figure <- function(win, key, colour_by, file) {
  w <- win |>
    pivot_longer(c(complexity, z_NODF, z_Q), names_to = "metric", values_to = "v") |>
    group_by(across(all_of(key)), window, metric) |>
    summarise(m = mean(v, na.rm = TRUE), .groups = "drop") |>
    mutate(t = window + WINDOW_WIDTH / 2)
  grp <- setdiff(key, c("world-type", "perception-radius"))
  p <- ggplot(w, aes(t, m, colour = factor(.data[[colour_by]]),
                     group = interaction(!!!syms(grp)))) +
    geom_line() + geom_point(size = 1.2) +
    facet_grid(metric ~ `world-type` + `perception-radius`, scales = "free_y",
               labeller = labeller(`perception-radius` = function(x) paste("r =", x))) +
    scale_colour_viridis_d(name = colour_by, end = 0.9) +
    scale_x_continuous(breaks = seq(WINDOW_WIDTH / 2, RUN_LENGTH, WINDOW_WIDTH)) +
    labs(x = "Window centre (tick)", y = NULL) + th
  if ("renewal?" %in% grp)
    p <- p + aes(linetype = ifelse(`renewal?`, "renewal on", "renewal off")) +
      labs(linetype = NULL)
  save_fig(p, file, 10, 6.5)
}

# 7.4 E4 — renewal
analyse_E4 <- function(d, summ, win) {
  key <- REG$E4$key
  ren <- do.call(rbind, lapply(seq_len(nrow(d)), function(i) {
    r <- parse_renewals(d$`renewal-list`[i])
    if (nrow(r) == 0) return(NULL)
    data.frame(run = d$`[run number]`[i], d[i, key], r, check.names = FALSE,
               row.names = NULL)
  }))
  write.csv(ren, "e4_renewals.csv", row.names = FALSE)
  if (!DO_FIGURES) return(invisible())
  p <- long_summary(summ, key, c("share-too-easy", "skill-complexity-gap",
                                 "mean-complexity-alive", "share-active-foragers",
                                 "share-alive-resources", "mean-quality")) |>
    ggplot(aes(`skill-growth`, mean, colour = `renewal?`, group = `renewal?`)) +
    geom_errorbar(aes(ymin = mean - se, ymax = mean + se), width = 0.004) +
    geom_line() + geom_point(size = 1.5) +
    facet_grid(metric ~ `world-type` + `perception-radius`, scales = "free_y",
               labeller = labeller(`perception-radius` = function(x) paste("r =", x))) +
    scale_colour_manual(values = c(`FALSE` = "#9A9A9A", `TRUE` = "#C0392B"),
                        labels = c("M4 (no renewal)", "M5a (renewal)"), name = NULL) +
    labs(x = "Learning rate (skill-growth)", y = NULL) + th
  save_fig(p, "fig_e4_renewal_effect.png", 9, 11)

  nc <- ren |>
    mutate(t = floor(tick / WINDOW_WIDTH) * WINDOW_WIDTH + WINDOW_WIDTH / 2) |>
    group_by(across(all_of(key)), t) |>
    summarise(m = mean(new), se = sd(new) / sqrt(n()), .groups = "drop")
  p2 <- ggplot(nc, aes(t, m, colour = factor(`skill-growth`))) +
    geom_errorbar(aes(ymin = m - se, ymax = m + se), width = 4) +
    geom_line() + geom_point(size = 1.5) +
    facet_grid(`world-type` ~ `perception-radius`,
               labeller = labeller(`perception-radius` = function(x) paste("r =", x))) +
    scale_colour_viridis_d(name = "skill-growth", end = 0.9) +
    labs(x = "Window centre (tick)", y = "Complexity of new resources") + th
  save_fig(p2, "fig_e4_newcomer_complexity.png", 7, 5)
  if (!is.null(win)) windows_figure(win, key, "skill-growth", "fig_e4_windows.png")
}

# 7.5 E5 — global sensitivity and robustness of the meadow–wiki contrasts
analyse_E5 <- function(d, summ) {
  outs <- c("share-active-foragers", "share-alive-resources", "mean-quality",
            "fail-rate", "share-too-easy", "skill-gain", "skill-complexity-gap",
            "unique-links", "cross-cluster-share")
  # standardised regression coefficients (SRC) per world and output
  src <- do.call(rbind, lapply(split(d, d$`world-type`), function(dw)
    do.call(rbind, lapply(outs, function(y) {
      z <- as.data.frame(scale(dw[, c(y, E5_PARS)]))
      names(z) <- make.names(names(z))
      fit <- lm(reformulate(make.names(E5_PARS), make.names(y)), data = z)
      data.frame(world = dw$`world-type`[1], output = y, parameter = E5_PARS,
                 SRC = unname(coef(fit)[-1]), R2 = summary(fit)$r.squared,
                 row.names = NULL)
    }))))
  write.csv(src, "e5_src.csv", row.names = FALSE)

  # contrast wiki - meadow in every parameter cell; does its sign hold?
  cm <- d |>
    group_by(across(all_of(REG$E5$key))) |>
    summarise(across(all_of(outs), mean), .groups = "drop") |>
    pivot_longer(all_of(outs), names_to = "output") |>
    pivot_wider(names_from = `world-type`, values_from = value) |>
    mutate(contrast = wiki - meadow)
  base <- cm |> filter(`mutualism-strength` == 0.1, `regeneration-rate` == 0.2,
                       `adaptation-rate` == 5, `visit-cost` == 0.05,
                       `activity-mean` == 0.3) |>
    select(output, base = contrast)
  rob <- cm |> left_join(base, by = "output") |>
    group_by(output) |>
    summarise(contrast_default = first(base),
              contrast_median = median(contrast),
              contrast_min = min(contrast), contrast_max = max(contrast),
              share_same_sign = mean(sign(contrast) == sign(first(base))),
              .groups = "drop")
  write.csv(rob, "e5_contrast.csv", row.names = FALSE)
  print(rob, n = Inf)
  if (!DO_FIGURES) return(invisible())

  p <- ggplot(src, aes(SRC, parameter, fill = world)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_vline(xintercept = 0, colour = "grey50") +
    facet_wrap(~ output, ncol = 3) +
    scale_fill_manual(values = WORLD_COL, name = NULL) +
    labs(x = "Standardised regression coefficient", y = NULL) + th
  save_fig(p, "fig_e5_src.png", 10, 9)

  p2 <- ggplot(cm, aes(contrast, output)) +
    geom_vline(xintercept = 0, colour = "grey50") +
    geom_jitter(height = 0.15, alpha = 0.25, size = 0.8, colour = "#5B2A86") +
    geom_point(data = base, aes(base, output), colour = "#C0392B", size = 3, shape = 18) +
    facet_wrap(~ output, scales = "free", ncol = 3) +
    scale_x_continuous(n.breaks = 4) +
    labs(x = "Contrast wiki − meadow in each of 243 parameter cells (red = defaults)",
         y = NULL) + th + theme(axis.text.y = element_blank())
  save_fig(p2, "fig_e5_contrast.png", 10, 8)
}


# ---------------------------------------------------------------------
# 8. Run
# ---------------------------------------------------------------------
for (e in EXPERIMENTS) {
  d <- load_experiment(e)
  if (is.null(d)) next
  check_experiment(e, d)
  summ <- summarise_experiment(e, d)
  net <- if (DO_NET && e %in% c("E1", "E2")) net_experiment(e, d)
  win <- if (DO_WINDOWS && e %in% c("E3", "E4")) windows_experiment(e, d)
  switch(e,
         E0 = analyse_E0(d, summ),
         E1 = analyse_E1(d, summ, net),
         E2 = analyse_E2(d, summ, net),
         E3 = analyse_E3(d, summ, win),
         E4 = analyse_E4(d, summ, win),
         E5 = analyse_E5(d, summ))
}
message("Done. Send the *_check.txt, *_summary.csv, *_net.csv, *_windows.csv, ",
        "e1_effects.csv, e5_src.csv and e5_contrast.csv files.")
