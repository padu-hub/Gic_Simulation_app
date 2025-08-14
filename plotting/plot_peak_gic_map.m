function plot_peak_gic_map(S, L, b, GIC_Subs, T, timeIndex)
%Plot peak GIC values and magnetic field vectors on a map.
%
%   plot_gic_mag_map(S, L, b, GIC_Subs, T) plots the electrical network
%   defined by substations S and lines L together with magnetic field data
%   contained in the structure array b. GIC_Subs is an nSubs-by-nTimes
%   matrix of modeled GIC values and T is the time vector.  The function
%   highlights the time step of peak |GIC| unless a specific timeIndex is
%   provided.
%
%   Inputs:
%       S        - array of substation structures with fields "Loc" and
%                  "Name".
%       L        - array of line structures containing field "Loc" with
%                  latitude/longitude coordinates of each line segment.
%       b        - magnetic data structure array with fields "lat",
%                  "lon", "site", "x", and "y".
%       GIC_Subs - matrix of substation GIC (nSubs x nTimes).
%       T        - vector of datetimes corresponding to columns of
%                  GIC_Subs and to samples in b(k).x/y.
%       timeIndex - (optional) index into T specifying which snapshot to
%                  visualize.
%
%   Example:
%       plot_gic_mag_map(S, L, b, GIC_Subs, T);
%
%   This function requires MATLAB's Mapping Toolbox.

if nargin < 6 || isempty(timeIndex)
    % Choose the time of maximum |GIC| if none supplied
    [~, timeIndex] = max(max(abs(GIC_Subs), [], 1));
end
peakTime = T(timeIndex);

% Substation coordinates
subLoc = reshape([S(:).Loc], 2, []).';
subLat = subLoc(:,1);
subLon = subLoc(:,2);

% Magnetometer coordinates
magLat = [b(:).lat];
magLon = [b(:).lon];

% Map limits padded slightly
latLim = [min([subLat; magLat']) max([subLat; magLat'])];
lonLim = [min([subLon; magLon']) max([subLon; magLon'])];
latPad = 0.5*diff(latLim); lonPad = 0.5*diff(lonLim);
latLim = latLim + [-latPad latPad];
lonLim = lonLim + [-lonPad lonPad];

figure;
worldmap(latLim, lonLim);
setm(gca,'FontSize',12);

% Background polygons (if available)
try
    provinces = shaperead('province.shp','UseGeoCoords',true);
    geoshow(provinces,'DisplayType','polygon', ...
        'DefaultFaceColor',[0.9 1 0.7],'EdgeColor','black');
catch
    warning('province.shp not found. Background not shown.');
end
try
    states = shaperead('usastatehi','UseGeoCoords',true);
    geoshow(states,'DisplayType','polygon', ...
        'DefaultFaceColor',[0.9 1 0.7],'EdgeColor','black');
end
hold on;

% Plot transmission lines
for k = 1:numel(L)
    lat = L(k).Loc(:,1);
    lon = L(k).Loc(:,2);
    if isfield(L(k),'Voltage') && L(k).Voltage >= 400
        tcolor = 'b';
    else
        tcolor = [0.3 0.3 0.3];
    end
    plotm(lat, lon, '-', 'Color', tcolor, 'LineWidth', 1.5);
end

% Plot substations with GIC values
gicVals = GIC_Subs(:, timeIndex);
scatterm(subLat, subLon, 30 + 30*abs(gicVals), gicVals, ...
    'filled', 'MarkerEdgeColor', 'k');
cb = colorbar; %#ok<*NASGU>
cb.Label.String = 'GIC (A)';

% Magnetic vectors at observatories
refScale = 500; % arrow scale in nT
for k = 1:numel(b)
    if numel(b(k).x) >= timeIndex
        bx = b(k).x(timeIndex);
        by = b(k).y(timeIndex);
    else
        bx = 0; by = 0; % if missing data
    end
    quivermc(magLat(k), magLon(k), by, bx, 'color','r', ...
        'reference', refScale, 'arrowstyle','tail', 'linewidth', 1.5);
    textm(magLat(k), magLon(k), b(k).site, 'FontSize', 8, ...
        'VerticalAlignment', 'bottom');
end
% Edmonton
plotm(53.5461, -113.4938, 'sk', 'MarkerFaceColor', 'b');
textm(53.5461, -113.4938, 'Edmonton', 'FontSize', 8, 'VerticalAlignment', 'top');

% Calgary
plotm(51.0477, -114.0719, 'sk', 'MarkerFaceColor', 'b');
textm(51.0477, -114.0719, 'Calgary', 'FontSize', 8, 'VerticalAlignment', 'top');

% Red Deer
plotm(52.2681, -113.8112, 'sk', 'MarkerFaceColor', 'b');
textm(52.2681, -113.8112, 'Red Deer', 'FontSize', 8, 'VerticalAlignment', 'top');

% Fort McMurray
plotm(56.7267, -111.3790, 'sk', 'MarkerFaceColor', 'b');
textm(56.7267, -111.3790, 'Fort McMurray', 'FontSize', 8, 'VerticalAlignment', 'top');

% Lethbridge
plotm(49.6942, -112.8328, 'sk', 'MarkerFaceColor', 'b');
textm(49.6942, -112.8328, 'Lethbridge', 'FontSize', 8, 'VerticalAlignment', 'top');

% Medicine Hat
plotm(50.0405, -110.6765, 'sk', 'MarkerFaceColor', 'b');
textm(50.0405, -110.6765, 'Medicine Hat', 'FontSize', 8, 'VerticalAlignment', 'top');

%title(['GIC and Magnetic Field Map @ ', char(peakTime)],'FontSize',14);
hold off;
end