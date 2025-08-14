function SaveGraphButtonPushed(app)
    % Get selections
    graphName = app.GraphDropdown.Value;
    format = app.FormatDropdown.Value;
    dpi = str2double(app.ResolutionField.Value);
    bg = app.BackgroundDropdown.Value;
    fontMode = app.FontScalingCheckbox.Value;

    % Validate
    if isempty(graphName) || isnan(dpi) || dpi <= 0
        uialert(app.UIFigure, 'Please select a graph and enter a valid DPI.', 'Invalid Settings');
        return;
    end

    % Find the matching axes
    idx = find(strcmp({app.StoredAxes.Name}, graphName));
    if isempty(idx)
        uialert(app.UIFigure, 'Selected graph not found.', 'Error');
        return;
    end
    ax = app.StoredAxes(idx).Axes;

    % Choose file
    [file, path] = uiputfile(['*.', format], 'Save Graph As');
    if isequal(file, 0), return; end
    filename = fullfile(path, file);

    % Set export settings
    contentType = "image";
    if ismember(lower(format), ["pdf", "eps"])
        contentType = "vector";
    end

    % If background is 'none', make it transparent
    if strcmpi(bg, 'none')
        bgColor = 'none';
    else
        bgColor = bg;
    end

    try
        exportgraphics(ax, filename, ...
            'Resolution', dpi, ...
            'ContentType', contentType, ...
            'BackgroundColor', bgColor, ...
            'FontMode', ternary(fontMode, 'scaled', 'fixed'), ...
            'LineMode', ternary(fontMode, 'scaled', 'fixed'));

        uialert(app.UIFigure, 'Graph exported successfully.', 'Success');
    catch err
        uialert(app.UIFigure, ['Error exporting graph: ', err.message], 'Export Failed');
    end
end

function out = ternary(cond, valTrue, valFalse)
    if cond
        out = valTrue;
    else
        out = valFalse;
    end
end
