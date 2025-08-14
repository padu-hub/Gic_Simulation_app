function [S, L, T, GIC, subLoc, nLines, nSubs, nTrans] = calc_gic_main(app, S, L, T, ex, ey, latq, lonq, tind, uniform, OriginalL, OriginalT)
% =======================================================================
% CALC_GIC_MAIN
% Computes GIC for edited and original networks and returns as struct
% =======================================================================

subLoc = reshape([S(:).Loc], 2, length(S))';
nLines = length(L);
nSubs = length(S);
nTrans = length(T);

% === Voltage Calculation ===
app.StatusTextArea.Value = [app.StatusTextArea.Value; '************************LINE VOLTAGES****************************'];
drawnow;

if ~uniform
    V = calc_line_voltage(L, latq, lonq, ex(tind,:), ey(tind,:), 'natural');
    V_original = calc_line_voltage(OriginalL, latq, lonq, ex(tind,:), ey(tind,:), 'natural');
    nTimes = size(V,1);
else
    nTimes = 1;
end
app.StatusTextArea.Value = [app.StatusTextArea.Value; '********************LINE VOLTAGES:COMPLETED************************'];

% === Network Setup for Edited and Original ===
app.StatusTextArea.Value = [app.StatusTextArea.Value; '********************NETWORK TOPOLOGY************************'];
drawnow;

[nodePairs, nodeRes, ~, edges, indices, neutralNodes, autoind, nBus] = get_nodePairs(L, T, S);
[Yn, Ye] = calc_admittance_matrices(edges, indices, nodeRes, neutralNodes, S, nBus);
indnull = find(diag(Yn) == 0);
indnotnull = find(diag(Yn) ~= 0);

[nodePairs0, nodeRes0, ~, edges0, indices0, neutralNodes0, autoind0, nBus0] = get_nodePairs(OriginalL, OriginalT, S);
[Yn0, Ye0] = calc_admittance_matrices(edges0, indices0, nodeRes0, neutralNodes0, S, nBus0);
indnull0 = find(diag(Yn0) == 0);
indnotnull0 = find(diag(Yn0) ~= 0);

% === GIC Calculation ===
app.StatusTextArea.Value = [app.StatusTextArea.Value; '***********************CALCULATING GIC*************************'];
drawnow;

GIC_Subs = zeros(nSubs, nTimes);
GIC_Lines = zeros(nLines, nTimes);
GIC_Trans = zeros(nTrans, 2, nTimes);

% Check if original GICs already exist
originalGICExists = isprop(app, 'GIC_Subs_Original') && ~isempty(app.GIC_Subs_Original);
if originalGICExists
    app.StatusTextArea.Value = [app.StatusTextArea.Value; 'Original GIC already exists. Skipping recalculation.'];
    original_GIC_Subs = app.GIC_Subs_Original;
    original_GIC_Lines = nan(length(OriginalL), nTimes);
    original_GIC_Trans = nan(length(OriginalT), 2, nTimes);
else
    original_GIC_Subs = zeros(nSubs, nTimes);
    original_GIC_Lines = zeros(length(OriginalL), nTimes);
    original_GIC_Trans = zeros(length(OriginalT), 2, nTimes);
end

milestones = [10, 25, 50, 70, 100];
loggedPercents = false(size(milestones));
tic

for i = 1:nTimes
    % === Edited Network ===
    [GIC_Subs(:, i), GIC_Lines(:, i), GIC_Trans(:,:, i)] = ...
        calc_gic(L, T, V(i,:), Yn, Ye, nodePairs, nodeRes, autoind, indices, edges, indnull, indnotnull, nBus);

    % === Original Network ===
    if ~originalGICExists
        [original_GIC_Subs(:, i), original_GIC_Lines(:, i), original_GIC_Trans(:,:, i)] = ...
            calc_gic(OriginalL, OriginalT, V_original(i,:), Yn0, Ye0, nodePairs0, nodeRes0, autoind0, indices0, edges0, indnull0, indnotnull0, nBus0);
    end

    % === Progress ===
    percentDone = round(100 * i / nTimes);
    for m = 1:length(milestones)
        if ~loggedPercents(m) && percentDone >= milestones(m)
            msg = sprintf('...%d%% complete', milestones(m));
            disp(msg);
            app.StatusTextArea.Value = [app.StatusTextArea.Value; msg];
            drawnow;
            loggedPercents(m) = true;
        end
    end
end
toc

% === Assign GICs to Network ===
[maxSub, ~] = max(abs(GIC_Subs), [], 2);
for i = 1:nLines
    L(i).GIC = GIC_Lines(i,:);
end
for i = 1:nSubs
    S(i).GIC = GIC_Subs(i,:);
    S(i).maxGIC = maxSub(i);
end

if ~originalGICExists
    maxSub0 = max(abs(original_GIC_Subs), [], 2);
    for i = 1:length(OriginalL)
        OriginalL(i).GIC = original_GIC_Lines(i,:);
    end
    for i = 1:nSubs
        S(i).GIC_Original = original_GIC_Subs(i,:);
        S(i).maxGIC_Original = maxSub0(i);
    end
end

% === Package all GIC data into struct ===
GIC = struct();
GIC.Subs           = GIC_Subs;
GIC.Lines          = GIC_Lines;
GIC.Trans          = GIC_Trans;
GIC.Original_Subs  = original_GIC_Subs;
GIC.Original_Lines = original_GIC_Lines;
GIC.Original_Trans = original_GIC_Trans;

app.StatusTextArea.Value = [app.StatusTextArea.Value; '*******************COMPLETED: GIC***************************'];
drawnow;

fprintf(['Node #1       tap       Series (W1)       Node #2\n' ...
         'LV bus o------------.--------{}{}{}{}{}--------o HV bus\n' ...
         '                    |\n' ...
         '                    {}\n' ...
         '                    {}\n' ...
         '                    {}  Common (W2)\n' ...
         '                    {}\n' ...
         '                    |\n' ...
         '                    |               ___\n' ...           
         '          Node #3   o--------------- _   Ground point\n' ...
         '                                     . \n\n\n']);
end
