# STiMUS v2.1 — COMSES Deposit Materials

**Model:** STiMUS (Stigmergic–Mutualistic IMOI Model)
**Platform:** NetLogo 7
**Language:** NetLogo
**Version deposited:** 2.1
**Date:** 2026-07-06

---

## 1. Short title (≤ 300 characters)

> **STiMUS: A Stigmergic–Mutualistic Agent-Based Model of Teamwork on Shared Digital Artefacts (IMOI)**

(119 characters — within the limit.)

---

## 2. Summary description (abstract)

> STiMUS (Stigmergic–Mutualistic IMOI Model) is an agent-based model of teamwork in socio-technical systems where contributors collaborate through shared digital artefacts — wiki pages, code files, issue tickets, project cards, Scratch projects — represented as patches in a NetLogo world. The model integrates and *decouples* two coordination mechanisms. **Stigmergy** is indirect coordination through traces left in a shared environment: each edit deposits a pheromone that diffuses to neighbouring patches and evaporates over time, so recent activity attracts further contributions; stigmergy decides *where* a contributor works. **Mutualism** is the mutualistic relationship between contributors and the artefact-objects they tend: contributors enrich artefacts, and valuable, well-maintained artefacts return benefit that fuels contributor motivation; mutualism decides *with what effort* a contributor works. The central theoretical claim of v2.1 is that these two levers are orthogonal and can be designed independently.
>
> Contributors (turtles of the `contributor` breed) carry individual state: `skill`, `motivation`, `shared-mental-model`, `specialty`, `benefit-gain`, and an `explicit-mode?` flag. At each tick every contributor selects a target artefact either by a stigmergic ant-colony-optimization rule weighing the artefact's pheromone, incompleteness, maintenance-need, task flag and topic match, or — with probability `p-explicit` — by explicit task assignment, picking the hardest unfinished visible task and falling back to the stigmergic rule when no task is in sight. Each edit increases `pheromone`, `quality`, `completeness` and `resource-value`, lowers `maintenance-need`, and appends the editor to the artefact's `edit-authors` list. When the previous editor differs from the current one, the Edit Succession Ratio rises, the editor's `shared-mental-model` grows, and a co-editing link is created, operationalising the idea that repeated cross-author succession on the same artefact builds shared understanding. A mutualism channel runs `resource-value → local-benefit → motivation → edit-power → quality`; crucially, `resource-value` does *not* enter the target-selection weight, so mutualism affects effort but not target choice.
>
> Each patch maintains a stigmergic layer (`pheromone`, `quality`, `completeness`, `recentness`, `last-editor-id`, `edit-count`, `edit-authors`) and a mutualistic layer (`resource-value`, `reuse-count`, `maintenance-need`, `topic-tag`), plus task flags (`is-task?`, `task-complexity`). Twenty-five monitors are recorded: base metrics (event-level `ESR = cross-author-edits / total-edits`, a patch-level `esr-value`, `mean-quality`, `mean-resource-value`, `mutualism-index`, `coediting-density`, `active-pages-share`, `task-completion-rate`, `mean-shared-mental-model`, normalised Shannon `page-diversity`, `gini-edits`, `bigraph-edges`, `total-edits`, `cross-author-edits`), v2 diagnostics (`mean-motivation`, `benefit-gain-per-edit`, `mutualism-index-norm`, `edits-on-tasks`, `edits-on-non-tasks`, `task-edit-share`, `resource-edit-correlation`), and v2.1 explicit-channel diagnostics (`explicit-edit-share`, `explicit-hit-rate`, `explicit-fallback-rate`, `active-task-count`). The model logs every edit as a bipartite edge (`tick, author_id, pageid, specialty, topic_tag, quality`), exportable to CSV.
>
> The decoupling claim was verified by a 2×2 factorial experiment (E6, 1000 runs): `mutualism-gain-factor` strongly drives motivation (η² = 0.74) and benefit-per-edit (η² = 0.99) but not quality (η² = 0.006), while `p-explicit` strongly drives task completion and explicit-edit-share (η² = 0.95) but not motivation (η² = 0.004); their interaction on quality is negligible (η² = 0.016). A full parameter-space analysis across seven experiments (10,900 runs, 500 ticks, 50 repetitions each) confirms that visibility radius is the master variable for collaboration density (ESR 0.41 → 0.90, η² ≈ 0.96), that thematic structure is a meaningful lever once specialisation is strong (η² = 0.53), and that a tight explicit-assignment filter is required for task assignment to focus effort (task-completion rises 0.12 → 0.97 with `p-explicit`). Conclusions are scale-robust across participant and task densities.
>
> STiMUS instantiates the Input–Mediator–Output–Input (IMOI) team framework and is intended for education researchers, instructors, and modellers studying collaborative learning and digital pedagogy. Parameters map to platform features (`evaporation-rate` to trace persistence, `p-explicit` to the share of assigned versus self-selected work, `vision-radius` to notification/recent-changes visibility), enabling counterfactual analysis of how environmental design shapes collaborative outcomes. Distinguishing human and AI contributors (bots, LLM assistants, CI/CD pipelines) and dynamic, shared-mental-model-scaled vision are documented as open extensions rather than features of this release.

---

## 3. What this release contains

| Artefact | File | Contents |
|---|---|---|
| Executable model | `STiMUS_4_v2.1.nlogox` | NetLogo 7 model with 11 sliders, 25 monitors, full v2.1 code |
| ODD protocol | `STiMUS_ODD_v2.1.md` | Grimm-standard ODD (7 core sections + experiments + interpretation) |
| BehaviourSpace experiments | `STiMUS_v2.1_experiments.xml` | E1–E7, importable via Tools → BehaviorSpace → Import |
| Release notes | `STiMUS_release_notes.md` | How to run, dependencies, inputs/outputs |
| Experiment results | `STiMUS_5-..._table.csv` (×7) | E1–E7 output tables (500 ticks, 50 reps) |

---

## 4. Contributors

- **Yevgeny Patarakin** — Institute of Education, HSE University; Institute of Digital Education, Moscow City University. Model design, implementation, analysis, documentation.

---

## 5. Release notes (summary)

**How to run.** Open `STiMUS_4_v2.1.nlogox` in NetLogo 7. Press `setup`, then `go`. Default run: 500 ticks. For experiments: Tools → BehaviorSpace → Import → select `STiMUS_v2.1_experiments.xml`; the seven experiments E1–E7 appear in the list. Select one, click Run, choose Table output and a destination CSV. Parallel runs recommended (set to CPU core count).

**Dependencies.** NetLogo 7.0.0 or later. No extensions required.

**Inputs (11 interface sliders).** `num-contributors`, `num-tasks`, `topic-count`, `vision-radius`, `evaporation-rate`, `diffusion-rate`, `edit-increment`, `p-explicit`, `lambda-smm`, `mutualism-gain-factor`, `activity-probability`.

**Outputs.** 25 end-of-run metrics (see §2). Optional bipartite edit log via the `save-edge-log` procedure (CSV: `tick, author_id, pageid, specialty, topic_tag, quality`).

**Version history.**
- **v1** — initial release with bug fixes and comments; added `activity-probability` slider (seed-identical default), `page-diversity`, `gini-edits`, fixed `task-completion-rate`.
- **v2** — structural decoupling: removed `resource-value` from ACO target weight; added `task-priority-bonus`; strengthened `specialization-weight` (0.35→0.60) and `topic-match-bonus` (0.30→0.50); added 7 diagnostic reporters.
- **v2.1** — task-focused explicit assignment (candidate filter narrowed to `is-task?` with stigmergic fallback); added `explicit-edit-share`, `explicit-hit-rate`, `explicit-fallback-rate`, `active-task-count` reporters; mutualism terminology throughout.

---

## 6. COMSES metadata

| Field | Value |
|---|---|
| Operating system | Cross-platform (NetLogo) |
| Platform | NetLogo 7 |
| Programming language | NetLogo |
| License | MIT (recommended for code) |
| Model type | Agent-based model |
| Research domain | Educational technology, collaborative learning, digital pedagogy |

---

## 7. Narrative documentation

The ODD protocol document (`STiMUS_ODD_v2.1.md`) provides the peer-review-ready
narrative: Purpose; Entities, state variables, and scales; Process overview and
scheduling; Design concepts; Initialization; Input data; Submodels; Simulation
experiments and key results; Interpretation for pedagogical design; Limitations
and future extensions. This supersedes the model's Info tab for review purposes,
though the Info tab remains the in-environment reference.

---

## 8. Status of previously noted discrepancies

Earlier draft notes flagged gaps between the Info tab and the executable code.
As of v2.1 their status is:

| Earlier flag | v2.1 status |
|---|---|
| AI contributor types / `ai-share` | Still a documented *open extension* (ODD §10, Q6), not implemented. Abstract states this explicitly. |
| `show-topics?` / `count-ai-in-esr?` switches | Not implemented; not required for v2.1 mechanisms. |
| Separate `ESR (human-only)` / `ESR (all agents)` monitors | Not implemented; the single event-level `ESR` and patch-level `esr-value` are documented as two coexisting metrics (ODD §4.8, Q4). |
| `Gini of edits` | **Implemented** as `gini-edits` (v1) and exercised in E4. |
| Sliders `topic-count`, `num-tasks`, `vision-radius`, `edit-increment`, `mutualism-gain-factor` | All declared as interface sliders (ODD §2.6). |
| `mutualism-index` formula | Code formula `(mean [benefit-gain] of contributors + mean-resource-value) / 2` is documented in ODD §4.8 and §7.3; a normalised variant `mutualism-index-norm` (v2) is also reported. |

No unresolved blocking discrepancies remain between the deposited code and its
documentation for the v2.1 mechanisms.
