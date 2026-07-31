function results = mitigateOnOrder(app, idx_sorted)
% Run mitigations in provided order (lines and transformers). Accepts:
% - numeric vector of line indices (legacy)
% - struct with fields .order (indices) and .type ("Line"/"Trans") for combo
%
% Mitigation for lines uses type 'line'.
% Mitigation for transformers uses type 'winding' and blocks W1 (HV) for the
% matching transformer index.

if nargin < 2
    error('Requires app and idx_sorted');
end

% Normalize idx_sorted and type
if isstruct(idx_sorted) && isfield(idx_sorted,'order') && isfield(idx_sorted,'type')
    idx_order = idx_sorted.order(:);
    Type = string(idx_sorted.type(:));
    if numel(Type) ~= numel(idx_order)
        error('idx_sorted.order and idx_sorted.type must be same length');
    end
else
    % legacy: all entries are lines
    idx_order = idx_sorted(:);
    Type = repmat("Line", numel(idx_order), 1);
end

nL = numel(app.L);
nT = numel(app.T);

% Track opens / blocked windings
lineOpen = false(nL,1);
transOpen = false(nT,1);         % marker if transformer had mitigation applied
windingBlocked = false(nT,2);    % [trans, winding]

% Baseline simulation
app.gic_originalS=[]; app.gic_originalL=[]; app.gic_originalT=[];
[~, ~, ~, GICbase] = runGIC_now(app);
GICbase.Subs  = GICbase.Original_Subs;
GICbase.Lines = GICbase.Original_Lines;
GICbase.Trans = GICbase.Original_Trans;
[sumN0, maxTN0, maxTName0, maxLN0, maxLName0] = extractMetrics(app, GICbase);

% Prepare storage
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

% Main loop: stop if all processed OR last max transformer < 15 A OR sumSubs < 50
nCand = numel(idx_order);
for k = 1:nCand
    if maxTrans(end) < 5 || sumSubs(end) < 50
        try
            app.StatusTextArea.Value = [app.StatusTextArea.Value; "Stopping: max transformer GIC < 15 A or sumSubs < 50"];
            app.StatusTextArea.scroll('bottom');
            drawnow limitrate;
        catch
        end
        break;
    end

    curIdx = idx_order(k);
    curType = Type(k);

    switch lower(curType)
        case "line"
            if curIdx < 1 || curIdx > nL
                description = sprintf('Skipping invalid line index %d', curIdx);
            else
                [app, lineOpen, ~, description] = ...
                    applyMitigationToNetwork(app, 'line', curIdx, lineOpen, windingBlocked);
            end

        case "trans"
            if curIdx < 1 || curIdx > nT
                description = sprintf('Skipping invalid trans index %d', curIdx);
            else
                hv = string(app.T(curIdx).HV_Type);
                if contains(lower(hv), 'wye') % wye-wye, %wye-delta
                    widx = [curIdx, 1];
                elseif contains(lower(hv), 'auto')
                    widx = [curIdx, 2];
                end
                [app, lineOpen, windingBlocked, description] = ...
                    applyMitigationToNetwork(app, 'winding', widx, lineOpen, windingBlocked);
                transOpen(curIdx) = true;
            end

        otherwise
            description = sprintf('Unknown type "%s" for index %d - skipped', curType, curIdx);
    end

    % re-run sim and extract metrics
    [~, ~, ~, GIC_current] = runGIC_now(app);
    [sumN, maxTN, maxTNameN, maxLN, maxLNameN] = extractMetrics(app, GIC_current);

    % store step results
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
results.idx_sorted      = struct('order', idx_order(:), 'type', Type(:));
results.lineOpen        = lineOpen;
results.transOpen       = transOpen;
results.windingBlocked  = windingBlocked;

% restore original network objects
app.L = app.OriginalL;
app.T = app.OriginalT;
end

%% Helper: simplified metrics extractor (unchanged)
function [sumVal, maxT, maxTName, maxL, maxLName] = extractMetrics(app, GIC)
    if isfield(GIC, 'Subs') && ~isempty(GIC.Subs)
        subsAbs = abs(GIC.Subs);
        totPerT = sum(subsAbs, 1, 'omitnan');
        sumVal  = max(totPerT, [], 'omitnan');
        if isempty(sumVal) || isnan(sumVal), sumVal = 0; end
    else
        sumVal = 0;
    end

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
