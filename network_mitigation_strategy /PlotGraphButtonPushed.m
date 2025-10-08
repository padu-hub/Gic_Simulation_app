function PlotGraphButtonPushed(app)
% Build an external heatmap figure:
% X = change index (SimID), Y = EntityName (subs & xfmrs), Z = Avg Δ|GIC| (A)
% Filters:
%   keep if (abs(Avg Δ|GIC|) >= AbsThresholdA) AND (Max % change ≥ ThresholdPct)

try
    app.PlotLamp.Color = [1 0.6 0]; % amber

    T = app.MitigationResults;
    if isempty(T), app.PlotLamp.Color=[0.8 0 0]; return; end

    pctThr = app.ThresholdPctEdit.Value;   % e.g., 30
    absThr = app.AbsThresholdAEdit.Value;  % e.g., 3

    keep = abs(T.AvgDeltaAbs_A) >= absThr & (T.MaxPctChange >= pctThr);
    T2 = T(keep, :);
    if isempty(T2), figure; text(0.1,0.5,'No entries pass thresholds'); axis off; app.PlotLamp.Color=[0 0.7 0]; return; end

    entities = unique(T2.EntityName, 'stable');
    sims     = unique(T2.SimID, 'stable');
    Z = nan(numel(entities), numel(sims));

    for r = 1:numel(entities)
        for c = 1:numel(sims)
            mask = (T2.EntityName==entities(r)) & (T2.SimID==sims(c));
            Z(r,c) = mean(T2.AvgDeltaAbs_A(mask), 'omitnan');  % average Δ over any duplicate rows
        end
    end

    % External figure
    fig = figure('Name','Mitigation Heatmap','Color','w');
    h = heatmap(fig, sims, entities, Z);
    h.Title   = 'Average Δ|GIC| (A)  — filtered';
    h.XLabel  = 'Change index (SimID)';
    h.YLabel  = 'Entity';
    % Diverging colormap: blue (improve, negative) → white → red (worse, positive)
    clim = max(abs(Z),[],'all','omitnan'); 
    if isempty(clim) || isnan(clim), clim=1; end
    h.ColorLimits = [-clim clim];
    h.Colormap = bluewhitered();

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
