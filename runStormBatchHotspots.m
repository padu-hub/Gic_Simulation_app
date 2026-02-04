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
%   3) Box/whisker: distribution across storms for Top-N substations
%   4) Rank-consistency: median rank across events (lower = more consistently high)
%
% Your bubble map (substation bubbles) can use:
%   results.aggregate.sub.median15  (or max15/mean15)
%   results.sub.Latitude / Longitude
%
% ASSUMES:
%   - Event .mat contains loaded.data with:
%       data.ex, data.ey, data.latq, data.lonq, data.tind, data.b.times
%   - calc_gic_main returns GIC_temp with:
%       GIC_temp.Original_Subs  [nSubs x nTime]
%       GIC_temp.Original_Trans [nTrans x 2 x nTime]
%   - Substations:
%       S(k).Name, S(k).Latitude, S(k).Longitude exist
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
    % Keep originals for calc_gic_main call (your workflow)
    % ---------------------------------------------------------------------
    OriginalL = L;
    OriginalT = T;

    % ---------------------------------------------------------------------
    % Substation metadata (bubble-ready later)
    % ---------------------------------------------------------------------
    nSubs = numel(S);
    results.sub.Name      = string({S.Name}).';
    results.sub.Latitude  = reshape([S.Latitude],  [], 1);
    results.sub.Longitude = reshape([S.Longitude], [], 1);

    % ---------------------------------------------------------------------
    % Transformer metadata (stored, but you said no transformer bubbles)
    % ---------------------------------------------------------------------
    nTrans = numel(T);
    if nTrans > 0
        results.trans.Name = string({T.Name}).';
    else
        results.trans.Name = strings(0,1);
    end

    % ---------------------------------------------------------------------
    % Pre-allocate event containers
    % ---------------------------------------------------------------------
    nEvents = numel(fileNames);
    results.events = repmat(struct(), nEvents, 1);

    % Matrices you'll use for analysis/plots:
    % subMat:   [nSubs  x nEvents] = max 15-min mean per event per sub
    % transMat: [nTrans x nEvents] = max 15-min mean per event per trans (W1)
    subMat   = nan(nSubs,  nEvents);
    transMat = nan(nTrans, nEvents);

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
        % Example:
        % "Line E-Field from 11-May-2024 09/00/00 to 11-May-2024 10/00/00.mat"
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

        % tind defines the simulated segment
        tind = data.tind(:);

        % IMPORTANT: time vector ONLY for tind
        timeVec = data.b(1).times(tind);

        % -----------------------------
        % Run GIC simulation only for tind
        % -----------------------------
        currentTind = tind;

        [~,~,~,GIC_temp,~,~,~,~] = ...
            calc_gic_main(app, S, L, T, ...
                          ex, ey, latq, lonq, ...
                          currentTind, false, ...
                          OriginalL, OriginalT);

        % -----------------------------
        % Extract known outputs (your exact structure)
        % -----------------------------
        if ~isfield(GIC_temp,'Original_Subs')
            warning('Skipping "%s": GIC_temp missing Original_Subs.', fileNames{i});
            continue;
        end

        gicSubs = GIC_temp.Original_Subs;  % [nSubs x nTime]

        if size(gicSubs,1) ~= nSubs
            warning('Event "%s": Original_Subs row count mismatch (expected %d).', baseName, nSubs);
        end

        % Transformer winding 1 (optional store)
        gicTransW1 = [];
        if nTrans > 0 && isfield(GIC_temp,'Original_Trans')
            gicTrans = GIC_temp.Original_Trans;  % [nTrans x 2 x nTime]
            if ndims(gicTrans) == 3 && size(gicTrans,1) == nTrans && size(gicTrans,2) >= 1
                gicTransW1 = squeeze(gicTrans(:,1,:)); % [nTrans x nTime]
            else
                warning('Event "%s": Original_Trans shape unexpected; skipping transformer metrics.', baseName);
            end
        end

        % -----------------------------
        % Compute 15-min window in samples using timeVec
        % -----------------------------
        wSamp = windowSamplesFromDatetime(timeVec, minutes(15));

        % -----------------------------
        % Compute max 15-min mean |GIC|
        % -----------------------------
        sub_max15 = maxMovMeanAbs_2D(gicSubs, wSamp); % [nSubs x 1]
        subMat(:,i) = sub_max15(:);

        if ~isempty(gicTransW1)
            trans_max15 = maxMovMeanAbs_2D(gicTransW1, wSamp); % [nTrans x 1]
            transMat(:,i) = trans_max15(:);
        end

        % -----------------------------
        % Store event info
        % -----------------------------
        results.events(i).file       = fileNames{i};
        results.events(i).label      = string(baseName);
        results.events(i).tStartFile = tStartName;  % may be NaT if parse failed
        results.events(i).tEndFile   = tEndName;    % may be NaT if parse failed

        results.events(i).tStartSim  = timeVec(1);
        results.events(i).tEndSim    = timeVec(end);
        results.events(i).nSamples   = numel(timeVec);
        results.events(i).winSamples15 = wSamp;

        results.events(i).sub_max15  = sub_max15;      % vector, bubble-size input later
        results.events(i).trans_max15_w1 = [];         % keep field consistent
        if ~isempty(gicTransW1)
            results.events(i).trans_max15_w1 = transMat(:,i);
        end
    end

    % ---------------------------------------------------------------------
    % Save matrices (useful for your own plotting / exporting)
    % ---------------------------------------------------------------------
    results.matrix.sub_max15_byEvent   = subMat;    % [nSubs x nEvents]
    results.matrix.trans_max15_byEvent = transMat;  % [nTrans x nEvents]

    % ---------------------------------------------------------------------
    % Aggregate "persistent hotspot" metrics (substations)
    % ---------------------------------------------------------------------
    results.aggregate.sub.median15 = nanmedian(subMat, 2);
    results.aggregate.sub.mean15   = nanmean(subMat,   2);
    results.aggregate.sub.max15    = nanmax(subMat,    [], 2);
    results.aggregate.sub.nEvents  = sum(~isnan(subMat), 2);

    % Transformer aggregates stored too (even if you won't bubble-map them)
    if nTrans > 0
        results.aggregate.trans.median15 = nanmedian(transMat, 2);
        results.aggregate.trans.mean15   = nanmean(transMat,   2);
        results.aggregate.trans.max15    = nanmax(transMat,    [], 2);
        results.aggregate.trans.nEvents  = sum(~isnan(transMat), 2);
    else
        results.aggregate.trans = struct();
    end

    % ---------------------------------------------------------------------
    % Rank-consistency metric (substations)
    % Lower median rank = more consistently high across storms
    % ---------------------------------------------------------------------
    results.rank = computeMedianRankAcrossEvents(subMat);

    % ---------------------------------------------------------------------
    % Make non-bubble summary plots (you asked me to include these)
    % ---------------------------------------------------------------------
    makeStormSummaryPlots(results);
end

% =========================================================================
% Compute window length (samples) from datetime vector
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
% Parse start/end times from your filename format
% Example baseName:
%   "Line E-Field from 11-May-2024 09/00/00 to 11-May-2024 10/00/00"
% Returns NaT if parsing fails.
% =========================================================================
function [tStart, tEnd] = parseEventTimesFromFileName(baseName)
    tStart = NaT; tEnd = NaT;

    % Grab the two date-time chunks between "from" and "to"
    % Accepts "/" in time section and "-" in date.
    expr = "from\s+(\d{2}-[A-Za-z]{3}-\d{4}\s+\d{2}/\d{2}/\d{2})\s+to\s+(\d{2}-[A-Za-z]{3}-\d{4}\s+\d{2}/\d{2}/\d{2})";
    tok  = regexp(baseName, expr, 'tokens', 'once');

    if isempty(tok) || numel(tok) < 2
        return;
    end

    % Convert "09/00/00" -> "09:00:00" then parse
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
% For each event: rank substations by value (descending), then take median rank.
% =========================================================================
function rankOut = computeMedianRankAcrossEvents(subMat)
    [nSubs, nEvents] = size(subMat);
    rankMat = nan(nSubs, nEvents);

    for e = 1:nEvents
        x = subMat(:,e);
        if all(isnan(x)), continue; end

        % Descending ranks: biggest value -> rank 1
        [~, order] = sort(x, 'descend', 'MissingPlacement','last');

        r = nan(nSubs,1);
        r(order) = (1:nSubs).';
        rankMat(:,e) = r;
    end

    rankOut.rankMat     = rankMat;
    rankOut.medianRank  = nanmedian(rankMat, 2);
    rankOut.meanRank    = nanmean(rankMat,   2);
end

% =========================================================================
% Summary plots (not bubble maps)
% =========================================================================
function makeStormSummaryPlots(results)
    subMat = results.matrix.sub_max15_byEvent; % [nSubs x nEvents]
    subNames = results.sub.Name;
    eventLabels = strings(size(subMat,2),1);
    for i = 1:numel(results.events)
        eventLabels(i) = results.events(i).label;
    end

    % Drop events that are entirely NaN (skipped)
    validEvent = ~all(isnan(subMat), 1);
    subMatV = subMat(:, validEvent);
    eventLabelsV = eventLabels(validEvent);

    if isempty(subMatV)
        warning('No valid events to plot.');
        return;
    end

    % -----------------------------
    % Plot 1: Heatmap (Substations x Events)
    % -----------------------------
    figure('Name','GIC Hotspots Heatmap (Max 15-min Mean |GIC|)');
    imagesc(subMatV);
    colorbar;
    xlabel('Event');
    ylabel('Substation Index');
    title('Heatmap: Max 15-min Mean |GIC| per Substation per Event');
    set(gca,'XTick',1:numel(eventLabelsV),'XTickLabel',eventLabelsV);
    xtickangle(45);

    % -----------------------------
    % Decide Top-N for deeper plots
    % Use persistent hotspot score = median across events
    % -----------------------------
    med15 = results.aggregate.sub.median15;
    [~, idxSort] = sort(med15, 'descend', 'MissingPlacement','last');

    N = min(20, numel(idxSort)); % Top 20 default
    topIdx = idxSort(1:N);

    % -----------------------------
    % Plot 2: Bar chart of Top-N by median15
    % -----------------------------
    figure('Name','Top Hotspot Substations (Median across Events)');
    bar(med15(topIdx));
    grid on;
    ylabel('Median of Event Max 15-min Mean |GIC|');
    title(sprintf('Top %d Substations by Persistent Hotspot Score (Median)', N));
    set(gca,'XTick',1:N,'XTickLabel',subNames(topIdx));
    xtickangle(45);

    % -----------------------------
    % Plot 3: Box/Whisker across events for Top-N
    % -----------------------------
    figure('Name','Distribution across Storms (Top Hotspots)');
    boxplot(subMatV(topIdx,:).', 'Labels', cellstr(subNames(topIdx)));
    grid on;
    ylabel('Event Max 15-min Mean |GIC|');
    title(sprintf('Across-Storm Distribution for Top %d Hotspots', N));
    xtickangle(45);

    % -----------------------------
    % Plot 4: Rank-consistency (median rank)
    % Lower median rank = consistently high
    % -----------------------------
    medRank = results.rank.medianRank;
    [~, idxRankSort] = sort(medRank, 'ascend', 'MissingPlacement','last');
    Nr = min(30, numel(idxRankSort));

    figure('Name','Rank Consistency (Median Rank across Events)');
    bar(medRank(idxRankSort(1:Nr)));
    grid on;
    ylabel('Median Rank (Lower = more consistently high)');
    title(sprintf('Top %d Consistent Hotspots by Median Rank', Nr));
    set(gca,'XTick',1:Nr,'XTickLabel',subNames(idxRankSort(1:Nr)));
    xtickangle(45);
end
