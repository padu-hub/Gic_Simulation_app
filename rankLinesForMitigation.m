function [idx_sorted, scores, comp] = rankLinesForMitigation(app, results)
% Rank lines for mitigation by normalizing three criteria to 0-100 and
% combining them. Outputs sorted line indices (idx_sorted), final scores,
% and component scores (comp: struct with fields lenScore, gicScore, locScore).
%
% Inputs:
%   app     - application object with app.L array. Each app.L(i) should have:
%               - Length (numeric)
%               - ResKm (numeric)  (resistance per km)
%               - Loc  (string/char or categorical) identifying pathway/location
%   results - struct containing results.rank.line (Mx2) where column 1 =
%             line index, column 2 = overall GIC metric for that line.
%
% Outputs:
%   idx_sorted - vector of line indices sorted by descending combined score
%   scores     - combined score (0-100) per line (aligned to 1..nLines)
%   comp       - struct with per-line components (lenScore,gicScore,locScore)

if nargin < 2, error('Requires app and results'); end

% Number of lines
nL = numel(app.L);
lineIdxAll = (1:nL).';

% --- 1) Length score (use L.Length) ---
lenScore= zeros(nL,1);
for i=1:nL
    if isfield(app.L(i),'Length') && ~isempty(app.L(i).Length)    
        lenScore(i) = app.L(i).Length;
    end
end
lenScore = normalize0to20(lenScore);


% --- 2) GIC score from results.rank.line(:,2) ---
gicScore = zeros(nL,1);
if isfield(results,'rank') && isfield(results.rank,'line') && ~isempty(results.rank.line)
    rl = results.rank.line;
    vals = rl{:,2};           % column 2 = sum
    gicScore(1:numel(vals)) = vals; % assume same ordering / same length
end
gicScore = normalize0to100(gicScore);
% --- Save gicScore with timestamp ---
try
    tstamp_gic = datetime('now');
    savefname_gic = fullfile(pwd, sprintf('gicScore_%s.mat', datestr(tstamp_gic,'yyyymmdd_HHMMSS')));
    save(savefname_gic, 'gicScore', 'tstamp_gic');
catch
    warning('Failed to save gicScore to file.');
end

% --- 3) Location-group rule (Loc is nx2 double of lat/lon points) ---
locScore = zeros(nL,1);

% collect Loc matrices and ResKm
Locs = cell(nL,1);
for i=1:nL
    if isfield(app.L(i),'Loc') && ~isempty(app.L(i).Loc)
        Locs{i} = app.L(i).Loc; % expected numeric Nx2
    else
        Locs{i} = [];
    end
end
reskm = nan(nL,1);
for i=1:nL
    if isfield(app.L(i),'ResKm') && ~isempty(app.L(i).ResKm)
        reskm(i) = app.L(i).ResKm;
    end
end

% Find groups of identical Loc (pairwise compare)
assigned = false(nL,1);
for i = 1:nL
    if assigned(i), continue; end
    if isempty(Locs{i}), continue; end
    group = i;
    for j = i+1:nL
        if ~isempty(Locs{j}) && isequal(Locs{i}, Locs{j})
            group(end+1) = j; 
        end
    end
    if numel(group) >= 2
        % treat NaN ResKm as -Inf so they are not selected as maximum
        rvals = reskm(group);
        rvals(isnan(rvals)) = -Inf;
        [~, maxPos] = max(rvals);
        maxIdx = group(maxPos);
        locScore(group) = 20;
        locScore(maxIdx) = 0;
    end
    assigned(group) = true;
end



% --- Combine components ---
% If any component has NaN (e.g. missing Length), treat its score as 0.
lenScore(isnan(lenScore)) = 0;
gicScore(isnan(gicScore)) = 0;
locScore(isnan(locScore)) = 0;

% Combine by simple average (equal weighting)
scores = (lenScore + gicScore + locScore) / 3;

% Sort descending to produce idx_sorted
[~, order] = sort(scores, 'descend', 'MissingPlacement', 'last');
idx_sorted = lineIdxAll(order);

% Package components for output
comp.lenScore = lenScore;
comp.gicScore = gicScore;
comp.locScore = locScore;



% four scatter plots (x = 0:(nL-1)) ---
try
    x = 0:(nL-1);
    assert(numel(lenScore)==nL && numel(gicScore)==nL && numel(scores)==nL && numel(locScore)==nL, ...
        'Score vectors must be length nL.');
    
    % clamp to 0-100 for display
    lenPlot = min(max(lenScore,0),100);
    gicPlot = min(max(gicScore,0),100);
    combPlot = min(max(scores,0),100);
    locPlot = min(max(locScore,0),100);

    figure;

    tiledlayout(4,1,'Padding','compact','TileSpacing','compact');

    ax1 = nexttile;
    scatter(ax1, x, gicPlot, 36, gicPlot, 'filled');
    colorbar(ax1); xlabel(ax1,'Line index (0-based)'); ylabel(ax1,'GIC Score');
    title(ax1,'GIC Score by Line'); grid(ax1,'on'); xlim(ax1,[min(x)-1 max(x)+1]);

    ax2 = nexttile;
    scatter(ax2, x, lenPlot, 36, lenPlot, 'filled');
    colorbar(ax2); xlabel(ax2,'Line index (0-based)'); ylabel(ax2,'Length Score');
    title(ax2,'Length Score by Line'); grid(ax2,'on'); xlim(ax2,[min(x)-1 max(x)+1]);

    ax3 = nexttile;
    scatter(ax3, x, locPlot, 36, locPlot, 'filled');
    colorbar(ax3); xlabel(ax3,'Line index (0-based)'); ylabel(ax3,'Loc Score');
    title(ax3,'Loc Score by Line'); grid(ax3,'on'); xlim(ax3,[min(x)-1 max(x)+1]);

    ax4 = nexttile;
    scatter(ax4, x, combPlot, 36, combPlot, 'filled');
    colorbar(ax4); xlabel(ax4,'Line index (0-based)'); ylabel(ax4,'Combined Score');
    title(ax4,'Combined Score by Line'); grid(ax4,'on'); xlim(ax4,[min(x)-1 max(x)+1]);

    linkaxes([ax1 ax2 ax3 ax4],'x');
catch ME
    warning('Failed to create score plots: %s', ME.message);
end





% --- Save idx_sorted with timestamp ---
try
    tstamp = datetime('now');
    savefname = fullfile(pwd, sprintf('idx_sorted_%s.mat', datestr(tstamp,'yyyymmdd_HHMMSS')));
    save(savefname, 'idx_sorted', 'tstamp');
catch
    warning('Failed to save idx_sorted to file.');
end

end

%% Helper: linear normalize vector to 0-100
function out = normalize0to100(v)
    out = zeros(size(v));
    if all(isnan(v) | v==0)
        out(:) = 0;
        return;
    end
    % replace NaN with -Inf so they become min if needed, but keep zeros handled
    valid = ~isnan(v);
    if ~any(valid)
        out(:) = 0; return;
    end
    vValid = v(valid);
    vmin = min(vValid);
    vmax = max(vValid);
    if vmin == vmax
        % all same -> assign 100 to all valid entries
        out(valid) = 100;
        out(~valid) = 0;
        return;
    end
    out(valid) = (vValid - vmin) ./ (vmax - vmin) * 100;
    out(~valid) = 0;
end

function out = normalize0to20(v)
    out = zeros(size(v));
    if all(isnan(v) | v==0)
        out(:) = 0;
        return;
    end
    % replace NaN with -Inf so they become min if needed, but keep zeros handled
    valid = ~isnan(v);
    if ~any(valid)
        out(:) = 0; return;
    end
    vValid = v(valid);
    vmin = min(vValid);
    vmax = max(vValid);
    if vmin == vmax
        % all same -> assign 100 to all valid entries
        out(valid) = 20;
        out(~valid) = 0;
        return;
    end
    out(valid) = (vValid - vmin) ./ (vmax - vmin) * 20;
    out(~valid) = 0;
end