# What the paper predicts, and how to score the four economies

Quotes are from `oil_price_JIE.pdf`. `cv` = intermediate (constant volatility),
`mp` = mean-preserving (new, added for the referees), `bm` = full SV.

## Tables

| quantity | paper's claim | predicted ordering |
|---|---|---|
| mean spread | *"the full model generates a higher average spread ... for an equivalent average debt/GDP ratio"* | basic < cv < mp < bm |
| spread sd | *"increased spread variability"* | basic < cv < mp < bm |
| default rate | *"an elevated default rate"* | basic < cv < mp < bm |
| welfare, full -> basic | *"average welfare gain of 0.2 to 1.1% increase in consumption"* | **+1.1%** |
| welfare, full -> intermediate | same sentence, lower end | **+0.2%** |
| mean debt | *"governments strategically borrow more during high volatility periods"* | bm > cv (precautionary) |

The decomposition is **new** -- the paper has no mean-preserving economy. But the
paper's stated mechanism is a first-moment one: *"higher oil price volatility
raises expected future oil prices ... which implies lower expected future oil
imports and output, higher future default probabilities ... and higher sovereign
spreads."* So on the paper's own logic the **mean (Jensen) channel should be
positive and the larger of the two**, with dispersion adding less. That is
exactly the split both referees asked to see, and exactly the one R2 argues is
not really "uncertainty".

## Figures

| figure | paper's claim | what it should look like |
|---|---|---|
| FIGURE2 | spread menu, full vs intermediate vs basic | Full above Intermediate above Basic at every debt/GDP |
| FIGURE3 | *"spreads respond three times more sharply"*; *"a 10% increase in oil price leads to a 0.5 bp rise in the spread during low volatility, while the same price change results in a 1.5 bp increase during high volatility"* | three clearly separated curves, **high/low ratio = 3** |
| FIGURE4d | *"higher oil price volatility raises expected future oil prices"* | E[p'] rising in volatility; flat under the mean-preserving correction |
| FIGURE5 | *"Debt levels amplify this sensitivity -- more indebted economies experience larger spread increases"* | slope rising with debt |
| FIGURE6a/6b | *"the debt slope falls to 0.16 during low volatility but rises to 0.70 during high volatility"*; at mean volatility 0.25 | **ratio > 4** between high and low volatility; default threshold shifts **left** at high oil prices |
| FIGURE7 | welfare gains | both curves **positive**, 0.2-1.1% |

## Already known to fail, before these runs

| claim | status |
|---|---|
| FIGURE3 ratio = 3 | the 3x is a measurement artifact -- per-state price intervals divided by a single vol-3 denominator, ratio 3.245. Confirmed from the submitted source. |
| FIGURE4d rise | the published +17% to +58% is the grid nodes themselves at a fixed price index. True Jensen lift is +1.94% under the corrected volatility. |
| welfare +1.1% | reversed: removing oil price risk costs **-3.2%** of consumption, because output is convex in price at sigma = 2. |
| full > cv spreads | the time-varying volatility channel is **-0.3 bp**, below the 1.3 bp noise floor. |

## Still genuinely open, to be settled by the running set

- **basic < cv**: does oil price risk raise spreads? Earlier runs say yes, **+155 bp**, and this is the one large robust result.
- **FIGURE5**: does the slope rise with debt? Not yet checked on a clean build.
- **FIGURE6a/6b**: the debt slope 0.16 / 0.25 / 0.70 claim has **never been checked** in this revision.
- **mean vs dispersion split**: both are +/-4 bp and flipped sign with the bisection fix, so likely unresolvable.
- **risk premium** (kappa = 2, 5): new, no prior claim to compare against.
