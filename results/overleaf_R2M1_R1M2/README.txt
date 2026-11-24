Overleaf package: response to R2 Major 1 / R1 Major 2
-----------------------------------------------------
Upload BOTH files to a new Overleaf project and compile with pdfLaTeX:

    response_R2M1_R1M2.tex
    FIGURE_decomposition.jpg

Only standard packages are used (geometry, graphicx, booktabs, framed,
hyperref, microtype), all of which Overleaf has by default.

To paste the text into an existing response document instead of compiling
this standalone, copy everything between the two marker comments:

    % =========================== BODY BEGINS ===
    % ============================ BODY ENDS ====

and make sure the host document loads graphicx, booktabs and framed, and
that FIGURE_decomposition.jpg sits where the host document can find it.

The figure and every table are produced by one MATLAB file:
    model/analysis/JEDC_decomposition.m
