function testFunc(app)
% Plot E-field at time of maximum total magnitude over time

% --- Basic checks (use actual property names) ---
if ~isprop(app,'Ex_s') || ~isprop(app,'Ey_s') || isempty(app.Ex_s) || isempty(app.Ey_s)
    return;
end

ex = app.Ex_s;   % assume rows = time, cols = sensors
ey = app.Ey_s;

% Ensure rows = time (uncomment/adapt if needed)
T = size(ex,1);
if size(ex,1) ~= size(ey,1)
    error('Ex_s and Ey_s must have same number of time samples.');
end

% --- Find peak E over time ---
[~, idx] = max(sum(hypot(ex, ey), 2));   % peak row index

% --- Grab time of idx and store it as a string ---
emaxT = '';
if isprop(app,'b') && ~isempty(app.b) && isfield(app.b(1),'times')
    times = app.b(1).times;
    if numel(times) >= idx
        ti = times(idx);
        if isa(ti,'datetime')
            emaxT = datestr(ti);
        elseif isnumeric(ti)
            emaxT = num2str(ti);
        else
            emaxT = char(ti);
        end
    end
end

% --- Extract snapshot (ensure indexing matches your orientation) ---
ex_t = ex(idx,:).';
ey_t = ey(idx,:).';

% Create figure and worldmap axes
fig = figure('Name','E-field Snapshot','NumberTitle','off');
try
    ax = worldmap([min(app.lat_s(:)) max(app.lat_s(:))], [min(app.lon_s(:)) max(app.lon_s(:))]);
catch
    ax = worldmap('world');
end

% Plot quiver directly into the map axes
axes(ax);                            % make ax current
hq = quiverm(app.lat_s(:), app.lon_s(:), ey_t(:), ex_t(:), 'r', 'AutoScale','on','AutoScaleFactor',2);

% Add coastlines and title
coast = load('coastlines');
geoshow(ax, coast.coastlat, coast.coastlon, 'DisplayType','line','Color','k');
title(ax, ['E-field at peak time: ' emaxT]);

end
