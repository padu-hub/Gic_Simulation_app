%function result = weightRanking(app, results, w_lines_in, w_trans_in)
function weightRanking(app, results)
% Rank lines and transformers into one combined list.
% Fields: .order, .type, .score (scores in [-100,100])

%Weights (edit as needed)
w_lines = [100, 0, 100];    % [w_gic, w_doubleCircuit, w_length]
w_trans = [100, 0];        % [w_gic, w_value]

% w_lines = w_lines_in;   % [w_gic, w_doubleCircuit, w_length]
% w_trans = w_trans_in;   % [w_gic, w_value]

%% Prepare lines
nL = numel(app.L);
lineIdxAll = (1:nL).';

% 1) Line GIC sum (positional from results.rank.line(:,2))
gicLine = zeros(nL,1);
if isfield(results,'rank') && isfield(results.rank,'line') && ~isempty(results.rank.line)
    rl = results.rank.line;
    if istable(rl), vals = rl{:,2}; else vals = rl(:,2); end
    nAssign = min(nL, numel(vals));
    gicLine(1:nAssign) = vals(1:nAssign);
end

% 2) Double-circuit indicator -> -100 if single, 100 if double (all members)
tol = 1e-4;
keys = strings(nL,1);
for i = 1:nL
    P = app.L(i).Loc;            % m x 2
    P = sortrows(P);
    P = round(P./tol).*tol;
    keys(i) = strjoin(arrayfun(@(r) sprintf('%.12g_%.12g', P(r,1), P(r,2)), ...
                               (1:size(P,1))','UniformOutput',false), '|');
end
[~, ~, gid] = unique(keys);

doubleCircuit_s = -100 * ones(nL,1);   % default single-circuit = -100
for k = 1:max(gid)
    members = find(gid == k);
    if numel(members) > 1
        doubleCircuit_s(members) = 100;   % assign 100 to all members of a double-circuit group
    end
end


% 3) Length -> normalize 0..100
len = nan(nL,1);
for i=1:nL
    if isfield(app.L(i),'Length') && ~isempty(app.L(i).Length)
        len(i) = app.L(i).Length;
    end
end
len(isnan(len)) = 0;
len_n = normalize0to100(len); % 0..100 (independent)

%% Prepare transformers (build rW and vM)
transIDs = []; transScore = [];
if isfield(results,'rank') && isfield(results.rank,'trans') && ~isempty(results.rank.trans) ...
        && isfield(results,'average') && isfield(results.average,'trans') && ~isempty(results.average.trans)

    rt = results.rank.trans;
    ra = results.average.trans;

    % extract rt values (positional)
    if istable(rt), rt_vals = rt{:,2}; else rt_vals = rt(:,2); end

    % choose signed value from ra fields w1,w2 by larger absolute
    a = [ra.w1].'; b = [ra.w2].';
    vals = [a b];
    [~, colIdx] = max(abs(vals), [], 2);
    ra_vals = vals(sub2ind(size(vals), (1:size(vals,1)).', colIdx));

    % build arrays (positional)
    nT = max(numel(rt_vals), numel(ra_vals));
    rW = zeros(nT,1); vM = zeros(nT,1);
    rW(1:numel(rt_vals)) = rt_vals;
    vM(1:numel(ra_vals)) = ra_vals;

    % Compute shared min/max across gicLine and rW (use finite entries)
    combinedGIC = [gicLine(:); rW(:)];
    finiteMask = isfinite(combinedGIC) & ~isnan(combinedGIC);
    if any(finiteMask)
        sharedMin = min(combinedGIC(finiteMask));
        sharedMax = max(combinedGIC(finiteMask));
    else
        sharedMin = 0; sharedMax = 0;
    end

    % Normalize using shared min/max
    gicLine_n = normalize0to100(gicLine, sharedMin, sharedMax); % 0..100
    rW_n      = normalize0to100(rW, sharedMin, sharedMax);     % 0..100

    % vM mapping per rule: negatives -> 0..100, positives -> 0..-100 (each normalized independently)
    vM_s = zeros(nT,1);
    negMask = vM < 0;
    posMask = vM > 0;
    if any(negMask)
        vneg_n = normalize0to100(abs(vM(negMask)));
        vM_s(negMask) = vneg_n;
    end
    if any(posMask)
        vpos_n = normalize0to100(vM(posMask));
        vM_s(posMask) = -vpos_n;
    end

    % combine using weights
    wt = w_trans(:).';
    if all(wt==0)
        transScore = zeros(nT,1);
    else
        denomt = sum(abs(wt));
        c1 = rW_n ./ 100;   % 0..1
        c2 = vM_s ./ 100;   % -1..1
        transScore = ( wt(1)*c1 + wt(2)*c2 ) ./ denomt * 100; % -100..100
    end
    transScore(isnan(transScore)) = 0;

    % default positional IDs if none provided
    transIDs = (1:numel(transScore)).';
end

% If no transformer block executed, still compute gicLine_n now
if ~exist('gicLine_n','var')
    % rW absent -> normalize gicLine alone
    gicLine_n = normalize0to100(gicLine);
end

% Assemble line combined score using weights (uses gicLine_n, doubleCircuit_s, len_n)
wl = w_lines(:).';
if all(wl==0)
    lineScore = zeros(nL,1);
else
    denom = sum(abs(wl));
    comp1 = gicLine_n ./ 100;         % 0..1
    comp2 = doubleCircuit_s ./ 200;   % -1..1
    comp3 = len_n ./ 100;             % 0..1
    lineScore = ( wl(1)*comp1 + wl(2)*comp2 + wl(3)*comp3 ) ./ denom * 100; % -100..100
end
lineScore(isnan(lineScore)) = 0;

% Ensure column vectors
lineIdxAll = lineIdxAll(:); lineScore = lineScore(:);
transScore = transScore(:); transIDs = transIDs(:);

% Combine and sort
allIdx = [lineIdxAll; transIDs];
allScore = [lineScore; transScore];
Type = [repmat("Line", numel(lineIdxAll), 1); repmat("Trans", numel(transIDs), 1)];

[~, orderCombo] = sort(allScore, 'descend', 'MissingPlacement', 'last');
idx_sorted.name = allIdx(orderCombo);
idx_sorted.type  = Type(orderCombo);
idx_sorted.score = allScore(orderCombo);

% Save idx_sorted with timestamp
ts = datestr(now,'yyyy-mm-dd_HH-MM-SS');
fname = sprintf('mitigateorder_%s.mat', ts);
mitigateorder = idx_sorted; 
save(fname, 'mitigateorder');

%plotRanking(lineScore, transScore, allScore, Type, lineIdxAll, transIDs, allIdx)
% Apply mitigation (preserves function behavior)
%result = mitigateOnOrder(app, idx_sorted);
%plotGICSubsComparison(results, results_original);
end

%% Helper: normalize 0-100 with optional shared min/max
function out = normalize0to100(v, vmin, vmax)
    out = zeros(size(v));
    valid = isfinite(v) & ~isnan(v);
    if ~any(valid), return; end
    if nargin < 3
        vmin = min(v(valid));
        vmax = max(v(valid));
    end
    if vmin == vmax
        out(valid) = 100;
    else
        out(valid) = (v(valid) - vmin) ./ (vmax - vmin) * 100;
    end
end
    
function plotRanking(lineScore, transScore, allScore, Type, lineIdxAll, transIDs, allIdx)
    % Create scatter plot of scores and rankings for lines, transformers, and combined
    figure('Name','Ranking Scatter','NumberTitle','off');
    
    % Prepare indices and ranks
    nLines = numel(lineIdxAll);
    nTrans  = numel(transIDs);
    nAll   = numel(allIdx);
    
    % Individual ranks (1 = highest score)
    [~, idxOrderLines] = sort(lineScore, 'descend', 'MissingPlacement','last');
    rankLines = nan(nLines,1); rankLines(idxOrderLines) = (1:nLines).';
    
    if nTrans>0
        [~, idxOrderTrans] = sort(transScore, 'descend', 'MissingPlacement','last');
        rankTrans = nan(nTrans,1); rankTrans(idxOrderTrans) = (1:nTrans).';
    else
        rankTrans = zeros(0,1);
    end
    
    [~, idxOrderAll] = sort(allScore, 'descend', 'MissingPlacement','last');
    rankAll = nan(nAll,1); rankAll(idxOrderAll) = (1:nAll).';
    
    % Subplots: lines, trans, combined
    tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
    
    % Lines scatter
    nexttile;
    scatter(lineScore, rankLines, 36, lineScore, 'filled');
    set(gca,'YDir','reverse'); % rank 1 at top
    xlabel('Score'); ylabel('Rank');
    title('Lines: score vs rank');
    colorbar; colormap(parula);
    
    % Transformers scatter (if present)
    nexttile;
    if nTrans>0
        scatter(transScore, rankTrans, 36, transScore, 'filled');
        set(gca,'YDir','reverse');
        xlabel('Score'); ylabel('Rank');
        title('Transformers: score vs rank');
        colorbar; colormap(parula);
    else
        text(0.5,0.5,'No transformers','HorizontalAlignment','center');
        axis off;
        title('Transformers: none');
    end
    
    % Combined scatter (mark type)
    nexttile;
    isLine = Type == "Line";
    isTrans = Type == "Trans";
    hold on;
    scatter(allScore(isLine), rankAll(isLine), 36, [0 0.4470 0.7410], 'o', 'filled');
    scatter(allScore(isTrans), rankAll(isTrans), 36, [0.8500 0.3250 0.0980], 's', 'filled');
    set(gca,'YDir','reverse');
    xlabel('Score'); ylabel('Rank');
    legend('Lines','Trans','Location','best');
    title('Combined: score vs rank');
    hold off;
    
    % Improve overall figure
    sgtitle('Segment Rankings (score vs rank)');

end








% 
% % sweep script
% weights = 0:20:100;
% nW = numel(weights);
% 
% % preallocate cell for results vectors
% allSums = cell(nW,1);
% maxLen = 171;
% 
% for k = 1:nW
%     w_dc = weights(k);    % double-circuit weight
%     w_len = weights(k);   % length weight
%     w_val = weights(k);   % transformer value weight
% 
%     % assemble weights (gic remain 100)
%     w_lines = [100, w_dc, w_len];    % sum maybe <= 300
%     w_trans = [100, w_val];
% 
%     % call ranking that uses these weights
%     results= weightRanking(app, topStorms, w_lines, w_trans);
% 
% 
%     % collect sumGICSubs (assumed vector)
%     s = results.sumGICSubs(:);
%     allSums{k} = s;
% end
% 
% % build common x axis 0..maxLen-1
% x = 0:(maxLen-1);
% 
% % plot all series on same axes, padding/truncating as needed
% figure; hold on;
% cols = lines(nW);
% leg = cell(nW,1);
% for k = 1:nW
%     s = allSums{k};
%     % extend or truncate to match x length (pad with NaN so plot ignores missing)
%     spad = NaN(size(x));
%     m = numel(s);
%     spad(1:m) = s;
%     plot(x, spad, '-', 'Color', cols(k,:), 'LineWidth', 1.5);
%     leg{k} = sprintf('w = %d', weights(k));
% end
% xlabel('Number of Mitigations Applied');
% ylabel('Total Substation GIC Sum (A/phase)');
% title('Sweep: w_{doubleCircuit}=w_{length}=w_{value}');
% legend(leg, 'Location', 'northeast');
% grid on;
% xlim([min(x)-0.5, max(x)+0.5]);
% hold off;
