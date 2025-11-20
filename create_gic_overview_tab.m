function create_gic_overview_tab(app, S, L, T,  b, GIC, tind, timeInput)
% CREATE_GIC_MAP_AND_TIMESERIES_TAB - Adds a tab showing a map + GIC time series.
% Supports toggling between Substations, Lines, and Transformers.
% Substation Sciemeatic    - A breakdown into what are the inputs and
% outputs in a substation.

    %% === Remove previous GIC tab if exists ===
    existingTabs = findall(app.TabGroup.Children, 'Type', 'uitab', 'Title', 'GIC Overview');
    delete(existingTabs);

    %% === Create Tab Layout ===
    gicTab = uitab(app.TabGroup, 'Title', 'GIC Overview');
    grid = uigridlayout(gicTab, [1 2]);
    grid.ColumnWidth = {'1x', '2x'};
    
    
    %% === Find Position of timeInput in tind ===
    if ~isempty(tind)
        timeIndex = find(tind == timeInput, 1);
        if isempty(timeIndex)
            warning('timeInput does not match any calculated GIC time range.');
            timeIndex = max(min(tind), min(timeInput, max(tind))); % Clamp timeIndex to the range [6, 100]
        end
    else
        warning('GIC not calculated.');
    end

    %% === Time Vector ===
    timeVec = b(1).times(tind);
    
    %% === LEFT: geoaxes map ===
    mapAxes = geoaxes(grid);
    mapAxes.Layout.Row = 1;
    mapAxes.Layout.Column = 1;
    hold(mapAxes, 'on');
    title(mapAxes, 'Alberta Substations & Magnetic Sites');

    % Coordinates
    subLoc = reshape([S.Loc], 2, []).';
    subLat = subLoc(:,1); subLon = subLoc(:,2);
    magLat = [b.lat]; magLon = [b.lon];

    % Map scatter plots
    s1 = geoscatter(mapAxes, subLat, subLon, 40, 'o', ...
        'MarkerFaceColor', [0.3 0.3 0.3], 'MarkerEdgeColor', 'k');
    s2 = geoscatter(mapAxes, magLat, magLon, 60, 'd', ...
        'MarkerFaceColor', [1 0.5 0], 'MarkerEdgeColor', 'k');
    mtLat = subLat + 0.03 * randn(size(subLat));
    mtLon = subLon + 0.03 * randn(size(subLon));
    s3 = geoscatter(mapAxes, mtLat, mtLon, 25, '^', ...
        'MarkerFaceColor', [0 0.6 0], 'MarkerEdgeColor', 'k');

    % Labels
    for k = 1:numel(b)
        text(mapAxes, magLat(k)+0.1, magLon(k)+0.1, b(k).site, 'FontSize', 8, 'Color', 'black');
    end
    for k = 1:numel(S)
        label = S(k).Name(1:min(4, strlength(S(k).Name)));
        text(mapAxes, subLat(k)+0.15, subLon(k), label, 'FontSize', 8, 'Color', [0.8 0.8 0]);
    end

    % Lines
    lat = []; lon = []; latHi = []; lonHi = [];
    for i = 1:numel(L)
        if L(i).Voltage < 400
            lat = [lat; L(i).Loc(:,1); NaN];
            lon = [lon; L(i).Loc(:,2); NaN];
        else
            latHi = [latHi; L(i).Loc(:,1); NaN];
            lonHi = [lonHi; L(i).Loc(:,2); NaN];
        end
    end
    geoplot(mapAxes, lat, lon, '-', 'Color', 'k', 'LineWidth', 3);
    geoplot(mapAxes, latHi, lonHi, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 3);

    legend(mapAxes, [s1, s2, s3], {'Substations', 'Magnetic Observatories', 'MT Sites'}, 'Location', 'northeast');
    geolimits(mapAxes, 'auto');

    %% === RIGHT: GIC Time Series Panel ===
    sidePanel = uipanel(grid, 'Title', 'GIC Time Series');
    subGrid = uigridlayout(sidePanel, [3 1]);
    subGrid.RowHeight = {'1x', '1x', '10x'};

    % === GIC Type Dropdown ===
    gicTypeDropdown = uidropdown(subGrid, ...
        'Items', {'Substations', 'Lines', 'Transformers w1', 'Transformers w2'}, ...
        'Value', 'Substations', ...
        'Editable', 'off');

    % === Name Dropdown ===
    entityDropdown = uidropdown(subGrid, 'Editable', 'off');
    
    Axes = uiaxes(subGrid);
    Axes.Layout.Row = 3;
    % Plot the sine graph in the tsPanel
    %plot(Axes, t, y, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Sine Wave');
    %title(Axes, 'Simple Sine Graph');
    %xlabel(Axes, 'Time (s)');
    %ylabel(Axes, 'Amplitude');
    %legend(Axes, 'show');

    % === Setup initial list ===
    updateEntityDropdown();

    % === Callbacks ===
    gicTypeDropdown.ValueChangedFcn = @(src, event) updateEntityDropdown();
    entityDropdown.ValueChangedFcn = @(src, event) updateTimeseries();

    %% === Internal Functions ===
    function updateEntityDropdown()
        switch gicTypeDropdown.Value
            case 'Substations'
                names = {S.Name};
            case 'Lines'
                names = {L.Name};
            case 'Transformers w1'
                names = {T.Name};           
            case 'Transformers w2'
                names = {T.Name};
        end
        names = sort(names);
        entityDropdown.Items = names;
        entityDropdown.Value = names{1};
        updateTimeseries();
    end

    function updateTimeseries()
        type = gicTypeDropdown.Value;
        name = entityDropdown.Value;       
        cla(Axes); % Clear the axes for a fresh plot
        
        switch type
            case 'Substations'
                idx = find(strcmp({S.Name}, name));
                y1 = GIC.Subs(idx,:);
                y2 = GIC.Original_Subs(idx,:);
            case 'Lines'
                idx = find(strcmp({L.Name}, name));
                y1 = GIC.Lines(idx,:);
                y2 = GIC.Original_Lines(idx,:);
            case 'Transformers w1'
                idx = find(strcmp({app.T.Name}, name));
                y1 = squeeze(GIC.Trans(idx,1,:))';
                y2 = squeeze(GIC.Original_Trans(idx,1,:))';
            case 'Transformers w2'
                idx = find(strcmp({app.T.Name}, name));
                y1 = squeeze(GIC.Trans(idx,2,:))';
                y2 = squeeze(GIC.Original_Trans(idx,2,:))';            
        end
        
        % Check if y1 and y2 have only one value
        if numel(y1) == 1 && numel(y2) == 1
            % Create a histogram-like plot for single values with different colors
            bar(Axes, [1, 2], [y1, y2], 'FaceColor', 'flat');
            bObj = Axes.Children; % Get the bar object
            bObj.CData(1, :) = [1 0 0]; % Set color for edited (red)
            bObj.CData(2, :) = [0 0 1]; % Set color for original (blue)
            Axes.XTick = [1, 2];
            Axes.XTickLabel = {'Edited', 'Original'};
            ylim(Axes, 'auto');
        else
            % Plot both y1 and y2, excluding NaN values
            plot(Axes, timeVec(~isnan(y1)), y1(~isnan(y1)), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Edited');
            hold(Axes, 'on');
            plot(Axes, timeVec(~isnan(y2)), y2(~isnan(y2)), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Original');
            hold(Axes, 'off');      
            % Update axes properties
            title(Axes, sprintf('GIC Time Series for %s (%s)', name, type));
            xlabel(Axes, 'Time');
            ylabel(Axes, 'GIC Value');
            legend(Axes, 'show');
            ylim(Axes, 'auto');
                    
        end
        addGraphToStorage(app, Axes, sprintf('GIC @ %s (%s)', name, type));
    end

    % === Create new App Tab ===
    existingTabs = findall(app.TabGroup.Children, 'Type', 'uitab', 'Title', 'Substation Schematic');
    delete(existingTabs);  % remove if exists

    tab = uitab(app.TabGroup, 'Title', 'Substation Schematic');
  
    % === Main Layout: Dropdown row and Scrollable plot area ===
    mainLayout = uigridlayout(tab, [2,1]);
    mainLayout.RowHeight = {'1x', '6x'};
    
    % === Top layout for dropdown and button ===
    topLayout = uigridlayout(mainLayout, [1,3]);
    topLayout.Layout.Row = 1;
    topLayout.ColumnWidth = {'1x','9x', '1x'};
    
    % === Scrollable panel for schematic ===
    scrollPanel = uipanel(mainLayout);
    scrollPanel.Scrollable = true;
    scrollPanel.Layout.Row = 2;
    
    % === Axes for schematic inside scrollable panel ===
    ax = uiaxes(scrollPanel);
    ax.Position = [0 0 800 1500];  % Increase height if needed
    ax.XColor = 'none';
    ax.YColor = 'none';  
    ax.Title.String = 'Substation Schematic';

    
    % === Schematic Display Options Dropdown ===
    displayOptionsDropdown = uidropdown(topLayout, ...
        'Items', {'Display schematic at max', 'Display schematic at chosen time'}, ...
        'Value', 'Display schematic at max', ...
        'Editable', 'off');
    displayOptionsDropdown.Layout.Column = 1;


    subNames = sort(string({S.Name}));  % Alphabetically sort the names
    dd = uidropdown(topLayout, 'Items', subNames);
    dd.Layout.Column = 2;
    dd.Value = subNames(1);

    btn = uibutton(topLayout, 'Text', 'Draw');
    btn.Layout.Column = 3;
    
    btn.ButtonPushedFcn = @(~,~) draw_schematic(b, displayOptionsDropdown.Value, dd.Value, find(strcmpi({S.Name}, dd.Value)), ax, L, T, GIC, timeIndex, timeVec);

end
