# MUTUS (v1.0) — CoMSES Deposit Materials

**Model:** MUTUS (Mutualism in Texts and Understanding of Students)
**Platform:** NetLogo 7
**Language:** NetLogo; analysis in R
**Version deposited:** 1.0 (CoMSES release 1.0.0)
**Date:** 2026-10-26

---

## 1. Short title (≤ 300 characters)

> **MUTUS: A Mutualistic-Network Agent-Based Model of Pollinators and Flowers, Students and Wiki Texts**

(98 characters — within the limit.)

---

## 2. Summary description (abstract)

> MUTUS (Mutualism in Texts and Understanding of Students) is a minimal agent-based model of a **mutualistic network between two guilds**. One computational core supports two worlds. In the **meadow**, pollinators visit flowering plants; in the **wiki**, students of a course read and improve the articles of a course wiki. Trait matching is the shared mechanism: proboscis length vs. corolla depth in the meadow, and competence vs. conceptual difficulty, read as the **zone of proximal development (ZPD)**, in the wiki. The two worlds differ only in a small set of fixed world constants: the width and asymmetry of the ZPD band, the efficiency of transfer between clusters (species or topics), scaffolding of difficulty by text quality, and the decay of novelty and quality. The model asks which regularities of plant–pollinator networks transfer to collaborative text production, and which are changed by processes that are slow or absent in ecology: learning, scaffolding, and authoring of new texts by the learners themselves.
>
> MUTUS is built as a **ladder of six levels**, each adding one switchable mechanism:
> - M0 — heterogeneous activity with neutral partner choice;
> - M1 — trait matching (ZPD band);
> - M2 — mutualistic feedback and resource dynamics;
> - M3 — adaptive foraging (Valdovinos et al. 2013);
> - M4 — trait development (learning within the band);
> - M5a — renewal of faded resources: seedlings that inherit complexity in the meadow, new articles written at the upper edge of the author's ZPD in the wiki.
>
> Any combination of switches is valid, so factorial BehaviorSpace designs isolate each mechanism.
>
> **Six experiments (5,610 runs)** show the following.
> 1. **Trait matching structures the system, and feedback makes it a mutualism.** The ZPD band causes 30–36 % failed visits; feedback triples resource quality but lets half of the resources fade; adaptive foraging halves failures.
> 2. **Space shapes the network.** Modularity is far above a degree-preserving null model at every level and collapses only when the perception radius exceeds the distance between clusters. Nestedness never emerges: the two-sided ZPD band forbids links both to too-hard and to too-easy resources. MUTUS therefore predicts modular, not nested, learning networks.
> 3. **Learners outgrow their resources.** The too-easy share rises from 0.19 to 0.46 in the wiki. Only renewal by student authors keeps resources at the learners' frontier, narrowing the skill–complexity gap by 0.07–0.12; seedlings in the meadow stay accessible.
> 4. **Some contrasts are robust, others are not.** A global sensitivity analysis (3⁵ factorial) shows that three meadow–wiki contrasts hold across the whole parameter cube: the skill–complexity gap, resource quality and cross-cluster linking. Contrasts in failure rate, activity and skill gain do not.
>
> MUTUS is intended for education researchers, instructors and modellers interested in learning design, collaborative writing and the transfer of ecological network theory to socio-semantic systems. It also serves as a learning object for non-STEM students, who explore the meadow first and then build and criticise the analogical mapping to the wiki.

---

## 3. What this release contains

| Artefact | File | Contents |
|---|---|---|
| Executable model | `MUTUS_v1.0.nlogox` | NetLogo 7 model: code, interface, Info tab and the six BehaviorSpace experiments |
| Model code | `MUTUS-code-v1.0.nls` | The full code of the Code tab as plain text (English comments, references to ODD sections) |
| Info tab | `MUTUS-info.md` | Content of the NetLogo Info tab: WHAT IS IT / HOW IT WORKS / HOW TO USE IT / THINGS TO NOTICE / THINGS TO TRY / EXTENDING / NETLOGO FEATURES / RELATED MODELS / CREDITS |
| ODD protocol | `MUTUS_ODD_v1.0.md` | ODD (Grimm et al. 2020): 7 core sections, model ladder and experiments, R pipeline, main results and limitations |
| BehaviorSpace experiments | `MUTUS_v1.0_experiments.xml` | E0_demo, E1_ladder, E2_radius, E3_development, E4_renewal, E5_sensitivity; importable via Tools → BehaviorSpace → Import |
| Analysis script | `MUTUS_analysis.R` | One self-contained R script for all six experiments: checksums, cell summaries, NODF and modularity vs curveball null models, time windows, renewal records, main effects, sensitivity coefficients, figures |
| Results | `results/` | Checksums, cell summaries and derived tables of E0–E5 produced by `MUTUS_analysis.R`; figures |

The raw BehaviorSpace tables (about 65 MB) are not included. Every table is reproducible bit for bit: the random seed of each run equals its run number. Reference checksums are listed in `README.md`.

---

## 4. Contributors

- **Yevgeny Patarakin** — Institute of Education, HSE University; Institute of Digital Education, Moscow City University. Model design, implementation, analysis, documentation.

---

## 5. Release notes (summary)

**How to run.** Open `MUTUS_v1.0.nlogox` in NetLogo 7. Choose `world-type` and the ladder switches, press `setup`, then `go`. A run lasts 150 ticks (one season or semester) and stops by itself.

**Experiments.** The six experiments are already in the model (Tools → BehaviorSpace). To restore them in another copy, use Tools → BehaviorSpace → Import with `MUTUS_v1.0_experiments.xml`. Choose Table output, one table per experiment; parallel runs are recommended. Run times: E0 seconds; E5 about two minutes headless.

**Analysis.** Put `MUTUS_analysis.R` in the folder with the tables and run it in RStudio (Source). Required packages: `dplyr`, `tidyr`, `ggplot2`, `vegan`, `igraph`.

**Dependencies.** NetLogo 7.0 or later; no extensions. R 4.x for the analysis.

**Inputs.**
- Chooser: `world-type` (meadow / wiki).
- Five ladder switches: `trait-matching?`, `feedback?`, `adaptive-foraging?`, `trait-development?`, `renewal?`.
- Fourteen sliders: `num-foragers`, `num-resources`, `cluster-count`, `cluster-spread`, `perception-radius`, `activity-mean`, `activity-concentration`, `visit-cost`, `mutualism-strength`, `regeneration-rate`, `adaptation-rate`, `skill-growth`, `renewal-rate`, `offspring-sd`.
- World constants (ZPD band, cross-cluster efficiency, scaffolding, service without pollen, quality and novelty decay) are fixed by `world-type`.

**Outputs.**
- 21 scalar reporters, including `share-active-foragers`, `share-alive-resources`, `mean-quality`, `mean-skill`, `skill-gain`, `fail-rate`, `share-in-band`, `share-too-easy`, `cross-cluster-share`, `unique-links`, `renewal-count`, `mean-complexity-alive` and `skill-complexity-gap`.
- Six string reporters for R: `web-edgelist`, `forager-traits`, `forager-skills`, `resource-traits`, `visit-sequence`, `renewal-list`.
- All output is collected through BehaviorSpace; the model writes no files.

**Version history.** Development versions were not released separately.
- **v0.1** — ODD and scaffold: M0–M1, two worlds.
- **v0.2** — M2: mutualistic feedback and resource dynamics.
- **v0.3** — M3: adaptive foraging; single BehaviorSpace table design.
- **v0.4** — M4: trait development; visit sequence for time windows.
- **v0.5** — M5a: renewal of faded resources; skill–complexity gap.
- **v1.0 (this deposit)** — interface clean-up:
  - world parameters fixed by `world-type`;
  - run length fixed at 150 ticks;
  - CSV logging, stress schedules and cheaters removed;
  - dead code removed.

  v1.0 reproduces the E3 and E4 tables of v0.4 and v0.5 bit for bit.

---

## 6. CoMSES metadata

| Field | Value |
|---|---|
| Title | MUTUS: A Mutualistic-Network Agent-Based Model of Pollinators and Flowers, Students and Wiki Texts |
| Version | 1.0.0 |
| Operating system | Operating System Independent |
| Programming language | NetLogo 7 |
| Software framework | None |
| License | GPL-2.0 (as for STiMUS-HAI on CoMSES) |
| Model type | Agent-based model |
| Keywords | mutualistic networks; plant–pollinator networks; zone of proximal development; collaborative learning; wiki; adaptive foraging; nestedness; modularity; learning design; socio-semantic networks |
| Research domain | Educational technology; collaborative learning; network ecology; digital pedagogy |
| Replication of a previously described model | No. MUTUS is a new model that descends from STiMUS v2.1 (the stigmergy mechanism is removed and mutualism is rebuilt as a two-guild partner-choice network); see "Related models". |
| Related models | STiMUS (CoMSES, release 1.2.0): https://www.comses.net/codebases/4f5761e1-b21a-46a6-9164-5c945d91fb68/releases/1.2.0/ ; STiMUS-HAI (CoMSES, release 1.1.0, DOI 10.25937/6jh3-8x66): https://www.comses.net/codebases/ddd5dfb8-0fa6-4001-858c-252c91a0a0b9/releases/1.1.0/ |
| External repository | github.com/patarakin/STiMUS/tree/main/models/MUTUS_v1.0 |
| Associated publications | Conference paper in preparation (to be added when available). |

---

## 7. Narrative documentation

The ODD protocol (`MUTUS_ODD_v1.0.md`) is the peer-review narrative. It contains:
- Purpose and patterns P1–P4;
- Hypotheses H1, H2, H7, H7r, H8, H9;
- Entities, state variables and scales;
- Process overview and scheduling;
- Design concepts;
- Initialisation;
- Input data (none);
- Submodels with all formulas, and the parameter tables (world constants, interface parameters, internal constants);
- The model ladder and the six experiments;
- The R analysis pipeline;
- Main results and limitations.

The Info tab (`MUTUS-info.md`) is the in-environment reference.

---

## 8. Known limitations

- **No empirical calibration.** The wiki world is a theoretical mapping; it has not been fitted to course-wiki data.
- **Synchronous fading.** All resources start with vitality 0.5, so unvisited resources fade together at about tick 80. This is visible as a step in time-course plots; end-of-run results are not affected.
- **Renewal replaces faded resources only.** Retiring or rewriting resources that learners have outgrown (a possible M5b) is outside the scope of v1.0.
- **`cheater?` is a reserved forager variable.** It is always false in v1.0 and kept only so that the `forager-traits` string keeps a stable format for the R parser.
