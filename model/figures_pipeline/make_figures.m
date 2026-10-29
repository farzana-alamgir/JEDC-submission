%MAKE_FIGURES  Draw all ten paper figures from one MATLAB command.
%
%   >> make_figures
%
% Replaces run_all_va_final.sh. Run it from model/figures_pipeline with the
% three solved run directories in place; all ten FIGURE*.jpg are written here.
%
% ---------------------------------------------------------------------------
% WHY THIS IS NOT ONE MERGED SCRIPT
%
% script_intermediate.m and script_basic.m each call `clear all` partway
% through, which wipes the caller's workspace -- so a driver cannot hold the
% run paths, or even a loop counter, in ordinary variables across a stage.
% Everything that must survive is therefore passed through the environment
% (getenv/setenv), which `clear all` does not touch. That is the same reason
% the scripts already read CONTRAST_MODE from the environment.
%
% The three stages are written out explicitly rather than looped, because a
% loop variable would not survive either.
%
% ORDER MATTERS. script_bm.m draws all ten figures and loads the other two
% workspaces for FIGURE2 and FIGURE7, so it must run last. The earlier stages
% exist only to produce oil_intermediate.mat and oil_basic.mat; their own
% figure output is deleted before the benchmark stage.
% ---------------------------------------------------------------------------

%% ---- configuration -------------------------------------------------------
% Edit these three paths, or set the environment variables before calling.
if isempty(getenv('FIG_RUN_INT'))
    setenv('FIG_RUN_INT', fullfile('..','runs_va_final','intermediate_matched'));
end
if isempty(getenv('FIG_RUN_BAS'))
    setenv('FIG_RUN_BAS', fullfile('..','runs_va_final','basic_matched'));
end
if isempty(getenv('FIG_RUN_BM'))
    setenv('FIG_RUN_BM',  fullfile('..','runs_va_final','bm'));
end
% 'fraction' = the submitted relative price contrast (nodes 2 and 6 at p_num=7)
if isempty(getenv('CONTRAST_MODE'))
    setenv('CONTRAST_MODE', 'fraction');
end

fprintf('\n=== make_figures ===\n');
fprintf('  intermediate : %s\n', getenv('FIG_RUN_INT'));
fprintf('  basic        : %s\n', getenv('FIG_RUN_BAS'));
fprintf('  benchmark    : %s\n', getenv('FIG_RUN_BM'));
fprintf('  contrast     : %s\n\n', getenv('CONTRAST_MODE'));

%% ---- stage 1: intermediate -> oil_intermediate.mat -----------------------
% Its trailing section loads oil_bm.mat, which may not exist on a first run;
% that error is expected and harmless, so it is caught. The .mat it needs to
% produce is written before that point.
fprintf('[1/3] intermediate\n');
stage_run(getenv('FIG_RUN_INT'));
try
    run('script_intermediate.m');
catch ME
    fprintf('  (trailing section skipped: %s)\n', ME.message);
end

%% ---- stage 2: basic -> oil_basic.mat -------------------------------------
fprintf('[2/3] basic\n');
stage_run(getenv('FIG_RUN_BAS'));
try
    run('script_basic.m');
catch ME
    fprintf('  (trailing section skipped: %s)\n', ME.message);
end

%% ---- stage 3: benchmark -> all ten figures -------------------------------
% Clear the earlier stages' figure output first: those were drawn from the
% comparison economies and are not the published panels.
fprintf('[3/3] benchmark (draws all ten)\n');
old = dir('FIGURE*.jpg');
for k = 1:numel(old), delete(old(k).name); end
stage_run(getenv('FIG_RUN_BM'));
run('script_bm.m');

%% ---- report --------------------------------------------------------------
want = {'FIGURE2','FIGURE3','FIGURE4a','FIGURE4b','FIGURE4c', ...
        'FIGURE4d','FIGURE5','FIGURE6a','FIGURE6b','FIGURE7'};
fprintf('\n=== result ===\n');
missing = {};
for k = 1:numel(want)
    f = [want{k} '.jpg'];
    if isfile(f)
        d = dir(f);
        fprintf('  %-10s %7.1f kB\n', want{k}, d.bytes/1024);
    else
        fprintf('  %-10s MISSING\n', want{k});
        missing{end+1} = want{k}; %#ok<SAGROW>
    end
end
if isempty(missing)
    fprintf('\nall ten written. Check for blank panels with:  ink_optionA\n');
else
    fprintf('\n%d MISSING: %s\n', numel(missing), strjoin(missing, ', '));
end
