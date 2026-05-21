function results = runStormBatchHotspots(app, S, L, T)
% =========================================================================
% runStormBatchHotspots
%
% Batch-runs historical E-field events on one Alberta grid, computes:
%   - Substation max 15-min mean |GIC| per event
%   - Transformer winding-1 max 15-min mean |GIC| per event (stored only)
%
% Also generates summary plots (NOT bubble maps):
%   1) Heatmap: substations x events (max 15-min mean)
%   2) Top-N bar: persistent hotspots (median across events)
%   3) Box/whisker: distribution across storms for Top-N substations,
%   transformers and lines.
%   4) Rank-consistency: median rank across events (lower = more consistently high)
%
% Your bubble map (substation bubbles) can use:
%   results.aggregate.sub.median15  (or max15/mean15)
%   results.sub.Latitude / Longitude
%
% =========================================================================

    % ---------------------------------------------------------------------
    % Select event files
    % ---------------------------------------------------------------------
    [fileNames, pathName] = uigetfile('*.mat', ...
        'Select E-field event .mat files', 'MultiSelect', 'on');
    
    if isequal(fileNames,0)
        results = struct();
        return;
    end
    if ischar(fileNames)
        fileNames = {fileNames};
    end

    % ---------------------------------------------------------------------
    % Substation metadata 
    % ---------------------------------------------------------------------
    nSubs = numel(S);
    results.sub.Name      = string({S.Name}).';
    results.sub.Latitude  = reshape([S.Latitude],  [], 1);
    results.sub.Longitude = reshape([S.Longitude], [], 1);

    % ---------------------------------------------------------------------
    % Transformer metadata 
    % ---------------------------------------------------------------------
    nTrans = numel(T);
    if nTrans > 0
        results.trans.Name = string({T.Name}).';
    else
        results.trans.Name = strings(0,1);
    end

    % ---------------------------------------------------------------------
    % Lines metadata 
    % ---------------------------------------------------------------------
    nLines = numel(L);
    if nLines > 0 && isstruct(L) && isfield(L,'Name')
        results.line.Name = string({L.Name}).';
    else
        results.line.Name = strings(0,1);
    end

    % ---------------------------------------------------------------------
    % Pre-allocate event containers
    % ---------------------------------------------------------------------
    nEvents = numel(fileNames);
    results.events = repmat(struct(), nEvents, 1);

    subMat      = nan(nSubs,  nEvents);
    transMat_w1 = nan(nTrans, nEvents);
    transMat_w2 = nan(nTrans, nEvents);
    lineMat     = nan(nLines, nEvents);

    % ---------------------------------------------------------------------
    % Loop through all events
    % ---------------------------------------------------------------------
    for i = 1:nEvents

        % -----------------------------
        % Load event file
        % -----------------------------
        fpath  = fullfile(pathName, fileNames{i});
        loaded = load(fpath);

        if ~isfield(loaded,'data')
            warning('Skipping "%s": missing data struct.', fileNames{i});
            continue;
        end

        data = loaded.data;

        % -----------------------------
        % Validate required fields
        % -----------------------------
        req = {'ex','ey','latq','lonq','tind','b'};
        if any(~isfield(data, req)) || ~isfield(data.b,'times')
            warning('Skipping "%s": missing required fields.', fileNames{i});
            continue;
        end

        % -----------------------------
        % Parse event time range from filename (if possible)
        % -----------------------------
        [~, baseName, ~] = fileparts(fileNames{i});
        [tStartName, tEndName] = parseEventTimesFromFileName(baseName);
        
        % -----------------------------
        % Extract inputs
        % -----------------------------
        ex   = data.ex;
        ey   = data.ey;
        latq = data.latq;
        lonq = data.lonq;

        tind    = data.tind(:);
        timeVec = data.b(1).times(tind);

        % -----------------------------
        % Run GIC simulation
        % -----------------------------
        app.gic_originalS = [];
        app.gic_originalL = [];
        app.gic_originalT = [];
        [~,~,~,GIC_temp,~,~,~,~] = ...
            calc_gic_main(app, S, L, T, ...
                          ex, ey, latq, lonq, ...
                          tind, ...
                          app.OriginalL, app.OriginalT);

        % -----------------------------
        % Validate GIC output
        % -----------------------------
        if ~isfield(GIC_temp,'Original_Subs')
            warning('Skipping "%s": GIC_temp missing Original_Subs.', fileNames{i});
            continue;
        end

        gicSubs  = GIC_temp.Original_Subs;   % [nSubs  x nTime]
        gicTrans = GIC_temp.Original_Trans;  % [nTrans x nW x nTime]
        gicLine  = GIC_temp.Original_Lines;  % [nLines x nTime]

        if size(gicSubs,1) ~= nSubs
            warning('Event "%s": Original_Subs row count mismatch (expected %d).', baseName, nSubs);
        end

        % -----------------------------
        % Window size in samples
        % -----------------------------
        wSamp = windowSamplesFromDatetime(timeVec, minutes(15));

        % -----------------------------
        % Substations
        % -----------------------------
        sub_max15    = maxMovMeanAbs_2D(gicSubs, wSamp);
        subMat(:,i)  = sub_max15(:);

        % -----------------------------
        % Lines
        % -----------------------------
        if ismatrix(gicLine) && size(gicLine,2) == numel(tind)
            line_max15 = maxMovMeanAbs_2D(gicLine, wSamp);
        else
            warning('Event "%s": Original_Lines shape unexpected; filling with NaN.', baseName);
            line_max15 = nan(nLines,1);
        end
        lineMat(:,i) = line_max15(:);

        % -----------------------------
        % Transformers (W1 and W2)
        % -----------------------------
        if ndims(gicTrans) == 3 && size(gicTrans,1) == nTrans && size(gicTrans,3) == numel(tind)
            gicW1          = squeeze(gicTrans(:,1,:));
            trans_max15_w1 = maxMovMeanAbs_2D(gicW1, wSamp);
            if size(gicTrans,2) >= 2
                gicW2          = squeeze(gicTrans(:,2,:));
                trans_max15_w2 = maxMovMeanAbs_2D(gicW2, wSamp);
            else
                trans_max15_w2 = nan(nTrans,1);
            end
        else
            warning('Event "%s": Original_Trans shape unexpected; filling with NaN.', baseName);
            trans_max15_w1 = nan(nTrans,1);
            trans_max15_w2 = nan(nTrans,1);
        end
        transMat_w1(:,i) = trans_max15_w1(:);
        transMat_w2(:,i) = trans_max15_w2(:);

        % -----------------------------
        % Store event info
        % -----------------------------
        results.events(i).file            = fileNames{i};
        results.events(i).label           = string(baseName);
        results.events(i).tStartFile      = tStartName;
        results.events(i).tEndFile        = tEndName;
        results.events(i).tStartSim       = timeVec(1);
        results.events(i).tEndSim         = timeVec(end);
        results.events(i).nSamples        = numel(timeVec);
        results.events(i).winSamples15    = wSamp;
        results.events(i).sub_max15       = sub_max15;
        results.events(i).line_max15      = line_max15;
        results.events(i).trans_max15_w1  = trans_max15_w1;
        results.events(i).trans_max15_w2  = trans_max15_w2;
    end

    % ---------------------------------------------------------------------
    % Save substation matrix (used for heatmap plot)
    % ---------------------------------------------------------------------
    results.matrix.sub_max15_byEvent = subMat;

    % ---------------------------------------------------------------------
    % Aggregate: Substations
    % ---------------------------------------------------------------------
    results.aggregate.sub.median15 = median(subMat, 2);
    results.aggregate.sub.mean15   = mean(subMat,   2);
    results.aggregate.sub.max15    = max(subMat,    [], 2);
    results.aggregate.sub.nEvents  = sum(~isnan(subMat), 2);
    results.rank_sub = computeMedianRankAcrossEvents(subMat);

    % ---------------------------------------------------------------------
    % Save to MAT-file
    % ---------------------------------------------------------------------
    ts      = datestr(now, 'yyyymmdd_HHMMSS');
    outName = sprintf('storm_results_%s.mat', ts);
    save(outName, 'results', '-v7.3');


    results.lineMat= lineMat;
    results.transMat_w1 = transMat_w1;
    results.transMat_w2 = transMat_w2;
    % ---------------------------------------------------------------------
    % Summary plots — pass everything the plot function needs
    % ---------------------------------------------------------------------
    makeStormSummaryPlots(results);
end

% =========================================================================
% Window length in samples from datetime vector
% =========================================================================
function wSamp = windowSamplesFromDatetime(timeVec, winDur)
    if numel(timeVec) < 2
        wSamp = 1;
        return;
    end
    dt = seconds(diff(timeVec));
    dt = dt(isfinite(dt) & dt > 0);
    if isempty(dt)
        wSamp = 1;
        return;
    end
    dt_med = median(dt);
    wSamp  = max(1, round(seconds(winDur)/dt_med));
end

% =========================================================================
% Max moving mean of abs for [nSites x nTime]
% =========================================================================
function out = maxMovMeanAbs_2D(X, wSamp)
    A = abs(X);
    M = movmean(A, wSamp, 2, 'Endpoints','shrink');
    out = max(M, [], 2);
    out = out(:);
end

% =========================================================================
% Parse start/end times from filename
% =========================================================================
function [tStart, tEnd] = parseEventTimesFromFileName(baseName)
    tStart = NaT; tEnd = NaT;
    expr = "from\s+(\d{2}-[A-Za-z]{3}-\d{4}\s+\d{2}/\d{2}/\d{2})\s+to\s+(\d{2}-[A-Za-z]{3}-\d{4}\s+\d{2}/\d{2}/\d{2})";
    tok  = regexp(baseName, expr, 'tokens', 'once');
    if isempty(tok) || numel(tok) < 2
        return;
    end
    s1 = strrep(tok{1}, '/', ':');
    s2 = strrep(tok{2}, '/', ':');
    try
        tStart = datetime(s1, 'InputFormat','dd-MMM-yyyy HH:mm:ss');
        tEnd   = datetime(s2, 'InputFormat','dd-MMM-yyyy HH:mm:ss');
    catch
        tStart = NaT;
        tEnd   = NaT;
    end
end

% =========================================================================
% Median rank across events
% =========================================================================
function rankOut = computeMedianRankAcrossEvents(Mat)
    [nSubs, nEvents] = size(Mat);
    rankMat = nan(nSubs, nEvents);
    for e = 1:nEvents
        x = Mat(:,e);
        if all(isnan(x)), continue; end
        [~, order] = sort(x, 'descend', 'MissingPlacement','last');
        r = nan(nSubs,1);
        r(order) = (1:nSubs).';
        rankMat(:,e) = r;
    end
    rankOut.rankMat    = rankMat;
    rankOut.medianRank = median(rankMat, 2);
    rankOut.meanRank   = mean(rankMat,   2);
end

% =========================================================================
% Summary plots
% =========================================================================
function makeStormSummaryPlots(results)
    subMat      = results.matrix.sub_max15_byEvent;
    lineMat     = results.lineMat;
    transMat_w1 = results.transMat_w1;
    transMat_w2 = results.transMat_w2;
    subNames    = results.sub.Name;
    lineNames   = results.line.Name;
    transNames  = results.trans.Name;

    nEvents = size(subMat, 2);
    eventLabels = strings(nEvents, 1);
    for i = 1:numel(results.events)
        eventLabels(i) = results.events(i).label;
    end

    % Drop entirely-NaN events
    validEvent      = ~all(isnan(lineMat), 1);
    subMatV         = subMat(:, validEvent);
    lineMatV        = lineMat(:, validEvent);
    transMatV_w1    = transMat_w1(:, validEvent);
    transMatV_w2    = transMat_w2(:, validEvent);
    eventLabelsV    = eventLabels(validEvent);

    if isempty(subMatV)
        warning('No valid events to plot.');
        return;
    end

    % -----------------------------------------------------------------------
    % Plot 1: Heatmap (Substations x Events)
    % -----------------------------------------------------------------------
    figure('Name','GIC Hotspots Heatmap (Max 15-min Mean |GIC|)');
    imagesc(subMatV);
    colorbar;
    xlabel('Event');
    ylabel('Substation Index');
    title('Heatmap: Max 15-min Mean |GIC| per Substation per Event');
    set(gca,'XTick',1:numel(eventLabelsV),'XTickLabel',eventLabelsV);
    xtickangle(45);

    % -----------------------------------------------------------------------
    % Plot 2: Bar — Top-N substations by median across events
    % -----------------------------------------------------------------------
    med15 = results.aggregate.sub.median15;
    [~, idxSort] = sort(med15, 'descend', 'MissingPlacement','last');
    N      = min(20, numel(idxSort));
    topIdx = idxSort(1:N);

    figure('Name','Top Hotspot Substations (Median across Events)');
    bar(med15(topIdx));
    grid on;
    ylabel('Median of Event Max 15-min Mean |GIC|');
    title(sprintf('Top %d Substations by Persistent Hotspot Score (Median)', N));
    set(gca,'XTick',1:N,'XTickLabel',subNames(topIdx));
    xtickangle(45);

    % -----------------------------------------------------------------------
    % Plot 3: Box/Whisker — Top-N substations across events
    % -----------------------------------------------------------------------
    figure('Name','Distribution across Storms — Top Substations');
    boxplot(subMatV(topIdx,:).', 'Labels', cellstr(subNames(topIdx)));
    grid on;
    ylabel('Event Max 15-min Mean |GIC|');
    title(sprintf('Across-Storm Distribution for Top %d Substations', N));
    xtickangle(45);

    % -----------------------------------------------------------------------
    % Plot 4: Box/Whisker — Top 20 Lines + Transformers (W1/W2 combined)
    % -----------------------------------------------------------------------
    combTransV   = max(transMatV_w1, transMatV_w2);  % elementwise max of windings
    combinedMat  = [lineMatV; combTransV];
    combinedNames = [lineNames; transNames];

    medCombined = median(combinedMat, 2, 'omitnan');
    [~, idxComb] = sort(medCombined, 'descend', 'MissingPlacement','last');
    NC      = min(20, numel(idxComb));
    topComb = idxComb(1:NC);

    figure('Name','Top 20 Lines + Transformers — Distribution across Storms');
    boxplot(combinedMat(topComb,:).', 'Labels', cellstr(combinedNames(topComb)));
    grid on;
    ylabel('Event Max 15-min Mean |GIC|');
    title(sprintf('Top %d Lines and Transformers by Median Event Value', NC));
    xtickangle(45);

    % -----------------------------------------------------------------------
    % Plot 5: Rank-consistency — Top 30 substations
    % -----------------------------------------------------------------------
    medRank = results.rank_sub.medianRank;
    [~, idxRankSort] = sort(medRank, 'ascend', 'MissingPlacement','last');
    Nr = min(30, numel(idxRankSort));

    figure('Name','Rank Consistency — Substations (Median Rank across Events)');
    bar(medRank(idxRankSort(1:Nr)));
    grid on;
    ylabel('Median Rank (Lower = more consistently high)');
    title(sprintf('Top %d Consistent Hotspots by Median Rank', Nr));
    set(gca,'XTick',1:Nr,'XTickLabel',subNames(idxRankSort(1:Nr)));
    xtickangle(45);
end