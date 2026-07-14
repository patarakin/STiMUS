#!/usr/bin/env Rscript
# ==============================================================================
# collect_wiki_data.R
#
# Minimal MediaWiki API extractor for a single Scratch wiki.
# Produces one CSV file, wiki_df_events_<code>.csv, with the same schema
# used throughout the STiMUS project (see data/README.md in this repository):
#
#   author_anon, object_id, object_name, commit_time, year, commit_type,
#   commit_message, total_changes, pageid, page_title, revid, parentid,
#   rev_size, source_namespace, author_id, author_name, author_type,
#   minor, anon
#
# Usage:
#   Rscript collect_wiki_data.R <base_api_url> <lang_code> [out_dir]
#
# Example:
#   Rscript collect_wiki_data.R https://en.scratch-wiki.info/w/api.php en data/
#
# Requires: httr, jsonlite, dplyr (install.packages(c("httr","jsonlite","dplyr")))
# ==============================================================================

suppressWarnings(suppressMessages({
  library(httr)
  library(jsonlite)
  library(dplyr)
}))

DEFAULT_DELAY  <- 0.5
API_TIMEOUT    <- 30
MAX_RETRIES    <- 4

# ---------- Generic request helper with retries ----------
safe_get <- function(base_url, params, max_retries = MAX_RETRIES) {
  for (attempt in seq_len(max_retries)) {
    ans <- tryCatch({
      resp <- GET(base_url, query = params, timeout(API_TIMEOUT))
      if (status_code(resp) != 200) return(NULL)
      txt <- content(resp, as = "text", encoding = "UTF-8")
      fromJSON(txt, simplifyVector = TRUE)
    }, error = function(e) NULL)
    if (!is.null(ans)) return(ans)
    Sys.sleep(1)
  }
  NULL
}

# ---------- Robust extractor for data$query$pages ----------
extract_page_data <- function(pages_obj) {
  if (is.null(pages_obj)) return(NULL)

  if (is.data.frame(pages_obj)) {
    if (nrow(pages_obj) == 0) return(NULL)
    return(as.list(pages_obj[1, , drop = FALSE]))
  }

  if (is.list(pages_obj)) {
    if (length(pages_obj) == 0) return(NULL)
    first_el <- pages_obj[[1]]
    if (is.data.frame(first_el)) {
      if (nrow(first_el) == 0) return(NULL)
      return(as.list(first_el[1, , drop = FALSE]))
    }
    if (is.list(first_el)) return(first_el)
    if (!is.null(names(pages_obj)) &&
        all(c("pageid", "title") %in% names(pages_obj))) {
      return(pages_obj)
    }
  }
  NULL
}

# ---------- 1. All content pages (namespace 0) ----------
get_all_pages <- function(base_url, delay = DEFAULT_DELAY, verbose = TRUE) {
  all_pages <- tibble()
  apcontinue <- NULL

  repeat {
    params <- list(
      action        = "query",
      list          = "allpages",
      apnamespace   = "0",
      aplimit       = "max",
      apdir         = "ascending",
      formatversion = "2",
      format        = "json"
    )
    if (!is.null(apcontinue)) params$apcontinue <- apcontinue

    data <- safe_get(base_url, params)
    if (is.null(data) || is.null(data$query$allpages)) break

    batch <- as_tibble(data$query$allpages) %>%
      select(any_of(c("pageid", "ns", "title"))) %>%
      rename(page_title = title, source_namespace = ns) %>%
      mutate(pageid = as.numeric(pageid),
             source_namespace = as.integer(source_namespace))

    all_pages <- bind_rows(all_pages, batch)
    if (verbose) message("  pages collected: ", nrow(all_pages))

    if (is.null(data$continue$apcontinue)) break
    apcontinue <- data$continue$apcontinue
    Sys.sleep(delay)
  }

  all_pages %>%
    filter(!is.na(pageid)) %>%
    distinct(pageid, .keep_all = TRUE) %>%
    arrange(pageid)
}

# ---------- 2. List of bot accounts (list=allusers&augroup=bot) ----------
get_bot_names <- function(base_url, delay = DEFAULT_DELAY) {
  bots <- character(0)
  aufrom <- NULL

  repeat {
    params <- list(
      action        = "query",
      list          = "allusers",
      augroup       = "bot",
      aulimit       = "max",
      formatversion = "2",
      format        = "json"
    )
    if (!is.null(aufrom)) params$aufrom <- aufrom

    data <- safe_get(base_url, params)
    if (is.null(data) || is.null(data$query$allusers)) break

    users_df <- as_tibble(data$query$allusers)
    if ("name" %in% names(users_df)) bots <- c(bots, users_df$name)

    if (is.null(data$continue$aufrom)) break
    aufrom <- data$continue$aufrom
    Sys.sleep(delay)
  }

  unique(bots)
}

# ---------- 3. Revisions for one page ----------
get_page_revisions <- function(base_url, pageid, delay = DEFAULT_DELAY) {
  params <- list(
    action        = "query",
    prop          = "revisions",
    pageids       = as.character(pageid),
    rvprop        = "ids|timestamp|comment|user|userid|size|flags",
    rvlimit       = "max",
    rvdir         = "newer",
    formatversion = "2",
    format        = "json"
  )

  page_rows <- tibble()

  repeat {
    data <- safe_get(base_url, params)
    if (is.null(data) || is.null(data$query) || is.null(data$query$pages)) break

    page_data <- extract_page_data(data$query$pages)
    if (is.null(page_data) || !is.list(page_data)) break
    if (is.null(page_data[["revisions"]])) break

    revs_raw <- page_data[["revisions"]]
    if (is.data.frame(revs_raw)) {
      revs_df <- as_tibble(revs_raw)
    } else if (is.list(revs_raw) && length(revs_raw) > 0) {
      revs_df <- tryCatch(as_tibble(dplyr::bind_rows(revs_raw)), error = function(e) NULL)
    } else {
      revs_df <- NULL
    }

    if (!is.null(revs_df) && nrow(revs_df) > 0) {
      parsed <- revs_df %>%
        transmute(
          author_id      = if ("userid" %in% names(.)) suppressWarnings(as.numeric(userid)) else NA_real_,
          author_name    = if ("user" %in% names(.)) as.character(user) else NA_character_,
          revid          = if ("revid" %in% names(.)) suppressWarnings(as.numeric(revid)) else NA_real_,
          parentid       = if ("parentid" %in% names(.)) suppressWarnings(as.numeric(parentid)) else NA_real_,
          commit_time    = if ("timestamp" %in% names(.)) as.character(timestamp) else NA_character_,
          commit_message = if ("comment" %in% names(.)) as.character(comment) else NA_character_,
          rev_size       = if ("size" %in% names(.)) suppressWarnings(as.integer(size)) else NA_integer_,
          minor          = if ("minor" %in% names(.)) TRUE else FALSE,
          anon           = if ("anon" %in% names(.)) TRUE else FALSE
        )
      page_rows <- bind_rows(page_rows, parsed)
    }

    if (!is.null(data$continue) && !is.null(data$continue$rvcontinue)) {
      params$rvcontinue <- data$continue$rvcontinue
      params$continue   <- data$continue$continue
      Sys.sleep(delay)
    } else {
      break
    }
  }

  page_rows
}

# ---------- 4. Main: collect wiki_df_events for one wiki ----------
collect_wiki_events <- function(base_url,
                                 lang_code,
                                 out_dir = ".",
                                 delay   = DEFAULT_DELAY,
                                 verbose = TRUE) {

  if (verbose) message("Fetching page list from ", base_url, " ...")
  pages <- get_all_pages(base_url, delay = delay, verbose = verbose)

  if (verbose) message("Fetching bot account list ...")
  bot_names <- get_bot_names(base_url, delay = delay)

  all_revs <- tibble()

  for (i in seq_len(nrow(pages))) {
    pid    <- pages$pageid[i]
    ptitle <- pages$page_title[i]
    pns    <- pages$source_namespace[i]

    if (verbose) message("[", i, "/", nrow(pages), "] ", ptitle)

    revs <- get_page_revisions(base_url, pid, delay = delay)

    if (nrow(revs) > 0) {
      revs <- revs %>%
        arrange(commit_time, revid) %>%
        mutate(
          pageid           = pid,
          page_title       = ptitle,
          source_namespace = pns,
          total_changes    = rev_size - dplyr::lag(rev_size, default = 0L),
          commit_type      = "wiki_edit",
          year             = as.integer(substr(commit_time, 1, 4)),
          author_type      = case_when(
            !is.na(author_id) & author_id == 0 ~ "system",
            author_name %in% bot_names          ~ "bot",
            TRUE                                 ~ "human"
          ),
          author_anon      = ifelse(!is.na(author_id),
                                     paste0("W", author_id),
                                     paste0("WU_", author_name))
        )

      all_revs <- bind_rows(all_revs, revs)
    }

    Sys.sleep(delay)
  }

  wiki_df_events <- all_revs %>%
    transmute(
      author_anon,
      object_id        = pageid,
      object_name       = page_title,
      commit_time,
      year,
      commit_type,
      commit_message,
      total_changes,
      pageid,
      page_title,
      revid,
      parentid,
      rev_size,
      source_namespace,
      author_id,
      author_name,
      author_type,
      minor,
      anon
    )

  out_file <- file.path(out_dir, paste0("wiki_df_events_", lang_code, ".csv"))
  write.csv(wiki_df_events, out_file, row.names = FALSE, fileEncoding = "UTF-8")
  message("Saved ", nrow(wiki_df_events), " rows to ", out_file)

  wiki_df_events
}

# ---------- Command-line entry point ----------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  message("Usage: Rscript collect_wiki_data.R <base_api_url> <lang_code> [out_dir]")
  message("Example: Rscript collect_wiki_data.R https://en.scratch-wiki.info/w/api.php en data/")
} else {
  base_url  <- args[1]
  lang_code <- args[2]
  out_dir   <- if (length(args) >= 3) args[3] else "."

  collect_wiki_events(base_url = base_url, lang_code = lang_code, out_dir = out_dir)
}
