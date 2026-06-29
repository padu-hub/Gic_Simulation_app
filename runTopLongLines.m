function results = runTopLongLines(app, idx_sorted)
% RUNANDPLOTGICMITIGATION Run line mitigations in the order idx_sorted and plot results
%   results = runAndPlotGICMitigation(app, idx_sorted)
%
% Inputs:
%   app         - application object providing:
%                   - runGIC_now(app) -> [~,~,~,GIC_current]
%                   - applyMitigationToNetwork(app,'line',idx,lineOpen,windingBlocked)
%                   - StatusTextArea UI field (string array)
%                   - flushTable() method if present (optional)
%   idx_sorted  - vector of line indices into L, ordered by resistance
%
% Output:
%   results     - struct containing time-series results and final masks

% ----- Initial state and pre-flight checks -----
if nargin < 2
    error('Requires app and idx_sorted');
end
idx_sorted = idx_sorted(:);

% Ensure masks exist on app workspace or create defaults
if isprop(app, 'lineOpen')
    lineOpen = app.lineOpen;
else
    % assume all closed at start
    nLines = max(idx_sorted);
    lineOpen = false(1, nLines);
end

if isprop(app, 'windingBlocked')
    windingBlocked = app.windingBlocked;
else
    windingBlocked = false(1,1); %#ok<NASGU> % not used but passed through
end

% Run initial simulation to get baseline
app.gic_originalS=[];
app.gic_originalL=[];
app.gic_originalT=[];
[~, ~, ~, GICbase] = runGIC_now(app);
app.gic_originalS=GICbase.Original_Subs;
app.gic_originalL=GICbase.Original_Lines;
app.gic_originalT=GICbase.Original_Trans;
GICbase.Subs  = GICbase.Original_Subs;
GICbase.Lines = GICbase.Original_Lines;
GICbase.Trans = GICbase.Original_Trans;
[sumN0, maxTN0, maxTName0, maxLN0, maxLName0] = extractMetrics(app, GICbase);

% Preallocate buffers (will grow if needed)
alloc = 256;
sumGICSubs   = zeros(1, alloc);
maxTransGIC  = zeros(1, alloc);
maxLinesGIC  = zeros(1, alloc);
maxTransName = cell(1, alloc);
maxLineName  = cell(1, alloc);
mitigations  = cell(1, alloc);
rowAccum     = cell(0,6);

% store baseline as step 0
step = 0;
sumGICSubs(1)   = sumN0;
maxTransGIC(1)  = maxTN0;
maxLinesGIC(1)  = maxLN0;
maxTransName{1} = maxTName0;
maxLineName{1}  = maxLName0;
mitigations{1}  = "Baseline";
rowAccum(end+1, :) = {string("Baseline"), maxTN0, maxTName0, sumN0, maxLN0, maxLName0};

% UI log
try
    app.StatusTextArea.Value = [app.StatusTextArea.Value; "Starting mitigation run"];
    app.StatusTextArea.scroll('bottom');
    drawnow limitrate;
catch
end

% ----- Main mitigation loop (ordered by idx_sorted) -----
nCand = numel(idx_sorted);
nextPtr = 1;

while true
    % stopping conditions
    currentTotalGIC = sumGICSubs(step+1); 
    noMoreLineCandidates = nextPtr > nCand;
    gicIsZero = currentTotalGIC <= 50;

    if noMoreLineCandidates || gicIsZero
        if noMoreLineCandidates
            stopMsg = 'Stopping: No further mitigations available';
        else
            stopMsg = 'Stopping: GIC has reached zero';
        end
        try
            app.StatusTextArea.Value = [app.StatusTextArea.Value; stopMsg];
            app.StatusTextArea.scroll('bottom');
            drawnow limitrate;
        catch
        end
        break;
    end

    % pick next candidate index from idx_sorted
    lineIdx = idx_sorted(nextPtr);
    nextPtr = nextPtr + 1;

    % apply mitigation
    try
        [app, lineOpen, windingBlocked, description] = ...
            applyMitigationToNetwork(app, 'line', lineIdx, lineOpen, windingBlocked);
    catch ME
        % if applyMitigation fails, log and stop
        try
            app.StatusTextArea.Value = [app.StatusTextArea.Value; ...
                sprintf('Error applying mitigation to line %d: %s', lineIdx, ME.message)];
            app.StatusTextArea.scroll('bottom');
            drawnow limitrate;
        catch
        end
        break;
    end

    % mark line open locally
    if lineIdx <= numel(lineOpen)
        lineOpen(lineIdx) = true;
    end

    % re-run simulation
    [~, ~, ~, GIC_current] = runGIC_now(app);
    [sumN, maxTN, maxTNameN, maxLN, maxLNameN] = extractMetrics(app, GIC_current);

    % grow buffers if needed
    rowIdx = step + 2; % next storage index (step starts at 0 -> stored at 1)
    if rowIdx > numel(sumGICSubs)
        extend = max(alloc, numel(sumGICSubs));
        sumGICSubs(end+1:end+extend) = 0;
        maxTransGIC(end+1:end+extend) = 0;
        maxLinesGIC(end+1:end+extend) = 0;
        maxTransName(end+1:end+extend) = cell(1, extend);
        maxLineName(end+1:end+extend) = cell(1, extend);
        mitigations(end+1:end+extend) = cell(1, extend);
    end

    % store results
    sumGICSubs(rowIdx)   = sumN;
    maxTransGIC(rowIdx)  = maxTN;
    maxLinesGIC(rowIdx)  = maxLN;
    maxTransName{rowIdx} = maxTNameN;
    maxLineName{rowIdx}  = maxLNameN;
    mitigations{rowIdx}  = description;
    rowAccum(end+1, :)   = {string(description), maxTN, maxTNameN, sumN, maxLN, maxLNameN};

    % UI log per step
    try
        stepMsg = sprintf('Step %d -> TotalGIC = %.2f | MaxTrans = %.2f [%s] | MaxLine = %.2f [%s]', ...
            step+1, sumN, maxTN, char(maxTNameN), maxLN, char(maxLNameN));
        app.StatusTextArea.Value = [app.StatusTextArea.Value; description; stepMsg];
        app.StatusTextArea.scroll('bottom');
        drawnow limitrate;
    catch
    end

    % optional flushTable if app has it (every 5 steps)
    try
        if mod(step+1, 5) == 0 && ismethod(app, 'flushTable')
            app.flushTable();
        end
    catch
    end

    step = step + 1;
end

% ----- Trim buffers to actual length -----
nSteps = step + 1; % include baseline
sumGICSubs   = sumGICSubs(1:nSteps);
maxTransGIC  = maxTransGIC(1:nSteps);
maxLinesGIC  = maxLinesGIC(1:nSteps);
maxTransName = maxTransName(1:nSteps);
maxLineName  = maxLineName(1:nSteps);
mitigations  = mitigations(1:nSteps);

% package results
results.sumGICSubs     = sumGICSubs;
results.maxTransGIC    = maxTransGIC;
results.maxLinesGIC    = maxLinesGIC;
results.maxTransName   = maxTransName;
results.maxLineName    = maxLineName;
results.mitigations    = mitigations;
results.lineOpen       = lineOpen;
results.windingBlocked = windingBlocked;
results.idx_sorted     = idx_sorted;

% save and plot
try
    save('mitigation_results.mat', 'mitigations', 'sumGICSubs', 'maxTransGIC', 'maxLinesGIC', ...
        'maxTransName', 'maxLineName');
    save('mitigation_results_full.mat', 'results');
catch
end

% call plotting subfunction
plotGICMitigationResults_local(results);

end


%% Local plotting function (based on provided code)
function plotGICMitigationResults_local(results)
figure('Name','GIC Mitigation Results','NumberTitle','off');
nSteps = numel(results.sumGICSubs);
x = 0:(nSteps-1); % 0 = baseline

% Bottom axes for bar graphs
axBar = axes;

yyaxis(axBar, 'right')
b1 = bar(axBar, x, results.maxTransGIC, 0.75, ...
    'FaceColor', [1.00 0.65 0.65], ...
    'EdgeColor', [0.80 0.25 0.25], ...
    'LineWidth', 1.0);
hold(axBar, 'on')

b2 = bar(axBar, x, results.maxLinesGIC, 0.45, ...
    'FaceColor', [0.35 0.55 1.00], ...
    'EdgeColor', [0.10 0.25 0.80], ...
    'LineWidth', 1.0);

axBar.YColor = [0.15 0.15 0.15];
ylabel(axBar, 'Max Transformer / Line GIC (A/phase)');

xlim(axBar, [min(x)-0.5, max(x)+0.5]);
axBar.FontSize = 14;
grid(axBar, 'on')
hold(axBar, 'on')

% Hide left y-axis on bottom axes
axBar.YAxis(1).Visible = 'off';
axBar.YAxis(2).Visible = 'on';

% Top axes for line graph
axLine = axes('Position', axBar.Position);

p1 = plot(axLine, x, results.sumGICSubs, '-k', ...
    'LineWidth', 2.5, ...
    'MarkerSize', 4, ...
    'MarkerFaceColor', 'k');
hold(axLine, 'on')

axLine.Color = 'none';

% Formatting
axLine.YAxisLocation = 'left';
axLine.XAxisLocation = 'bottom';
axLine.YColor = [0 0 0];
ylabel(axLine, 'Total Substation GIC Sum (A/phase)');

xlim(axLine, [min(x)-0.5, max(x)+0.5]);

% Match x ticks
axLine.XTick = axBar.XTick;
axLine.FontSize = 14;

box(axLine, 'off')
linkaxes([axBar, axLine], 'x');

xlabel(axBar, 'Number of Mitigations Applied');

legend(axLine, [p1, b1, b2], ...
    {'Substations: total GIC sum', ...
     'Transformers: max |GIC|', ...
     'Lines: max |GIC|'}, ...
     'Location', 'northeast', ...
     'FontSize', 12);
end



%% ── Nested helper: extract GIC metrics from a GIC struct ─────────────────
    function [sumVal, maxT, maxTName, maxL, maxLName] = extractMetrics(app, GIC)
        % Total substation GIC: sum each substation column, take the max
        subsAbs = abs(GIC.Subs);
        totPerT = sum(subsAbs, 1, 'omitnan');
        sumVal  = max(totPerT, [], 'omitnan');

        % Max transformer winding GIC
        if isfield(GIC, 'Trans') && ~isempty(GIC.Trans)
            transAbs       = abs(GIC.Trans);
            [maxT, linIdx] = max(transAbs, [], 'all', 'omitnan');

            if isempty(maxT) || isnan(maxT)
                maxT = 0; maxTName = "None";
            else
                [tIdx, wIdx] = ind2sub(size(transAbs), linIdx);
                if isfield(app.T(tIdx), 'Name')
                    maxTName = string(app.T(tIdx).Name) + " (W" + wIdx + ")";
                else
                    maxTName = "Transformer " + tIdx + " (W" + wIdx + ")";
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