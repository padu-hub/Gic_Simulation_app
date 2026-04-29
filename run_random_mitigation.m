function results = run_random_mitigation(app, ...
    useHighVoltageLines, ...
    useParallelLines, ...
    useNeutralBlockers, ...
    useAllLines, ...
    nSim, ...
    minMit, ...
    maxMit, ...
    resultType, ...
    target)

    %% -------------------- PRE-COMPUTATION & CACHING --------------------
    L0 = app.L;
    T0 = app.T;
    nLines = numel(L0);
    nTrans = numel(T0);

    % Cache field names to avoid isfield() calls in the loop
    hasRes = isfield(L0, 'Resistance');
    hasResKm = isfield(L0, 'ResKm');
    
    % Pre-build Parallel Group Map for O(1) lookup
    lineGroupMap = zeros(nLines, 1);
    if useParallelLines
        parallelGroups = buildParallelGroups(L0);
        for g = 1:numel(parallelGroups)
            lineGroupMap(parallelGroups{g}) = g;
        end
    else
        parallelGroups = {};
    end

    % Detect equipment types (Vectorized)
    isAuto = arrayfun(@(t) (isfield(t,'HV_Type') && strcmpi(t.HV_Type,'auto')) || ...
                           (isfield(t,'LV_Type') && strcmpi(t.LV_Type,'auto')), T0);
    windingIsWye = getWyeGroundedWindings(T0);
    bothWye = windingIsWye(:,1) & windingIsWye(:,2);

    % Pre-build HV Mask
    hvMask = false(nLines, 1);
    for i = 1:nLines
        if isfield(L0(i),'Voltage') && ~isempty(L0(i).Voltage) && isfinite(L0(i).Voltage)
            hvMask(i) = L0(i).Voltage >= 500;
        end
    end

    %% -------------------- BUILD POOLS --------------------
    linePool = [];
    if useAllLines, linePool = (1:nLines)'; end
    if useHighVoltageLines, linePool = unique([linePool; find(hvMask)]); end
    if useParallelLines
        for g = 1:numel(parallelGroups)
            if numel(parallelGroups{g}) >= 2
                linePool = unique([linePool; parallelGroups{g}(:)]);
            end
        end
    end

    transPool = [];
    if useNeutralBlockers
        idxBoth = find(bothWye);
        transPool = [idxBoth, ones(size(idxBoth)); idxBoth, 2*ones(size(idxBoth))];
        idxAuto = find(isAuto);
        transPool = unique([transPool; idxAuto, 2*ones(size(idxAuto))], 'rows');
    end

    % Combined mitigation block (numeric indices for speed)
    % Column 1: Type (1 for Line, 2 for Trans), Column 2: Index, Column 3: Winding
    mitBlock = [ones(numel(linePool), 1), linePool, zeros(numel(linePool), 1);
                2*ones(size(transPool,1), 1), transPool];

    if isempty(mitBlock), error('No eligible mitigation candidates found.'); end

    %% -------------------- PREALLOCATE --------------------
    lineState = true(nSim, nLines);
    transState = false(nSim, nTrans, 2);
    chosenMitIndices = cell(nSim, 1); % Store indices, format strings later
    metricValue = nan(nSim, 1);
    label = false(nSim, 1);
    maxTransName = strings(nSim, 1);
    maxLineName = strings(nSim, 1);

    tic
    %% -------------------- MAIN SIMULATION LOOP --------------------
    for simIdx = 1:nSim
        tic
        % Reset network
        app.L = L0;
        app.T = T0;
        
        lineOpen = false(nLines, 1);
        windingBlocked = false(nTrans, 2);

        nThisMit = min(randi([minMit maxMit]), size(mitBlock, 1));
        pickIdx = randperm(size(mitBlock, 1), nThisMit);
        
        appliedList = [];

        for p = 1:nThisMit
            mType = mitBlock(pickIdx(p), 1);
            mIdx  = mitBlock(pickIdx(p), 2);

            if mType == 1 % LINE
                if lineOpen(mIdx), continue; end
                
                % Parallel Check
                gID = lineGroupMap(mIdx);
                if gID > 0
                    grp = parallelGroups{gID};
                    if sum(~lineOpen(grp)) <= 1, continue; end
                end

                lineOpen(mIdx) = true;
                if hasRes, app.L(mIdx).Resistance = NaN; end
                if hasResKm, app.L(mIdx).ResKm = NaN; end
                appliedList = [appliedList; pickIdx(p)]; 

            else % TRANSFORMER
                wIdx = mitBlock(pickIdx(p), 3);
                if windingBlocked(mIdx, wIdx), continue; end
                
                windingBlocked(mIdx, wIdx) = true;
                app.T(mIdx).(sprintf('blocker_w%d', wIdx)) = true;
                appliedList = [appliedList; pickIdx(p)]; 
            end
        end

        
        [~, ~, ~, GIC_current] = runGIC_now(app);

        %% -------------------- METRICS --------------------
        switch lower(strtrim(resultType))
            case 'max trans gic'
                transAbs = abs(GIC_current.Trans);
                [val, linIdx] = max(transAbs, [], 'all', 'omitnan');
                metricValue(simIdx) = val;
                if ~isnan(val)
                    [trM, wM] = ind2sub(size(transAbs), linIdx);
                    maxTransName(simIdx) = sprintf('%s (W%d)', string(app.T(trM).Name), wM);
                end
            case 'change in total gic'
                totalNow = max(sum(abs(GIC_current.Subs), 1, 'omitnan'), [], 'omitnan');
                totalBase = max(sum(abs(GIC_current.Original_Subs), 1, 'omitnan'), [], 'omitnan');
                metricValue(simIdx) = totalBase - totalNow;
        end

        label(simIdx) = metricValue(simIdx) <= target;
        lineState(simIdx, :) = ~lineOpen;
        transState(simIdx, :, :) = windingBlocked;
        chosenMitIndices{simIdx} = appliedList;
        
        elapsed = toc;
        fprintf('Sim %d/%d, time: %.3f s\n', simIdx, nSim, elapsed);
        
    end

    %% -------------------- POST-PROCESSING --------------------
    % Move string building out of the performance-critical loop
    results = struct();
    results.chosenMitigations = cell(nSim, 1);
    for s = 1:nSim
        indices = chosenMitIndices{s};
        logs = strings(numel(indices), 1);
        for i = 1:numel(indices)
            row = mitBlock(indices(i), :);
            if row(1) == 1
                logs(i) = "Line OFF: " + string(L0(row(2)).Name);
            else
                logs(i) = sprintf("Blocker ON: %s W%d", string(T0(row(2)).Name), row(3));
            end
        end
        results.chosenMitigations{s} = cellstr(logs);
    end

%% -------- BUILD ML-READY TABLE --------
    % Only include candidate lines and transformers to keep the table compact.
    
    % X_lines: 1 = Line was OPEN (mitigation active), 0 = Line was CLOSED (normal)
    X_lines = double(~lineState(:, linePool));
    
    % X_trans: 1 = Blocker was ON, 0 = Blocker was OFF
    nTransCand = size(transPool, 1);
    X_trans = zeros(nSim, nTransCand);
    for j = 1:nTransCand
        trIdx = transPool(j,1);
        wIdx  = transPool(j,2);
        X_trans(:,j) = double(transState(:, trIdx, wIdx));
    end
    
    % Combine into feature matrix [Lines | Transformers]
    X = [X_lines, X_trans];
    
    %% -------- DYNAMIC VARIABLE NAMING --------
    % Generate valid, unique headers for CSV/Table columns
    
    lineNames = strings(1, numel(linePool));
    for i = 1:numel(linePool)
        idx = linePool(i);
        name = "Line_" + idx;
        if isfield(L0(idx), 'Name') && ~isempty(L0(idx).Name)
            name = string(L0(idx).Name);
        end
        lineNames(i) = matlab.lang.makeValidName(name);
    end
    
    transNames = strings(1, nTransCand);
    for j = 1:nTransCand
        trIdx = transPool(j,1);
        wIdx  = transPool(j,2);
        name = "Trans_" + trIdx;
        if isfield(T0(trIdx), 'Name') && ~isempty(T0(trIdx).Name)
            name = string(T0(trIdx).Name);
        end
        transNames(j) = matlab.lang.makeValidName(name + "_W" + wIdx);
    end
    
    % Final Header Setup
    varNames = [lineNames, transNames, "Metric", "Label"];
    varNames = matlab.lang.makeUniqueStrings(varNames);

    
    %% -------- PACKAGING & STORAGE --------
    % Add metrics and labels to the structure for the .mat file
    results.lineState = lineState;
    results.transState = transState;
    results.metricValue = metricValue;
    results.label = label;
    results.maxTransName = maxTransName;
    results.maxLineName = maxLineName;

    % Build the final Table
    results.MLTable = array2table([X, metricValue, double(label)], ...
        'VariableNames', cellstr(varNames));
    
    % Export with Timestamp
    ts = datestr(now, 'yyyymmdd_HHMMSS');
    matName = "gic_results_" + ts + ".mat";
    csvName = "gic_ML_table_" + ts + ".csv";
    
    save(matName, 'results', '-v7.3');
    writetable(results.MLTable, csvName);
    
    results.saveFile = char(matName);
    results.MLTableFile = char(csvName);











%%Generate random names for assignment
    
% Additionally export a CSV with randomized variable names to anonymize headers
rng('shuffle'); % non-deterministic for anonymization

% Helper to generate random numeric string of length n
randDigits = @(n) char('0' + randi([0 9], 1, n));

% Helper to generate random alphanumeric string of length n
chars = ['0':'9' 'A':'Z' 'a':'z'];
randAlphaNum = @(n) chars(randi(numel(chars), 1, n));

% Build anonymized names in same order as varNames (Lines, Trans, Metric, Label)
nLinesVars = numel(lineNames);
nTransVars = numel(transNames);

anonLineNames = strings(1, nLinesVars);
for k = 1:nLinesVars
    anonLineNames(k) = "L" + string(randDigits(3));
end

anonTransNames = strings(1, nTransVars);
for k = 1:nTransVars
    anonTransNames(k) = "xT" + string(randAlphaNum(3));
end

% Ensure Metric and Label get anonymized fixed names (but distinct)
anonMetricName = "Metric_" + string(randDigits(3));
anonLabelName  = "Label_"  + string(randDigits(3));

anonVarNames = [anonLineNames, anonTransNames, anonMetricName, anonLabelName];
anonVarNames = matlab.lang.makeUniqueStrings(anonVarNames);

% Create anonymized table and write CSV
anonTable = results.MLTable;
anonTable.Properties.VariableNames = cellstr(anonVarNames);

anonCsvName = "gic_ML_table_anon_" + ts + ".csv";
writetable(anonTable, anonCsvName);

% Record filenames in results
results.MLTableAnonFile = char(anonCsvName);
results.AnonVariableMap = struct('Original', {varNames}, 'Anon', {cellstr(anonVarNames)});
    
end