function animate_gic_mag_panel(panelHandle, S, L, b, GIC_Subs, T, tind)
%ANIMATE_GIC_MAG_PANEL Display animated GIC and magnetic vectors on a map panel.
%
%   animate_gic_mag_panel(panelHandle, S, L, b, GIC_Subs, T, tind) creates a
%   map in the specified panel showing substations, transmission lines, and
%   magnetic observatories. The display animates over the time indices given
%   by tind, updating GIC magnitudes and magnetic vectors for each step.
%
%   Inputs:
%       panelHandle - uipanel or UIFigure container for the map axes.
%       S           - array of substation structs with field "Loc" and "Name".
%       L           - array of line structs with field "Loc" and optional
%                     "Voltage".
%       b           - magnetic data structure array with fields "lat", "lon",
%                     "site", "x", and "y".
%       GIC_Subs    - matrix of GIC values (nSubs x nTimes).
%       T           - vector of datetimes corresponding to columns of
%                     GIC_Subs and samples in b(k).x/y.
%       tind        - vector of time indices to animate over. If empty, all
%                     times are shown.
%
%   This function requires MATLAB's Mapping Toolbox.

if nargin < 7 || isempty(tind)
    tind = 1:numel(T);
end

% Substation coordinates
subLoc = reshape([S(:).Loc], 2, []).';
subLat = subLoc(:,1);
subLon = subLoc(:,2);

% Magnetometer coordinates (ensure -180..180 range)
magLat = [b(:).lat];
magLon = wrapTo180([b(:).lon]);

% Determine map limits
latLim = [min([subLat; magLat']) max([subLat; magLat'])];
lonLim = [min([subLon; magLon']) max([subLon; magLon'])];
latPad = 0.5 * diff(latLim); lonPad = 0.5 * diff(lonLim);
latLim = latLim + [-latPad latPad];
lonLim = lonLim + [-lonPad lonPad];

% Create classic axes inside the panel
ax = axes('Parent', panelHandle, 'Units', 'normalized', 'Position', [0 0 1 1]);
worldmap(ax, latLim, lonLim);
setm(ax, 'FontSize', 12);

% Background polygons
try
    provinces = shaperead('province.shp','UseGeoCoords',true);
    geoshow(ax, provinces,'DisplayType','polygon', ...
        'DefaultFaceColor',[0.9 1 0.7],'EdgeColor','black');
catch
    warning('province.shp not found. Background not shown.');
end
try
    states = shaperead('usastatehi','UseGeoCoords',true);
    geoshow(ax, states,'DisplayType','polygon', ...
        'DefaultFaceColor',[0.9 1 0.7],'EdgeColor','black');
end
hold(ax, 'on');

% Plot transmission lines
for k = 1:numel(L)
    lat = L(k).Loc(:,1);
    lon = L(k).Loc(:,2);
    if isfield(L(k),'Voltage') && L(k).Voltage >= 400
        tcolor = 'b';
    else
        tcolor = [0.3 0.3 0.3];
    end
    plotm(ax, lat, lon, '-', 'Color', tcolor, 'LineWidth', 1.5);
end

% Initial scatter and quiver objects
hSubs = scatterm(ax, subLat, subLon, 50, zeros(size(subLat)), ...
    'filled', 'MarkerEdgeColor', 'k');
cb = colorbar(ax); %#ok<*NASGU>
cb.Label.String = 'GIC (A)';

refScale = 500; % arrow scale in nT
hQuiv = gobjects(numel(b),1);
hText = gobjects(numel(b),1);
for k = 1:numel(b)
    hQuiv(k) = quivermc(magLat(k), magLon(k), 0, 0, 'color','r', ...
        'reference', refScale, 'arrowstyle','tail', 'linewidth',1.5);
    hText(k) = textm(magLat(k), magLon(k), b(k).site, 'FontSize',8, ...
        'VerticalAlignment','bottom');
end

% Animation loop
for it = reshape(tind,1,[])
    gicVals = GIC_Subs(:, it);
    set(hSubs, 'SizeData', 30 + 30*abs(gicVals), 'CData', gicVals);

    for k = 1:numel(b)
        if numel(b(k).x) >= it
            bx = b(k).x(it);
            by = b(k).y(it);
        else
            bx = 0; by = 0;
        end
        delete(hQuiv(k));
        hQuiv(k) = quivermc(magLat(k), magLon(k), by, bx, 'color','r', ...
            'reference', refScale, 'arrowstyle','tail', 'linewidth',1.5);
    end

    title(ax, ['GIC and Magnetic Field Map @ ', char(T(it))], 'FontSize', 14);
    drawnow;
    pause(0.1);
end
hold(ax, 'off');
end