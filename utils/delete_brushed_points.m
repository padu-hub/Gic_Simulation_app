function delete_brushed_points(app, siteIndices, magPanel, mapPanel)
% DELETE_BRUSHED_POINTS - Replaces brushed points with interpolated values,
% updates plots and sets edit lamp to red.

    b = app.b_cleaned;
    lines = findall(app.UIFigure, 'Type', 'line');

    for i = 1:length(lines)
        h = lines(i);
        if isprop(h, 'BrushData') && ~isempty(h.BrushData) && ~isempty(h.Parent.Title.String)
            siteTitle = h.Parent.Title.String;
            siteName = strrep(siteTitle, 'Time Series for ', '');
            siteIdx = find(strcmpi(siteName, {b.site}));
            if isempty(siteIdx); continue; end

            brushed = logical(h.BrushData);
            if ~any(brushed); continue; end

            isBlue = isequal(h.Color, [0 0 1]);
            isRed  = isequal(h.Color, [1 0 0]);

            if isBlue
                raw = b(siteIdx).x;
                raw = interpolate_over_brushed(raw, brushed);
                app.b_cleaned(siteIdx).x = raw;
            elseif isRed
                raw = b(siteIdx).y;
                raw = interpolate_over_brushed(raw, brushed);
                app.b_cleaned(siteIdx).y = raw;
            end
        end
    end

    % Recompute frequency
    app.b_freq = conv_to_freqD(app.b_cleaned, app.freqmenu);
    assignin('base', 'b_cleaned', app.b_cleaned);

    % Redraw just the plots (faster)
    replot_mag_time_and_freq(app, siteIndices, magPanel);

    app.StatusTextArea.Value = "🧽 Brushed points interpolated and saved.";
    app.EditLamp.Color = [1 0 0];  % Red
end
