function mitigateOnOrder(app, idx_sorted)
% Run mitigations in the provided order until all entries processed or
% max transformer GIC < 5 A. Return per-step mitigation description,
% total substation sum, max line value+name, max transformer value+name, and plot.
%
% idx_sorted: numeric vector of line indices into app.L in the exact order
%             to apply mitigations (e.g. [12,5,3,20]). Duplicates allowed.

if nargin < 2
    error('Requires app and idx_sorted');
end
idx_sorted = idx_sorted(:);

% Ensure masks exist or create defaults
if isprop(app, 'lineOpen')
    lineOpen = app.lineOpen;
else
    lineOpen = false(1, max(idx_sorted));
end

% Baseline simulation
app.gic_originalS=[]; app.gic_originalL=[]; app.gic_originalT=[];
[~, ~, ~, GICbase] = runGIC_now(app);
GICbase.Subs  = GICbase.Original_Subs;
GICbase.Lines = GICbase.Original_Lines;
GICbase.Trans = GICbase.Original_Trans;
[sumN0, maxTN0, maxTName0, maxLN0, maxLName0] = extractMetrics(app, GICbase);

% Prepare storage (only requested)
mitSteps      = {}; % description per step (including "Baseline")
sumSubs       = [];
maxTrans      = [];
maxTransName  = {};
maxLine       = [];
maxLineName   = {};

% store baseline
mitSteps{end+1}     = "Baseline";
sumSubs(end+1)      = sumN0;
maxTrans(end+1)     = maxTN0;
maxTransName{end+1} = maxTName0;
maxLine(end+1)      = maxLN0;
maxLineName{end+1}  = maxLName0;

% UI log start
try
    app.StatusTextArea.Value = [app.StatusTextArea.Value; "Starting ordered mitigation run"];
    app.StatusTextArea.scroll('bottom');
    drawnow limitrate;
catch
end

% Main loop: stop if all processed OR last max transformer < 5 A
nCand = numel(idx_sorted);
for k = 1:nCand
    if maxTrans(end) < 10 || sumSubs(end) < 50
        try
            app.StatusTextArea.Value = [app.StatusTextArea.Value; "Stopping: max transformer GIC < 5 A"];
            app.StatusTextArea.scroll('bottom');
            drawnow limitrate;
        catch
        end
        break;
    end

    lineIdx = idx_sorted(k);

    % apply mitigation (no winding/blocking arguments)
    try
        [app, lineOpen,~, description] = ...
            applyMitigationToNetwork(app, 'line', lineIdx, lineOpen,0);
    catch ME
        try
            msg = sprintf('Error applying mitigation to line %d: %s', lineIdx, ME.message);
            app.StatusTextArea.Value = [app.StatusTextArea.Value; msg];
            app.StatusTextArea.scroll('bottom');
            drawnow limitrate;
        catch
        end
        break;
    end
    
    % mark line open locally if in bounds
    if lineIdx <= numel(lineOpen)
        lineOpen(lineIdx) = true;
    end

    % re-run sim and extract metrics
    [~, ~, ~, GIC_current] = runGIC_now(app);
    [sumN, maxTN, maxTNameN, maxLN, maxLNameN] = extractMetrics(app, GIC_current);

    % store only requested outputs
    mitSteps{end+1}     = string(description);
    sumSubs(end+1)      = sumN;
    maxTrans(end+1)     = maxTN;
    maxTransName{end+1} = maxTNameN;
    maxLine(end+1)      = maxLN;
    maxLineName{end+1}  = maxLNameN;

    % UI log per step
    try
        stepMsg = sprintf('Applied: %s | TotalSubSum=%.2f | MaxTrans=%.2f [%s] | MaxLine=%.2f [%s]', ...
            char(description), sumN, maxTN, char(maxTNameN), maxLN, char(maxLNameN));
        app.StatusTextArea.Value = [app.StatusTextArea.Value; string(description); stepMsg];
        app.StatusTextArea.scroll('bottom');
        drawnow limitrate;
    catch
    end

end

% Package minimal results
results.mitigationSteps = mitSteps(:);
results.sumGICSubs      = sumSubs(:);
results.maxTransGIC     = maxTrans(:);
results.maxTransName    = maxTransName(:);
results.maxLinesGIC     = maxLine(:);
results.maxLineName     = maxLineName(:);
results.idx_sorted      = idx_sorted(:);
results.lineOpen        = lineOpen;

% Save results with title "mass mitigation" and timestamp
timestamp = datestr(now,'yyyy-mm-dd_HH-MM-SS');
fname = sprintf('mass_mitigation_%s.mat', timestamp);
save(fname, 'results');
try
    app.StatusTextArea.Value = [app.StatusTextArea.Value; ...
        sprintf('Results saved: %s', fname)];
    app.StatusTextArea.scroll('bottom');
    drawnow limitrate;
catch
end
plotGICMitigationResults(results)
end

%% Helper: simplified metrics extractor (no winding detail)
function [sumVal, maxT, maxTName, maxL, maxLName] = extractMetrics(app, GIC)
    % Total substation GIC: sum absolute per time then max across time
    if isfield(GIC, 'Subs') && ~isempty(GIC.Subs)
        subsAbs = abs(GIC.Subs);
        totPerT = sum(subsAbs, 1, 'omitnan'); % sum across substations -> time series
        sumVal  = max(totPerT, [], 'omitnan');
        if isempty(sumVal) || isnan(sumVal), sumVal = 0; end
    else
        sumVal = 0;
    end

    % Max transformer
    if isfield(GIC, 'Trans') && ~isempty(GIC.Trans)
        trAbs = abs(GIC.Trans);
        [maxT, linIdx] = max(trAbs(:), [], 'omitnan');
        if isempty(maxT) || isnan(maxT)
            maxT = 0; maxTName = "None";
        else
            idx = linIdx;
            if isfield(app, 'T') && numel(app.T) >= idx && isfield(app.T(idx), 'Name')
                maxTName = string(app.T(idx).Name);
            else
                maxTName = "Transformer " + string(idx);
            end
        end
    else
        maxT = 0; maxTName = "None";
    end

    % Max line
    if isfield(GIC, 'Lines') && ~isempty(GIC.Lines)
        lnAbs = abs(GIC.Lines);
        [maxL, linIdxL] = max(lnAbs(:), [], 'omitnan');
        if isempty(maxL) || isnan(maxL)
            maxL = 0; maxLName = "None";
        else
            idxL = linIdxL;
            if isfield(app, 'L') && numel(app.L) >= idxL && isfield(app.L(idxL), 'Name')
                maxLName = string(app.L(idxL).Name);
            else
                maxLName = "Line " + string(idxL);
            end
        end
    else
        maxL = 0; maxLName = "None";
    end
end