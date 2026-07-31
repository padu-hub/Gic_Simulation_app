function runStormBatchHotspots(app, S, L, T)
% runStormBatchHotspots_15minSamples  Collect 15-min mean |GIC| samples across events,
% rank sites by sum of those samples, and plot boxplots for top-20 each of lines, subs, trans.
%
% Usage:
%   results = runStormBatchHotspots_15minSamples(app, S, L, T)
%
% Output (results):
%   .samples.sub   - cell [nSubs x 1] of vectors (all 15-min samples across events)
%   .samples.line  - cell [nLines x 1]
%   .samples.trans - cell [nTrans x 1] (combines winding samples)
%   .eventsUsed    - cell array of event filenames used
%   .rank.sub/.line/.trans - table with Name, Sum, Rank, Nsamples

% Select event files
[fileNames, pathName] = uigetfile('*.mat', ...
    'Select E-field event .mat files', 'MultiSelect', 'on');
if isequal(fileNames,0)
    results = struct(); return;
end
if ischar(fileNames), fileNames = {fileNames}; end
nEvents = numel(fileNames);

nSubs  = numel(S); nLines = numel(L); nTrans = max(1,numel(T));
subNames  = string({S.Name}).';
lineNames = string({L.Name}).';
transNames = string({T.Name}).';

% Initialize cell arrays to collect 15-min-windowed mean absolute samples
subSamples  = cell(nSubs,1);
lineSamples = cell(nLines,1);
transSamples = cell(nTrans,2);

eventsUsed = {};

for ei = 1:nEvents
    fpath = fullfile(pathName, fileNames{ei});
    dat = load(fpath);
    if ~isfield(dat,'data'), continue; end
    data = dat.data;
    req = {'ex','ey','latq','lonq','tind','b'};
    if any(~isfield(data, req)) || ~isfield(data.b,'times'), continue; end

    ex   = data.ex; ey = data.ey;
    latq = data.latq; lonq = data.lonq;
    tind = data.tind(:);
    timeVec = data.b(1).times(tind);

    % Run GIC simulation
    app.gic_originalS = []; app.gic_originalL = []; app.gic_originalT = [];
    [~,~,~,GIC_temp] = calc_gic_main(app, S, L, T, ...
        ex, ey, latq, lonq, tind, app.OriginalL, app.OriginalT);
    if ~isfield(GIC_temp,'Original_Subs'), continue; end

    gicSubs  = GIC_temp.Original_Subs;   % [nSubs x nTime]
    gicLine  = GIC_temp.Original_Lines;  % [nLines x nTime]
    gicTrans = GIC_temp.Original_Trans;  % [nTrans x nW x nTime]

    % Determine window length (samples) for 15 minutes for this event
    wSamp = windowSamplesFromDatetime(timeVec, minutes(15));

    % Helper to compute moving-mean of abs and return column-wise time samples
    movmean_abs_samples = @(X) conditional_split(X, wSamp);

    % Substations
    if ~isempty(gicSubs)
        Ssamples = movmean_abs_samples(gicSubs); % cell: one cell per site (column)
        for k = 1:numel(Ssamples)
            subSamples{k} = [subSamples{k}; Ssamples{k}];
        end
    end

    % Lines
    if ~isempty(gicLine) && ismatrix(gicLine)
        Lsamples = movmean_abs_samples(gicLine);
        for k = 1:numel(Lsamples)
            lineSamples{k} = [lineSamples{k}; Lsamples{k}]; 
        end
    end

    % Initialize transSamples as cell or struct array beforehand:
    nT = size(gicTrans,1);
    transSamples = repmat(struct('w1',[],'w2',[]), nT, 1); % for exactly 2 windings
    
    % Populate per transformer/winding( w1 and w2)
    if ndims(gicTrans) == 3
        nW = size(gicTrans,2);
        for ti = 1:nT
            for w = 1:nW
                wvec = squeeze(gicTrans(ti,w,:)).';
                if isempty(wvec), continue; end
                s = split_movmean_abs(wvec, wSamp);
                if iscell(s), s = s{1}; end
    
                switch w
                    case 1
                        if isempty(transSamples(ti).w1)
                            transSamples(ti).w1 = s;
                        else
                            transSamples(ti).w1 = [transSamples(ti).w1; s];
                        end
                    otherwise
                        if isempty(transSamples(ti).w2)
                            transSamples(ti).w2 = s;
                        else
                            transSamples(ti).w2 = [transSamples(ti).w2; s];
                        end
                end
            end
        end
    end


    eventsUsed{end+1} = fileNames{ei}; 
end

% Compute sums, ranks and assemble tables
sum_and_rank = @(C, names) build_rank_table(C, names);

results.samples.sub = subSamples;
results.samples.line = lineSamples;
results.samples.trans = transSamples;
results.eventsUsed = eventsUsed;

results.rank.sub   = sum_and_rank(subSamples, subNames);
results.rank.line  = sum_and_rank(lineSamples, lineNames);
results.rank.trans = sum_and_rank(transSamples, transNames);

% Save compact MAT for later use
ts = datestr(now, 'yyyymmdd_HHMMSS');
outName = sprintf('storm_results_compact_%s.mat', ts);
save(outName, 'results', '-v7.3');
rankByLinesandTrans(app, results);


% Plot boxplots for top-20 by rank
Nplot = 20;
plot_top_box(results.rank.line,  Nplot, lineSamples,  lineNames,  'Top-20 Lines (15-min samples) from top stormes');
plot_top_box(results.rank.sub,   Nplot, subSamples,   subNames,   'Top-20 Substations (15-min samples) from top storms');
plot_top_box(results.rank.trans, Nplot, transSamples, transNames, 'Top-20 Transformers (15-min samples) from top storms');

end

%% Helper: produce moving-mean of abs and return cell of column samples for X [nSites x nTime] or vector
function cellsOut = split_movmean_abs(X, wSamp)
    if isempty(X)
        cellsOut = {};
        return;
    end
    if isvector(X)
        A = abs(X(:).');
        M = movmean(A, wSamp, 2, 'Endpoints','shrink');
        cellsOut = {M(:)}; % single cell
        return;
    end
    A = abs(X);
    M = movmean(A, wSamp, 2, 'Endpoints','shrink'); % same shape
    % return cell per row (site)
    cellsOut = cell(size(M,1),1);
    for r = 1:size(M,1)
        cellsOut{r} = M(r,:).';
    end
end

function T = build_rank_table(cellSamples, names)
% Builds a rank table. Behaves exactly like the original single-field version
% when each cell is a numeric vector. If each cell is an Nx1 struct with two
% fields (e.g. w1 and w2) the function returns Nsamples plus two Sum and
% two Rank columns (one per field).
    n = numel(cellSamples);
    sums = nan(n,1);
    % Single-field 
    if ~isstruct(cellSamples)
        nsamps = zeros(n,1);
        for i = 1:n
            v = cellSamples{i};
            if isempty(v)
                sums(i) = NaN;
                nsamps(i) = 0;
            else
                sums(i) = sum(v,'omitnan');
                nsamps(i) = numel(v);
            end
        end
        [~, ord] = sort(sums, 'descend', 'MissingPlacement','last');
        rankIdx = nan(n,1);
        rankIdx(ord(~isnan(sums(ord)))) = 1:sum(~isnan(sums));
        T = table(names(:), sums, nsamps, rankIdx, ...
            'VariableNames', {'Name','Sum','Nsamples','Rank'});
    else
        fn = fieldnames(cellSamples);
        if numel(fn) ~= 2
            error('When using structs, expected exactly 2 fields per cell.');
        end
        f1 = fn{1}; f2 = fn{2};
        sums = NaN(1,n);
        ns1   = zeros(n,1);
        ns2   = zeros(n,1);
    
        for i = 1:n
            v = cellSamples(i);
            if isempty(v)
                sums1 = NaN; sums2 = NaN;
            else
                if isfield(v, f1) && ~isempty(v.(f1))
                    a = v.(f1);
                    sums1 = sum(a, 'omitnan');
                    ns1(i) = numel(a);              % or nnz(~isnan(a)) for non-NaN count
                else
                    sums1 = NaN; ns1(i) = 0;
                end
        
                if isfield(v, f2) && ~isempty(v.(f2))
                    b = v.(f2);
                    sums2 = sum(b, 'omitnan');
                    ns2(i) = numel(b);              % or nnz(~isnan(b))
                else
                    sums2 = NaN; ns2(i) = 0;
                end
            end
            sums(i) = max(sums1, sums2);
        end
        sums = sums(:);

        % rank based on combined Sum
        rankIdx = nan(n,1);
        [~, ord] = sort(sums, 'descend', 'MissingPlacement','last');
        valid = ~isnan(sums);
        rankIdx(ord(valid(ord))) = 1:sum(valid);
    
        T = table(names(:), sums, ns1, rankIdx, ...
            'VariableNames', {'Name','Sum', 'Nsamples','Rank'});
    end
end



%% Helper: plot top-k (violin) given rank table and samples
function plot_top_box(rankTable, K, samplesCell, names, figTitle)

    if isempty(rankTable)
        return;
    end

    valid = ~isnan(rankTable.Sum);
    ranked = sortrows(rankTable(valid,:), 'Rank', 'ascend');

    K = min(K,height(ranked));
    if K == 0
        return;
    end

    topNames = ranked.Name(1:K);
    idx = arrayfun(@(s)find(names==s,1),topNames);

    % Build long-form data and group labels
    Y = [];
    G = categorical();

    for k = 1:K
        vals = samplesCell{idx(k)}(:);

        Y = [Y; vals];

        G = [G;
             categorical( ...
                 repmat(string(topNames(k)),length(vals),1), ...
                 string(topNames), ...
                 string(topNames))];
    end

    figure('Name',figTitle);

    vp = violinplot(G,Y,...
        DensityWidth=0.8,...
        DensityScale="width");

    % Make all violins the same color
    blue = [0 0.4470 0.7410];

    for k = 1:numel(vp)
        vp(k).FaceColor = blue;
    end

    title(figTitle)
    ylabel('15-min mean |GIC|')

    % Optional for GIC data
    % set(gca,'YScale','log')

    xtickangle(45)
    grid on

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

function out = conditional_split(X, wSamp)
    if isempty(X)
        out = {};
    else
        out = split_movmean_abs(X, wSamp);
    end
end