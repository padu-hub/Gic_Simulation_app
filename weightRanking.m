function idx_sorted = weightRanking(app, results)
% Rank lines and transformers into one combined list.
% Outputs idx_sorted struct with fields:
%   .order - numeric IDs (line indices 1..nL for lines, transformer IDs as given)
%   .type  - string array, "Line" or "Trans" aligned with .order
%   .score - combined score in range [-100,100] aligned with .order
%
% Behavior:
% - Line components: gicSum (0..100), doubleCircuit (-100 or 100), length (0..100)
% - Transformer components: gicSum (0..100), value (signed -100..100 per rules below)
% - Component weights w_lines and w_trans define the maximum contribution of each
%   component; currently set to zero as requested. If sum of abs(weights)==0 the
%   combined scores are zero.

%% --- Weights (edit here). Currently all zeros as requested ---
% Lines: [w_gic, w_doubleCircuit, w_length]
w_lines = [100, 50, 100];
% Transformers: [w_gic, w_value]
w_trans = [100, 100];

%% --- Prepare lines ---
nL = numel(app.L);
lineIdxAll = (1:nL).';

% 1) Line GIC sum from results.rank.line(:,2) -> normalized 0..100
gicLine = zeros(nL,1);
if isfield(results,'rank') && isfield(results.rank,'line') && ~isempty(results.rank.line)
    rl = results.rank.line;
    if istable(rl), vals = rl{:,2}; else vals = rl(:,2); end
    % assign up to nL entries
    nAssign = min(nL, numel(vals));
    gicLine = zeros(nL,1);
    gicLine(1:nAssign) = vals(1:nAssign);
end
gicLine_n = normalize0to100(gicLine); % 0..100

% 2) Double-circuit indicator -> -100 if not double, 100 if double
doubleCircuit = zeros(nL,1);
for i=1:nL
    if isfield(app.L(i),'DoubleCircuit') && ~isempty(app.L(i).DoubleCircuit)
        doubleCircuit(i) = double(app.L(i).DoubleCircuit) ~= 0;
    else
        doubleCircuit(i) = 0;
    end
end
% Map 0 -> -100, 1 -> 100
doubleCircuit_s = (doubleCircuit==1)*200 - 100; % yields -100 or 100

% 3) Length -> normalize 0..100
len = nan(nL,1);
for i=1:nL
    if isfield(app.L(i),'Length') && ~isempty(app.L(i).Length)
        len(i) = app.L(i).Length;
    end
end
len(isnan(len)) = 0;
len_n = normalize0to100(len); % 0..100

% Assemble line combined score using weights.
wl = w_lines(:).';
if all(wl==0)
    lineScore = zeros(nL,1);
else
    denom = sum(abs(wl));
    % combine components converting each to fraction of 100, but keeping sign for doubleCircuit
    comp1 = gicLine_n ./ 100;         % 0..1
    comp2 = doubleCircuit_s ./ 100;   % -1..1
    comp3 = len_n ./ 100;             % 0..1
    lineScore = ( wl(1)*comp1 + wl(2)*comp2 + wl(3)*comp3 ) ./ denom * 100; % final -100..100
end
lineScore(isnan(lineScore)) = 0;

% --- Prepare transformers ---
transIDs = []; transScore = [];
if isfield(results,'rank') && isfield(results.rank,'trans') && ~isempty(results.rank.trans) ...
        && isfield(results,'average') && isfield(results.average,'trans') && ~isempty(results.average.trans)

    rt = results.rank.trans;
    ra = results.average.trans;

    % extract rt values (positional)
    if istable(rt), rt_vals = rt{:,2}; else rt_vals = rt(:,2); end

    % get the larger-absolute-value field from ra (assumes fields w1 and w2)
    a = [ra.w1].'; b = [ra.w2].';          % Nx1 each
    vals = [a b]; 
    [~, colIdx] = max(abs(vals), [], 2);  % column index (1 or 2)
    ra_vals = vals(sub2ind(size(vals), (1:size(vals,1)).', colIdx)); % chosen signed values

    % build arrays (positional)
    nT = max(numel(rt_vals), numel(ra_vals));
    rW = zeros(nT,1); vM = zeros(nT,1);
    rW(1:numel(rt_vals)) = rt_vals;
    vM(1:numel(ra_vals)) = ra_vals;

    % rW normalized 0..100
    rW_n = normalize0to100(rW); % 0..100

    % vM mapping per rule: negatives -> 0..100, positives -> 0..-100
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

    % combine using weights (w_trans must be defined)
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
end

% Ensure column vectors
lineIdxAll = lineIdxAll(:); lineScore = lineScore(:);
transScore = transScore(:);

% If transIDs is empty but transScore exists, use positional IDs 1..nT
if isempty(transIDs) && ~isempty(transScore)
    transIDs = (1:numel(transScore)).';
else
    transIDs = transIDs(:);
end

% Now combine
allIdx = [lineIdxAll; transIDs];
allScore = [lineScore; transScore];
Type = [repmat("Line", numel(lineIdxAll), 1); repmat("Trans", numel(transIDs), 1)];

[~, orderCombo] = sort(allScore, 'descend', 'MissingPlacement', 'last');
idx_sorted.order = allIdx(orderCombo);
idx_sorted.type  = Type(orderCombo);
idx_sorted.score = allScore(orderCombo);


end

%% Helper: normalize 0-100 (handles NaN)
function out = normalize0to100(v)
    out = zeros(size(v));
    if ~any(isfinite(v(:)))
        return;
    end
    valid = isfinite(v);
    vValid = v(valid);
    vmin = min(vValid); vmax = max(vValid);
    if vmin == vmax
        out(valid) = 100;
        return;
    end
    out(valid) = (vValid - vmin) ./ (vmax - vmin) * 100;
end
