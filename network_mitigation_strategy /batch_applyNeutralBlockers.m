function Tadd = batch_applyNeutralBlockers(app, Sbase, Tbase, tidx)
% Build rows for: set W2=NaN on each AUTO transformer individually.

rows = []; simID = height(app.MitigationResults) + 1; % change index starts after existing

% Detect autos by type strings (HV_Type/LV_Type)
isAuto = arrayfun(@(t) strcmpi(t.HV_Type,'auto') || strcmpi(t.LV_Type,'auto'), app.T);

for k = find(isAuto)
    % --- Reset network
    resetAllNetwork(app);
    % --- Apply NB (neutral blocker) to THIS transformer only
    app.T(k).W2 = NaN;

    % --- Run edited
    [S1, ~, T1, ~] = runGIC_now(app);

    % --- Per-transformer metric (neutral current magnitude proxy)
    % If you store a specific winding-neutral series, point directly to it.
    g0_tr_avg = meanAbs_overWin(Tbase(k).GIC, tidx);
    g1_tr_avg = meanAbs_overWin(T1(k).GIC,    tidx);
    g0_tr_max = maxAbs_overWin (Tbase(k).GIC, tidx);
    g1_tr_max = maxAbs_overWin (T1(k).GIC,    tidx);

    pctMax = pctChange(g0_tr_max, g1_tr_max);      % helper below
    dAvg   = g1_tr_avg - g0_tr_avg;                % Avg Δ|GIC| = |edit|avg - |orig|avg

    rows(end+1) = makeRowNB(simID, 'NB_W2_OFF', app.T(k).Name, k, ...   %#ok<AGROW>
                            'transformer', app.T(k).Name, k, ...
                            g0_tr_avg, g1_tr_avg, dAvg, pctMax);

    % --- Per-substation metric (avg of its transformers over window)
    sid = app.T(k).Sub;             % <-- you said: T(k).Sub maps to substation ID
    tri = find([app.T.Sub] == sid); % all xfmrs at this sub
    g0_sub_avg = mean( arrayfun(@(ii) meanAbs_overWin(Tbase(ii).GIC, tidx), tri), 'omitnan');
    g1_sub_avg = mean( arrayfun(@(ii) meanAbs_overWin(T1(ii).GIC,    tidx), tri), 'omitnan');

    g0_sub_max = mean( arrayfun(@(ii) maxAbs_overWin (Tbase(ii).GIC, tidx), tri), 'omitnan');
    g1_sub_max = mean( arrayfun(@(ii) maxAbs_overWin (T1(ii).GIC,    tidx), tri), 'omitnan');

    pctMax_sub = pctChange(g0_sub_max, g1_sub_max);
    dAvg_sub   = g1_sub_avg - g0_sub_avg;

    rows(end+1) = makeRowNB(simID, 'NB_W2_OFF', app.T(k).Name, k, ...   %#ok<AGROW>
                            'substation', app.S(sid).Name, sid, ...
                            g0_sub_avg, g1_sub_avg, dAvg_sub, pctMax_sub);

    simID = simID + 1; % each change is a new column in heatmap
end

Tadd = rows2table(rows);

    function p = pctChange(max0, max1)
        if max0>0, p = 100*(max1 - max0)/max0; else, p = NaN; end
    end
end
