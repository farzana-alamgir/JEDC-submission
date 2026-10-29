function stage_run(src)
%STAGE_RUN  Copy one solved run's text dumps into the working directory.
%
%   The figure scripts read graphs_*.txt from the CURRENT folder, and every
%   economy writes the same filenames, so each stage has to clear the previous
%   one first. graphs_data_sim_dss.txt is deleted after copying: it is ~160 MB,
%   the figure scripts never read it, and leaving it in place makes the MATLAB
%   `load` calls far slower.

if ~isfolder(src)
    error('stage_run:missing', 'run directory not found: %s', src);
end

% clear whatever the previous stage left behind
old = dir('graphs_*.txt');
for k = 1:numel(old)
    delete(old(k).name);
end
for f = {'p_grid.txt','p_vol_grid.txt'}
    if isfile(f{1}), delete(f{1}); end
end

% copy this run in
n = 0;
src_files = dir(fullfile(src, 'graphs_*.txt'));
for k = 1:numel(src_files)
    copyfile(fullfile(src, src_files(k).name), src_files(k).name);
    n = n + 1;
end
for f = {'p_grid.txt','p_vol_grid.txt'}
    s = fullfile(src, f{1});
    if isfile(s), copyfile(s, f{1}); n = n + 1; end
end

if n == 0
    error('stage_run:empty', 'no graphs_*.txt found in %s', src);
end
if isfile('graphs_data_sim_dss.txt')
    delete('graphs_data_sim_dss.txt');
end
fprintf('  staged %d files from %s\n', n, src);
end
