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

    if app.TurnoffallHighvoltagelinesindividuallyCheckBox.Value
        batch_turnOff500kVLines(app, GICbase);
    end

    if app.RunothermassindividualmitigationsCheckBox.Value
            % Get selected text
        modeUI = app.MitigationModeDropDown.Value;
    
        % Map UI text to internal modeStr
        switch modeUI
            case 'Mode 1: More feasible solution'
                modeStr = 'original';
    
            case 'Mode 2: Neutral blockers (all wye windings)'
                modeStr = 'windings_only';
    
            case 'Mode 3: Any line'
                modeStr = 'all_lines';

            case 'Mode 4: Parallel Lines'
                modeStr = 'parallel_lines';
    
            otherwise
                modeStr = 'original';  % fallback
        end
    
        % Run mitigation loop under selected mode
        app.SpreadsheetTable = runGreedyGICMitigation(app, GICbase, modeStr);
    end
    app.ClearBtn.Enable  = 'on';
    app.ExportBtn.Enable = 'on';

    app.UpdateLamp.Color = [0 0.7 0]; % green = done
catch ME
    app.UpdateLamp.Color = [0.8 0 0]; % red = error
    rethrow(ME)
end
end
