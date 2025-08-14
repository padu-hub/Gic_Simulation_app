function handleTransformerToggle(app, event)
    row = event.Indices(1);
    col = event.Indices(2);

    data = app.TransTable.Data;
    enabled = data{row, 'Enabled'};
    bypass = data{row, 'Bypass'};

    % === Column 5: Enable/Disable Transformer ===
    if col == 5
        app.TransEnabled(row) = enabled;
        if ~enabled
            app.T(row).W1 = inf;
            app.T(row).W2 = inf;
        else
            % Apply bypass if checked
            if bypass
                if ismember(lower(app.T(row).HV_Type), {'wye', 'auto'})
                    app.T(row).W1 = 1e9;
                else
                    app.T(row).W1 = app.OriginalT(row).W1;
                end
                if ismember(lower(app.T(row).LV_Type), {'wye', 'auto'})
                    app.T(row).W2 = 1e9;
                else
                    app.T(row).W2 = app.OriginalT(row).W2;
                end
            else
                app.T(row).W1 = app.OriginalT(row).W1;
                app.T(row).W2 = app.OriginalT(row).W2;
            end
        end

    % === Column 6: Toggle Bypass Checkbox ===
    elseif col == 6
        if enabled
            if bypass
                if ismember(lower(app.T(row).HV_Type), {'wye','auto'})
                    app.T(row).W1 = 1e9;
                else
                    app.T(row).W1 = app.OriginalT(row).W1;
                end
                if ismember(lower(app.T(row).LV_Type), {'wye','auto'})
                    app.T(row).W2 = 1e9;
                else
                    app.T(row).W2 = app.OriginalT(row).W2;
                end
            else
                app.T(row).W1 = app.OriginalT(row).W1;
                app.T(row).W2 = app.OriginalT(row).W2;
            end
        end
    end

    % === Update Color on Map ===
    if isvalid(app.TransPlots(row))
        if enabled
            app.TransPlots(row).MarkerFaceColor = 'b';  % blue when active
        else
            app.TransPlots(row).MarkerFaceColor = 'w';  % white when disabled
        end
    end

end
