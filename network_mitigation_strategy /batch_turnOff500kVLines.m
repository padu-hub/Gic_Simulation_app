function Tadd = batch_turnOff500kVLines(app, Sbase, Tbase, tidx)
% For each 500 kV line, open it (ResKm/Resistance = NaN), run, store.

rows = []; simID = height(app.MitigationResults) + 1;

is500 = arrayfun(@(x) isfield(x,'Voltage') && x.Voltage==500, app.L);
idx500 = find(is500);

for i = idx500(:)'
    resetAllNetwork(app);

    % Open line i
    app.L(i).ResKm     = NaN;
    app.L(i).Resistance= NaN;

    % Run edited
    [S1, ~, T1, ~] = runGIC_now(app);

    % Per-substation averages (rows)
    for sid = 1:numel(app.S)
        tri = find([app.T.Sub]==sid);
        if isempty(tri), continue; end

        g0_sub_avg = mean( arrayfun(@(ii) meanAbs_overWin(Tbase(ii).GIC, tidx), tri), 'omitnan');
        g1_sub_avg = mean( arrayfun(@(ii) meanAbs_overWin(T1(ii).GIC,    tidx), tri), 'omitnan');

        g0_sub_max = mean( arrayfun(@(ii) maxAbs_overWin (Tbase(ii).GIC, tidx), tri), 'omitnan');
        g1_sub_max = mean( arrayfun(@(ii) maxAbs_overWin (T1(ii).GIC,    tidx), tri), 'omitnan');

        pctMax = pctChange(g0_sub_max, g1_sub_max);
        dAvg   = g1_sub_avg - g0_sub_avg;

        rows(end+1) = makeRowNB(simID, 'LINE_OFF_500kV', app.L(i).Name, i, ...  %#ok<AGROW>
                                'substation', app.S(sid).Name, sid, ...
                                g0_sub_avg, g1_sub_avg, dAvg, pctMax);
    end

    simID = simID + 1;
end

Tadd = rows2table(rows);

    function p = pctChange(max0, max1)
        if max0>0, p = 100*(max1 - max0)/max0; else, p = NaN; end
    end
end
