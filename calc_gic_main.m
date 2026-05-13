function [S, L, T, GIC, subLoc, nLines, nSubs, nTrans] = calc_gic_main(app, S, L, T, ex, ey, latq, lonq, tind, OriginalL, OriginalT)
% =======================================================================
% CALC_GIC_MAIN  —  Computes GIC for edited and original networks.
% Skips edited GIC if network has not changed.
% =======================================================================

uniform      = app.uniform;
subLoc       = reshape([S(:).Loc], 2, length(S))';
nLines       = length(L);
nSubs        = length(S);
nTrans       = length(T);

% Initialise gic_original* fields in app startup to [] so isprop is never needed
needOriginal = isempty(app.gic_originalS) || ...
    isempty(app.gic_originalL) || ...
    isempty(app.gic_originalT);

%% === Voltage Calculation ===
appendStatus(app, '************************LINE VOLTAGES****************************');
tic;

editedChanged = isNetworkChanged(app, L, T, OriginalL, OriginalT);

if uniform
    nTimes = 1;
else
    V_original = calc_line_voltage(OriginalL, latq, lonq, ex(tind,:), ey(tind,:), 'natural');
    if editedChanged
        V = calc_line_voltage(L, latq, lonq, ex(tind,:), ey(tind,:), 'natural');
    else
        V = [];
    end
    nTimes = size(V_original, 1);
end
appendStatus(app, '********************LINE VOLTAGES: COMPLETED************************');

%% === Network Topology ===
appendStatus(app, '********************NETWORK TOPOLOGY************************');

[nodePairs0, nodeRes0, ~, edges0, indices0, neutralNodes0, autoind0, nBus0] = get_nodePairs(OriginalL, OriginalT, S);
[Yn0, Ye0] = calc_admittance_matrices(edges0, indices0, nodeRes0, neutralNodes0, S, nBus0);
indnull0    = find(diag(Yn0) == 0);
indnotnull0 = find(diag(Yn0) ~= 0);

if editedChanged
    [nodePairs, nodeRes, ~, edges, indices, neutralNodes, autoind, nBus] = get_nodePairs(L, T, S);
    [Yn, Ye] = calc_admittance_matrices(edges, indices, nodeRes, neutralNodes, S, nBus);
    indnull    = find(diag(Yn) == 0);
    indnotnull = find(diag(Yn) ~= 0);
end

%% === Initialise GIC Containers ===
appendStatus(app, '***********************CALCULATING GIC*************************');

% Edited results stay NaN if network unchanged — no need to re-assign inside loop
GIC_Subs  = NaN(nSubs,          nTimes);
GIC_Lines = NaN(nLines,         nTimes);
GIC_Trans = NaN(nTrans, 2,      nTimes);

original_GIC_Subs  = zeros(nSubs,            nTimes);
original_GIC_Lines = zeros(length(OriginalL), nTimes);
original_GIC_Trans = zeros(length(OriginalT), 2, nTimes);

%% === GIC Calculation ===
if uniform
    x  = 1/sqrt(2);
    y  = -1/sqrt(2);
    Vu = calc_line_voltage_uniform(x, y, L, S);
    if needOriginal
        [original_GIC_Subs, original_GIC_Lines, original_GIC_Trans] = ...
            calc_gic(OriginalL, OriginalT, Vu, Yn0, Ye0, ...
                nodePairs0, nodeRes0, autoind0, indices0, edges0, ...
                indnull0, indnotnull0, nBus0);
    else
        original_GIC_Subs    = app.gic_originalS;
        original_GIC_Lines  = app.gic_originalL;
        original_GIC_Trans = app.gic_originalT;
    end

    % Edited GIC (containers remain NaN if unchanged)
    if editedChanged
        [GIC_Subs, GIC_Lines, GIC_Trans] = ...
            calc_gic(L, T, Vu, Yn, Ye, nodePairs, nodeRes, autoind, indices, edges, ...
            indnull, indnotnull, nBus);
    end

else
    % Pre-compute which loop indices correspond to each milestone (avoids
    % inner for-loop + round() on every iteration)
    milestoneThresh = [10 25 50 70 100];
    milestoneIdx    = unique(max(1, round(milestoneThresh / 100 * nTimes)));

    for i = 1:nTimes
        % Original GIC
        if needOriginal
            [original_GIC_Subs(:,i), original_GIC_Lines(:,i), original_GIC_Trans(:,:,i)] = ...
                calc_gic(OriginalL, OriginalT, V_original(i,:), Yn0, Ye0, ...
                nodePairs0, nodeRes0, autoind0, indices0, edges0, ...
                indnull0, indnotnull0, nBus0);
        else
            original_GIC_Subs(:,i)    = app.gic_originalS(:,i);
            original_GIC_Lines(:,i)   = app.gic_originalL(:,i);
            original_GIC_Trans(:,:,i) = app.gic_originalT(:,:,i);
        end

        % Edited GIC (containers remain NaN if unchanged)
        if editedChanged
            [GIC_Subs(:,i), GIC_Lines(:,i), GIC_Trans(:,:,i)] = ...
                calc_gic(L, T, V(i,:), Yn, Ye, nodePairs, nodeRes, autoind, ...
                indices, edges, indnull, indnotnull, nBus);
        end

        % Progress — only fires on pre-computed milestone indices
        if ismember(i, milestoneIdx)
            pct = round(100 * i / nTimes);
            appendStatus(app, sprintf('...%d%% complete', pct));
        end
    end
end

elapsedTime = toc;   % single toc matches single tic above
appendStatus(app, sprintf('Elapsed time: %.2f seconds', elapsedTime));

%% === Assign GICs back to network structs (vectorised) ===
maxSub  = max(abs(GIC_Subs),          [], 2);
maxSub0 = max(abs(original_GIC_Subs), [], 2);

% Convert each row to a cell entry first
L_GIC_cells             = num2cell(GIC_Lines, 2);
S_GIC_cells             = num2cell(GIC_Subs, 2);
S_maxGIC_cells          = num2cell(maxSub);
S_GIC_Original_cells    = num2cell(original_GIC_Subs, 2);
S_maxGIC_Original_cells = num2cell(maxSub0);
OriginalL_GIC_cells     = num2cell(original_GIC_Lines, 2);

% Assign into struct arrays
[L.GIC]             = L_GIC_cells{:};
[S.GIC]             = S_GIC_cells{:};
[S.maxGIC]          = S_maxGIC_cells{:};
[S.GIC_Original]    = S_GIC_Original_cells{:};
[S.maxGIC_Original] = S_maxGIC_Original_cells{:};
[OriginalL.GIC]     = OriginalL_GIC_cells{:};


%% === Cache originals & package output ===
app.gic_originalS = original_GIC_Subs;
app.gic_originalL = original_GIC_Lines;
app.gic_originalT = original_GIC_Trans;

GIC = struct( ...
    'Subs',          GIC_Subs,          ...
    'Lines',         GIC_Lines,         ...
    'Trans',         GIC_Trans,         ...
    'Original_Subs', original_GIC_Subs, ...
    'Original_Lines',original_GIC_Lines,...
    'Original_Trans',original_GIC_Trans);

appendStatus(app, '*******************COMPLETED: GIC***************************');

fprintf(['Node #1       tap       Series (W1)       Node #2\n' ...
    'LV bus o------------.--------{}{}{}{}{}--------o HV bus\n' ...
    '                    |\n' ...
    '                    {}  Common (W2)\n' ...
    '                    |\n' ...
    '          Node #3   o--------------- _   Ground\n\n']);
end

%% === Helpers ===
function appendStatus(app, msg)
app.StatusTextArea.Value = [app.StatusTextArea.Value; msg];
drawnow;
end

function changed = isNetworkChanged(app, L, T, L0, T0)
changed = ~isequal(extractNetwork(L),  extractNetwork(L0)) || ...
    ~isequal(extractNetwork(T),  extractNetwork(T0))||...
    ~isequal(app.b_original, app.b_cleaned);

end

function out = extractNetwork(s)
% Hard-coded field list avoids fieldnames() reflection call each time
dropFields = {'GIC','maxGIC','GIC_Original','maxGIC_Original'};
existing   = dropFields(isfield(s, dropFields));
out        = rmfield(s, existing);
end

