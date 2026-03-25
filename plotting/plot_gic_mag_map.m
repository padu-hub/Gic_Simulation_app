function plot_gic_mag_map(app, S, L, tind, b, GIC, timeInput, mode)
% =========================================================================
% PLOT_GIC_MAG_MAP - Plots GIC values and magnetic field vectors on a map.
%
% Inputs:
%   S                - Substation struct array (with .Loc)
%   L                - Line struct array (with .Loc and optional .Voltage)
%   tind             - Time indices into magnetic field data
%   b                - Magnetic field struct array (with .x, .y, .times)
%   timeInput        - Either:
%                        • [] (default → peak GIC)
%                        • datetime object to target a specific time

% Plots GIC values on a geographic map with three modes:
%   1. 'Max GIC'     - Peak GIC magnitude per substation (edited network)
%   2. 'GIC Change'  - Peak difference between edited and original GIC
%   3. 'Snapshot'    - GIC values at a specific timeIndex
%
% Creates two separate plots for each choice:
%   1. Full Alberta GIC map with automatic limits and no E-field
%   2. Close-up GIC map with user-defined focus and E-field overlay
    % === Time index handling ===
if isempty(timeInput)
    [~, timeIndex] = max(max(abs(GIC.Subs), [], 1));
elseif isdatetime(timeInput)
    tvec = b(1).times(tind);
    [~, timeIndex] = min(abs(tvec - timeInput));
else
    timeIndex = timeInput;
end

% === Clamp time index to valid GIC range ===
timeIndex = max(1, min(timeIndex, size(GIC.Subs, 2)));

switch mode
    case {'Max GIC', 'GIC Change', 'Snapshot'}

        % === Extract substation coordinates ===
        subLoc = reshape([S(:).Loc], 2, []).';
        subLat = subLoc(:,1);
        subLon = subLoc(:,2);

        % === Automatic Alberta limits ===
        latLimFull = [min(subLat), max(subLat)];
        lonLimFull = [min(subLon), max(subLon)];
        latPad = 0.1 * diff(latLimFull);
        lonPad = 0.1 * diff(lonLimFull);

        latLimFull = latLimFull + [-latPad, latPad];
        lonLimFull = lonLimFull + [-lonPad, lonPad];

        % === Default close-up limits start as full limits ===
        latLimClose = latLimFull;
        lonLimClose = lonLimFull;

        % === Ask user for close-up focus ===
        promptTitle = 'Map Focus Options';
        prompt = {'centerLat (deg)','centerLon (deg)','latPad (deg)','lonPad (deg)'};
        opts.WindowStyle = 'modal';
        answer = inputdlg(prompt, promptTitle, 1, {'53','-113','1','4'}, opts);

        if ~isempty(answer)
            centerLat = str2double(answer{1});
            centerLon = str2double(answer{2});
            padDegLat = str2double(answer{3});
            padDegLon = str2double(answer{4});

            if ~(isnan(centerLat) || isnan(centerLon) || isnan(padDegLat) || isnan(padDegLon) || padDegLat < 0 || padDegLon < 0)
                latLimClose = centerLat + [-padDegLat, padDegLat];
                lonLimClose = centerLon + [-padDegLon, padDegLon];
            else
                warning('Invalid focus point inputs. Using automatic limits for close-up map.');
            end
        end

        % === Determine current GIC data source ===
        if any(isnan(GIC.Subs), 'all')
            currentData = GIC.Original_Subs;
        else
            currentData = GIC.Subs;
        end

        % === Select GIC values based on mode ===
        switch mode
            case 'Max GIC'
                [~, idxMax] = max(abs(currentData), [], 2);
                gicVals = arrayfun(@(i) currentData(i, idxMax(i)), 1:size(currentData,1))';
                cVals = gicVals;
                titleStr = 'Max GIC Magnitude (All Time)';

            case 'GIC Change'
                gicDiff = abs(currentData) - abs(GIC.Original_Subs);
                [~, idxMaxDiff] = max(abs(gicDiff), [], 2);
                gicVals = arrayfun(@(i) gicDiff(i, idxMaxDiff(i)), 1:size(gicDiff,1))';
                cVals = gicVals;
                titleStr = 'Max GIC Change (Edited - Original)';

            case 'Snapshot'
                gicVals = currentData(:, timeIndex);
                cVals = gicVals;
                peakTime = b(1).times(tind(timeIndex));
                titleStr = ['GIC Map Snapshot @ ', char(peakTime)];
        end

        % === Plot 1: Full Alberta map (no E-field) ===
        figure;
        worldmap(latLimFull, lonLimFull);
        setm(gca, 'FontSize', 12);
        hold on;

        drawBaseMapAndData(L, subLat, subLon, gicVals, cVals, "geoshow");

        title([titleStr, ' - Full Alberta'], 'FontSize', 14);
        hold off;

        % === Plot 2: Close-up map (with E-field) ===
        figure;
        worldmap(latLimClose, lonLimClose);
        hold on;
        
        [A, RA] = readBasemapImage("streets", latLimClose, lonLimClose);
        [xGrid, yGrid] = worldGrid(RA);
        [latGrid, lonGrid] = projinv(RA.ProjectedCRS, xGrid, yGrid);
        geoshow(latGrid, lonGrid, A)


        drawBaseMapAndData(L, subLat, subLon, gicVals, cVals , "real");

        % === Overlay E-field only on close-up map ===
        emaxT = plotEfield(app, b, subLat, subLon);

        title([titleStr, ' - Close-Up with E-Field at ', emaxT], 'FontSize', 14);
        
        hold off;

    otherwise
        error('Unknown mode: %s', mode);
end
end
   

function drawBaseMapAndData(L, subLat, subLon, gicVals, cVals,type)
% =========================================================================
% DRAWBASEMAPANDDATA
% Draws provinces/states, transmission lines, substations, and cities.
% =========================================================================    
    % Only draw background polygons when using 'geoshow' mode
    if strcmpi(string(type), "geoshow")
        try
            provinces = shaperead('province.shp', 'UseGeoCoords', true);
            geoshow(provinces, 'DisplayType', 'polygon', ...
                'DefaultFaceColor', [0.9 1 0.7], 'EdgeColor', 'black');
        end

        try
            states = shaperead('usastatehi', 'UseGeoCoords', true);
            geoshow(states, 'DisplayType', 'polygon', ...
                'DefaultFaceColor', [0.9 1 0.7], 'EdgeColor', 'black');
        end
    end

    % === Transmission lines ===
    for k = 1:numel(L)
        lat = L(k).Loc(:,1);
        lon = L(k).Loc(:,2);

        lineColor = 'r';
        if isfield(L(k), 'Voltage') && L(k).Voltage >= 400
            lineColor = 'b';
        end

        plotm(lat, lon, '-', 'Color', lineColor, 'LineWidth', 1.5);
    end

    % === Substation bubbles ===
    scatterm(subLat, subLon, 30 + 30*abs(gicVals), cVals, ...
        'filled', 'MarkerEdgeColor', 'k');

    cb = colorbar;
    cb.Label.String = 'GIC (A)';
    colormap(redblue(10));

    % === Symmetric color scaling ===
    maxAbs = max(abs(cVals(:)));
    if ~isempty(maxAbs) && isfinite(maxAbs) && maxAbs > 0
        caxis([-maxAbs maxAbs]);
    else
        caxis([-1 1]);
    end

    % === Cities ===
    cities = {
        'Edmonton',      53.5461, -113.4938;
        'Calgary',       51.0477, -114.0719;
        'Red Deer',      52.2681, -113.8112;
        'Fort McMurray', 56.7267, -111.3790;
        'Lethbridge',    49.6942, -112.8328;
        'Medicine Hat',  50.0405, -110.6765;
    };

    for i = 1:size(cities,1)
        plotm(cities{i,2}, cities{i,3}, 'sk', 'MarkerFaceColor', 'b');
        textm(cities{i,2}, cities{i,3}, cities{i,1}, ...
            'FontSize', 8, 'VerticalAlignment', 'top');
    end
end

