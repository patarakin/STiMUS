# STiMUS / STiMUS-HAI

Data, extraction/analysis scripts, and NetLogo agent-based models supporting:

> Patarakin, Y. (2026). *Modeling Mixed-Team Interactions: A Stigmergic–Mutualistic
> Agent-Based Model Calibrated Against Multilingual Scratch Wiki Communities.*
> (Manuscript under revision, Frontiers in Education.)

This repository accompanies the paper's Data and Code Availability statement and
is intended to make the empirical extraction pipeline, the resulting datasets,
the analysis script, and both agent-based models (human-only and human-AI)
independently reproducible. It is also the deposit basis for the corresponding
[CoMSES Network](https://www.comses.net/) model library entries.

## Repository structure

```
STiMUS/
├── data/                     Anonymized MediaWiki-API revision-history datasets,
│                             one CSV per Scratch wiki language community
│                             (en, fr, de, ru, ja, id). Identical schema across
│                             all six files -- see data/README.md.
│
├── scripts/
│   ├── collect_wiki_data.R   Collects revision-history data from a Scratch wiki's
│   │                         MediaWiki Action API (action=query&list=allrevisions)
│   │                         and writes it to the common wiki_df_events_<lang>.csv
│   │                         schema used throughout this repository.
│   └── analyze_esr.R         Reads any number of wiki_df_events_<lang>.csv files
│                             and computes, per language community: Edit Succession
│                             Ratio (ESR-all and human-only ESR-HH), the bot-driven
│                             ESR inflation, and basic descriptives. Base R only,
│                             no external package dependencies. Produces
│                             scratch_wikis_esr_summary.csv, which is the source
│                             table for the paper's Table 1.
│
├── models/
│   ├── STiMUS_v2.1/          Human-only stigmergic-mutualistic ABM (NetLogo).
│   │                         ODD protocol + CoMSES deposit notes.
│   └── STiMUS-HAI_v3.1/      Human-AI extension: a second agent breed
│                             (ai-agents), ai-share / judgment-share sliders,
│                             ai-trust mechanic. CoMSES deposit notes.
│                             (NetLogo .nlogo file(s) to be added alongside
│                             the deposit notes.)
│
└── README.md                 This file.
```

## Reproducing the paper's empirical results (Table 1 / Section 4.1)

1. Collect (or re-collect) revision-history data for each Scratch wiki language
   community with `scripts/collect_wiki_data.R`, or use the datasets already
   provided in `data/`.
2. Run the analysis script:

   ```bash
   Rscript scripts/analyze_esr.R --input_dir data --out_dir output
   ```

3. The resulting `output/scratch_wikis_esr_summary.csv` reproduces the per-language
   ESR-all / ESR-HH values reported in Table 1 of the paper.

No packages beyond base R are required for `analyze_esr.R`. `collect_wiki_data.R`
requires `httr`/`jsonlite` (or equivalent) to query the MediaWiki API — see the
header comment in that script for exact dependencies.

## Data provenance and ethics

All datasets in `data/` are public-facing MediaWiki edit histories of publicly
editable, publicly documented Scratch wiki communities, collected through each
site's public MediaWiki Action API under its published terms of use. Contributor
identifiers are the pseudonymous usernames MediaWiki itself displays in public
revision histories; no additional identifying information was collected, and no
attempt was made to link usernames to real-world identities. See Section 2.4 of
the paper for the full ethics statement.

An earlier version of the underlying project also drew on a Semantic MediaWiki
installation containing identifiable student/instructor course logs
(`digida.mgpu.ru`) and on Scratch project/studio metadata via the Scratch API.
Both sources have been intentionally excluded from this repository and from the
paper's empirical base; this repository contains **only** MediaWiki-API-collected
Scratch wiki revision histories.

## Models

Both `STiMUS_v2.1` (human-only) and `STiMUS-HAI_v3.1` (human-AI extension) are
implemented in NetLogo and documented following the Grimm et al. ODD protocol.
See each model's `COMSES_deposit.md` for parameters, experiments, and version
history. `STiMUS-HAI_v3.1` is backward-compatible with `STiMUS_v2.1`: setting
`ai-share = 0` reproduces the human-only model's behavior.

## Citation

If you use this data or these models, please cite the paper above and, for the
models specifically, the corresponding CoMSES Network deposit (DOI to be
assigned on deposit; placeholder to be updated on publication).

## License

Data: [CC-BY-4.0]
Code: [MIT]
