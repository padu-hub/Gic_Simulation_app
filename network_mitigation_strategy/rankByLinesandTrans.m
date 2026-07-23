function rankByLinesandTrans(app, results)

% Lines
nL = numel(app.L);
lineIdxAll = (1:nL).';
lineScore = zeros(nL,1);
idx_sorted = struct();
if isfield(results,'rank') && isfield(results.rank,'line') && ~isempty(results.rank.line)
    rl = results.rank.line;
    if istable(rl)
        vals = rl{:,2};
    else
        vals = cell2mat(rl(:,2));
    end
    nvals = numel(vals);
    lineScore(1:min(nL,nvals)) = vals(1:min(nL,nvals));
end

% Transformers
nTrans = numel(app.T);
transScore = zeros(nTrans,1);
transIdxAll = (1:nTrans).';

if isfield(results,'rank') && isfield(results.rank,'trans') && ~isempty(results.rank.trans)
    rt = results.rank.trans; % expected 305x4 table or cell
    % names in column 1, scores in column 2
    if istable(rt)
        rt_names = rt{:,1};
        rt_scores = rt{:,2};
    else
        rt_names = rt(:,1);
        rt_scores = cell2mat(rt(:,2));
    end
    % normalize to string array for robust matching
    rt_names = string(rt_names);
    appTnames = string({app.T.Name}'); % column vector
    % find matching transformers and check HV_Type for 'wye' or 'auto'
    for k = 1:numel(rt_names)
        name = rt_names(k);
        if strlength(name)==0, continue; end
        idx = find(appTnames == name, 1);
        if isempty(idx), continue; end
        hv = string(app.T(idx).HV_Type);
        lv = string(app.T(idx).LV_Type);
        if (contains(lower(hv), 'wye') || contains(lower(hv), 'auto'))...
                && (contains(lower(lv), 'wye') || contains(lower(lv), 'auto'))
            transScore(idx) = rt_scores(k);
        end
    end
end

allIdx = [lineIdxAll; transIdxAll];
allScore = [lineScore; transScore];

Type = [repmat("Line", nL, 1); repmat("Trans", nTrans, 1)];

[~, orderCombo] = sort(allScore, 'descend', 'MissingPlacement', 'last');
idx_sorted_combo = allIdx(orderCombo);
Type_sorted = Type(orderCombo);  
idx_sorted.order = idx_sorted_combo;
idx_sorted.type = Type_sorted;
results = mitigateOnOrder(app,idx_sorted);
plotGICMitigationResults(results);


end