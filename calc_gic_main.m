function [S, L, T, GIC, subLoc, nLines, nSubs, nTrans] = calc_gic_main(app, S, L, T, ex, ey, latq, lonq, tind, OriginalL, OriginalT)
% CALC_GIC_MAIN  —  Computes GIC for edited and original networks.
% Skips edited GIC if network has not changed. If sandBoxMode is true,
% original GIC calculations are skipped entirely.

sandBoxMode  = app.sandBoxMode;
theta        = app.theta;
uniform      = app.uniform;
subLoc       = reshape([S(:).Loc], 2, length(S))';
nLines       = length(L);
nSubs        = length(S);
nTrans       = length(T);


% Determine whether cached originals are present
hasCachedOriginalS = isprop(app, 'gic_originalS') && ~isempty(app.gic_originalS);
hasCachedOriginalL = isprop(app, 'gic_originalL') && ~isempty(app.gic_originalL);
hasCachedOriginalT = isprop(app, 'gic_originalT') && ~isempty(app.gic_originalT);

% Helper: must compute originals (only when not in sandbox AND no cached originals)
mustComputeOriginal = ~sandBoxMode && ~(hasCachedOriginalS && hasCachedOriginalL && hasCachedOriginalT);

%% === Voltage Calculation ===
appendStatus(app, '************************LINE VOLTAGES****************************');
tic;

editedChanged = isNetworkChanged(app, L, T, OriginalL, OriginalT);

if uniform
    nTimes = 1;
elseif sandBoxMode
    nTimes = length(theta);
else
    % Only compute original voltages if not in sandbox (we will skip original GIC if in sandbox)
    V_original = calc_line_voltage(OriginalL, latq, lonq, ex(tind,:), ey(tind,:), 'natural');

    if editedChanged
        V = calc_line_voltage(L, latq, lonq, ex(tind,:), ey(tind,:), 'natural');
    else
        V = [];
    end
    % Use nTimes from original if available, otherwise from edited if available, else 1
    if ~isempty(V_original)
        nTimes = size(V_original, 1);
    elseif ~isempty(V)
        nTimes = size(V, 1);
    else
        nTimes = 1;
    end
end
appendStatus(app, '********************LINE VOLTAGES: COMPLETED************************');

%% === Network Topology ===
appendStatus(app, '********************NETWORK TOPOLOGY************************');

% Build original topology only when not in sandbox and when needed
if ~sandBoxMode
    [nodePairs0, nodeRes0, ~, edges0, indices0, neutralNodes0, autoind0, nBus0] = get_nodePairs(OriginalL, OriginalT, S);
    [Yn0, Ye0] = calc_admittance_matrices(edges0, indices0, nodeRes0, neutralNodes0, S, nBus0);
    indnull0    = find(diag(Yn0) == 0);
    indnotnull0 = find(diag(Yn0) ~= 0);
else
    % Placeholders to keep downstream calls safe if they are incorrectly invoked
    nodePairs0 = []; nodeRes0 = []; edges0 = []; indices0 = []; neutralNodes0 = []; autoind0 = []; nBus0 = 0;
    Yn0 = []; Ye0 = []; indnull0 = []; indnotnull0 = [];
end

% Edited topology (compute when edited changed OR when in sandbox we still might need edited)
if editedChanged||sandBoxMode
    [nodePairs, nodeRes, ~, edges, indices, neutralNodes, autoind, nBus] = get_nodePairs(L, T, S);
    [Yn, Ye] = calc_admittance_matrices(edges, indices, nodeRes, neutralNodes, S, nBus);
    indnull    = find(diag(Yn) == 0);
    indnotnull = find(diag(Yn) ~= 0);
else
    nodePairs = []; nodeRes = []; edges = []; indices = []; neutralNodes = []; autoind = []; nBus = 0;
    Yn = []; Ye = []; indnull = []; indnotnull = [];
end

%% === Initialise GIC Containers ===
appendStatus(app, '***********************CALCULATING GIC*************************');

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

    % Original GIC: only compute when mustComputeOriginal is true. If cached, use cached.
    if mustComputeOriginal
        [original_GIC_Subs, original_GIC_Lines, original_GIC_Trans] = ...
            calc_gic(OriginalL, OriginalT, Vu, Yn0, Ye0, ...
                nodePairs0, nodeRes0, autoind0, indices0, edges0, ...
                indnull0, indnotnull0, nBus0);
    elseif hasCachedOriginalS || hasCachedOriginalL || hasCachedOriginalT
        % Use cached originals where present; otherwise keep zeros
        if hasCachedOriginalS, original_GIC_Subs = app.gic_originalS; end
        if hasCachedOriginalL, original_GIC_Lines = app.gic_originalL; end
        if hasCachedOriginalT, original_GIC_Trans = app.gic_originalT; end
    end

    % Edited GIC (containers remain NaN if unchanged)
    if editedChanged || sandBoxMode
        [GIC_Subs, GIC_Lines, GIC_Trans] = ...
            calc_gic(L, T, Vu, Yn, Ye, nodePairs, nodeRes, autoind, indices, edges, ...
            indnull, indnotnull, nBus);
    end
    Emf = Vu;
elseif sandBoxMode
    for i = 1:nTimes
    
        Ex = ex*cosd(theta(i));
        Ey = ex*sind(theta(i));
    
        V(i,:) = ...
            calc_line_voltage_uniform( ...
            Ex,Ey,L,S);
        [GIC_Subs(:,i), GIC_Lines(:,i), GIC_Trans(:,:,i)] = ...
        calc_gic(L, T, V(i,:), Yn, Ye, nodePairs, nodeRes, autoind, ...
        indices, edges, indnull, indnotnull, nBus);
    end
    Emf = V;
else
    milestoneThresh = [10 25 50 70 100];
    milestoneIdx    = unique(max(1, round(milestoneThresh / 100 * nTimes)));

    for i = 1:nTimes
        % Original GIC: compute only when mustComputeOriginal
        if mustComputeOriginal
            [original_GIC_Subs(:,i), original_GIC_Lines(:,i), original_GIC_Trans(:,:,i)] = ...
                calc_gic(OriginalL, OriginalT, V_original(i,:), Yn0, Ye0, ...
                nodePairs0, nodeRes0, autoind0, indices0, edges0, ...
                indnull0, indnotnull0, nBus0);
        elseif hasCachedOriginalS || hasCachedOriginalL || hasCachedOriginalT
            if hasCachedOriginalS, original_GIC_Subs(:,i)    = app.gic_originalS(:,i); end
            if hasCachedOriginalL, original_GIC_Lines(:,i)   = app.gic_originalL(:,i); end
            if hasCachedOriginalT, original_GIC_Trans(:,:,i) = app.gic_originalT(:,:,i); end            
        end

        % Edited GIC (containers remain NaN if unchanged)
        if editedChanged
            [GIC_Subs(:,i), GIC_Lines(:,i), GIC_Trans(:,:,i)] = ...
                calc_gic(L, T, V(i,:), Yn, Ye, nodePairs, nodeRes, autoind, ...
                indices, edges, indnull, indnotnull, nBus);
        end

        if ismember(i, milestoneIdx)
            pct = round(100 * i / nTimes);
            appendStatus(app, sprintf('...%d%% complete', pct));
        end
    end
    Emf = V;
end

elapsedTime = toc;
appendStatus(app, sprintf('Elapsed time: %.2f seconds', elapsedTime));

%% === Assign GICs back to network structs (vectorised) ===
maxSub  = max(abs(GIC_Subs),          [], 2);
maxSub0 = max(abs(original_GIC_Subs), [], 2);

L_GIC_cells             = num2cell(GIC_Lines, 2);
S_GIC_cells             = num2cell(GIC_Subs, 2);
S_maxGIC_cells          = num2cell(maxSub);
S_GIC_Original_cells    = num2cell(original_GIC_Subs, 2);
S_maxGIC_Original_cells = num2cell(maxSub0);
OriginalL_GIC_cells     = num2cell(original_GIC_Lines, 2);

[L.GIC]             = L_GIC_cells{:};
[S.GIC]             = S_GIC_cells{:};
[S.maxGIC]          = S_maxGIC_cells{:};
[S.GIC_Original]    = S_GIC_Original_cells{:};
[S.maxGIC_Original] = S_maxGIC_Original_cells{:};
[OriginalL.GIC]     = OriginalL_GIC_cells{:};

%% === Cache originals & package output ===
% Only cache when originals were actually computed (avoid overwriting cached data in sandbox)
if mustComputeOriginal
    app.gic_originalS = original_GIC_Subs;
    app.gic_originalL = original_GIC_Lines;
    app.gic_originalT = original_GIC_Trans;
end

GIC = struct( ...
    'Subs',          GIC_Subs,          ...
    'Lines',         GIC_Lines,         ...
    'Trans',         GIC_Trans,         ...
    'Original_Subs', original_GIC_Subs, ...
    'Original_Lines',original_GIC_Lines,...
    'Original_Trans',original_GIC_Trans,...
    'Emf'           ,Emf);

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
    ~isequal(extractNetwork(T),  extractNetwork(T0)) || ...
    ~isequal(app.b_original, app.b_cleaned);
end

function out = extractNetwork(s)
dropFields = {'GIC','maxGIC','GIC_Original','maxGIC_Original'};
existing   = dropFields(isfield(s, dropFields));
out        = rmfield(s, existing);
end
