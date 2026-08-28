function results = runGreedyGICMitigation(app, GICbase, modeStr)
% RUNGREEDYGICMITIGATION
% Sequentially mitigates the highest-GIC eligible line or transformer
% winding, reruns the GIC simulation after each change, and records the
% resulting GIC metrics in app.MitigationResults.
% Errors are reported using appendStatus(app,message).

%% INITIALIZE
results = struct();

try
    %% PREPARE BASELINE DATA
    GICbase.Subs  = GICbase.Original_Subs;
    GICbase.Lines = GICbase.Original_Lines;
    GICbase.Trans = GICbase.Original_Trans;

    modeStr = lower(strtrim(string(modeStr)));

    %% DECODE MITIGATION MODE
    switch modeStr
        case "original"
            activeLineMitigation = true;
            activeWindingMitigation = true;
            lineMode = "allLines";
            windingMode = "all";

        case "windings_only"
            activeLineMitigation = false;
            activeWindingMitigation = true;
            lineMode = "";
            windingMode = "all";

        case "all_lines"
            activeLineMitigation = true;
            activeWindingMitigation = false;
            lineMode = "allLines";
            windingMode = "";

        case "parallel_lines"
            activeLineMitigation = true;
            activeWindingMitigation = false;
            lineMode = "parallel";
            windingMode = "";

        case "hv_lines"
            activeLineMitigation = true;
            activeWindingMitigation = false;
            lineMode = "hv_line";
            windingMode = "";

        otherwise
            error("Invalid mitigation mode: %s", modeStr);
    end

    %% NETWORK SIZE
    nLines = numel(app.L);
    nTrans = numel(app.T);

    %% BUILD LINE CANDIDATES
    parallelGroups = {};
    lineToGroup = zeros(nLines,1);
    groupAliveCount = [];
    lineEligible = false(nLines,1);

    if lineMode == "parallel"
        parallelGroups = buildParallelGroups(app.L);
        groupAliveCount = zeros(numel(parallelGroups),1);

        for g = 1:numel(parallelGroups)
            idx = parallelGroups{g};
            lineToGroup(idx) = g;
            groupAliveCount(g) = numel(idx);

            if groupAliveCount(g) >= 2
                lineEligible(idx) = true;
            end
        end

    elseif lineMode == "hv_line"
        voltages = [app.L.Voltage];
        lineEligible = voltages(:) >= 400;

    elseif lineMode == "allLines"
        lineEligible(:) = true;
    end

    %% BUILD TRANSFORMER INFORMATION
    isAuto = false(nTrans,1);

    for k = 1:nTrans
        t = app.T(k);

        isAuto(k) = ...
            (isfield(t,'HV_Type') && strcmpi(t.HV_Type,'auto')) || ...
            (isfield(t,'LV_Type') && strcmpi(t.LV_Type,'auto'));
    end

    windingIsWye = getWyeGroundedWindings(app.T);   % nTrans×2 logical
    oneWye  = windingIsWye(:,1) & ~windingIsWye(:,2); % only first
    bothWye = windingIsWye(:,1) & windingIsWye(:,2);  % both
    
    % BUILD WINDING CANDIDATES
    windingCandMask = false(nTrans,2);
    
    if activeWindingMitigation
        switch windingMode
            case "autoW2"
                windingCandMask(isAuto,2) = true;
            case "wye"
                windingCandMask(oneWye,1) = true;
                windingCandMask(bothWye,:) = true;  
            case "all"
                windingCandMask(oneWye,1) = true;
                windingCandMask(bothWye,:) = true;  
                windingCandMask(isAuto,2) = true;
        end
    end


    %% STATE TRACKERS
    lineOpen = false(nLines,1);
    windingBlocked = false(nTrans,2);

    %% RESULT STORAGE
    allocSize = nLines + 2*nTrans + 1;

    sumGICSubs = zeros(allocSize,1);
    maxTransGIC = zeros(allocSize,1);
    maxLinesGIC = zeros(allocSize,1);
    maxTransName = strings(allocSize,1);
    maxLineName = strings(allocSize,1);
    mitigations = cell(allocSize,1);

    %% RESET APP RESULT TABLE
    app.MitigationResults = app.MitigationResults([], :);
    app.SpreadsheetTable.Data = app.MitigationResults;

    %% BASELINE METRICS
    [sum0, maxT0, maxTName0, maxL0, maxLName0] = extractMetrics(GICbase,app);

    sumGICSubs(1) = sum0;
    maxTransGIC(1) = maxT0;
    maxLinesGIC(1) = maxL0;
    maxTransName(1) = maxTName0;
    maxLineName(1) = maxLName0;
    mitigations{1} = "Baseline";

    %% ADD BASELINE TO TABLE
    newRow = table("0","Baseline",sum0,maxT0,string(maxTName0),maxL0,string(maxLName0), ...
        'VariableNames', {'Count','Mitigation','SumGICSubs','MaxTransGIC', ...
        'MaxTransName','MaxLinesGIC','MaxLineName'});

    app.MitigationResults = [app.MitigationResults; newRow];
    app.SpreadsheetTable.Data = app.MitigationResults;

    message = sprintf(['Baseline -> Total GIC: %.2f | Max Transformer: %.2f [%s] | ' ...
        'Max Line: %.2f [%s]'], sum0,maxT0,maxTName0,maxL0,maxLName0);
    appendStatus(app,message);

    %% MAIN GREEDY LOOP
    GIC_current = GICbase;
    step = 1;

    while true
        %% BUILD LINE CANDIDATES
        if activeLineMitigation
            candLines = find(lineEligible & ~lineOpen);
        else
            candLines = [];
        end

        %% BUILD WINDING CANDIDATES
        if activeWindingMitigation
            [tr,wd] = find(windingCandMask & ~windingBlocked);
            candWind = [tr,wd];
        else
            candWind = [];
        end

        %% CHECK STOP CONDITIONS
        currentTotalGIC = sumGICSubs(step);
        noMoreMitigation = isempty(candLines) && isempty(candWind);
        gicBelowThreshold = currentTotalGIC <= 50;

        if noMoreMitigation
            appendStatus(app,"Stopping: No further mitigation candidates available.");
            break;
        end

        if gicBelowThreshold
            message = sprintf("Stopping: Total GIC reached %.2f A.",currentTotalGIC);
            appendStatus(app,message);
            break;
        end

        %% SELECT WORST CANDIDATE
        [type,idx,val] = selectWorstGICElement(GIC_current,candLines,candWind);

        if isempty(type) || isempty(val) || isnan(val)
            appendStatus(app,"Stopping: No valid mitigation candidate found.");
            break;
        end

        %% APPLY MITIGATION
        [app,lineOpen,windingBlocked,description] = ...
            applyMitigationToNetwork(app,type,idx,lineOpen,windingBlocked);

        %% UPDATE CANDIDATE STATE
        if strcmp(type,'line')
            lineOpen(idx) = true;

            if lineMode == "parallel" && lineToGroup(idx) > 0
                g = lineToGroup(idx);
                groupAliveCount(g) = groupAliveCount(g) - 1;

                if groupAliveCount(g) < 2
                    lineEligible(parallelGroups{g}) = false;
                end
            end

        elseif strcmp(type,'winding')
            windingBlocked(idx(1),idx(2)) = true;
            windingCandMask(idx(1),idx(2)) = false;
        end

        %% RUN UPDATED GIC SIMULATION
        [~,~,~,GIC_current] = runGIC_now(app);

        %% EXTRACT NEW METRICS
        [sumN,maxTN,maxTNameN,maxLN,maxLNameN] = extractMetrics(GIC_current,app);

        %% STORE RESULTS
        rowIdx = step + 1;

        sumGICSubs(rowIdx) = sumN;
        maxTransGIC(rowIdx) = maxTN;
        maxLinesGIC(rowIdx) = maxLN;
        maxTransName(rowIdx) = maxTNameN;
        maxLineName(rowIdx) = maxLNameN;
        mitigations{rowIdx} = char(description);

        %% ADD RESULT TO APP TABLE
        newRow = table(string(step),string(description),sumN,maxTN,string(maxTNameN), ...
            maxLN,string(maxLNameN), ...
            'VariableNames', {'Count','Mitigation','SumGICSubs','MaxTransGIC', ...
            'MaxTransName','MaxLinesGIC','MaxLineName'});

        app.MitigationResults = [app.MitigationResults; newRow];
        app.SpreadsheetTable.Data = app.MitigationResults;

        %% REPORT STEP
        message = sprintf(['Step %d: %s | Total GIC: %.2f | Max Transformer: %.2f [%s] | ' ...
            'Max Line: %.2f [%s]'], step,string(description),sumN,maxTN,maxTNameN,maxLN,maxLNameN);
        appendStatus(app,message);

        step = step + 1;
    end

    %% TRIM RESULTS
    sumGICSubs = sumGICSubs(1:step);
    maxTransGIC = maxTransGIC(1:step);
    maxLinesGIC = maxLinesGIC(1:step);
    maxTransName = maxTransName(1:step);
    maxLineName = maxLineName(1:step);
    mitigations = mitigations(1:step);

    %% PACKAGE OUTPUT
    results.sumGICSubs = sumGICSubs;
    results.maxTransGIC = maxTransGIC;
    results.maxLinesGIC = maxLinesGIC;
    results.maxTransName = maxTransName;
    results.maxLineName = maxLineName;
    results.mitigations = mitigations;
    results.lineOpen = lineOpen;
    results.windingBlocked = windingBlocked;
    results.parallelGroups = parallelGroups;
    results.modeStr = modeStr;
    results.errorOccurred = false;

    appendStatus(app,sprintf("Greedy mitigation completed after %d steps.",step-1));

catch ME
    %% REPORT ERROR
    % Replace StatusLamp with the actual name of your app LED if different.
    app.StatusLamp.Color = 'red';

    if ~isempty(ME.stack)
        message = sprintf("Greedy mitigation error:\n%s\nFunction: %s | Line: %d", ...
            ME.message,ME.stack(1).name,ME.stack(1).line);
    else
        message = sprintf("Greedy mitigation error:\n%s",ME.message);
    end

    appendStatus(app,message);

    results.errorOccurred = true;
    results.errorMessage = string(ME.message);
end
end

function [sumVal,maxT,maxTName,maxL,maxLName] = extractMetrics(GIC,app)
        % Calculates total substation GIC and maximum transformer/line GIC.

        %% SUBSTATION GIC
        subsAbs = abs(GIC.Subs);
        totalPerTime = sum(subsAbs,1,'omitnan');
        sumVal = max(totalPerTime,[],'omitnan');

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