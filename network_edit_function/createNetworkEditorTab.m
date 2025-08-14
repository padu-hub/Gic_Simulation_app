function createNetworkEditorTab(app)
% =======================================================================
% CREATE NETWO RK EDITOR TAB FOR GUI
% Purpose: Creates a new tab that lets the user edit network elements
% like transformers using a table and view network topology on a map.
% =======================================================================

%% --- Delete Existing 'Network Editor' Tab If Exists ---
existingTabs = app.TabGroup.Children;
for i = 1:numel(existingTabs)
    if strcmp(existingTabs(i).Title, 'Network Editor')
        delete(existingTabs(i));
        break;
    end
end

%% --- Create New Tab and Layout ---
netTab = uitab(app.TabGroup, 'Title', 'Network Editor');
mainGrid = uigridlayout(netTab, [1, 2]);
mainGrid.ColumnWidth = {'1x', '2x'};
mainGrid.RowHeight = {'1x'};

%% --- LEFT PANEL: Transformer and lines Table + Buttons ---
leftPanel = uipanel(mainGrid, 'Title', 'Transformer and Line Control Panel');
leftGrid = uigridlayout(leftPanel, [5, 1]);
leftGrid.RowHeight = {30, '2x', '2x', 30, 30};

% --- Heading Label ---
uilabel(leftGrid, 'Text', 'Toggle Transformers (Sets W1/W2 = NaN) and Toggle Line (Set R = NaN', ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% --- Transformer Table ---
app.TransTable = uitable(leftGrid);
app.TransTable.ColumnName = {'Name','Sub','W1', 'W2', 'Enabled'};
app.TransTable.ColumnEditable = [false, false, false, false, true];

app.TransTable.CellEditCallback = @(src, event) handleTransformerToggle(app, event);

% --- Line Table ---
app.LineTable = uitable(leftGrid);
app.LineTable.ColumnName = {'Name', 'Voltage', 'Resistance','Enabled'};
app.LineTable.ColumnEditable = [false, false, false, true];  % Only "Enabled" column is editable
app.LineTable.CellEditCallback = @(src, event) onLineTableEdit(app, event);

% --- Reset Button ---
uibutton(leftGrid, 'Text', 'Reset All', 'ButtonPushedFcn', @(~,~) resetAllNetwork(app));

% --- Export Button ---
uibutton(leftGrid, 'Text', 'Export .mat', 'ButtonPushedFcn', @(~,~) exportNetworkToMat(app));

%% --- RIGHT PANEL: Interactive Map ---
rightPanel = uipanel(mainGrid, 'Title', 'Interactive Network Map');
app.NetworkMapAxes = uiaxes(rightPanel); % Use uiaxes with static map drawing
app.NetworkMapAxes.Position = [20 20 rightPanel.Position(3)-40 rightPanel.Position(4)-40];
title(app.NetworkMapAxes, 'Network Topology Map');
xlabel(app.NetworkMapAxes, 'Longitude');
ylabel(app.NetworkMapAxes, 'Latitude');
end