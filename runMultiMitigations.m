function runMultiMitigations(app)

% ============================================================
% OUTAGE SWEEP ANALYSIS FOR GIC NETWORK
% PURPOSE:
%   - Disconnect each line + selected transformer windings
%   - Run GIC simulation per outage
%   - Measure max change in substation GIC
%   - Filter weak-impact substations
%   - Keep only top 50 most impactful outage cases
%   - Plot heatmap of results
% ============================================================

% -------------------- ORIGINAL NETWORK --------------------
L0 = app.OriginalL;
T0 = app.OriginalT;

nLines = numel(L0);
nSubs = numel(app.S);

% ============================================================
% STEP 1: BASELINE RUN (CRITICAL - DO ONLY ONCE)
% ============================================================

app.L = L0;
app.T = T0;

[~, ~, ~, GIC_base] = runGIC_now(app);
baseSubs = abs(GIC_base.Original_Subs);

% ============================================================
% STEP 2: BUILD TRANSFORMER POOL (optional)
% ============================================================

isAuto = arrayfun(@(t) ...
    (isfield(t,'HV_Type') && strcmpi(t.HV_Type,'auto')) || ...
    (isfield(t,'LV_Type') && strcmpi(t.LV_Type,'auto')), T0);

wyeMask = getWyeGroundedWindings(T0);
bothWye = wyeMask(:,1) & wyeMask(:,2);

idxBoth = find(bothWye);
transPool = [idxBoth, ones(size(idxBoth)); ...
             idxBoth, 2*ones(size(idxBoth))];

idxAuto = find(isAuto);
transPool = unique([transPool; idxAuto, 2*ones(size(idxAuto))], 'rows');

% ============================================================
% STEP 3: COMBINE ALL OUTAGE CANDIDATES
% ============================================================

nRuns = nLines + size(transPool,1);

runNames = strings(nRuns,1);
gicMatrix = nan(nRuns, nSubs);

% ============================================================
% STEP 4: LINE OUTAGE SWEEP
% ============================================================

for i = 1:nLines

    % reset system

    app.L = L0;
    app.T = T0;

    % trip line
    app.L(i).Resistance = inf;

    % name
    if isfield(L0(i),'Name')
        runNames(i) = "L: " + string(L0(i).Name);
    else
        runNames(i) = "Line_" + i;
    end

    % run model
    [~, ~, ~, GIC] = runGIC_now(app);
    subsNow = abs(GIC.Subs);


    % max change per substation
    gicMatrix(i,:) = max(subsNow - baseSubs, [], 2, 'omitnan')';

end

% ============================================================
% STEP 5: TRANSFORMER OUTAGE SWEEP
% ============================================================

for j = 1:size(transPool,1)

    app.L = L0;
    app.T = T0;

    tIdx = transPool(j,1);
    wIdx = transPool(j,2);

    if wIdx == 1
        % -------------------- OPEN WINDING 1 ONLY --------------------
        if isfield(app.T(tIdx),'W1')
            app.T(tIdx).W1 = inf;
        end
    
    elseif wIdx == 2
        % -------------------- OPEN WINDING 2 ONLY --------------------
        if isfield(app.T(tIdx),'W2')
            app.T(tIdx).W2 = inf;
        end
    end

    runNames(nLines + j) = "T: " + string(tIdx) + " W" + string(wIdx);

    [~, ~, ~, GIC] = runGIC_now(app);
    subsNow = abs(GIC.Subs);

    gicMatrix(nLines + j,:) = max(subsNow - baseSubs, [], 2, 'omitnan')';

end

% ============================================================
% STEP 6: FILTER WEAK SUBSTATIONS (GLOBAL RULE)
% remove substations that NEVER exceed 5 A change
% ============================================================

maxPerSub = max(gicMatrix, [], 1, 'omitnan');
keepSubs = maxPerSub > 5;

gicMatrix = gicMatrix(:, keepSubs);

% ============================================================
% STEP 7: SELECT TOP 50 MOST IMPACTFUL RUNS
% ============================================================

runImpact = max(gicMatrix, [], 2, 'omitnan');
[~, idxSort] = sort(runImpact, 'descend', 'MissingPlacement', 'last');


topN = min(50, numel(idxSort));
idxKeepRuns = idxSort(1:topN);

gicMatrix = gicMatrix(idxKeepRuns,:);
runNames = runNames(idxKeepRuns);

% ============================================================
% STEP 8: PLOT HEATMAP
% ============================================================

figure;
imagesc(gicMatrix);
colorbar;

xlabel('Substations (filtered)');
ylabel('Outage scenario (top 50 only)');
title('GIC Sensitivity Heatmap (Line + Transformer Outages)');

set(gca, 'YTick', 1:topN, 'YTickLabel', cellstr(runNames));
% save the figure
figName = 'GIC_Sensitivity_Heatmap.png';
% try to use app.ProjectPath if available, otherwise current folder
if isprop(app,'ProjectPath') && ~isempty(app.ProjectPath)
    outFile = fullfile(app.ProjectPath, figName);
else
    outFile = fullfile(pwd, figName);
end
% ensure renderer for consistent output
set(gcf, 'PaperPositionMode', 'auto');
print(gcf, outFile, '-dpng', '-r300');



end