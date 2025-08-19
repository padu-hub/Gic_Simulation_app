function handleTransformerToggle(app, event)
    row = event.Indices(1);   % Transformer row index
    col = event.Indices(2);   % Column index (determines W1 or W2)
    enabled = event.NewData;  % New toggle state

    if col == 5  % HV_On column → W1
        app.TransEnabled(row,1) = enabled;
        if ~enabled
            app.T(row).W1 = NaN;
        else
            app.T(row).W1 = app.OriginalT(row).W1;
        end
    elseif col == 8  % LV_On column → W2
        app.TransEnabled(row,2) = enabled;
        if ~enabled
            app.T(row).W2 = NaN;
        else
            app.T(row).W2 = app.OriginalT(row).W2;
        end
    end

    % Map marker color update (unchanged)
    if isvalid(app.TransPlots(row))
        if enabled
            app.TransPlots(row).MarkerFaceColor = 'b';
        else
            app.TransPlots(row).MarkerFaceColor = 'w';
        end
    end
end
