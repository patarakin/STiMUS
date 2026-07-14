# STiMUS v2.1 — ODD Protocol Document

**Model:** STiMUS — Stigmergic-Mutualistic IMOI Model of collaborative artefact editing
**Platform:** NetLogo 7
**Version:** 2.1
**Date:** 2026-07-06
**Author:** Yevgeny Patarakin (HSE University / Moscow City University)

This document follows the ODD (Overview, Design concepts, Details) protocol for
describing individual- and agent-based models (Grimm et al. 2006, 2010). Sections
1–7 are the core ODD protocol. Section 8 onwards document simulation experiments,
interpretation, and limitations and are not part of the core ODD.

---

## 1. Purpose

### 1.1 Overall purpose

STiMUS simulates the emergence of collaborative-editing patterns in a
socio-technical system where human contributors enrich a shared repository of
digital artefacts (e.g., wiki pages, shared documents, open educational resources).
Its purpose is twofold:

1. **Theoretical.** To test whether two fundamental coordination mechanisms of
   joint work — **stigmergy** (indirect coordination through traces left in the
   environment) and **mutualism** (the mutualistic relationship between contributors
   and the artefact-objects they tend) — can be **decoupled**: stigmergy deciding
   *where* a contributor works, mutualism deciding *with what effort* the
   contributor works. This decoupling is the central theoretical claim of v2.1.

2. **Practical.** To provide a reusable, inspectable computational object for
   pedagogical designers of collaborative activity, translating five verified
   mechanisms into design principles for joint-work environments.

### 1.2 What the model tests

The version history reflects an iterative sharpening of the model:

- **v1 → v2.** In v1 the mutualism channel (resource-value) was part of the
  target-selection weight, so mutualism distorted *where* contributors worked
  (a preferential-attachment pathology: mutualism enriched mature artefacts,
  which then attracted more edits). Experiment E3 (v1, 50 seeds) confirmed
  mutualism *harmed* quality (slope = −0.106, t = 10.88, p < 0.0001). v2
  removed resource-value from the target weight and strengthened topic
  specialisation. E3 on v2 confirmed mutualism became neutral (slope = +0.018,
  n.s.).

- **v2 → v2.1.** v2 left one weakness: the explicit-assignment candidate filter
  was wide, so even at p-explicit = 1 only ~4% of edits landed on tasks
  (E1, v2). v2.1 narrows the filter to formal tasks only, with a stigmergic
  fallback when no task is visible, and adds reporters that make the
  explicit-assignment channel measurable. E1 on v2.1 confirms the fix
  (task-completion-rate now *rises* with p-explicit, 0.12 → 0.97).

### 1.3 Hypotheses addressed

H1 (Decoupling). Stigmergy and mutualism are orthogonal levers: varying
mutualism strength affects motivation and benefit but not the *distribution* of
work (quality, target choice); varying explicit assignment affects the
distribution of work but not motivation. Verified by E6 (interaction η² ≈ 0.016).

H2 (Visibility as master variable). The radius of local perception is the
strongest single determinant of collaboration density. Verified by E5
(ESR 0.41 → 0.90 across vision-radius 1–8, η² ≈ 0.96).

H3 (Topic structure as a lever, not a label). Thematic fragmentation
structurally shapes the collaboration network once specialisation is strong
enough. Verified by E5 (η²(topic-count → quality) = 0.53, up from ~0 in v1).

H4 (Explicit assignment focuses on tasks only when its filter is tight).
Verified by E1 (v2.1 vs v2): task-completion-rate collapsed in v2, rises in v2.1.

H5 (Mutualism sustains engagement, not peak quality). Verified by E3
(quality neutral, motivation and benefit-per-edit rise sharply with mutualism).

---

## 2. Entities, State Variables, and Scales

### 2.1 Entities

| Entity | Breed | Count (default) | Role |
|---|---|---|---|
| Contributor | `contributors` | 25 (slider `num-contributors`) | Human editor; mobile agent |
| Artefact patch | `patches` | 1089 (33×33 world) | A unit of shared content (a "page") |
| Co-editing link | `coedits` (undirected) | dynamic | Edge between two contributors who co-edited a patch |

### 2.2 State variables — patches (artefacts)

| Variable | Type | Range | Meaning |
|---|---|---|---|
| `pheromone` | float | ≥ 0 | Stigmergic trace intensity; diffuses and evaporates |
| `quality` | float | [0, 1] | Content quality |
| `completeness` | float | [0, 1] | Task/content completion |
| `recentness` | int | ≥ 0 | Ticks since last edit (init 9999) |
| `last-editor-id` | int | −1 or who | Most recent editor's who |
| `edit-count` | int | ≥ 0 | Total edits received |
| `edit-authors` | list | unique whos | Distinct prior authors (deduplicated) |
| `is-task?` | bool | — | Designated formal task |
| `task-complexity` | float | [0, 1] | Task difficulty |
| `resource-value` | float | [0, 1] | Mutualistic benefit available to visitors |
| `reuse-count` | int | ≥ 0 | Number of reuse/edit events |
| `maintenance-need` | float | [0, 1] | Degradation accumulator; grows when unattended |
| `topic-tag` | int | [0, topic-count−1] | Domain index |

### 2.3 State variables — contributors

| Variable | Type | Range | Meaning |
|---|---|---|---|
| `skill` | float | [0.3, 1.0] | Competence |
| `motivation` | float | [0.05, 1.0] | Engagement; updated over time |
| `shared-mental-model` | float | [0, 1] | Proxy for team shared understanding |
| `specialty` | int | [0, topic-count−1] | Preferred topic |
| `my-last-page` | patch/nobody | — | Last edited patch |
| `my-edit-count` | int | ≥ 0 | Contributor's total edits |
| `benefit-gain` | float | ≥ 0 | Cumulative benefit obtained from artefacts |
| `explicit-mode?` | bool | — | Did the current step use explicit task assignment? |

### 2.4 Global variables

`total-edits`, `cross-author-edits`, `ESR`, `mean-quality`, `mean-resource-value`,
`mutualism-index`, `coediting-density`, `active-pages-share`, `edge-log`,
`initial-task-count`, `tasks-completed`, `edits-on-tasks-count`,
`explicit-attempts-count`, `explicit-edits-count`, `explicit-fallback-count`.

### 2.5 Scales

- **Spatial.** A 33×33 torus of patches; one patch = one artefact unit.
- **Temporal.** One tick = one collaborative "session"; default run length 500 ticks.
- **Organisational.** Contributors are undifferentiated by role; differentiation
  emerges through `specialty`, `skill`, `motivation`, and network position.

### 2.6 Interface sliders (11)

| Slider | Default | Role |
|---|---|---|
| `num-contributors` | 25 | Population size |
| `num-tasks` | 25 | Number of formal tasks flagged at setup |
| `topic-count` | 5 | Number of thematic domains |
| `vision-radius` | 5 | Local perception radius |
| `evaporation-rate` | 0.02 | Pheromone evaporation per tick |
| `diffusion-rate` | 0.05 | Pheromone diffusion per tick |
| `edit-increment` | 0.6 | Pheromone added per edit |
| `p-explicit` | 0.1 | Probability of explicit task assignment |
| `lambda-smm` | 0.01 | Shared-mental-model growth per cross-author edit |
| `mutualism-gain-factor` | 0.06 | Resource-value growth per mutualistic edit |
| `activity-probability` | 0.7 | Per-tick probability a contributor acts |

---

## 3. Process Overview and Scheduling

### 3.1 Tick structure

One tick executes, in order:

1. **Contributor actions.** Each contributor, subject to `activity-probability`,
   runs `step-contributor`: choose a target patch (`choose-target-page`), move
   to it, edit it (`perform-edit`). At `activity-probability = 1.0` the fast path
   is taken without consuming a random number, preserving the random stream.
2. **Pheromone dynamics.** `diffuse pheromone diffusion-rate`, then each patch
   evaporates: `pheromone *= (1 − evaporation-rate)`.
3. **Artefact ageing.** Each patch: `recentness += 1`;
   `maintenance-need = min(1, maintenance-need + 0.010)`;
   `resource-value = max(0, resource-value − 0.003 × maintenance-need)`.
4. **Metrics.** `update-metrics` recomputes all global monitors.
5. `tick`.

### 3.2 Target choice (two modes)

**Explicit mode** (with probability `p-explicit`). v2.1: candidates are ONLY
visible task patches (`visible with [is-task?]`). If any are visible, select
the hardest unfinished one by `max-one-of [task-complexity + (1 − completeness)]`
and set `explicit-mode? = true`. If NO task is visible, fall back to the
stigmergic rule and set `explicit-mode? = false` (so the explicit-bonus is not
applied to a stigmergic choice). The model deliberately does NOT fall back to
"do nothing", because that would turn `p-explicit` into an activity-suppression
parameter and confound E1 with `activity-probability`.

**Stigmergic mode** (otherwise). `aco-choose-patch`: among visible patches worth
working on (`completeness < 1 or maintenance-need > 0.05`), pick the one
maximising the ACO-style weight (see §7.1).

### 3.3 Subprocesses captured

- **Stigmergic target selection** (§7.1).
- **Explicit task assignment** (§7.2) — the v2.1 fix.
- **Artefact editing** (`perform-edit`, §7.3).
- **Shared-mental-model and co-editing network growth** (§7.3).
- **Mutualism channel: benefit → motivation → edit-power** (§7.3, §7.4).
- **Pheromone dynamics** (§3.1 step 2).
- **Task completion** (§7.3): a task is completed when `completeness ≥ 0.90`.

---

## 4. Design Concepts

### 4.1 Emergence

The collaboration pattern (ESR, quality, task completion, network density,
participation inequality) emerges from local choices. No contributor has a
global view or a collective objective.

### 4.2 Adaptation

Contributors adapt their *target* each tick via the stigmergic/explicit choice,
and their *effort* adapts via the motivation update (`motivation =
motivation + recovery × benefit − fatigue`, bounded [0.05, 1]). There is no
learning of skill or specialty during a run.

### 4.3 Fitness / Objectives

No explicit fitness. The implicit objective is to raise artefact quality and
completeness, but this is a consequence of local editing, not a goal-seeking
term.

### 4.4 Sensing

Contributors sense, within `vision-radius`: patch `pheromone`, `completeness`,
`maintenance-need`, `is-task?`, `topic-tag`, `resource-value` (for benefit
computation, NOT for target choice in v2.1 — this is the decoupling). They
sense their own `skill`, `motivation`, `specialty`, `explicit-mode?`.

### 4.5 Interaction

- **Indirect (stigmergic):** through pheromone and artefact state.
- **Indirect (mutualistic):** contributors enrich artefacts; artefacts return
  benefit that fuels motivation.
- **Direct (co-editing network):** two contributors become linked when they
  co-edit a patch; the shared-mental-model grows on cross-author successions.

### 4.6 Stochasticity

Initial states are random uniform (see §5). Target choice in stigmergic mode is
deterministic (`max-one-of`); explicit mode is deterministic among tasks. The
`activity-probability` gate and the `p-explicit` branch consume random numbers.
50 repetitions per condition are used to estimate central tendencies.

### 4.7 Collectives

No explicit subgroups; emergent collectives are (a) co-editing network clusters
and (b) topic-specialised contributors (via `specialty`).

### 4.8 Observation

25 metrics recorded at run end (`runMetricsEveryStep = false`): 14 base
(ESR, coediting-density, mean-quality, mean-resource-value, mutualism-index,
task-completion-rate, mean-shared-mental-model, page-diversity, gini-edits,
bigraph-edges, total-edits, cross-author-edits, active-patch count,
non-task-active-pages), 7 v2 diagnostics (mean-motivation,
benefit-gain-per-edit, mutualism-index-norm, edits-on-tasks,
edits-on-non-tasks, task-edit-share, resource-edit-correlation), and 4 v2.1
diagnostics (explicit-edit-share, explicit-hit-rate, explicit-fallback-rate,
active-task-count). A bipartite edit log (`edge-log`) records every edit event.

---

## 5. Initialization

`setup` clears the world, resets all globals (including `explicit-attempts-count`,
`explicit-edits-count`, `explicit-fallback-count`, `edits-on-tasks-count`),
then:

**Patches.** Each patch initialises:
`quality ~ U(0, 0.15)`, `completeness ~ U(0, 0.20)`, `recentness = 9999`,
`last-editor-id = −1`, `edit-count = 0`, `edit-authors = []`, `is-task? = false`,
`task-complexity ~ U(0, 1)`, `resource-value ~ U(0.2, 0.4)`,
`maintenance-need ~ U(0, 0.3)`, `topic-tag ~ U{0,…,topic-count−1}`. Then
`num-tasks` patches are flagged `is-task? = true` with
`task-complexity ~ U(0.4, 1.0)`; `initial-task-count` records the count.

**Contributors.** `num-contributors` agents placed at random positions;
`skill ~ U(0.3, 1.0)`, `motivation ~ U(0.4, 1.0)`,
`shared-mental-model ~ U(0.1, 0.2)`, `specialty ~ U{0,…,topic-count−1}`,
all counters zero, `explicit-mode? = false`, color green (stigmergic).

Default run: 500 ticks, 50 repetitions per condition.

---

## 6. Input Data

The model uses no external input data. All dynamics are endogenous, driven by
the 11 sliders and the fixed internal parameters (§7.5).

---

## 7. Submodels

### 7.1 Stigmergic target selection (`aco-choose-patch`)

Among visible patches worth working on (`completeness < 1 or maintenance-need > 0.05`),
select the one maximising:

\[
W = (\text{pheromone}+0.01)^{\alpha} \cdot (1-\text{completeness}+0.01)^{\beta}
    \cdot (1+\text{maintenance-need}) \cdot T \cdot S
\]

where `α = 1.6` (alpha-pheromone), `β = 1.3` (beta-heuristic),
\(T = \text{task-priority-bonus} = 1.25\) if `is-task?` else 1,
and \(S = 1 + 0.60\) (specialization-weight) if `topic-tag = specialty` else 1.

**v2 decoupling (verified by E6):** `resource-value` is NOT part of W. It was
removed in v2 because its presence created preferential attachment to mature
artefacts, which is why mutualism harmed quality in v1 (E3: slope −0.106).
After removal, mutualism acts only through the benefit→motivation→edit-power
channel (§7.4), not through target choice.

### 7.2 Explicit task assignment (v2.1)

With probability `p-explicit`:
1. `task-candidates = visible with [is-task?]`.
2. If any: `explicit-mode? = true`; report `max-one-of task-candidates [task-complexity + (1 − completeness)]`.
3. If none: fall back to `aco-choose-patch`; set `explicit-mode? = false`
   (explicit-bonus not applied).

The fallback (not "do nothing") is essential: it keeps `p-explicit` semantically
about *assignment*, not about *activity level*. The three v2.1 reporters make the
channel measurable: `explicit-edit-share` (share of edits genuinely task-assigned),
`explicit-hit-rate` (fraction of explicit attempts that found a visible task),
`explicit-fallback-rate` (fraction that found none and fell back), and
`active-task-count` (distinguishes "no task visible" from "all tasks completed").

### 7.3 Editing (`perform-edit`)

Given target patch and contributor, compute:
- `topic-match = 1` if `topic-tag = specialty` else 0.
- `explicit-bonus = 0.10` (explicit-effect) if `explicit-mode?` else 0.
- `edit-power = skill · (0.5 + 0.5·motivation) · (1 + topic-match·0.50 + explicit-bonus)`.

Then update the patch (logistic gains):
- `quality = min(1, quality + 0.08 · edit-power · (1 − quality))`.
- `completeness = min(1, completeness + 0.05 · edit-power · (1 − completeness))`.
- `pheromone += edit-increment`.
- `resource-value = min(1, resource-value + mutualism-gain-factor · edit-power · (1 − resource-value))`.
- `maintenance-need = max(0, maintenance-need − 0.08 · edit-power)`.
- `recentness = 0`; `edit-count += 1`; `edit-authors` (dedup) gets `who`;
  `last-editor-id = who`.
- **Task completion:** if `is-task?` and `completeness ≥ 0.90`: `is-task? = false`,
  `tasks-completed += 1` (counted once; `is-task?` flip prevents double counting).

**Shared mental model & co-editing network.** If `last-editor-id` is a different
contributor, `cross-author-edits += 1`, `shared-mental-model = min(1, smm + lambda-smm)`,
and a `coedit` link is created. The editor is also linked to every other prior
author of the patch, so the network reflects shared work, not only succession.

**Benefit and motivation (mutualism channel).**
`local-benefit = 0.40·resource-value + 0.20·quality + 0.30·topic-match`.
`benefit-gain += local-benefit`.
`motivation = max(0.05, min(1, motivation + 0.03·local-benefit − 0.005))`.

**v2.1 explicit-count.** If `explicit-mode?`, `explicit-edits-count += 1`
(in `perform-edit`, after a task was actually selected in §7.2).

### 7.4 The mutualism channel (decoupled)

The channel is: `mutualism-gain-factor → resource-value → local-benefit → motivation → edit-power → quality`.

Crucially, `mutualism-gain-factor` raises `resource-value` (§7.3), which raises
`local-benefit`, which raises `motivation`, which raises `edit-power`, which
raises `quality`. But `resource-value` does NOT enter the target weight (§7.1),
so the channel affects *effort*, not *target choice*. E6 verifies this
decoupling: the `mgf × p-explicit` interaction on quality is negligible
(η² ≈ 0.016), while `mgf` strongly drives motivation (η² = 0.743) and
`p-explicit` strongly drives explicit-edit-share (η² = 0.957) but not
motivation (η² = 0.004).

### 7.5 Fixed internal parameters

| Parameter | Value | Meaning |
|---|---|---|
| `alpha-pheromone` | 1.6 | Pheromone exponent in W |
| `beta-heuristic` | 1.3 | Incompleteness exponent in W |
| `specialization-weight` | 0.60 | Topic-match bonus in W (v2: 0.35→0.60) |
| `topic-match-bonus` | 0.50 | Topic-match bonus on edit-power (v2: 0.30→0.50) |
| `explicit-effect` | 0.10 | Explicit-mode bonus on edit-power |
| `quality-gain-factor` | 0.08 | Logistic quality gain |
| `completeness-gain-factor` | 0.05 | Logistic completeness gain |
| `maintenance-relief-factor` | 0.08 | maintenance-need relief per edit |
| `maintenance-drift` | 0.010 | Per-tick maintenance-need growth |
| `resource-decay` | 0.003 | Per-tick resource-value decay (× maintenance-need) |
| `motivation-recovery` | 0.03 | Motivation recovery (× local-benefit) |
| `motivation-fatigue` | 0.005 | Per-edit motivation fatigue |
| `resource-benefit-weight` | 0.40 | resource-value weight in local-benefit |
| `quality-benefit-weight` | 0.20 | quality weight in local-benefit |
| `topic-benefit-weight` | 0.30 | topic-match weight in local-benefit |
| `task-completion-threshold` | 0.90 | completeness threshold for task done |
| `task-priority-bonus` | 1.25 | ACO weight multiplier for is-task? patches (v2) |

---

## 8. Simulation Experiments and Key Results

*The following section is not part of the core ODD protocol but documents the
simulation experiments used for verification, sensitivity analysis, and
theoretical interpretation. All experiments: 500 ticks, 50 repetitions per
condition, NetLogo 7.*

### 8.1 E1 — Explicit assignment (p-explicit × vision-radius)

**RQ.** Does the v2.1 task-focused filter fix the task-completion collapse seen
in v2?

**Design.** p-explicit ∈ {0, 0.1, …, 1} (11) × vision-radius ∈ {2, 5}; 1100 runs.

**Result (vision = 5).**

| p-explicit | task-completion v2 | v2.1 | explicit-edit-share | explicit-hit-rate | active-task-count | quality v2.1 |
|---|---|---|---|---|---|---|
| 0 | 0.098 | 0.120 | 0.000 | 0.000 | 22.0 | 0.229 |
| 0.3 | 0.058 | 0.818 | 0.085 | 0.284 | 4.5 | 0.228 |
| 0.5 | 0.005 | 0.921 | 0.107 | 0.213 | 2.0 | 0.230 |
| 1 | 0.000 | 0.971 | 0.171 | 0.171 | 0.7 | 0.226 |

**Finding.** The fix works. task-completion-rate now *rises* monotonically with
p-explicit (0.12 → 0.97) instead of collapsing to 0 (v2). The diagnostics explain
*how*: explicit-hit-rate and explicit-edit-share rise with p-explicit, while
active-task-count falls toward 0 (tasks get completed, so later explicit attempts
fall back to stigmergy — which is legitimate, not failure). H4 supported.

### 8.2 E2 — Stigmergic trace dynamics (evaporation × diffusion × vision)

**RQ.** How do pheromone evaporation and diffusion shape edit distribution and
quality?

**Design.** evaporation ∈ {0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.4} ×
diffusion ∈ {0.01, 0.05, 0.1, 0.15, 0.2} × vision ∈ {2, 5}; 4000 runs.

**Result.** Diffusion is monotonically positive for quality (η² = 0.35): quality
0.165 → 0.310 across diffusion 0.01 → 0.20. Evaporation is a strong inverse
lever (η² = 0.61): low evaporation gives high quality but low ESR (slow memory,
everything stays "busy"); high evaporation erases trace and lowers quality.
resource-edit-correlation is moderate (0.17–0.32) — legitimate stigmergic
attraction via pheromone, not the pathological resource-value attraction removed
in v2.

### 8.3 E3 — Mutualism channel (mutualism-gain-factor × vision)

**RQ.** Confirm mutualism no longer harms quality; verify the channel works.

**Design.** mgf ∈ {0, 0.03, 0.06, 0.09, 0.12, 0.15} × vision ∈ {2, 5}; 600 runs.

**Result (vision = 5).**

| mgf | quality v1 | v2.1 | motivation | benefit/edit | resource-value | mutualism-index-norm |
|---|---|---|---|---|---|---|
| 0 | 0.234 | 0.228 | 0.985 | 0.263 | 0.000 | 0.132 |
| 0.06 | 0.213 | 0.230 | 1.000 | 0.483 | 0.062 | 0.273 |
| 0.15 | 0.214 | 0.231 | 1.000 | 0.574 | 0.084 | 0.329 |

**Finding.** Quality slope: v1 = −0.106 (harmed) → v2.1 = +0.016 (neutral);
t-test mgf=0 vs 0.15: t = −1.60, p = 0.11 (n.s.). The channel works cleanly:
motivation, benefit-per-edit, resource-value, and mutualism-index-norm all rise
with mgf; quality is neutral. resource-edit-correlation = 0 at mgf = 0 (resource-value
decays to 0 without mutualism) and rises to ~0.25 at mgf > 0 — legitimate stigmergic
attraction, not the v1 pathology. H1, H5 supported.

### 8.4 E4 — Participation inequality (activity-probability)

**RQ.** Does stochastic activation create participation inequality?

**Design.** activity-probability ∈ {0.1, …, 1} (10); 500 runs.

**Result.** Gini rises as activity-probability falls: 0.0735 at ap = 0.1 → 0 at
ap = 1. total-edits is linear in ap (1242 → 12500). Quality and ESR rise with ap
(confounded with edit volume). The model produces participation inequality under
stochastic activation, as designed.

### 8.5 E5 — Search and topic structure (vision × topic-count)

**RQ.** How do perception radius and thematic fragmentation structure collaboration?

**Design.** vision ∈ {1, …, 8} × topic-count ∈ {2, …, 8}; 2800 runs.

**Result.** vision-radius is the master variable on ESR (0.41 → 0.90, η² ≈ 0.96).
topic-count is a strong lever on quality (η² = 0.53) and diversity (η² = 0.36) —
the v2 specialisation strengthening held. Fewer topics → higher task-completion
(0.51 at 2 topics vs 0.39 at 5). H2, H3 supported.

### 8.6 E6 — Decoupling test (mgf × p-explicit) — KEY THEORETICAL TEST

**RQ.** Are stigmergy and mutualism orthogonal? Does the mgf × p-explicit
interaction recreate the old pathology?

**Design.** mgf ∈ {0, 0.03, 0.09, 0.15} × p-explicit ∈ {0, 0.25, 0.5, 0.75, 1}; 1000 runs.

**Result.** η² decomposition on key DVs:

| Dependent variable | η²(mgf) | η²(p-explicit) | η²(interaction) |
|---|---|---|---|
| mean-quality | 0.006 | 0.048 | **0.016** |
| mean-motivation | 0.743 | 0.004 | 0.012 |
| benefit-gain-per-edit | 0.994 | 0.001 | 0.000 |
| explicit-edit-share | 0.001 | 0.957 | 0.001 |
| task-completion-rate | 0.000 | 0.948 | 0.000 |

**Finding.** Decoupling confirmed. mgf drives motivation/benefit but not the
distribution of work; p-explicit drives the distribution of work but not
motivation; the interaction on quality is negligible (0.016). The two levers
are orthogonal. H1 supported.

### 8.7 E7 — Scale and load (num-contributors × num-tasks × vision)

**RQ.** Do the qualitative conclusions survive different participant/task densities?

**Design.** num-contributors ∈ {10, 25, 50} × num-tasks ∈ {10, 25, 50} × vision ∈ {2, 5}; 900 runs.

**Result.** Qualitative conclusions hold across scale. ESR rises with vision at
all scales (e.g., 0.30 → 0.91 at nc=10). Quality rises with num-contributors
(0.14 → 0.39 from nc=10 to nc=50). task-completion is higher when contributors
outnumber tasks. coediting-density rises with scale (networks denser at larger
populations). The model is scale-robust; conclusions generalise.

### 8.8 Summary of hypotheses

| Hypothesis | Experiment | Outcome |
|---|---|---|
| H1 Decoupling | E6 | Supported (interaction η² ≈ 0.016) |
| H2 Visibility master | E5 | Supported (ESR η² ≈ 0.96) |
| H3 Topic structure lever | E5 | Supported (quality η² = 0.53) |
| H4 Tight explicit filter | E1 | Supported (tcr 0.12 → 0.97) |
| H5 Mutualism sustains engagement | E3 | Supported (quality neutral, motivation↑) |
| Scale robustness | E7 | Supported |

---

## 9. Interpretation for Pedagogical Design

The five verified mechanisms translate directly into design principles for
collaborative-learning environments:

1. **Two independent design levers.** Environment (visibility, traces, task flags)
   and reward (benefit→motivation) are separable. A designer can strengthen one
   without the other. In v1 they were coupled, making recommendations
   contradictory; v2.1 makes them clean and independent (E6).
2. **Visibility is the master variable.** How much of the workspace each
   participant perceives is the strongest single determinant of collaboration
   density (E5). In a wiki, this maps to notifications, recent-changes feeds,
   dashboards, tags.
3. **Topic structure is a lever, not a label.** How the domain is partitioned
   into topics shapes the network (E5). Fewer topics concentrate effort and
   aid task completion; more topics fragment but distribute participation.
4. **Explicit assignment only works with a tight filter.** Assigned tasks are
   ignored when the assignment logic is loose (E1 v2); a tight filter makes
   assignment focus effort on tasks (E1 v2.1).
5. **Mutualism sustains engagement, not peak quality.** Designing mutual
   contributor–artefact dependence reliably raises motivation and per-edit
   benefit, even when peak quality is unchanged (E3). The payoff is in
   persistence and sustainability of work.

---

## 10. Limitations and Future Extensions

1. **Constant vision-radius.** Could scale with shared-mental-model (open Q1).
2. **Constant lambda-smm.** Could weight by target quality (Q2).
3. **Cumulative ESR/mutualism-index.** A sliding-window version would reflect
   the "live" state (Q3).
4. **Two ESR metrics coexist** (event-level global, patch-level) — documented,
   not unified (Q4).
5. **edit-authors stores unique authors**, not chronology (Q5).
6. **Uniform activity-probability** — individual rates would model genuine
   participation inequality (Q6).
7. **No was-task? flag** — non-task-active-pages conflates "never a task" with
   "task completed" (Q7).

---

## References

Grimm, V., Berger, U., Bastiansen, F., et al. (2006). A standard protocol for
describing individual-based and agent-based models. *Ecological Modelling*,
198(1–2), 115–126.

Grimm, V., Berger, U., DeAngelis, D. L., Polhill, J. G., Giske, J., &
Railsback, S. F. (2010). The ODD protocol: A review and first update.
*Ecological Modelling*, 221(23), 2760–2768.
