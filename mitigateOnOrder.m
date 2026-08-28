function results = mitigateOnOrder(app, idx_sorted)
% MITIGATEONORDER
% Applies line and transformer mitigations in a supplied order, reruns the
% GIC simulation after each change, and records each result in the shared
% app.MitigationResults table.
% Errors are reported using appendStatus(app,message).

%% INITIALIZE
results = struct();

try
    %% VALIDATE INPUT
    if nargin < 2
        error('Requires app and idx_sorted.');
    end

    %% NORMALIZE MITIGATION ORDER
    if isstruct(idx_sorted) && isfield(idx_sorted,'order') && isfield(idx_sorted,'type')
        idx_order = idx_sorted.order(:);
        Type = string(idx_sorted.type(:));

        if numel(Type) ~= numel(idx_order)
            error('idx_sorted.order and idx_sorted.type must have the same length.');
        end
    else
        % Legacy format: numeric indices are treated as lines
        idx_order = idx_sorted(:);
        Type = repmat("Line",numel(idx_order),1);
    end

    nL = numel(app.L);
    nT = numel(app.T);

    %% STATE TRACKERS
    lineOpen = false(nL,1);
    transOpen = false(nT,1);
    windingBlocked = false(nT,2);

    %% RUN BASELINE SIMULATION
    app.gic_originalS = [];
    app.gic_originalL = [];
    app.gic_originalT = [];

    [~,~,~,GICbase] = runGIC_now(app);

    GICbase.Subs  = GICbase.Original_Subs;
    GICbase.Lines = GICbase.Original_Lines;
    GICbase.Trans = GICbase.Original_Trans;

    [sum0,maxT0,maxTName0,maxL0,maxLName0] = extractMetrics(GICbase);

    %% RESULT STORAGE
    nSteps = numel(idx_order) + 1;

    mitSteps = strings(nSteps,1);
    sumSubs = zeros(nSteps,1);
    maxTrans = zeros(nSteps,1);
    maxTransName = strings(nSteps,1);
    maxLine = zeros(nSteps,1);
    maxLineName = strings(nSteps,1);

    %% RESET APP RESULT TABLE
    app.MitigationResults = app.MitigationResults([], :);
    app.SpreadsheetTable.Data = app.MitigationResults;

    %% STORE BASELINE
    mitSteps(1) = "Baseline";
    sumSubs(1) = sum0;
    maxTrans(1) = maxT0;
    maxTransName(1) = maxTName0;
    maxLine(1) = maxL0;
    maxLineName(1) = maxLName0;

    %% ADD BASELINE TO TABLE
    newRow = table("0","Baseline",sum0,maxT0,string(maxTName0),maxL0,string(maxLName0), ...
        'VariableNames', {'Count','Mitigation','SumGICSubs','MaxTransGIC', ...
        'MaxTransName','MaxLinesGIC','MaxLineName'});

    app.MitigationResults = [app.MitigationResults; newRow];
    app.SpreadsheetTable.Data = app.MitigationResults;

    appendStatus(app,sprintf(['Starting ordered mitigation run | Baseline Total GIC: %.2f | ' ...
        'Max Transformer: %.2f [%s] | Max Line: %.2f [%s]'], ...
        sum0,maxT0,maxTName0,maxL0,maxLName0));

    %% MAIN ORDERED MITIGATION LOOP
    completedSteps = 0;

    for k = 1:numel(idx_order)
        curIdx = idx_order(k);
        curType = lower(strtrim(Type(k)));

        %% APPLY REQUESTED MITIGATION
        switch curType
            case "line"
                if curIdx < 1 || curIdx > nL
                    description = sprintf('Skipped invalid line index %d',curIdx);
                else
                    [app,lineOpen,windingBlocked,description] = ...
                        applyMitigationToNetwork(app,'line',curIdx,lineOpen,windingBlocked);
                end

            case {"trans","transformer"}
                if curIdx < 1 || curIdx > nT
                    description = sprintf('Skipped invalid transformer index %d',curIdx);
                else
                    hvType = string(app.T(curIdx).HV_Type);

                    if contains(lower(hvType),'auto')
                        widx = [curIdx,2];
                    elseif contains(lower(hvType),'wye')
                        widx = [curIdx,1];
                    else
                        description = sprintf('Skipped transformer %d: no eligible grounded winding',curIdx);
                        widx = [];
                    end

                    if ~isempty(widx)
                        [app,lineOpen,windingBlocked,description] = ...
                            applyMitigationToNetwork(app,'winding',widx,lineOpen,windingBlocked);
                        transOpen(curIdx) = true;
                    end
                end

            otherwise
                description = sprintf('Skipped unknown type "%s" at index %d',curType,curIdx);
        end

        %% RERUN GIC SIMULATION
        [~,~,~,GIC_current] = runGIC_now(app);

        %% EXTRACT UPDATED METRICS
        [sumN,maxTN,maxTNameN,maxLN,maxLNameN] = extractMetrics(GIC_current);

        rowIdx = k + 1;
        completedSteps = k;

        %% STORE RESULTS
        mitSteps(rowIdx) = string(description);
        sumSubs(rowIdx) = sumN;
        maxTrans(rowIdx) = maxTN;
        maxTransName(rowIdx) = maxTNameN;
        maxLine(rowIdx) = maxLN;
        maxLineName(rowIdx) = maxLNameN;

        %% ADD RESULT TO APP TABLE
        newRow = table(string(k),string(description),sumN,maxTN,string(maxTNameN), ...
            maxLN,string(maxLNameN), ...
            'VariableNames', {'Count','Mitigation','SumGICSubs','MaxTransGIC', ...
            'MaxTransName','MaxLinesGIC','MaxLineName'});

        app.MitigationResults = [app.MitigationResults; newRow];
        app.SpreadsheetTable.Data = app.MitigationResults;

        %% REPORT STEP
        message = sprintf(['Step %d: %s | Total GIC: %.2f | Max Transformer: %.2f [%s] | ' ...
            'Max Line: %.2f [%s]'], ...
            k,string(description),sumN,maxTN,maxTNameN,maxLN,maxLNameN);

        appendStatus(app,message);
    end

    %% TRIM RESULTS
    lastIdx = completedSteps + 1;

    mitSteps = mitSteps(1:lastIdx);
    sumSubs = sumSubs(1:lastIdx);
    maxTrans = maxTrans(1:lastIdx);
    maxTransName = maxTransName(1:lastIdx);
    maxLine = maxLine(1:lastIdx);
    maxLineName = maxLineName(1:lastIdx);

    %% PACKAGE OUTPUT
    results.mitigationSteps = mitSteps;
    results.sumGICSubs = sumSubs;
    results.maxTransGIC = maxTrans;
    results.maxTransName = maxTransName;
    results.maxLinesGIC = maxLine;
    results.maxLineName = maxLineName;
    results.idx_sorted = struct('order',idx_order,'type',Type);
    results.lineOpen = lineOpen;
    results.transOpen = transOpen;
    results.windingBlocked = windingBlocked;
    results.errorOccurred = false;

    appendStatus(app,sprintf('Ordered mitigation completed after %d steps.',completedSteps));

catch ME
    %% REPORT ERROR
    app.StatusLamp.Color = 'red';

    if ~isempty(ME.stack)
        message = sprintf("Ordered mitigation error:\n%s\nFunction: %s | Line: %d", ...
            ME.message,ME.stack(1).name,ME.stack(1).line);
    else
        message = sprintf("Ordered mitigation error:\n%s",ME.message);
    end

    appendStatus(app,message);

    results.errorOccurred = true;
    results.errorMessage = string(ME.message);
end


%% EXTRACT GIC METRICS
    function [sumVal,maxT,maxTName,maxL,maxLName] = extractMetrics(GIC)
        % Calculates total substation GIC and maximum transformer/line GIC.

        %% SUBSTATION GIC
        if isfield(GIC,'Subs') && ~isempty(GIC.Subs)
            totalPerTime = sum(abs(GIC.Subs),1,'omitnan');
            sumVal = max(totalPerTime,[],'omitnan');

            if isempty(sumVal) || isnan(sumVal)
                sumVal = 0;
            end
        else
            sumVal = 0;
        end

        %% TRANSFORMER GIC
        if isfield(GIC,'Trans') && ~isempty(GIC.Trans)
            transAbs = max(abs(GIC.Trans),[],2);
            transAbs = reshape(transAbs,size(GIC.Trans,1),[]);

            [maxT,linIdx] = max(transAbs,[],'all','omitnan');

            if isempty(maxT) || isnan(maxT)
                maxT = 0;
                maxTName = "None";
            else
                [tIdx,~] = ind2sub(size(transAbs),linIdx);

                if isfield(app.T(tIdx),'Name')
                    maxTName = string(app.T(tIdx).Name);
                else
                    maxTName = "Transformer " + tIdx;
                end
            end
        else
            maxT = 0;
            maxTName = "None";
        end

        %% LINE GIC
        if isfield(GIC,'Lines') && ~isempty(GIC.Lines)
            linesAbs = abs(GIC.Lines);
            [maxL,linIdx] = max(linesAbs,[],'all','omitnan');

            if isempty(maxL) || isnan(maxL)
                maxL = 0;
                maxLName = "None";
            else
                [lIdx,~] = ind2sub(size(linesAbs),linIdx);

                if isfield(app.L(lIdx),'Name')
                    maxLName = string(app.L(lIdx).Name);
                else
                    maxLName = "Line " + lIdx;
                end
            end
        else
            maxL = 0;
            maxLName = "None";
        end
    end
end