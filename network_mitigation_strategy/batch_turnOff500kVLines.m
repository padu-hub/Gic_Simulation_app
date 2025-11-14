function batch_turnOff500kVLines(app, GICbase)
% BATCH_TURNOFF500KVLINES
% ----------------------------------------------------------
% For each 500 kV line:
%   1) Reset to OriginalL/OriginalT (isolated trial).
%   2) "Open" that line by setting ResKm/Resistance = NaN.
%   3) Run GIC (GIC1).
%   4) For every substation, compute:
%        - Avg |GIC| over full simulation (baseline vs edited)
%        - Max |GIC| over full simulation (baseline vs edited)
%        - Z metric: AvgΔ|GIC| = avg|edit| - avg|orig|
%        - % metric: safe percent change of max |GIC|
%   5) Append one row per substation.
%
% INPUTS
%   app      : your App Designer handle (must have L/T/OriginalL/OriginalT/S, etc.)
%   GICbase  : baseline GIC struct from a run on OriginalL/OriginalT
%              - GICbase.Subs : [nSubs x nTime]
%
% OUTPUT
%   Tadd     : table of rows to append into app.MitigationResults
% ----------------------------------------------------------
    tic
    % ---------- small numeric helpers ----------
    meanAbs   = @(x) mean(abs(x), 'all', 'omitnan');    % avg |.| over full window
    maxAbs    = @(x)  max(abs(x), [], 'all', 'omitnan');% max |.| over full window

    % ---------- init row container as struct array----------
    rows = struct('SimID', [], 'ActionType', "", 'TargetName', "", 'TargetID', [], ...
             'Level', "", 'EntityName', "", 'EntityID', [], ...
             'AvgDeltaAbs_A', [], 'MaxGicChange', [], 'MaxPctChange', [], ...
             'AvgAbs_Orig_GIC', [], 'AvgAbs_Edit_GIC', [], ...
             'Max_Orig_GIC', [], 'Max_Edit_GIC', []);
    Tadd = table();
    % Next simulation index for heatmap X-axis
    simID = height(app.MitigationResults) + 1;

    % ---------- find candidate lines (exact 500 kV; change to >=500 if desired) ----------
    is500  = arrayfun(@(x) isfield(x,'Voltage') && x.Voltage == 500, app.L);
    idx500 = find(is500);

    nSubs = size(GICbase.Subs, 1);


    for i = idx500(:).'  % each line = one scenario
        % -- 1) Reset to pristine network for an isolated what-if
        resetAllNetwork(app);  % must restore app.L/app.T from app.OriginalL/app.OriginalT

        % -- 2) Open THIS line (your app's defined "off" semantics)
        app.L(i).ResKm      = NaN;
        app.L(i).Resistance = NaN;

        % -- 3) Run edited network (returns GIC1.* arrays)
        [~, ~, ~, GIC] = runGIC_now(app);

        % -- 4) Substation metrics over full time (one row per sub)
        for sid = 1:nSubs
            % Baseline vs Edited
            g0_sub_avg = meanAbs(GIC.Original_Subs(sid, :));
            g1_sub_avg = meanAbs(GIC.Subs(  sid, :));
            g0_sub_max =  maxAbs(GIC.Original_Subs(sid, :));
            g1_sub_max =  maxAbs(GIC.Subs(  sid, :));

            % % change of the max |GIC| with protected zero handling
            pctMax = pctChange_safe(g0_sub_max, g1_sub_max, 1e-9, 100);

            % Append row (uses your existing makeRowNB factory)
            rows(end+1) = makeRowNB(simID, 'Double Line OFF', app.L(i).Name, i, ... 
                                     'substation', app.S(sid).Name, sid, ...
                                     g0_sub_avg, g1_sub_avg, g0_sub_max,g1_sub_max, pctMax);
        end

        % -- 5) Next scenario column
        simID = simID + 1;
        % ---------- convert to table ----------
        if isempty(rows)
            Tadd = table();
        else
            Tadd = struct2table(rows);
        end
        updateTable(app, Tadd)
    end
    toc
    elapsedTime = toc; % Get the elapsed time from the previous tic
    app.StatusTextArea.Value = [app.StatusTextArea.Value; sprintf('Total time turning  of HV Lines: %.2f seconds', elapsedTime)];
    drawnow;
end
