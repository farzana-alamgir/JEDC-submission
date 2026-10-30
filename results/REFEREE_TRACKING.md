# Referee comments: what each one asks, and where it stands

Built by reading `Referee report.pdf` (R1, 5 pages) and `Report (1).pdf` (R2,
4 pages) directly, not from `RESPONSE_TO_REFEREES.md`. That matters: the
response draft omits two major comments and its status markers are stale in
four places (§4).

Comments are paraphrased, not quoted. **Type** is what the comment asks for —
model work, empirical work on the panel, or exposition. **Status** means
whether work answering it exists in this repository, *not* whether response
text has been written; `RESPONSE_TO_REFEREES.md` is still marked DRAFT.

## 1. Report 1

| # | Asks for | Type | Status | Evidence |
|---|---|---|---|---|
| M1a | Direct evidence that higher oil volatility raises expected future prices — futures curves or Consensus Forecasts | empirical | **not addressed** | — |
| M1b | Empirical analogue of the Figure 3 / Figure 5 state dependence: interact Δoil price with GDP growth, output gap or recession indicators, and with debt/GDP | empirical | **not addressed** | — |
| M1c | Two-way clustered standard errors, country **and** quarter, in Table 1 | empirical | **not addressed** | — |
| M2 | Separate the pure dispersion effect from the volatility-induced rise in the expected price level, using a mean-preserving specification, and recompute default probabilities, spreads and borrowing | model | **addressed; answer has since weakened** (§3) | `RESPONSE_TO_REFEREES.md` Part A |
| M2b | Whether precautionary borrowing survives once the mean effect is removed | model | **addressed — sign reversed** | Part A.4: isolated oil risk induces precautionary *saving* (−0.033 mean debt); Part B.3 shows the cross-state version is inside the noise floor |
| M3 | Discipline the substitution elasticity with external evidence, and show sensitivity over a plausible range | empirical + model | **addressed** | Part C.2: panel of 34 importers, 1995–2015, gives σ ≈ 0.39, 95% CI [0.23, 0.56], rejecting σ = 2; model recalibrated to σ_oil = 0.30. Range in `ELASTICITY_SWEEP.md`. **Open:** the referee also asks for discussion of imposing one elasticity on 35 heterogeneous economies |
| **M4** | **What is specifically "oil" about the mechanism; how it differs from Seoane (2019) and Johri–Khan–Sosa-Padilla (2022); whether the effect is stronger in more oil-dependent countries; a control for generic imported-input or producer-price volatility; optionally a model comparison against a generic imported input matched on persistence and unconditional volatility** | expositional + empirical + model | **not addressed, and missing from the response draft** | — |
| M5 | Clarify that the precautionary-borrowing result is conditional on risk-neutral pricing; if feasible, robustness with an exogenous SDF or a reduced-form global risk premium | model | **built and tested** — draft wrongly marks this not started | `kappa_risk` in `model/oil_prod_CES.f90`; sweeps in `model/runs_sdf/`, `model/runs_kappa/`; `RISK_PREMIUM_AND_FIGURE3.md`; re-probed at p=277 in `model/kappa_probe.sh`. It does not rescue FIGURE3, and the referee's actual question — whether precautionary borrowing survives under it — has not been revisited |
| m1 | Use "oil price volatility" rather than "uncertainty" unless a broader claim is intended | expositional | **not addressed** | — |
| m2 | Clarify the exogenous endowment *y* against endogenous output *x*; **and** a robustness exercise in which default costs depend on total output or total resources rather than the endowment | expositional + model | **model part addressed, not credited as a response** | `va_default_cost` bases the penalty on value added, output net of the oil bill, instead of the endowment — exactly the requested exercise (`VALUE_ADDED_DEFAULT_COST.md`). Terminology fix outstanding |
| m3 | Interact oil shocks or volatility with exchange-rate depreciation, or with foreign-currency debt exposure | empirical | **not addressed** | — |
| m4 | Typo: the CES elasticity is 1/(1−θ), not 1/θ | expositional | **confirmed**, text fix pending | Part C.4 |

## 2. Report 2

| # | Asks for | Type | Status | Evidence |
|---|---|---|---|---|
| M1 | Recognise that part of the "uncertainty" effect is a first-moment effect; isolate dispersion by subtracting ½Var(log p′ \| σ) from the conditional mean | model | **addressed; answer has since weakened** (§3) | Part A — the same exercise as R1 M2 |
| M2 | Welfare and spread comparisons confound less risk with cheaper oil; the comparison economies do not face the same average price. Construct them to match the full model's average price level | model | **addressed** | Part C.1: all economies share one physical price grid and the same average innovation variance, with the constant-price economy set at E[p] rather than the median exp(p̄) |
| M3 | Discuss the assumption that default does not disrupt oil imports; better, a robustness exercise with a price wedge or partial exclusion during autarky | model | **tested, negative result** — draft wrongly marks this not started | `oil_disruption` in `model/runs_oildisrupt/`; `OIL_DEPENDENT_DEFAULT_COST.md` reports it fails with the wrong sign. The "discuss this assumption" part remains |
| M4 | Soften the novelty claim and differentiate properly from Lopez-Martin et al. (2019), and from Hamann et al. (2018) and Esquivel (2020) in footnote 1 | expositional | **not addressed** | — |
| M5 | Test the 3× state dependence directly: interact Δoil price with a high-volatility indicator, and interact volatility with the country-level oil import share | empirical | **not addressed**; partly moot | The 3× is itself a measurement artifact (Part B.2), so the prediction being tested is one the paper will no longer make in that form |
| **M6** | **The model's effect is far smaller than the data's — spread slopes of 0.05/0.15 against panel coefficients implying 6–8 bp per 10% oil move. Discuss what governs the magnitude, and estimate regression (1) on model-simulated data so the coefficients are comparable** | model + empirical | **not addressed, and missing from the response draft** | — |
| m1 | Notation: the bond price is written q(b′,y) in (4) and below (8) but q(b′,y,p,σ) in (11); and the CES elasticity is 1/(1−ν) | expositional | **partly** — elasticity confirmed, bond-price notation outstanding | Part C.4 |
| m2 | Table 3 contains no oil moment: no spread–oil-price or spread–volatility correlation, no volatility of the oil import share, no default frequency against the data | model + empirical | **not addressed** | — |

## 3. Where the answer to the lead comment now stands

Both reports lead with the same request (R1 M2, R2 M1), and it was answered.
But the answer in the response draft is measured on the 549-node
corrected-volatility version, which has since been superseded:

| | response draft (Part A) | current common grid, p=277 |
|---|---|---|
| time-varying volatility, total | +22.6 bp | +7.3 ±10.1 (shipped), +6.3 ±8.7 (recalibrated) |
| of which pure dispersion | +26.1 bp | +3.2 ±10.3, +3.3 ±8.9 |
| of which expected-price (Jensen) | −3.5 bp | — |

On the current specification **both volatility channels straddle zero**, so the
draft's claim that "the genuine uncertainty channel accounts for essentially
the whole effect" no longer holds as written. What survives robustly is the
much larger oil-price-risk channel, full minus basic, at +286.0 ±7.5 bp
shipped and +218.9 ±6.5 bp recalibrated. See `VERSION_COMPARISON.md`.

That reframes the honest answer to R1 M2 / R2 M1: oil price *risk* matters a
great deal, while *time variation* in that risk is not separately identified.

## 4. Discrepancies with `RESPONSE_TO_REFEREES.md`

1. **R1 Major 4 is absent.** Not mentioned anywhere in the draft. It carries
   three separable requests, one of them empirical and testable.
2. **R2 Major 6 is absent.** Also unmentioned. It is the awkward one: the
   recalibration in `VERSION_COMPARISON.md` lowers the headline channel
   further, from 286.0 to 218.9 bp.
3. **R1 Major 5 and R2 Major 3 are listed as not started** (§C.4) but both
   were built and tested, each with a negative result that is worth reporting
   as a finding rather than left looking undone.
4. **R1 Minor 2's model request is already satisfied** by the value-added
   default cost, which the notes present as the authors' own idea rather than
   as a response to this referee.

Also stale, though self-identified rather than referee-raised: §C.3 flags the
`exp(h)` versus `exp(h/2)` volatility convention as the most consequential
open item. It is resolved — every version after the submitted one reproduces
quarterly oil price volatility of 14.63% against 14.47% in the data. And the
note that "Figures 2–7 on the corrected model are not yet regenerated" is
out of date: all ten exist for the common-grid version, and for the
recalibration in `model/figs_spdebt/`.

## 5. Tally

19 distinct items; R1 M2 ≡ R2 M1, R1 M1b ≡ R2 M5, and R1 m4 ≡ part of R2 m1.

| | count |
|---|---|
| addressed | 6 |
| tested, negative result | 2 |
| not addressed | 11 |

Of the 11 open items, **9 are empirical or expositional** — panel regressions,
interaction tests, inference, and framing against the literature. Only R2 M6
and part of R1 M4 need further modelling. The modelling side of this revision
is substantially done; the panel work and the framing are not.
