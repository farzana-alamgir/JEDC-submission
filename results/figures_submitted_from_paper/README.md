# Submitted figures, extracted from oil_price_JIE.pdf

These are the figures **as they appear in the submitted paper** — extracted
directly from the embedded JPEG streams of `oil_price_JIE.pdf`. Use these, not
`model/FIGURE*.jpg`, as the reference when checking whether a revision
reproduces the submission.

`model/FIGURE*.jpg` is stale for six of the ten figures. Mean absolute
greyscale difference against the paper:

| figure | `model/*.jpg` vs paper | rebuild of submitted source vs paper |
|---|---|---|
| FIGURE2  | 0.000 | not produced |
| FIGURE3  | **6.899** | **0.000** |
| FIGURE4a | **3.228** | **0.000** |
| FIGURE4b | **3.106** | **0.000** |
| FIGURE4c | **4.322** | **0.000** |
| FIGURE4d | **5.122** | **0.000** |
| FIGURE5  | **2.304** | **0.000** |
| FIGURE6a | 0.000 | 0.000 |
| FIGURE6b | 0.000 | 0.000 |
| FIGURE7  | 0.000 | not produced |

The rebuild is `git show c24560d:model/oil_prod_CES.f90` compiled with
`gfortran -O3` and plotted with `git show c24560d:model/working_graphs_dec29.m`,
unmodified. It reproduces the paper exactly, so the solver and plotting
pipeline are faithful to the submission.

FIGURE2 and FIGURE7 need `oil_intermediate.mat` and `oil_basic.mat`; the fork
sources for those two economies do not exist at commit c24560d, so the rebuild
stops before them. Both already match the paper in `model/`, so neither is in
question.
