function PlotGraphButtonPushed(app)
% Build an external heatmap figure:
%   X = change index (SimID)
%   Y = EntityName (subs & transformers)
%   Z = Avg Δ|GIC| (A)
% Filters:
%   keep if (abs(Avg Δ|GIC|) >= AbsThresholdA)
%   AND (Max % change ≥ ThresholdPct)

try
    app.PlotLamp.Color = [1 0.6 0]; % amber

    T = app.MitigationResults;
    if isempty(T), app.PlotLamp.Color=[0.8 0 0]; return; end

    pctThr = app.ThresholdPctEdit.Value;
    absThr = app.AbsThresholdAEdit.Value;

    % ============================================================
    % SAFE NUMERIC EXTRACTION (REPLACES cell2mat)
    % ============================================================
    toNum = @(x) ( ...
        (isnumeric(x) * double(x)) + ...
        (~isnumeric(x) * str2double(string(x))) );

    % Convert T columns into NUMERIC ARRAYS safely
    %avgDelta = arrayfun(@(x) toNum(T.AvgDeltaAbs_A{x}), 1:height(T))';
    %maxGIC   = arrayfun(@(x) toNum(T.MaxGICChange{x}), 1:height(T))';
    pctChange = arrayfun(@(x) toNum(T.MaxPctChange{x}), 1:height(T))';

    % ============================================================
    % FIRST HEATMAP — Avg Δ|GIC|
    % ============================================================

    keep = abs(avgDelta) >= absThr;

    T2 = T(keep, :);
    if isempty(T2)
        figure; text(0.1,0.5,'No entries pass thresholds'); axis off;
        app.PlotLamp.Color=[0 0.7 0];
        return;
    end

    entities = unique(T2.EntityName, 'stable');
    sims     = unique(T2.TargetName, 'stable');

    Z = nan(numel(entities), numel(sims));

    for r = 1:numel(entities)
        for c = 1:numel(sims)
            mask = (T2.EntityName == entities(r)) & (T2.TargetName == sims(c));
            Z(r,c) = mean(avgDelta(keep & mask), 'omitnan');
        end
    end

    fig = figure('Name','Mitigation Heatmap','Color','w');
    h = heatmap(fig, sims, entities, Z);
    h.Title   = 'Average Δ|GIC| (A) — filtered';
    h.Title = {h.Title; 'blue (improve, negative) → white → red (worse, positive)'};
    h.XLabel  = 'Change index (SimID)';
    h.YLabel  = 'Entity';

    clim = max(abs(Z),[],'all','omitnan'); if isempty(clim)||isnan(clim), clim=1; end
    h.ColorLimits = [-clim clim];
    h.Colormap = bluewhitered();

    % ============================================================
    % SECOND HEATMAP — Max GIC Change
    % ============================================================

    keep2 = (abs(maxGIC) >= absThr) & (pctChange >= pctThr);
    T3 = T(keep2, :);

    if isempty(T3)
        figure; text(0.1,0.5,'No entries pass thresholds'); axis off;
        app.PlotLamp.Color=[0 0.7 0];
        return;
    end

    entities = unique(T3.EntityName, 'stable');
    sims     = unique(T3.TargetName, 'stable');

    Z_max = nan(numel(entities), numel(sims));

    for r = 1:numel(entities)
        for c = 1:numel(sims)
            mask = (T3.EntityName == entities(r)) & (T3.TargetName == sims(c));
            Z_max(r,c) = max(maxGIC(keep2 & mask), [], 'omitnan');
        end
    end

    fig2 = figure('Name','Max Absolute Change Heatmap','Color','w');
    h2 = heatmap(fig2, sims, entities, Z_max);
    h2.Title   = 'Max Absolute Change — filtered';
    h2.Title = {h2.Title; 'blue (improve, negative) → white → red (worse, positive)'};
    h2.XLabel  = 'Change index (SimID)';
    h2.YLabel  = 'Entity';

    clim_max = max(abs(Z_max),[],'all','omitnan');
    if isempty(clim_max)||isnan(clim_max), clim_max = 1; end
    h2.ColorLimits = [-clim_max clim_max];
    h2.Colormap = bluewhitered();

    app.PlotLamp.Color = [0 0.7 0]; % green

catch ME
    app.PlotLamp.Color = [0.8 0 0]; % red
    rethrow(ME)
end
end


function cmap = bluewhitered()
    n = 256;
    r = [(0:n/2-1)/(n/2), ones(1,n/2)];
    b = [ones(1,n/2), (n/2-1:-1:0)/(n/2)];
    g = 0.5*(r + b);
    cmap = [r(:) g(:) b(:)];
end
