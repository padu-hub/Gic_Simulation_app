function magneticVisualTab(app, siteIndices, magPanel, controlPanel, mapPanel)
% PLOT_MAG_SITES - Main magnetic field UI plot manager
% Plots magnetic time series and frequency content for selected sites,
% allows brushing, cleaning, and dynamic UI feedback.

%% === Step 1: Initial Validation and Panel Cleanup ===
    if nargin < 5 || isempty(magPanel) || ~isvalid(magPanel)
        warning("Invalid or missing panel.");
        return;
    end
    delete(allchild(magPanel));
    delete(allchild(controlPanel));
    delete(allchild(mapPanel));

    if ~isfield(app, "b_original")
        app.b_original = app.b_cleaned;
    end

%% === Step 2: Control Panel Setup ===
    controlGrid = uigridlayout(controlPanel, [4 1]);
    controlGrid.RowHeight = {'fit', 'fit', 'fit'};
    controlGrid.Padding = [5 5 5 1];

    % Reset Button
    uibutton(controlGrid, 'Text', 'Reset b', ...
        'ButtonPushedFcn', @(~,~) reset_b_data());

    % Delete Brushed Button (interpolates brushed points)
    uibutton(controlGrid, 'Text', 'Delete Brushed Points', ...
        'ButtonPushedFcn', @(~,~) delete_brushed_points(app, siteIndices, magPanel, mapPanel));

    % Export b
        uibutton(controlGrid, 'Text', 'Export b', ...
        'ButtonPushedFcn', @(~,~) export_b(app, app.b_cleaned));
    % Edit Status Lamp
    app.EditLamp = uilamp(controlGrid);
    app.EditLamp.Color = [0 1 0];  % Green by default (no edits)
    app.EditLamp.Layout.Row = 4;


%% === Step 3: Initial Plot Rendering ===
    replot_mag_time_and_freq(app, siteIndices, magPanel);
    replot_mag_map(app, siteIndices, mapPanel);

    % Enable global brushing for user interaction
    brush(app.UIFigure, 'on');

%% === Reset Button Logic ===
    function reset_b_data()
        app.b_cleaned = app.b_original;
        app.b_freq = conv_to_freqD(app.b_cleaned, app.freqmenu);
        assignin('base', 'b_cleaned', app.b_cleaned);
        app.EditLamp.Color = [0 1 0];  % Green (reset)

        % Refresh both plot areas only
        replot_mag_time_and_freq(app, siteIndices, magPanel);
        replot_mag_map(app, siteIndices, mapPanel);
        app.StatusTextArea.Value = "🔁 b reset to original.";
    end
end
