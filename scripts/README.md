# Scripts

Two R scripts cover the full reproducibility pipeline: collecting raw revision
data from a Scratch wiki's MediaWiki installation, and computing the Edit
Succession Ratio (ESR) indicators used in the paper.

```
raw MediaWiki API  --[collect_wiki_data.R]-->  wiki_df_events_<lang>.csv  --[analyze_esr.R]-->  scratch_wikis_esr_summary.csv
```

---

## `collect_wiki_data.R`

Minimal single-wiki extractor. Given the API endpoint of one Scratch wiki, it
collects the full public revision history (namespace 0 content pages only)
and writes it to the common `wiki_df_events_<lang>.csv` schema documented in
[`../data/README.md`](../data/README.md).

**What it does:**

1. Enumerates all namespace-0 pages via `action=query&list=allpages`.
2. Fetches the complete revision history of each page via
   `action=query&prop=revisions` (`rvprop=ids|timestamp|comment|user|userid|size|flags`),
   paginating with `rvcontinue` until exhausted.
3. Fetches the wiki's bot-flagged accounts via
   `action=query&list=allusers&augroup=bot`.
4. Labels every edit `author_type`:
   - `"system"` — `author_id == 0` (the MediaWiki installation default account)
   - `"bot"` — author name appears in the bot-group account list
   - `"human"` — everything else
5. Computes `total_changes` (byte delta between consecutive revisions on a
   page) and `year` (parsed from the revision timestamp).
6. Assembles and writes one CSV per wiki: `wiki_df_events_<lang_code>.csv`.

**What it deliberately does *not* do** (removed for the minimal, single-wiki
version used in this project): it does not collect `wiki_df_team` /
per-page contributor lists, does not build any bipartite or co-editing
network, and does not perform namespace-1 (Talk) collection — none of these
are needed to compute the ESR indicators reported in the paper. Network-level
analysis for the Indonesian worked example (Table 2 in the paper) was done
separately from raw revision data, not from this script's output.

**Dependencies:** `httr`, `jsonlite`, `dplyr`.

```r
install.packages(c("httr", "jsonlite", "dplyr"))
```

**Usage:**

```bash
Rscript collect_wiki_data.R <base_api_url> <lang_code> [out_dir]
```

| Argument | Description | Example |
|---|---|---|
| `base_api_url` | Full `api.php` URL of the target Scratch wiki | `https://en.scratch-wiki.info/w/api.php` |
| `lang_code` | Short code used in the output filename | `en` |
| `out_dir` | Optional output directory (default: current directory) | `../data` |

**Example — collecting all six wikis used in the paper:**

```bash
Rscript collect_wiki_data.R https://en.scratch-wiki.info/w/api.php en ../data
Rscript collect_wiki_data.R https://fr.scratch-wiki.info/w/api.php fr ../data
Rscript collect_wiki_data.R https://de.scratch-wiki.info/w/api.php de ../data
Rscript collect_wiki_data.R https://ru.scratch-wiki.info/w/api.php ru ../data
Rscript collect_wiki_data.R https://ja.scratch-wiki.info/w/api.php ja ../data
Rscript collect_wiki_data.R https://id.scratch-wiki.info/w/api.php id ../data
```

Each run produces one `wiki_df_events_<lang_code>.csv` in `out_dir`, matching
the schema in [`../data/README.md`](../data/README.md).

**Notes on runtime and politeness:** the script pauses `0.5` s (`DEFAULT_DELAY`)
between successive API calls and retries transient failures up to 4 times
(`MAX_RETRIES`) with a 1 s backoff. Larger wikis (e.g. English, with several
thousand pages) can take a long time to complete a full run because revisions
are fetched page by page; consider running large wikis unattended (e.g.
`Rscript collect_wiki_data.R ... &` or a background job).

---

## `analyze_esr.R`

Reads all `wiki_df_events_<lang>.csv` files in an input directory and computes,
per language community:

- Descriptives: time span, total edits, pages, human/bot actor counts, human
  edit share.
- **ESR-all** — Edit Succession Ratio computed over the full edit sequence per
  page (human + bot + system contributors).
- **ESR-HH** — Edit Succession Ratio computed over the human-only edit
  subsequence per page (bot/system rows removed *before* computing succession,
  so a bot edit cannot artificially create or break a human-human transition).
- **ESR inflation (%)** — how much including non-human contributors inflates
  the succession ratio relative to the human-only baseline; large in small
  communities with few edits, small in large communities.

Base R only (no `dplyr`/`readr`/`igraph` dependency), so it runs identically
regardless of which R package versions are installed.

```bash
Rscript analyze_esr.R --input_dir ../data --out_dir ../output
```

Output: `scratch_wikis_esr_summary.csv` — one row per language, the source
table for the paper's Table 1.

