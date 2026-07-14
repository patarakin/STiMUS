# STiMUS-HAI (v3.1) — COMSES Deposit Materials

**Model:** STiMUS-HAI (Stigmergic–Mutualistic IMOI Model, Human-AI extension)
**Platform:** NetLogo 7
**Language:** NetLogo
**Version deposited:** 3.1
**Date:** 2026-07-13

---

## 1. Short title (≤ 300 characters)

> **STiMUS-HAI: A Stigmergic–Mutualistic Agent-Based Model of Human-AI Collaboration on Shared Digital Artefacts**

(105 characters — within the limit.)

---

## 2. Summary description (abstract)

> STiMUS-HAI (Stigmergic–Mutualistic IMOI Model, Human-AI extension) is an agent-based model of teamwork in socio-technical systems where **human and AI contributors** collaborate through shared digital artefacts — wiki pages, code files, issue tickets, project cards, Scratch projects — represented as patches in a NetLogo world. It extends the human-only base model STiMUS v2.2, which established that two coordination mechanisms — **stigmergy** (indirect coordination through traces left in the environment) and **mutualism** (mutual benefit between contributors and the artefacts they tend) — can be *decoupled*: stigmergy decides *where* a contributor works, mutualism decides *with what effort*. STiMUS-HAI preserves this decoupling unchanged and adds two further theoretical questions: whether mixing AI agents into a human team distorts human coordination in ways that aggregate indicators hide, and whether AI's cost to team outcomes depends on the *type* of work AI performs, not only on how much of it is present.
>
> Two breeds of turtle — `humans` and `ai-agents` — follow *identical* target-selection, pheromone, and mutualism rules, so that any behavioural difference is attributable to team composition rather than a built-in advantage. The one designed asymmetry: AI agents never accumulate `shared-mental-model` and their `motivation` is fixed rather than adaptive. On top of this v3.0 baseline, v3.1 adds a `task-type` dimension to artefacts (`"prediction"` versus `"judgment"`, set via a `judgment-share` slider) that scales down AI edit-power specifically on judgment-requiring artefacts, and an `ai-trust` mechanic: humans build or lose trust in AI contributions based on the *population-relative percentile rank* of observed AI work quality (bottom-quartile work counts as an observed "error"), and that trust gates how much mutualistic benefit a human derives from continuing an AI's work. Trust erodes quickly on a single error and recovers only after a streak of confirmed successes — an intentional asymmetry.
>
> Both extensions are strictly additive: at `judgment-share = 0` the model is seed-identical to v3.0; at `judgment-share = 0` **and** `ai-share = 0` it is seed-identical to the original human-only v2.2 model. This was verified computationally across two large factorial experiments.
>
> **Experiment E11** (3,600 runs; `ai-share` × `vision-radius` × `p-explicit` × `mutualism-gain-factor`) found that team-level productivity indicators (mean quality, task-completion-rate, coediting-density) are nearly blind to AI share (all η² < 0.003), while the human-only Edit Succession Ratio (`ESR-HH`) falls sharply as AI share rises (η² = 0.79) even as the aggregate `ESR-all` stays essentially flat (η² ≈ 0.000009) — a camouflage effect in which healthy-looking team metrics mask a real erosion of human-to-human coordination. Human shared-mental-model also falls measurably even at a modest 10% AI share (0.904 → 0.881), and this camouflage effect is *amplified*, not dampened, by wider visibility radii.
>
> **Experiment E12** (14,700 runs; `ai-share` × `judgment-share` × `vision-radius`) tested three further hypotheses. Two were rejected: `judgment-share` does not measurably steepen AI's dilution effect on `ESR-HH` (interaction η² ≈ 0.00015), and its apparent effect on AI-trust erosion is better explained as mediated through the population's quality distribution than as a direct interaction (η² = 0.035 direct vs. η² = 0.264 for the quality-mediated path) — a measurement-artifact finding that the model documentation records explicitly, alongside the code revision that resolved an earlier, noise-dominated absolute-threshold design for the trust mechanic. The third hypothesis was strongly supported: AI's cost to work quality is regime-conditional — in a judgment-heavy task mix, quality falls 40% (0.194 → 0.116) as AI share rises from 0 to 0.9, versus only 8% (0.193 → 0.178) in a prediction-heavy mix at the same AI share range.
>
> STiMUS-HAI is intended for education researchers, instructors, and modellers studying human-AI collaboration in digital pedagogy, collaborative platforms, and organisational design. Parameters map to platform and organisational features (`ai-share` to team AI adoption level, `judgment-share` to how much of an organisation's work is judgment- versus routine-intensive, `vision-radius` to notification/activity-feed visibility), enabling counterfactual analysis of how team composition and work-type mix shape human-AI collaborative outcomes.

---

## 3. What this release contains

| Artefact | File | Contents |
|---|---|---|
| Executable model code | `STiMUS-code-V3.1.nls` | NetLogo 7 procedures/reporters file: full v3.1 code (English, minimally commented), two breeds, ai-trust and task-type mechanics |
| Info tab | `STiMUS-HAI-info.md` | NetLogo Info-tab content: WHAT IS IT / HOW IT WORKS / HOW TO USE IT / THINGS TO NOTICE / THINGS TO TRY / EXTENDING / NETLOGO FEATURES / RELATED MODELS / CREDITS |
| ODD protocol | `STiMUS-HAI-ODD.md` | Grimm-standard ODD (7 core sections + E11/E12 experiments + interpretation + limitations) |
| BehaviourSpace experiment (E11) | `STiMUS_AI_01_E11_mixed_teams.xml` | `ai-share` × `vision-radius` × `p-explicit` × `mutualism-gain-factor`, importable via Tools → BehaviorSpace → Import |
| BehaviourSpace experiment (E12, pilot) | `STiMUS_AI_01_E12_pilot_judgment_x_ai.xml` | Pilot sweep that identified and motivated the trust-threshold revision documented in the code |
| BehaviourSpace experiment (E12, main) | `STiMUS_AI_01_E12_main_judgment_x_ai_x_vision_14700_100.xml` | `ai-share` × `judgment-share` × `vision-radius`, 100 repetitions, 14,700 runs |
| Experiment results (E11) | `STiMUS_AI_01-STiMUS_AI_01_E11_mixed_teams_500_50-table.csv` | E11 output table (500 ticks, 50 reps) |
| Experiment analysis scripts | `STiMUS_E11_analysis.r`, `STiMUS_E12_analysis.r` | R analysis: η² decomposition, headline hypothesis tests, backward-compatibility checks |

---

## 4. Contributors

- **Yevgeny Patarakin** — Institute of Education, HSE University; Institute of Digital Education, Moscow City University. Model design, implementation, analysis, documentation.

---

## 5. Release notes (summary)

**How to run.** Open the model's `.nlogox` interface file in NetLogo 7 with `STiMUS-code-V3.1.nls` as its Code tab / included procedures file. Press `setup`, then `go`. Default run: 500 ticks. For experiments: Tools → BehaviorSpace → Import → select the relevant experiment XML file; select it in the list, click Run, choose Table output and a destination CSV. Parallel runs recommended (set to CPU core count).

**Dependencies.** NetLogo 7.0.0 or later. No extensions required.

**Inputs (13 interface sliders).** The 11 base sliders (`num-contributors`, `num-tasks`, `topic-count`, `vision-radius`, `evaporation-rate`, `diffusion-rate`, `edit-increment`, `p-explicit`, `lambda-smm`, `mutualism-gain-factor`, `activity-probability`) plus two new sliders: `ai-share` (v3.0, fraction of the team that is AI) and `judgment-share` (v3.1, fraction of artefacts requiring human judgment).

**Outputs.** Base v2.1 metrics plus v3.0/v3.1 additions: `ESR-all`, `ESR-HH`, `ai-pheromone-share`, `human-edit-share`, `ai-edit-share`, `mean-ai-trust`, `judgment-edit-share`, `prediction-edit-share`, `human-smm-judgment`, `human-smm-prediction`, `mean-ai-error-observations`. Optional bipartite edit log via `save-edge-log` (CSV).

**Version history.**
- **v1–v2.1** — see the STiMUS v2.1 COMSES deposit for the human-only base model's history (stigmergy/mutualism decoupling, explicit-assignment fix).
- **v3.0** — added the `ai-agents` breed alongside `humans`; identical target-selection and mutualism rules for both breeds except that AI agents never accumulate `shared-mental-model` and hold a fixed `motivation`; added the `ai-share` slider and `ESR-all`/`ESR-HH` split reporters.
- **v3.1 (STiMUS-HAI, this deposit)** — added `task-type`/`judgment-weight` on patches and the `judgment-share` slider; added the `ai-trust` mechanic (population-relative percentile error threshold, asymmetric erosion/recovery) and the trust-modified benefit formula; added judgment/prediction-stratified reporters. **Revision within v3.1:** the ai-trust error threshold was changed from a fixed absolute quality value to a population-relative percentile rank, after a pilot BehaviorSpace run (`STiMUS_AI_01_E12_pilot_judgment_x_ai.xml`) showed the absolute-threshold design produced noise-dominated trust estimates at high AI share; this is documented inline in the code as a `REVISION NOTE`.

---

## 6. COMSES metadata

| Field | Value |
|---|---|
| Operating system | Cross-platform (NetLogo) |
| Platform | NetLogo 7 |
| Programming language | NetLogo |
| License | MIT (recommended for code) |
| Model type | Agent-based model |
| Research domain | Educational technology, human-AI collaboration, collaborative learning, digital pedagogy |

---

## 7. Narrative documentation

The ODD protocol document (`STiMUS-HAI-ODD.md`) provides the peer-review-ready narrative: Purpose (including new hypotheses H-E11.1–3, H-E12.1–3); Entities, state variables, and scales (including the two new breeds and task-type/trust variables); Process overview and scheduling; Design concepts; Initialization; Input data; Submodels (including the judgment-penalty and ai-trust update formulas); Simulation experiments and key results (E11, E12); Interpretation for pedagogical and organisational design; Limitations and future extensions. This supersedes the model's Info tab for review purposes, though the Info tab (`STiMUS-HAI-info.md`) remains the in-environment reference.

---

## 8. Status of previously noted discrepancies

The v2.1 deposit flagged several documented-but-unimplemented "open extensions" (AI contributor types, an `ai-share` slider, separate human/all-agent ESR monitors). As of this v3.1 (STiMUS-HAI) deposit, their status is:

| Earlier flag (v2.1) | v3.1 status |
|---|---|
| AI contributor types / `ai-share` | **Implemented** (v3.0): a genuine second breed, `ai-agents`, with `ai-share` slider controlling team composition. |
| Separate `ESR (human-only)` / `ESR (all agents)` monitors | **Implemented** (v3.0): `ESR-HH` and `ESR-all` reporters, the central diagnostic of experiment E11. |
| Q-learning / adaptive AI action selection (considered during v3.1 design) | **Explicitly deferred**, not implemented. The internal design analysis (Manseau integration notes) recommended against replacing the stigmergic rule with Q-learning at this stage, to preserve comparability with v2.2/v3.0; documented as an open extension in the ODD (§10). |
| Carlile semantic/pragmatic knowledge-boundary typing; Newman-Girvan community detection; "water cooler" informal-meeting mechanic (considered during v3.1 design) | **Out of scope for this release**, documented as such in the code header and ODD; left to R-side post-processing or future versions. |

**New discrepancy raised and resolved within this v3.1 development cycle** (not carried over from v2.1, and not a pre-existing gap in the deposited artefact): an early implementation of the `ai-trust` error threshold used a fixed absolute quality value, calibrated without reference to the model's actual emergent quality scale. A pilot BehaviorSpace sweep (`STiMUS_AI_01_E12_pilot_judgment_x_ai.xml`) surfaced this as producing an `ai-trust` measure dominated by small-sample noise rather than signal at high AI share. The design was revised to a population-relative percentile rank before the main E12 experiment (14,700 runs) was run, and the revision — including the diagnostic evidence that motivated it — is documented inline in the deposited code (`REVISION NOTE` at the `ai-trust-quality-threshold` reporter) and in the ODD (§7.4). No unresolved blocking discrepancies remain between the deposited code and its documentation for the v3.1 (STiMUS-HAI) mechanisms.
