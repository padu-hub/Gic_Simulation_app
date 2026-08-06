function plot_alberta_directional_heat(S, Lplot, values)
% Plots smooth zero-centered diverging heat surface, transmission lines and substations.
% S: substations struct array with .Loc = [lat lon] rows (or .Loc per station)
% Lplot: line structs with .Loc = [lat lon] rows
% values: signed average per substation (same order as S)

% Substation coordinates
subLoc = reshape([S(:).Loc], 2, []).';
subLat = subLoc(:,1);
subLon = subLoc(:,2);

% Alberta bounds (small pad)
latLimFull = [49.0, 60.0]; lonLimFull = [-120.0, -110.0];
padLat = 0.02*diff(latLimFull); padLon = 0.02*diff(lonLimFull);
latLimFull = latLimFull + [-padLat padLat];
lonLimFull = lonLimFull + [-padLon padLon];

% Create regular grid (adjust res_km for smoothness)
res_km = 12;
ddeg = res_km/111;
latq = latLimFull(1):ddeg:latLimFull(2);
lonq = lonLimFull(1):ddeg:lonLimFull(2);
[LonGrid, LatGrid] = meshgrid(lonq, latq);

% Interpolate scattered signed values (natural), fill outside hull by nearest
F = scatteredInterpolant(subLon(:), subLat(:), values(:), 'natural', 'none');
Vgrid = F(LonGrid, LatGrid);
if any(isnan(Vgrid(:)))
    F2 = scatteredInterpolant(subLon(:), subLat(:), values(:), 'nearest', 'none');
    Vnan = F2(LonGrid, LatGrid);         % store full output first
    Vgrid(isnan(Vgrid)) = Vnan(isnan(Vgrid));
end

% Optional extra smoothing (uncomment to use)
% Vgrid = imgaussfilt(Vgrid, 1.5);

% Robust symmetric color limit (95th percentile)
mx = prctile(abs(values(~isnan(values))),95);
if ~isfinite(mx) || mx==0, mx = max(abs(values(:))); end
if ~isfinite(mx) || mx==0, mx = 1; end
clim = [-mx mx];

% Plot
figure;
worldmap(latLimFull, lonLimFull);
setm(gca,'FontSize',12);
hold on;

% draw shapefile (detailed geography: provinces, lakes, rivers, roads if present)
try
    S = shaperead(shapefilePath,'UseGeoCoords',true);
    geoshow(S, 'DisplayType','polygon', 'FaceColor',[0.96 0.98 0.95], 'EdgeColor',[0.7 0.7 0.7]);
end


% Plot smooth surface with slight transparency
hSurf = surfm(LatGrid, LonGrid, Vgrid);
set(hSurf, 'FaceAlpha', 0.85, 'EdgeColor', 'none');

colormap(redblue(256));
caxis(clim);
cb = colorbar;
cb.Label.String = 'Average signed GIC (A/phase)';
cb.Label.FontSize = 12;

% Plot transmission lines ON TOP (draw crisp)
% If you have an 'openIdx' logic from elsewhere, provide it; here assume none
openIdx = [];
for k = 1:numel(Lplot)
    lat = Lplot(k).Loc(:,1);
    lon = Lplot(k).Loc(:,2);
    if any(openIdx == k)
        lc = [0.5 0.5 0.5];
    else
        if isfield(Lplot(k),'Voltage') && Lplot(k).Voltage >= 400
            lc = [0 0.2 0.7];
        else
            lc = [0.8 0 0];
        end
    end
    plotm(lat, lon, '-', 'Color', lc, 'LineWidth', 1.2);
end

% Plot substations as semi-transparent small circles with black edge
sz = 30;
scatterm(subLat, subLon, sz, values, 'filled', 'MarkerEdgeColor','k', 'MarkerFaceAlpha',0.9, 'MarkerEdgeAlpha',0.8);

% Add cities for context (small markers)
cities = {
    'Edmonton',      53.5461, -113.4938;
    'Calgary',       51.0477, -114.0719;
};
for i=1:size(cities,1)
    plotm(cities{i,2}, cities{i,3}, 'ok', 'MarkerFaceColor','k','MarkerSize',4);
    textm(cities{i,2}+0.08, cities{i,3}, cities{i,1}, 'FontSize',8);
end

title('Smoothed directional GIC (signed) — Alberta');
hold off;
end
