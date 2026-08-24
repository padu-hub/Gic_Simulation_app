function results = runGreedyGICMitigation(app, GICbase, modeStr)
% RUNGREEDYGICMITIGATION
% Runs a greedy GIC mitigation routine using the selected mode.
%
% Mode summary:
%   'original'        -> parallel lines + winding blockers
%   'windings_only'   -> only winding blockers
%   'all_lines'       -> line opening on any line
%   'parallel_lines'  -> only parallel-line opening

%% Normalize baseline GIC fields
GICbase.Subs  = GICbase.Original_Subs;
GICbase.Lines = GICbase.Original_Lines;
GICbase.Trans = GICbase.Original_Trans;

%% Decode selected mitigation mode
modeStr = lower(strtrim(modeStr));

switch modeStr
    case 'original'
        activeLineMitigation    = true;
        activeWindingMitigation = true;
        lineMode    = 'allLines';
        windingMode = 'all';

    case 'windings_only'
        activeLineMitigation    = false;
        activeWindingMitigation = true;
        lineMode    = '';
        windingMode = 'all';

    case 'all_lines'
        activeLineMitigation    = true;
        activeWindingMitigation = false;
        lineMode    = 'allLines';
        windingMode = '';

    case 'parallel_lines'
        activeLineMitigation    = true;
        activeWindingMitigation = false;
        lineMode    = 'parallel';
        windingMode = '';

    otherwise
        error('Invalid modeStr: %s', modeStr);
end

%% Basic network sizes
nLines = numel(app.L);
nTrans = numel(app.T);

%% Build parallel groups and a line-to-group lookup (computed once)
if strcmp(lineMode, 'parallel')
    parallelGroups = buildParallelGroups(app.L);

    % Map each line index to its group for O(1) lookup during updates
    lineToGroup = zeros(nLines, 1);
    for g = 1:numel(parallelGroups)
        for idx = parallelGroups{g}(:)'
            lineToGroup(idx) = g;
        end
    end

    % Track how many lines in each group are still open
    groupAliveCount = zeros(numel(parallelGroups), 1);
    for g = 1:numel(parallelGroups)
        groupAliveCount(g) = numel(parallelGroups{g});
    end

    % Mark which lines currently belong to an eligible parallel group (>= 2 alive)
    lineInEligibleGroup = false(nLines, 1);
    for g = 1:numel(parallelGroups)
        if groupAliveCount(g) >= 2
            lineInEligibleGroup(parallelGroups{g}) = true;
        end
    end
else
    parallelGroups      = {};
    lineToGroup         = [];
    groupAliveCount     = [];
    lineInEligibleGroup = false(nLines, 1);
end

%% Precompute transformer properties (done once, not per iteration)
isAuto = false(nTrans, 1);
for k = 1:nTrans
    t = app.T(k);
    isAuto(k) = (isfield(t, 'HV_Type') && strcmpi(t.HV_Type, 'auto')) || ...
                (isfield(t, 'LV_Type') && strcmpi(t.LV_Type, 'auto'));
end

windingIsWye = getWyeGroundedWindings(app.T);
bothWye      = windingIsWye(:,1) & windingIsWye(:,2);

%% Build initial winding candidate mask (nTrans x 2 logical)
windingCandMask = false(nTrans, 2);
if activeWindingMitigation
    switch windingMode
        case 'autoW2'
            windingCandMask(isAuto, 2) = true;
        case 'all'
            windingCandMask(bothWye, 1) = true;
            windingCandMask(bothWye, 2) = true;
            windingCandMask(isAuto, 2)  = true;
    end
end

%% State trackers
lineOpen       = false(nLines, 1);
windingBlocked = false(nTrans, 2);

%% Result storage using doubling-buffer allocation
allocSize    = 587; %num of lines and trans
sumGICSubs   = zeros(allocSize, 1);
maxTransGIC  = zeros(allocSize, 1);
maxLinesGIC  = zeros(allocSize, 1);
maxTransName = strings(allocSize, 1);
maxLineName  = strings(allocSize, 1);
mitigations  = cell(allocSize, 1);

%% Table row accumulator (cell array avoids repeated table vertcat in loop)
varNames = app.MitigationResults.Properties.VariableNames;
rowAccum = cell(0, numel(varNames));

%% Reset app table for a fresh run
app.MitigationResults     = app.MitigationResults([], :);
app.SpreadsheetTable.Data = app.MitigationResults;

%% Baseline metrics
[sum0, maxT0, maxTName0, maxL0, maxLName0] = extractMetrics(GICbase);

sumGICSubs(1)   = sum0;
maxTransGIC(1)  = maxT0;
maxLinesGIC(1)  = maxL0;
maxTransName(1) = maxTName0;
maxLineName(1)  = maxLName0;
mitigations{1}  = '0: Baseline (no mitigation applied)';
rowAccum(end+1, :) = {"Baseline", maxT0, maxTName0, sum0, maxL0, maxLName0};

baselineMsg = sprintf('Baseline -> TotalGIC = %.2f | MaxTrans = %.2f [%s] | MaxLine = %.2f [%s]', ...
    sum0, maxT0, char(maxTName0), maxL0, char(maxLName0));
app.StatusTextArea.Value = [app.StatusTextArea.Value; baselineMsg];
app.StatusTextArea.scroll('bottom');
drawnow limitrate;

%% Flush table to UI (used at intervals and at the end)
    function flushTable()
        app.MitigationResults     = cell2table(rowAccum, 'VariableNames', varNames);
        app.SpreadsheetTable.Data = app.MitigationResults;
        drawnow limitrate;
    end

flushTable();

%% Main greedy mitigation loop
GIC_current = GICbase;
step = 1;

while true

    %-- Build line candidate list from current mask --%
    if activeLineMitigation
        switch lineMode
            case 'parallel'
                candLines = find(lineInEligibleGroup & ~lineOpen);
            case 'allLines'
                candLines = find(~lineOpen);
            otherwise
                candLines = [];
        end
    else
        candLines = [];
    end

    %-- Build winding candidate list from current mask --%
    if activeWindingMitigation
        [tr, wd]  = find(windingCandMask & ~windingBlocked);
        candWind  = [tr, wd];
    else
        candWind = [];
    end

    %-- Check stopping conditions --%
    currentTotalGIC  = sumGICSubs(step);
    noMoreMitigation = isempty(candLines) && isempty(candWind);
    gicIsZero        = currentTotalGIC <= 50;

    if noMoreMitigation || gicIsZero
        if noMoreMitigation
            stopMsg = 'Stopping: No further mitigations available';
        else
            stopMsg = 'Stopping: GIC has reached zero';
        end
        app.StatusTextArea.Value = [app.StatusTextArea.Value; stopMsg];
        app.StatusTextArea.scroll('bottom');
        drawnow limitrate;
        break;
    end

    %-- Select the worst eligible element --%
    [type, idx, val] = selectWorstGICElement(GIC_current, candLines, candWind);

    if isempty(type) || isnan(val)
        app.StatusTextArea.Value = [app.StatusTextArea.Value; 'Stopping: No valid candidate found'];
        app.StatusTextArea.scroll('bottom');
        drawnow limitrate;
        break;
    end

    %-- Apply the mitigation to the network --%
    [app, lineOpen, windingBlocked, description] = ...
        applyMitigationToNetwork(app, type, idx, lineOpen, windingBlocked);

    %-- Incrementally update candidate masks --%
    % Only the affected entry changes, so no need to rebuild from scratch
    if strcmp(type, 'line')
        lineOpen(idx) = true;
        if strcmp(lineMode, 'parallel') && lineToGroup(idx) > 0
            g = lineToGroup(idx);
            groupAliveCount(g) = groupAliveCount(g) - 1;
            if groupAliveCount(g) < 2
                % Group no longer has enough parallel lines — remove eligibility
                lineInEligibleGroup(parallelGroups{g}) = false;
            end
        end

    elseif strcmp(type, 'winding')
        windingBlocked(idx(1), idx(2))  = true;
        windingCandMask(idx(1), idx(2)) = false;
    end

    %-- Re-run simulation with updated network --%
    [~, ~, ~, GIC_current] = runGIC_now(app);

    %-- Extract metrics from new result --%
    [sumN, maxTN, maxTNameN, maxLN, maxLNameN] = extractMetrics(GIC_current);

    %-- Grow result buffers if needed (doubling strategy) --%
    rowIdx = step + 1;
    %-- Store results for this step --%
    sumGICSubs(rowIdx)   = sumN;
    maxTransGIC(rowIdx)  = maxTN;
    maxLinesGIC(rowIdx)  = maxLN;
    maxTransName(rowIdx) = maxTNameN;
    maxLineName(rowIdx)  = maxLNameN;
    mitigations{rowIdx}  = description;
    rowAccum(end+1, :)   = {string(description), maxTN, maxTNameN, sumN, maxLN, maxLNameN};

    %-- Log step result to status text area --%
    stepMsg = sprintf('Step %d -> TotalGIC = %.2f | MaxTrans = %.2f [%s] | MaxLine = %.2f [%s]', ...
        step, sumN, maxTN, char(maxTNameN), maxLN, char(maxLNameN));
    app.StatusTextArea.Value = [app.StatusTextArea.Value; description; stepMsg];
    app.StatusTextArea.scroll('bottom');
    drawnow limitrate;

    %-- Flush table to UI every 5 steps --%
    if mod(step, 5) == 0
        flushTable();
    end

    step = step + 1;
end

%% Final table flush to catch any remaining rows
flushTable();

%% Trim result arrays to actual number of steps
sumGICSubs   = sumGICSubs(1:step);
maxTransGIC  = maxTransGIC(1:step);
maxLinesGIC  = maxLinesGIC(1:step);
maxTransName = maxTransName(1:step);
maxLineName  = maxLineName(1:step);
mitigations  = mitigations(1:step);

%% Package outputs
results.sumGICSubs     = sumGICSubs;
results.maxTransGIC    = maxTransGIC;
results.maxLinesGIC    = maxLinesGIC;
results.maxTransName   = maxTransName;
results.maxLineName    = maxLineName;
results.mitigations    = mitigations;
results.lineOpen       = lineOpen;
results.windingBlocked = windingBlocked;
results.parallelGroups = parallelGroups;
results.modeStr        = modeStr;

%% Save results and plot
save(' .mat', 'results')
plotGICMitigationResults(results);

























%% ── Nested helper: extract GIC metrics from a GIC struct ─────────────────
    function [sumVal, maxT, maxTName, maxL, maxLName] = extractMetrics(GIC)
        % Total substation GIC: sum each substation column, take the max
        subsAbs = abs(GIC.Subs);
        totPerT = sum(subsAbs, 1, 'omitnan');
        sumVal  = max(totPerT, [], 'omitnan');

        % Max transformer winding GIC
        if isfield(GIC, 'Trans') && ~isempty(GIC.Trans)                   
            % GIC.Trans is Nx2xM: choose larger winding per transformer -> transAbs is NxM
            transAbs = squeeze(max(abs(GIC.Trans), [], 2));  % result: N x M (be careful if N==1 or M==1)
           
            [maxT, linIdx] = max(transAbs, [], 'all', 'omitnan');
            
            if isempty(maxT) || isnan(maxT)
                maxT = 0;
                maxTName = "None";
            else
                [tIdx, ~] = ind2sub(size(transAbs), linIdx);  % tIdx = transformer row
                if isfield(app.T(tIdx), 'Name')
                    maxTName = string(app.T(tIdx).Name);
                else
                    maxTName = "Transformer " + tIdx;
                end
            end
        else
            maxT = 0; maxTName = "None";
        end

        % Max line GIC
        if isfield(GIC, 'Lines') && ~isempty(GIC.Lines)
            linesAbs       = abs(GIC.Lines);
            [maxL, linIdx] = max(linesAbs, [], 'all', 'omitnan');

            if isempty(maxL) || isnan(maxL)
                maxL = 0; maxLName = "None";
            else
                [lIdx, ~] = ind2sub(size(linesAbs), linIdx);
                if isfield(app.L(lIdx), 'Name')
                    maxLName = string(app.L(lIdx).Name);
                else
                    maxLName = "Line " + lIdx;
                end
            end
        else
            maxL = 0; maxLName = "None";
        end
    end

end

