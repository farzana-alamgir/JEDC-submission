# Figure pipeline (corrected)

These are the scripts that actually produced
`results/figures_corrected/`. They are `working_graphs_dec29.m` plus the fixes
recorded in `REVISION_NOTES.md` Parts 6-13, split into one driver per economy
because the benchmark script loads the other two workspaces to draw FIGURE2
and FIGURE7.

    CONTRAST_MODE=price bash run_all.sh      # the FINAL figure set
    CONTRAST_MODE=fraction bash run_all.sh   # robustness cut

`run_all.sh` expects the three solved economies' `graphs_*.txt` output. Edit the
`stage` lines to point at your run directories.

## What was changed relative to the submitted script

- `fl__` textscan reader replaces `load` for the large ASCII dumps
- six arrays preallocated (NOT `value_full` / `value_full_debt` -- preallocating
  those writes zeros into the workspace and sends welfare to -Inf)
- `i_matrix` hoisted out of the innermost loop
- `CONTRAST_MODE` selects how the two contrast prices are picked
- `pidx()` remaps price indices written for a 7-node grid (Figs 2, 3, 4d, 5)
- welfare is a consumption equivalent, not `(Va-Vf)/Vf*scale_y`, which has the
  sign backwards because the CRRA value function is negative
- Figure 7 legend labels unswapped
- Figure 4c smoothed with an edge-aware local cubic to suppress Tauchen aliasing
- Figure 3 autoscales its y-axis under the narrow contrast

Every change is documented with its justification inline.
