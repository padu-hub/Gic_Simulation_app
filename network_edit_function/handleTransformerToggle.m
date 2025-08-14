function handleTransformerToggle(app, event)
    row = event.Indices(1);
    enabled = event.NewData;

    app.TransEnabled(row) = enabled;

    if ~enabled
        app.T(row).W1 = NaN;
        app.T(row).W2 = NaN;
    else
        app.T(row).W1 = app.OriginalT(row).W1;
        app.T(row).W2 = app.OriginalT(row).W2;
    end

    % Update map marker face color
    if isvalid(app.TransPlots(row))
        if enabled
            app.TransPlots(row).MarkerFaceColor = 'b';
        else
            app.TransPlots(row).MarkerFaceColor = 'w';
        end
    end
end
