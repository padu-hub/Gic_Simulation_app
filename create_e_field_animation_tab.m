function create_e_field_animation_tab(app, b, ex, ey, lat, lon, L, S)
    %% === Remove existing tab ===
    for i = 1:numel(app.TabGroup.Children)
        if strcmp(app.TabGroup.Children(i).Title, 'E-field Animation')
            delete(app.TabGroup.Children(i));
            break;
        end
    end

    %% === Setup layout ===
    tab = uitab(app.TabGroup, 'Title', 'E-field Animation');
    mainLayout = uigridlayout(tab, [2, 1]);  % [rows, cols]
    mainLayout.RowHeight = {'9x', '1x'};
    
    %% === Top Split: Map + Scale ===
    topLayout = uigridlayout(mainLayout, [1, 2]);  % 1 row, 2 cols
    topLayout.ColumnWidth = {'9x', '1x'};
    
    % === Left: Map Axes ===
    ax = uiaxes(topLayout);
    hold(ax, 'on');
    
    % === Right: Scale Panel ===
    scalePanel = uigridlayout(topLayout, [3, 1]);  % vertical layout
    scalePanel.RowHeight = {'5x', '4x', '1x'};
    
    % --- Top: Scale Slider ---
    scaleSlider = uislider(scalePanel, ...
        'Orientation', 'vertical', ...
        'Limits', [0 1000], ...
        'Value', 500, ...
        'MajorTicks', 0:250:1000, ...
        'ValueChangedFcn', @(src,~) disp(['Current Value: ', num2str(src.Value)]));
    
    arrowAxes= uiaxes(scalePanel);
    axis(arrowAxes, 'equal');
    hold(arrowAxes, 'on');
    arrowAxes.XColor = 'none';
    arrowAxes.YColor = 'none';
    arrowAxes.XLim = [-1 1];
    arrowAxes.YLim = [0 1010];
    axis(arrowAxes, 'equal');
    disableDefaultInteractivity(arrowAxes);
    
    % === Display Scale Representation ===
    textLabel = uilabel(scalePanel, ...
        'Text', {'Arrow size','represents','1v/Km'}, ...
        'FontSize', 8, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
 
    %% === Bottom Controls ===
    ctrl = uigridlayout(mainLayout, [1, 4]);
    ctrl.ColumnWidth = {'1x', '7x', '1x', '1x'};
    playBtn = uibutton(ctrl, 'Text', '▶️ Play');
    
    times = b(1).times;
    nSteps = length(times);
    tickIndices = round(linspace(1, nSteps, 16));
    
    tSlider = uislider(ctrl, ...
        'Limits', [1 nSteps], ...
        'Value', 1, ...
        'MajorTicks', tickIndices, ...
        'MajorTickLabels', string(datestr(times(tickIndices), 'mmm-dd HH:MM')));
    
    speedDropdown = uidropdown(ctrl, ...
        'Items', {'1x', '2x', '5x', '10x', '20x', '50x'}, ...
        'ItemsData', [1 2 5 10 20 50], ...
        'Value', 10);
    
    timeLbl = uilabel(ctrl, 'Text', '', 'HorizontalAlignment', 'right', 'FontSize', 16);
    
    %% === Map Base Drawing ===
    provinces = shaperead('province.shp', 'UseGeoCoords', true);
    states = shaperead('usastatehi', 'UseGeoCoords', true);
    
    for k = 1:length(states)
        fill(ax, states(k).Lon, states(k).Lat, [0.9 1 0.7], ...
             'EdgeColor', 'w', 'FaceAlpha', 0.5);
    end
    
    for k = 1:length(provinces)
        fill(ax, provinces(k).Lon, provinces(k).Lat, [0.9 1 0.7], ...
             'EdgeColor', 'w', 'FaceAlpha', 0.5);
    end
    
    axis(ax, 'equal');
    %Limit for Alberta Region


    ax.XLim = [-120.5 -109];
    ax.YLim = [47.5 61];
    title(ax, 'E-field Arrows (Magnitude by Length)');
    ax.Interactions = [];

    %% === Preallocate Arrow Patches ===
    n = length(lat);
    scale = 500;
    instanTime = 1;

    app.arrowHandles = gobjects(n, 1);
    app.shaftHandles = gobjects(n, 1);
    for i = 1:n
        app.shaftHandles(i) = plot(ax, nan, nan, 'r-', 'LineWidth', 1.5);
        app.arrowHandles(i) = patch(ax, nan, nan, 'r', 'EdgeColor', 'r', 'FaceAlpha', 1);
    end
    
    %Create the refrence shaft and arrowhead.
    refShaft = plot(arrowAxes, nan, nan, 'r-', 'LineWidth', 2);
    refArrow = patch(arrowAxes, nan, nan, 'r', ...
    'EdgeColor', 'r', 'FaceAlpha', 1);


    %% === Frame Update ===
    function updateFrame(idx)
        scale = scaleSlider.Value;
        app.instanTime = idx;
        ex_t = ex(idx, :);
        ey_t = ey(idx, :);
        drawArrows(app, lon, lat, ex_t, ey_t, n, scale);
        timeLbl.Text = datestr(b(1).times(idx), 'yyyy-mmm-dd HH:MM:SS');
    end

    %% === Playback Logic ===
    isPlaying = false;
    function togglePlay()
        isPlaying = ~isPlaying;
        if isPlaying
            playBtn.Text = '⏸ Pause';
            step = speedDropdown.Value;
            for k = round(tSlider.Value):step:length(b(1).times)
                if ~isPlaying, break; end
                tSlider.Value = k;
                updateFrame(k);
                instanTime = k;
                drawnow limitrate;
            end
            playBtn.Text = '▶️ Play';
            isPlaying = false;
        else
            playBtn.Text = '▶️ Play';
        end
    end

    function onScaleChanged(scale, t)
        drawReferenceArrow(scale, arrowAxes, refShaft, refArrow);
        updateFrame(round(t));  % redraw map arrows
    end

    %% === Link callbacks ===
    playBtn.ButtonPushedFcn = @(~,~) togglePlay();
    tSlider.ValueChangedFcn = @(src,~) updateFrame(round(src.Value));
    scaleSlider.ValueChangedFcn = @(src,~) onScaleChanged(src.Value, tSlider.Value);

    %% === Initial Draw ===
    updateFrame(1);
    drawReferenceArrow(scaleSlider.Value, arrowAxes, refShaft, refArrow);

end
