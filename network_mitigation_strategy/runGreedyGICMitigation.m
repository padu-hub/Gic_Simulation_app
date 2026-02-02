function results = runGreedyGICMitigation(app, GICbase, modeStr)
% RUNGREEDYGICMITIGATION
% ========================================================================
% PURPOSE:
%   Runs a greedy mitigation loop to reduce GIC in the network using one of
%   three selectable modes. At each step, the algorithm:
%       1. Identifies which mitigation actions are allowed in the mode.
%       2. Evaluates the severity (max |GIC|) on all eligible components.
%       3. Picks the SINGLE worst element (line or winding).
%       4. Applies the correct mitigation (turn line off or block winding).
%       5. Re-simulates the GIC with the updated network.
%       6. Stores GIC metrics for plotting.
%
% MODES:
%   1) 'original'
%       - Turn OFF parallel lines ONLY (must leave ≥1 alive in each group)
%       - Apply neutral blocker ONLY to autotransformer W2
%
%   2) 'windings_only'
%       - Do NOT turn off any lines
%       - Apply neutral blocker to ANY transformer winding that is
%         wye-grounded (W1 or W2)
%
%   3) 'all_lines'
%       - Turn OFF ANY line (no parallel logic required)
%       - Do NOT apply any neutral blockers
%
% NOTES:
%   - The algorithm stops when no further valid mitigation is possible.
%   - Baseline (0 mitigations) is stored as step 1 in results arrays.
%   - Uses helper functions:
%         buildParallelGroups
%         getWyeGroundedWindings
%         selectWorstGICElement
%         applyMitigationToNetwork
%         plotGICMitigationResults
%
% INPUTS:
%   app      - App object containing L (lines), T (transformers), and
%              runGIC_now(app) for simulation.
%   GICbase  - Baseline GIC struct BEFORE mitigation.
%   modeStr  - 'original', 'windings_only', or 'all_lines'
%
% OUTPUT:
%   results - Struct containing:
%       sumGICSubs     -> total substation GIC per step
%       maxTransGIC    -> max transformer GIC per step
%       mitigations    -> description for each step
%       lineOpen       -> bool array tracking opened lines
%       windingBlocked -> bool array tracking blocked windings
%       parallelGroups -> parallel line groups (Mode 1 only)
%       modeStr        -> echo of selected mode
%
% ========================================================================

GICbase.Subs = GICbase.Original_Subs;
GICbase.Lines = GICbase.Original_Lines;
GICbase.Trans = GICbase.Original_Trans;
%% --------------------------------------------------
%  1. NORMALIZE MODE AND SET MODE FLAGS
% ---------------------------------------------------
modeStr = lower(strtrim(modeStr));

switch modeStr

    case 'original'
        % Mode 1: parallel line switching + auto W2 blockers only
        activeLineMitigation    = true;
        activeWindingMitigation = true;
        lineMode    = 'parallel';
        windingMode = 'autoW2';

    case 'windings_only'
        % Mode 2: only apply neutral blockers on any wye winding
        activeLineMitigation    = false;
        activeWindingMitigation = true;
        lineMode    = '';
        windingMode = 'allWye';

    case 'all_lines'
        % Mode 3: only turn off any line, no blockers at all
        activeLineMitigation    = true;
        activeWindingMitigation = false;
        lineMode    = 'allLines';
        windingMode = '';

    otherwise
        error('Invalid modeStr: %s. Must be original, windings_only, or all_lines.', modeStr);
end


%% --------------------------------------------------
%  2. INITIALIZE BASIC NETWORK INFO
% ---------------------------------------------------
nLines = numel(app.L);
nTrans = numel(app.T);

% Build parallel groups (only needed in Mode 1)
if strcmp(lineMode,'parallel')
    parallelGroups = buildParallelGroups(app.L);
else
    parallelGroups = {}; % unused
end

% Identify autotransformers for Mode 1 auto-winding blocking
isAuto = arrayfun(@(t) ...
    (isfield(t,'HV_Type') && strcmpi(t.HV_Type,'auto')) || ...
    (isfield(t,'LV_Type') && strcmpi(t.LV_Type,'auto')), ...
    app.T);

% Identify wye-grounded windings for Mode 2
windingIsWye = getWyeGroundedWindings(app.T);

% State trackers
lineOpen       = false(nLines,1);     % true = line has been opened
windingBlocked = false(nTrans,2);     % true = that winding has been blocked


%% --------------------------------------------------
%  3. STORAGE FOR RESULTS
% ---------------------------------------------------
sumGICSubs  = [];   % total substation GIC per step
maxTransGIC = [];   % max transformer GIC per step
mitigations = {};   % description log


%% --------------------------------------------------
%  4. BASELINE METRICS BEFORE ANY MITIGATION
% ---------------------------------------------------
subsAbs  = abs(GICbase.Subs);
totPerT  = sum(subsAbs,1,'omitnan');
sum0     = max(totPerT);

if isfield(GICbase,'Trans')
    transAbs = abs(GICbase.Trans);
    maxT0    = max(transAbs,[],'all','omitnan');
else
    maxT0 = 0;
end

sumGICSubs(1)  = sum0;
maxTransGIC(1) = maxT0;
mitigations{1} = '0: Baseline (no mitigation applied)';

fprintf('Baseline: TotalGIC = %.2f, MaxTrans = %.2f\n', sum0, maxT0);

% Current GIC state in loop
GIC_current = GICbase;
step = 1;    % number of mitigations applied


%% --------------------------------------------------
%  5. MAIN GREEDY MITIGATION LOOP
% ---------------------------------------------------
while true

    %% --------------------------------------------------
    %  BUILD CANDIDATE LINE SET (depending on mode)
    % ---------------------------------------------------
    if activeLineMitigation

        switch lineMode

            case 'parallel'
                % Only lines in parallel groups; must keep >=1 alive
                candLines = [];
                for g = 1:numel(parallelGroups)
                    grp = parallelGroups{g};
                    alive = grp(~lineOpen(grp));
                    if numel(alive) >= 2
                        candLines = [candLines; alive(:)];
                    end
                end
                candLines = unique(candLines);

            case 'allLines'
                % Every unopened line is a candidate
                candLines = find(~lineOpen);

            otherwise
                candLines = [];
        end

    else
        candLines = [];
    end


    %% --------------------------------------------------
    %  BUILD CANDIDATE WINDING SET (depending on mode)
    % ---------------------------------------------------
    if activeWindingMitigation

        switch windingMode

            case 'autoW2'
                candWind = [];
                for k = 1:nTrans
                    if isAuto(k) && ~windingBlocked(k,2)
                        candWind(end+1,:) = [k 2];
                    end
                end

            case 'allWye'
                candWind = [];
                for k = 1:nTrans
                    for w = 1:2
                        if windingIsWye(k,w) && ~windingBlocked(k,w)
                            candWind(end+1,:) = [k w];
                        end
                    end
                end

            otherwise
                candWind = [];
        end

    else
        candWind = [];
    end


    %% --------------------------------------------------
    %  STOP CONDITIONS
    %  1) No further mitigation options available
    %  2) Total GIC at substations has reached zero
    %  which ever comes first
    % ---------------------------------------------------
    subsAbsStop  = abs(GIC_current.Subs);
    totPerTStop  = sum(subsAbsStop,1,'omitnan');
    % Compute current total GIC sum over substations (max over time)
    currentTotalGIC = max(totPerTStop);
    
    % Condition A: no remaining line or winding actions
    noMoreMitigation = isempty(candLines) && isempty(candWind);
    
    % Condition B: GIC level has reached zero
    gicIsZero = (currentTotalGIC <= 0);
    
    if noMoreMitigation || gicIsZero
        if noMoreMitigation
            fprintf('Stopping: No further mitigations available.\n');
        else
            fprintf('Stopping: GIC has reached zero.\n');
        end
        break;
    end

    %% --------------------------------------------------
    %  PICK WORST GIC ELEMENT AMONG CANDIDATES
    % ---------------------------------------------------
    [type, idx, val] = selectWorstGICElement(GIC_current, candLines, candWind);

    % Safety check
    if isempty(type) || isnan(val)
        fprintf('No valid candidate found (likely all NaN). Stopping.\n');
        break;
    end


    %% --------------------------------------------------
    %  APPLY THE MITIGATION
    % ---------------------------------------------------
    [app, lineOpen, windingBlocked, description] = ...
        applyMitigationToNetwork(app, type, idx, lineOpen, windingBlocked);

    mitigations{step+1} = description;    
    app.StatusTextArea.Value{end+1} = description;    
    drawnow;
    fprintf('%s\n', description);


    %% --------------------------------------------------
    %  RE-RUN GIC SIMULATION AFTER THE CHANGE
    % ---------------------------------------------------
    [~, ~, ~, GIC_current] = runGIC_now(app);


    %% --------------------------------------------------
    %  COMPUTE METRICS FOR THIS STEP 
    % ---------------------------------------------------
    subsAbs  = abs(GIC_current.Subs);
    totPerT  = sum(subsAbs,1,'omitnan');
    sumN     = max(totPerT);

    if isfield(GIC_current,'Trans')
        transAbs = abs(GIC_current.Trans);
        maxTN    = max(transAbs,[],'all','omitnan');
    else
        maxTN = 0;
    end

    if isfield(GIC_current,'Lines')
        linesAbs = abs(GIC_current.Lines);
        maxLN    = max(linesAbs,[],'all','omitnan');
    else
        maxLN = 0;
    end



    sumGICSubs(step+1)  = sumN;
    maxTransGIC(step+1) = maxTN;
    maxLinesGIC(step+1) = maxLN;

    fprintf('Step %d → TotalGIC = %.2f, MaxTrans = %.2f\n\n', step, sumN, maxTN);

    step = step + 1;
end


%% --------------------------------------------------
%  PACKAGE RESULTS
% ---------------------------------------------------
results.sumGICSubs     = sumGICSubs;
results.maxTransGIC    = maxTransGIC;
results.maxLinesGIC    = maxLinesGIC;
results.mitigations    = mitigations;
results.lineOpen       = lineOpen;
results.windingBlocked = windingBlocked;
results.parallelGroups = parallelGroups;
results.modeStr        = modeStr;

% Save results to a .mat file
save('mitigation_results.mat', 'mitigations', 'sumGICSubs', 'maxTransGIC', 'maxLinesGIC');

%% --------------------------------------------------
%  AUTO-PLOT RESULTS
% ---------------------------------------------------
plotGICMitigationResults(results);

end
