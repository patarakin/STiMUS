#!/usr/bin/env Rscript
# =============================================================================
# scratch_wiki_esr.R
#
# MINIMAL pipeline: computes Edit Succession Ratio (ESR-all and ESR-HH) plus
# basic descriptives for each multilingual Scratch wiki dataset. No network
# graphs, no igraph dependency -- just the numbers needed to compare against
# the STiMUS / STiMUS-HAI model output.
#
# INPUT
#   Directory containing files named wiki_df_events_<lang>.csv, identical
#   schema to the Indonesian sample (author_id, author_name, author_type,
#   pageid, page_title, commit_time, ...).
#
# OUTPUT
#   scratch_wikis_esr_summary.csv in --out_dir, one row per language:
#     lang, n_total_edits, n_pages, n_human_actors, n_bot_actors,
#     human_edit_share, esr_all, esr_hh, esr_inflation_pct
#
# USAGE
#   Rscript scratch_wiki_esr.R --input_dir /path/to/csvs --out_dir /path/to/output
#
# DEPENDENCIES: base R only (no igraph, no dplyr/readr required)
# =============================================================================

args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(flag, default) {
  idx <- which(args == flag)
  if (length(idx) == 0 || idx == length(args)) return(default)
  args[idx + 1]
}
INPUT_DIR <- get_arg("--input_dir", ".")
OUT_DIR   <- get_arg("--out_dir", "scratch_wiki_output")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# ESR: base R only. df must have columns pageid, commit_time, author_id.
# ---------------------------------------------------------------------------
compute_esr <- function(df) {
  if (is.null(df) || nrow(df) == 0) {
    return(c(esr = NA_real_, n_cross = 0, n_denom = 0))
  }
  ord <- order(df$pageid, df$commit_time)
  pageid <- df$pageid[ord]
  author_id <- df$author_id[ord]

  prev_author <- ave(author_id, pageid, FUN = function(x) c(NA, x[-length(x)]))

  has_pred <- !is.na(prev_author)
  cross <- has_pred & (prev_author != author_id)

  n_cross <- sum(cross, na.rm = TRUE)
  n_denom <- sum(has_pred, na.rm = TRUE)
  esr <- if (n_denom > 0) n_cross / n_denom else NA_real_

  c(esr = esr, n_cross = n_cross, n_denom = n_denom)
}

# ---------------------------------------------------------------------------
# Process one file
# ---------------------------------------------------------------------------
analyze_one <- function(filepath) {
  lang <- sub("^wiki_df_events_(.*)\\.csv$", "\\1", basename(filepath))
  cat(sprintf(">>> %s (lang=%s)\n", basename(filepath), lang))

  df <- read.csv(filepath, stringsAsFactors = FALSE)

  # Required columns check
  required <- c("pageid", "commit_time", "author_id", "author_type")
  missing_cols <- setdiff(required, names(df))
  if (length(missing_cols) > 0) {
    stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")))
  }

  df$commit_time <- as.POSIXct(df$commit_time, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  df$author_type <- tolower(trimws(df$author_type))

  keep <- !is.na(df$commit_time) & !is.na(df$pageid) & !is.na(df$author_id)
  df <- df[keep, , drop = FALSE]

  df_human <- df[df$author_type == "human", , drop = FALSE]
  df_bot   <- df[df$author_type == "bot", , drop = FALSE]
  df_sys   <- df[df$author_type == "system", , drop = FALSE]

  esr_all <- compute_esr(df)
  esr_hh  <- compute_esr(df_human)

  inflation_pct <- if (!is.na(esr_hh["esr"]) && esr_hh["esr"] != 0) {
    round(100 * (esr_all["esr"] - esr_hh["esr"]) / esr_hh["esr"], 1)
  } else {
    NA_real_
  }

  data.frame(
    lang = lang,
    time_start = as.character(min(df$commit_time)),
    time_end = as.character(max(df$commit_time)),
    n_total_edits = nrow(df),
    n_pages = length(unique(df$pageid)),
    n_actors_total = length(unique(df$author_id)),
    n_human_actors = length(unique(df_human$author_id)),
    n_bot_actors = length(unique(df_bot$author_id)),
    n_human_edits = nrow(df_human),
    n_bot_edits = nrow(df_bot),
    n_system_edits = nrow(df_sys),
    human_edit_share = round(nrow(df_human) / nrow(df), 4),
    bot_edit_share = round(nrow(df_bot) / nrow(df), 4),
    esr_all = round(unname(esr_all["esr"]), 4),
    esr_all_n_cross = unname(esr_all["n_cross"]),
    esr_all_n_denom = unname(esr_all["n_denom"]),
    esr_hh = round(unname(esr_hh["esr"]), 4),
    esr_hh_n_cross = unname(esr_hh["n_cross"]),
    esr_hh_n_denom = unname(esr_hh["n_denom"]),
    esr_inflation_pct = inflation_pct,
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
files <- list.files(INPUT_DIR, pattern = "^wiki_df_events_.*\\.csv$", full.names = TRUE)
if (length(files) == 0) {
  stop(sprintf("No files matching wiki_df_events_*.csv found in %s", INPUT_DIR))
}
cat(sprintf("Found %d file(s): %s\n", length(files), paste(basename(files), collapse = ", ")))

rows <- list()
for (f in files) {
  row <- tryCatch(
    analyze_one(f),
    error = function(e) {
      lang <- sub("^wiki_df_events_(.*)\\.csv$", "\\1", basename(f))
      cat(sprintf("!! FAILED on %s: %s\n", basename(f), conditionMessage(e)))
      data.frame(lang = lang, error = conditionMessage(e), stringsAsFactors = FALSE)
    }
  )
  rows[[length(rows) + 1]] <- row
}

# rbind with different column sets (success rows vs error rows) -- fill missing with NA
all_cols <- unique(unlist(lapply(rows, names)))
rows_filled <- lapply(rows, function(r) {
  missing <- setdiff(all_cols, names(r))
  for (m in missing) r[[m]] <- NA
  r[all_cols]
})
result <- do.call(rbind, rows_filled)

out_path <- file.path(OUT_DIR, "scratch_wikis_esr_summary.csv")
write.csv(result, out_path, row.names = FALSE)
cat(sprintf("\nWritten to: %s\n", out_path))
print(result)
