function results = runGreedyGICMitigation(app, GICbase, modeStr)
% RUNGREEDYGICMITIGATION
% Runs a greedy GIC mitigation routine using the selected mode.
%
% Mode summary:
%   'original'        -> parallel lines + auto W2 blockers
%   'windings_only'   -> only winding blockers
%   'all_lines'       -> only line opening on any line
%   'parallel_lines'  -> only parallel-line opening
%
% Notes:
%   - Baseline is stored at row/index 1
%   - Each new mitigation is appended after re-running the simulation
%   - Helper functions are assumed to already exist and be correct

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
        lineMode    = 'parallel';
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

%% Basic network information and static eligibility masks
nLines = numel(app.L);
nTrans = numel(app.T);

if strcmp(lineMode, 'parallel')
    parallelGroups = buildParallelGroups(app.L);
else
    parallelGroups = {};
end


isAuto = arrayfun(@(t) ...
    (isfield(t,'HV_Type') && strcmpi(t.HV_Type,'auto')) || ...
    (isfield(t,'LV_Type') && strcmpi(t.LV_Type,'auto')), ...
    app.T);

windingIsWye = getWyeGroundedWindings(app.T);
bothWye = windingIsWye(:,1) & windingIsWye(:,2);

%% State trackers
lineOpen       = false(nLines,1);
windingBlocked = false(nTrans,2);

%% Clear and initialize result storage
sumGICSubs   = [];
maxTransGIC  = [];
maxLinesGIC  = [];
maxTransName = strings(0,1);
maxLineName  = strings(0,1);
mitigations  = {};

%% Reset app table for a fresh run
app.MitigationResults = app.MitigationResults([],:);
app.SpreadsheetTable.Data = app.MitigationResults;

%% Baseline metrics
subsAbs0 = abs(GICbase.Subs);
totPerT0 = sum(subsAbs0, 1, 'omitnan');
sum0     = max(totPerT0, [], 'omitnan');

if isfield(GICbase, 'Trans') && ~isempty(GICbase.Trans)
    transAbs0 = abs(GICbase.Trans);
    [maxT0, linIdxT0] = max(transAbs0, [], 'all', 'omitnan');

    if isempty(maxT0) || isnan(maxT0)
        maxT0 = 0;
        maxTransName0 = "None";
    else
        [transIdx0, windIdx0] = ind2sub(size(transAbs0), linIdxT0);
        if isfield(app.T(transIdx0), 'Name')
            maxTransName0 = string(app.T(transIdx0).Name) + " (W" + string(windIdx0) + ")";
        else
            maxTransName0 = "Transformer " + string(transIdx0) + " (W " + string(windIdx0) + ")";
        end
    end
else
    maxT0 = 0;
    maxTransName0 = "None";
end

if isfield(GICbase, 'Lines') && ~isempty(GICbase.Lines)
    linesAbs0 = abs(GICbase.Lines);
    [maxL0, linIdxL0] = max(linesAbs0, [], 'all', 'omitnan');

    if isempty(maxL0) || isnan(maxL0)
        maxL0 = 0;
        maxLineName0 = "None";
    else
        [lineIdx0, ~] = ind2sub(size(linesAbs0), linIdxL0);
        if isfield(app.L(lineIdx0), 'Name')
            maxLineName0 = string(app.L(lineIdx0).Name);
        else
            maxLineName0 = "Line " + string(lineIdx0);
        end
    end
else
    maxL0 = 0;
    maxLineName0 = "None";
end

sumGICSubs(1)   = sum0;
maxTransGIC(1)  = maxT0;
maxLinesGIC(1)  = maxL0;
maxTransName(1) = maxTransName0;
maxLineName(1)  = maxLineName0;
mitigations{1}  = '0: Baseline (no mitigation applied)';

baselineMsg = sprintf('Baseline -> TotalGIC = %.2f | MaxTrans = %.2f [%s] | MaxLine = %.2f [%s]', ...
    sum0, maxT0, char(maxTransName0), maxL0, char(maxLineName0));
app.StatusTextArea.Value = [app.StatusTextArea.Value; baselineMsg];

baselineRow = table( ...
    "Baseline", ...
    maxT0, ...
    maxTransName0, ...
    sum0, ...
    maxL0, ...
    maxLineName0, ...
    'VariableNames', app.MitigationResults.Properties.VariableNames);

app.MitigationResults = [app.MitigationResults; baselineRow];
app.SpreadsheetTable.Data = app.MitigationResults;
drawnow;

%% Initialize loop state
GIC_current = GICbase;
step = 1;

%% Main greedy mitigation loop
while true

    % Build current line candidates
    if activeLineMitigation
        switch lineMode
            case 'parallel'
                candLines = [];
                for g = 1:numel(parallelGroups)
                    grp = parallelGroups{g};
                    alive = grp(~lineOpen(grp));
                    if numel(alive) >= 2
                        candLines = [candLines; alive(:)];
                    end
                end
            %     candLines = unique(candLines);
            % case 'allLines_rankedBased'
            %     grp
            case 'allLines'
                candLines = find(~lineOpen);

            otherwise
                candLines = [];
        end
    else
        candLines = [];
    end

    % Build current winding candidates
    if activeWindingMitigation
        switch windingMode
            case 'autoW2'
                candWind = [];
                for k = 1:nTrans
                    if isAuto(k) && ~windingBlocked(k,2)
                        candWind(end+1,:) = [k 2];
                    end
                end

            case 'all'
                candWind = [];
                for k = 1:nTrans

                    if bothWye(k)
                        for w = 1:2
                            if ~windingBlocked(k,w)
                                candWind(end+1,:) = [k w];
                            end
                        end
                    end

                    if isAuto(k) && ~windingBlocked(k,2)
                        if isempty(candWind) || ~any(candWind(:,1)==k & candWind(:,2)==2)
                            candWind(end+1,:) = [k 2];
                        end
                    end
                end

            otherwise
                candWind = [];
        end
    else
        candWind = [];
    end

    % Stop if nothing remains or GIC is already zero
    currentTotalGIC = sumGICSubs(step);
    noMoreMitigation = isempty(candLines) && isempty(candWind);
    gicIsZero = (currentTotalGIC <= 50);

    if noMoreMitigation || gicIsZero
        if noMoreMitigation
            msg = 'Stopping: No further mitigations available';
        else
            msg = 'Stopping: GIC has reached zero';
        end
        app.StatusTextArea.Value = [app.StatusTextArea.Value; msg];
        drawnow;
        break;
    end

    % Pick worst eligible element
    [type, idx, val] = selectWorstGICElement(GIC_current, candLines, candWind);

    if isempty(type) || isnan(val)
        msg = 'Stopping: No valid candidate found';
        app.StatusTextArea.Value = [app.StatusTextArea.Value; msg];
        drawnow;
        break;
    end

    % Apply one mitigation
    [app, lineOpen, windingBlocked, description] = ...
        applyMitigationToNetwork(app, type, idx, lineOpen, windingBlocked);

    rowIdx = step + 1;
    mitigations{rowIdx} = description;
    app.StatusTextArea.Value = [app.StatusTextArea.Value; description];
    drawnow;

    % Re-run simulation after network update
    [~, ~, ~, GIC_current] = runGIC_now(app);

    % Updated total substation GIC
    subsAbsN = abs(GIC_current.Subs);
    totPerTN = sum(subsAbsN, 1, 'omitnan');
    sumN     = max(totPerTN, [], 'omitnan');

    % Updated max transformer value and name
    if isfield(GIC_current, 'Trans') && ~isempty(GIC_current.Trans)
        transAbsN = abs(GIC_current.Trans);
        [maxTN, linIdxTN] = max(transAbsN, [], 'all', 'omitnan');

        if isempty(maxTN) || isnan(maxTN)
            maxTN = 0;
            maxTransNameN = "None";
        else
            [transIdxN, windIdxN] = ind2sub(size(transAbsN), linIdxTN);
            if isfield(app.T(transIdxN), 'Name')
                maxTransNameN = string(app.T(transIdxN).Name) + " (W" + string(windIdxN) + ")";
            else
                maxTransNameN = "Transformer " + string(transIdxN) + " (W" + string(windIdxN) + ")";
            end
        end
    else
        maxTN = 0;
        maxTransNameN = "None";
    end

    % Updated max line value and name
    if isfield(GIC_current, 'Lines') && ~isempty(GIC_current.Lines)
        linesAbsN = abs(GIC_current.Lines);
        [maxLN, linIdxLN] = max(linesAbsN, [], 'all', 'omitnan');

        if isempty(maxLN) || isnan(maxLN)
            maxLN = 0;
            maxLineNameN = "None";
        else
            [lineIdxN, ~] = ind2sub(size(linesAbsN), linIdxLN);
            if isfield(app.L(lineIdxN), 'Name')
                maxLineNameN = string(app.L(lineIdxN).Name);
            else
                maxLineNameN = "Line " + string(lineIdxN);
            end
        end
    else
        maxLN = 0;
        maxLineNameN = "None";
    end

    % Store updated step results
    sumGICSubs(rowIdx)   = sumN;
    maxTransGIC(rowIdx)  = maxTN;
    maxLinesGIC(rowIdx)  = maxLN;
    maxTransName(rowIdx) = maxTransNameN;
    maxLineName(rowIdx)  = maxLineNameN;

    % Log to app
    stepMsg = sprintf('Step %d -> TotalGIC = %.2f | MaxTrans = %.2f [%s] | MaxLine = %.2f [%s]', ...
        step, sumN, maxTN, char(maxTransNameN), maxLN, char(maxLineNameN));
    app.StatusTextArea.Value = [app.StatusTextArea.Value; stepMsg];

    % Append row to app table
    newRow = table( ...
        string(description), ...
        maxTN, ...
        maxTransNameN, ...
        sumN, ...
        maxLN, ...
        maxLineNameN, ...
        'VariableNames', app.MitigationResults.Properties.VariableNames);

    app.MitigationResults = [app.MitigationResults; newRow];
    app.SpreadsheetTable.Data = app.MitigationResults;
    drawnow;

    % Advance step
    step = step + 1;
end

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

%% Save and plot
save('mitigation_results.mat', ...
    'mitigations', 'sumGICSubs', 'maxTransGIC', 'maxLinesGIC', ...
    'maxTransName', 'maxLineName');

plotGICMitigationResults(results);

end