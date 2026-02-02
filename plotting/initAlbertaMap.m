function h = initAlbertaMap(S, L)
    % Substation coords from S(:).Loc
    subLoc = reshape([S(:).Loc], 2, []).';
    subLat = subLoc(:,1);
    subLon = subLoc(:,2);

    % Map limits with padding
    latLim = [min(subLat), max(subLat)];
    lonLim = [min(subLon), max(subLon)];
    latPad = 0.2 * diff(latLim);
    lonPad = 0.3 * diff(lonLim);
    latLim = latLim + [-latPad latPad];
    lonLim = lonLim + [-lonPad lonPad];

    figure('Name','Live GIC (Alberta)','Color','w');
    worldmap(latLim, lonLim);
    setm(gca,'FontSize',12);
    hold on;

    % Background map polygons (optional)
    try
        provinces = shaperead('province.shp','UseGeoCoords',true);
        geoshow(provinces,'DisplayType','polygon', ...
            'DefaultFaceColor',[0.9 1 0.7],'EdgeColor','black');
    end
    try
        states = shaperead('usastatehi','UseGeoCoords',true);
        geoshow(states,'DisplayType','polygon', ...
            'DefaultFaceColor',[0.9 1 0.7],'EdgeColor','black');
    end

    % Plot transmission lines once
    for k = 1:numel(L)
        lat = L(k).Loc(:,1);
        lon = L(k).Loc(:,2);
        tcolor = 'k';
        if isfield(L(k), 'Voltage') && L(k).Voltage >= 400
            tcolor = 'b';
        end
        plotm(lat, lon, '-', 'Color', tcolor, 'LineWidth', 1.5);
    end

    % Plot cities once
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

    % Create bubble layer ONCE and return handle + coords
    h.subLat = subLat;
    h.subLon = subLon;

    h.bubbles = scatterm(subLat, subLon, ...
        30*ones(size(subLat)), zeros(size(subLat)), ...
        'filled', 'MarkerEdgeColor','k');

    h.cb = colorbar;
    h.cb.Label.String = 'Running Avg(minute max |GIC|) (A)';
    colormap jet;

    title('Live Running Avg(minute max |GIC|) — waiting...');
    hold off;
end
