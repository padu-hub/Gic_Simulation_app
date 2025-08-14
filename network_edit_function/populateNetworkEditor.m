function populateNetworkEditor(app, L, T, S)
% =======================================================================
% POPULATE NETWORK EDITOR
% Populates the tab with map, transformer table, and enables toggling
% =======================================================================

%% --- Save State Internally ---
% Sort Substations
[~, sidx] = sort({S.Name});
S = S(sidx);

% Sort Transformers
[~, tidx] = sort({T.Name});
T = T(tidx);

% Sort Lines
[~, lidx] = sort({L.Name});
L = L(lidx);

% Assign sorted data to app
app.S = S;
app.T = T;
app.L = L;

% Store original (already sorted)
app.OriginalT = T;
app.OriginalL = L;

app.LineEnabled = true(1, numel(L));
app.TransEnabled = true(1, numel(T));

%% --- Update Transformer Table ---
t_names = {T.Name}';
sub = {T.Sub}';
w1 = num2cell([T.W1]');
w2 = num2cell([T.W2]');
app.TransTable.Data = table(t_names, sub, w1, w2, app.TransEnabled', 'VariableNames', {'Name','Sub', 'W1', 'W2', 'Enabled'});
app.TransTable.ColumnSortable = true;

%% --- Update Line Table ---
% Extract relevant data from app.L
names    = {app.L.Name}';
voltages = num2cell([app.L.Voltage]');
resist   = num2cell([app.L.Resistance]');
enabled  = app.LineEnabled(:);  % Logical array tracking toggle state

% Define LineTableData
app.LineTableData = table(names, voltages, resist, enabled, ...
    'VariableNames', {'Name', 'Voltage', 'Resistance', 'Enabled'});
% Push to table UI
app.LineTable.Data = app.LineTableData;
%% --- Clear and Set Up Map ---
cla(app.NetworkMapAxes);
hold(app.NetworkMapAxes, 'on');

% --- Use geoshow-style map base manually ---
provinces = shaperead('province.shp','UseGeoCoords',true);
states = shaperead('usastatehi','UseGeoCoords',true);

% Plot provinces and states
for k = 1:length(states)
    fill(app.NetworkMapAxes, states(k).Lon, states(k).Lat, [0.9 1 0.7], 'EdgeColor', 'w', 'FaceAlpha', 0.5);
end
for k = 1:length(provinces)
    fill(app.NetworkMapAxes, provinces(k).Lon, provinces(k).Lat, [0.9 1 0.7], 'EdgeColor', 'w', 'FaceAlpha', 0.5);
end

% --- Plot Substations ---
subLoc = reshape([S.Loc], 2, [])';
plot(app.NetworkMapAxes, subLoc(:,2), subLoc(:,1), 'ko', 'MarkerFaceColor', 'w');

% --- Plot Transmission Lines (≥400kV = Red, else Blue), with toggle ---
allLat = [];
allLon = [];
app.LinePlots = gobjects(1, numel(L));
for k = 1:numel(L)
    lat = L(k).Loc(:,1);
    lon = L(k).Loc(:,2);
    allLat = [allLat; lat];
    allLon = [allLon; lon];
    color = 'r';
    if isfield(L(k), 'Voltage') && L(k).Voltage >= 400
        color = 'b';
    end
    app.LinePlots(k) = plot(app.NetworkMapAxes, lon, lat, '-', 'Color', color, 'LineWidth', 1.5);
    app.LinePlots(k).ButtonDownFcn = @(src,~) toggleLine(app, k, ~app.LineEnabled(k));  % flip and pass it
end

% --- Auto-center and zoom map ---
if ~isempty(allLat) && ~isempty(allLon)
    %Lock aspect ratio so the map isn't stretched
    axis(app.NetworkMapAxes, 'image');
    margin = 0.5;
    xlim(app.NetworkMapAxes, [min(allLon)-margin, max(allLon)+margin]);
    ylim(app.NetworkMapAxes, [min(allLat)-margin, max(allLat)+margin]);   
end

% --- Plot Transformer Substations and Add Labels ---
app.TransPlots = gobjects(1, numel(T));
for i = 1:numel(T)
    si = find(strcmp({S.Name}, T(i).Sub));
    if ~isempty(si)
        lat = S(si).Loc(1);
        lon = S(si).Loc(2);
        app.TransPlots(i) = plot(app.NetworkMapAxes, lon, lat, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
        text(app.NetworkMapAxes, lon + 0.05, lat, S(si).Name, 'FontSize', 8, 'Color', 'w');
    end
end

end