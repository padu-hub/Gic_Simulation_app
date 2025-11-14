function UpdateSpreadsheet(app)
% Runs whichever boxes are ticked, appends to app.MitigationResults,
% pushes to your Spreadsheet Results table, and flips the lamp green.

try
    app.UpdateLamp.Color = [1 0.6 0]; % amber = working

    % Baseline once for current window reference
    resetAllNetwork(app);
    app.gic_originalS=[];
    app.gic_originalL=[];
    app.gic_originalT=[];
    [~, ~, ~, GICbase] = runGIC_now(app);
    app.gic_originalS=GICbase.Original_Subs;
    app.gic_originalL=GICbase.Original_Lines;
    app.gic_originalT=GICbase.Original_Trans;

    if app.ApplyNBtoeachautotransformersIndividuallyCheckBox.Value
        batch_applyNeutralBlockers(app, GICbase);
    end
    if app.TurnoffHighvoltagelinesindividuallyCheckBox.Value
        batch_turnOff500kVLines(app, GICbase);
    end
    if app.TurnoffDoubleCircuitedparallellinesindividuallyCheckBox.Value
        batch_turnOffDoubleCircuitedParallelLines(app, GICbase);
    end
    app.ClearBtn.Enable  = 'on';
    app.ExportBtn.Enable = 'on';

    app.UpdateLamp.Color = [0 0.7 0]; % green = done
catch ME
    app.UpdateLamp.Color = [0.8 0 0]; % red = error
    rethrow(ME)
end
end
