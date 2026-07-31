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
        transScore = rt{:,2};
    else
        transScore = cell2mat(rt(:,2));
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