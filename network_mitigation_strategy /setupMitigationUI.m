function setupMitigationUI(app)
%SETUPMITIGATIONUI Build controls for the Mitigation tab
%  Call this once from your app's startupFcn.
%
% Expects:
%   - app.SetupPanel (uipanel from your Design View)
%   - app.SpredsheetResultsPanel (uipanel from your Design View)
% Creates:
%   - ThresholdPctEdit, AbsThresholdAEdit (numeric edit fields)
%   - UpdateBtn, UpdateLamp, PlotBtn, PlotLamp (main controls)
%   - ClearBtn, ExportBtn (disabled until Update runs)
%   - SpreadsheetTable (uitable inside the Results panel)
%
% Stores:
%   - app.MitigationResults (empty table at start)

    % --------- Initialize results store ---------
    app.MitigationResults = table();

    % ===========================
    % == Threshold edit fields ==
    % ===========================
    app.ThresholdPctEdit = uieditfield(app.SetupPanel, 'numeric', ...
        'Limits', [0 100], ...
        'Value', 30, ...
        'Tooltip', 'Minimum percent change of max |GIC| to include in plot');
    app.ThresholdPctEdit.Position = [20 120 100 24];
    uilabel(app.SetupPanel, ...
        'Text', 'Min % change', ...
        'Position', [20 145 100 18]);

    app.AbsThresholdAEdit = uieditfield(app.SetupPanel, 'numeric', ...
        'Limits', [0 Inf], ...
        'Value', 3, ...
        'Tooltip', 'Minimum absolute average Δ|GIC| (A) to include in plot');
    app.AbsThresholdAEdit.Position = [140 120 100 24];
    uilabel(app.SetupPanel, ...
        'Text', 'Min |Δ| (A)', ...
        'Position', [140 145 100 18]);

    % ===========================
    % == Buttons + status lamps ==
    % ===========================
    app.UpdateBtn = uibutton(app.SetupPanel, 'push', ...
        'Text', 'Update spreadsheet', ...
        'ButtonPushedFcn', @(~,~) UpdateSpreadsheetButtonPushed(app));
    app.UpdateBtn.Position = [20 70 180 28];

    app.UpdateLamp = uilamp(app.SetupPanel, 'Color', [0.4 0.4 0.4]); % gray
    app.UpdateLamp.Position = [210 74 20 20];

    app.PlotBtn = uibutton(app.SetupPanel, 'push', ...
        'Text', 'Plot graph', ...
        'ButtonPushedFcn', @(~,~) PlotGraphButtonPushed(app));
    app.PlotBtn.Position = [20 30 180 28];

    app.PlotLamp = uilamp(app.SetupPanel, 'Color', [0.4 0.4 0.4]); % gray
    app.PlotLamp.Position = [210 34 20 20];

    % ===========================
    % == Clear / Export buttons ==
    % ===========================
    app.ClearBtn = uibutton(app.SetupPanel, 'push', ...
        'Text', 'Clear results', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @(~,~) ClearResultsButtonPushed(app));
    app.ClearBtn.Position = [240 70 140 28];

    app.ExportBtn = uibutton(app.SetupPanel, 'push', ...
        'Text', 'Export CSV/XLSX', ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @(~,~) ExportResultsButtonPushed(app));
    app.ExportBtn.Position = [240 30 140 28];

    % ===========================
    % == Spreadsheet (uitable) ==
    % ===========================
    pad = 10;
    app.SpreadsheetTable = uitable(app.SpredsheetResultsPanel, ...
        'ColumnSortable', true, ...
        'FontSize', 12, ...
        'Data', app.MitigationResults);
    app.SpreadsheetTable.Position = [pad, pad, ...
        app.SpredsheetResultsPanel.Position(3)-2*pad, ...
        app.SpredsheetResultsPanel.Position(4)-2*pad];
end
