function results = runStormBatchHotspots(app, S, L, T)
% runStormBatchHotspots  Minimal pipeline to compute hotspot matrices,
% plot four summary figures, and save useful results.
%
% Inputs:
%   app - application object required by calc_gic_main
%   S, L, T - substation, line, transformer structs (arrays)
%
% Outputs:
%   results - struct with saved matrices and aggregates

    % Select event files
    [fileNames, pathName] = uigetfile('*.mat', ...
        'Select E-field event .mat files', 'MultiSelect', 'on');
    if isequal(fileNames,0)
        results = struct();
        return;
    end
    if ischar(fileNames)
        fileNames = {fileNames};
    end

    % Metadata
    nSubs  = numel(S);
    nLines = numel(L);
    nTrans = numel(T);
    subNames  = string({S.Name}).';
    lineNames = string({L.Name}).';
    transNames = string({T.Name}).';

    nEvents = numel(fileNames);
    subMat  = nan(nSubs,  nEvents);
    lineMat = nan(nLines, nEvents);
    transMat_w1 = nan(max(1,nTrans), nEvents);
    transMat_w2 = nan(max(1,nTrans), nEvents);

    % Loop events: compute per-site max 15-min mean |GIC|
    for i = 1:nEvents
        fpath = fullfile(pathName, fileNames{i});
        dat = load(fpath);
        if ~isfield(dat,'data'), continue; end
        data = dat.data;
        req = {'ex','ey','latq','lonq','tind','b'};
        if any(~isfield(data, req)) || ~isfield(data.b,'times'), continue; end

        ex   = data.ex; ey = data.ey;
        latq = data.latq; lonq = data.lonq;
        tind = data.tind(:);
        timeVec = data.b(1).times(tind);

        % Run GIC simulation (returns GIC arrays in GIC_temp)
        app.gic_originalS = []; app.gic_originalL = []; app.gic_originalT = [];
        [~,~,~,GIC_temp] = calc_gic_main(app, S, L, T, ...
            ex, ey, latq, lonq, tind, app.OriginalL, app.OriginalT);

        if ~isfield(GIC_temp,'Original_Subs'), continue; end
        gicSubs  = GIC_temp.Original_Subs;   % [nSubs x nTime]
        gicLine  = GIC_temp.Original_Lines;  % [nLines x nTime]
        gicTrans = GIC_temp.Original_Trans;  % [nTrans x nW x nTime]

        wSamp = windowSamplesFromDatetime(timeVec, minutes(15));

        % Substations
        if ~isempty(gicSubs)
            subMat(:,i) = maxMovMeanAbs_2D(gicSubs, wSamp);
        end

        % Lines
        if ~isempty(gicLine) && ismatrix(gicLine)
            lineMat(:,i) = maxMovMeanAbs_2D(gicLine, wSamp);
        end

        % Transformers (w1/w2)
        if ndims(gicTrans) == 3
            if size(gicTrans,2) >= 1
                w1 = squeeze(gicTrans(:,1,:));
                transMat_w1(:,i) = maxMovMeanAbs_2D(w1, wSamp);
            end
            if size(gicTrans,2) >= 2
                w2 = squeeze(gicTrans(:,2,:));
                transMat_w2(:,i) = maxMovMeanAbs_2D(w2, wSamp);
            end
        end
    end

    % Assemble results and basic aggregates
    results.matrix.sub = subMat;
    results.matrix.line = lineMat;
    results.matrix.trans_w1 = transMat_w1;
    results.matrix.trans_w2 = transMat_w2;
    results.names.sub = subNames;
    results.names.line = lineNames;
    results.names.trans = transNames;

    results.aggregate.sub.median = median(subMat, 2, 'omitnan');
    results.aggregate.line.median = median(lineMat, 2, 'omitnan');

    % Save compact MAT for later use
    ts = datestr(now, 'yyyymmdd_HHMMSS');
    outName = sprintf('storm_results_compact_%s.mat', ts);
    save(outName, 'results', '-v7.3');

    % ---------- Plots (4 figures) ----------
    % 1) Heatmap: substations x events
    validEvents = ~all(isnan([lineMat; transMat_w1; transMat_w2]), 1);
    subMatV = subMat(:, validEvents);
    evtLabels = string(1:size(subMatV,2));

    figure('Name','GIC Heatmap'); imagesc(subMatV); colorbar;
    xlabel('Event'); ylabel('Substation'); title('Heatmap: Max 15-min mean |GIC|');
    set(gca,'YTick',1:nSubs,'YTickLabel',subNames,'XTick',1:numel(evtLabels),'XTickLabel',evtLabels);
    xtickangle(45);

    % Determine top-20 substations by median
    [~, idxSub] = sort(results.aggregate.sub.median, 'descend', 'MissingPlacement','last');
    Nsub = min(20, numel(idxSub));
    topSub = idxSub(1:Nsub);

    % 2) Boxplot: top-20 substations
    figure('Name','Top-20 Substations Boxplot');
    boxplot(subMat(topSub,:).', 'Labels', cellstr(subNames(topSub)));
    title('Top 20 Substations Across Events'); ylabel('Max 15-min mean |GIC|');
    xtickangle(45); grid on;

    % Determine top-20 lines by median
    [~, idxLine] = sort(results.aggregate.line.median, 'descend', 'MissingPlacement','last');
    Nline = min(20, numel(idxLine));
    topLine = idxLine(1:Nline);

    % 3) Boxplot: top-20 lines
    figure('Name','Top-20 Lines Boxplot');
    boxplot(lineMat(topLine,:).', 'Labels', cellstr(lineNames(topLine)));
    title('Top 20 Lines Across Events'); ylabel('Max 15-min mean |GIC|');
    xtickangle(45); grid on;

    % 4) Boxplot: combined top-30 from lines+subs by median (combined median)
    combMat = [subMat; lineMat];
    combNames = [subNames; lineNames];
    combMed = median(combMat, 2, 'omitnan');
    [~, idxComb] = sort(combMed, 'descend', 'MissingPlacement','last');
    Ncomb = min(30, numel(idxComb));
    topComb = idxComb(1:Ncomb);

    figure('Name','Top-30 Combined (Subs+Lines) Boxplot');
    boxplot(combMat(topComb,:).', 'Labels', cellstr(combNames(topComb)));
    title('Top 30 Combined Substations and Lines'); ylabel('Max 15-min mean |GIC|');
    xtickangle(45); grid on;

end

%% Helper: window length in samples from datetime vector
function wSamp = windowSamplesFromDatetime(timeVec, winDur)
    if numel(timeVec) < 2
        wSamp = 1; return;
    end
    dt = seconds(diff(timeVec));
    dt = dt(isfinite(dt) & dt>0);
    if isempty(dt), wSamp = 1; return; end
    dt_med = median(dt);
    wSamp = max(1, round(seconds(winDur)/dt_med));
end

%% Helper: max moving mean of abs for [nSites x nTime]
function out = maxMovMeanAbs_2D(X, wSamp)
    if isempty(X)
        out = [];
        return;
    end
    A = abs(X);
    M = movmean(A, wSamp, 2, 'Endpoints','shrink');
    out = max(M, [], 2);
    out = out(:);
end
