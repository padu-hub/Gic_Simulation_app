% -------------------------------------------------------------------------
% Sandbox Topology Editor Startup
% Initializes sandbox plotting area and toolbox defaults
% -------------------------------------------------------------------------
function startupSandbox(app)

    % ---------------------------------------------------------------------
    % Initialize topology storage
    % ---------------------------------------------------------------------
    app.SandboxS = struct([]);
    app.SandboxL = struct([]);
    app.SandboxT = struct([]);

    % ---------------------------------------------------------------------
    % Initialize graphics handle arrays
    % ---------------------------------------------------------------------
    app.SandboxNodeHandles = gobjects(0);
    app.SandboxLineHandles = gobjects(0);
    app.SandboxTransformerHandles = gobjects(0);

    % ---------------------------------------------------------------------
    % Initialize interaction states
    % ---------------------------------------------------------------------
    app.SelectedNode = [];
    app.SelectedLine = [];

    app.LineStartNode = [];

    app.CurrentMode = "none";

    % ---------------------------------------------------------------------
    % Default E-field settings
    % ---------------------------------------------------------------------
    app.SandboxEField.Type = "Uniform";
    app.SandboxEField.Magnitude = 1;
    app.SandboxEField.Angle = 0;

    % ---------------------------------------------------------------------
    % Configure sandbox axes
    % ---------------------------------------------------------------------
    cla(app.SandboxAxes)

    hold(app.SandboxAxes,'on')

    grid(app.SandboxAxes,'on')

    axis(app.SandboxAxes,...
    [app.SandboxXMin ...
     app.SandboxXMax ...
     app.SandboxYMin ...
     app.SandboxYMax])

    app.SandboxAxes.XLim =[app.SandboxXMin ...
     app.SandboxXMax];
    app.SandboxAxes.YLim = [app.SandboxYMin ...
     app.SandboxYMax];

    app.SandboxAxes.DataAspectRatio = [1 1 1];

    app.SandboxAxes.Color = [0.05 0.05 0.05];

    app.SandboxAxes.XColor = [1 1 1];
    app.SandboxAxes.YColor = [1 1 1];

    xlabel(app.SandboxAxes,'X Position')
    ylabel(app.SandboxAxes,'Y Position')

    title(app.SandboxAxes,'Interactive GIC Sandbox')

    % ---------------------------------------------------------------------
    % Clear toolbox panel
    % ---------------------------------------------------------------------
    delete(app.ToolboxPanel.Children)

    % ---------------------------------------------------------------------
    % Create toolbox grid layout
    % ---------------------------------------------------------------------
    toolboxGrid = uigridlayout(app.ToolboxPanel);

    toolboxGrid.RowHeight = ...
        {30,30,30,30,15,30,30,30,15,30,30};

    toolboxGrid.ColumnWidth = {'1x'};

    toolboxGrid.Padding = [5 5 5 5];

    % ---------------------------------------------------------------------
    % TOPOLOGY SECTION
    % ---------------------------------------------------------------------
    uilabel(toolboxGrid,...
        'Text','TOPOLOGY',...
        'FontWeight','bold');

    app.AddSubstationButton = uibutton(toolboxGrid,...
        'Text','Add Substation');

    app.AddLineButton = uibutton(toolboxGrid,...
        'Text','Add Line');

    app.AddTransformerButton = uibutton(toolboxGrid,...
        'Text','Add Transformer');

    % ---------------------------------------------------------------------
    % Spacer
    % ---------------------------------------------------------------------
    uilabel(toolboxGrid,'Text','');

    % ---------------------------------------------------------------------
    % E-FIELD SECTION
    % ---------------------------------------------------------------------
    uilabel(toolboxGrid,...
        'Text','E-FIELD',...
        'FontWeight','bold');

    app.EFieldTypeDropDown = uidropdown(toolboxGrid,...
        'Items',{'Uniform','Northward','Eastward','Custom'},...
        'Value','Uniform');

    app.EFieldMagnitudeEditField = uieditfield(toolboxGrid,...
        'numeric',...
        'Value',1);

    app.EFieldAngleSlider = uislider(toolboxGrid);

    app.EFieldAngleSlider.Limits = [0 360];
    app.EFieldAngleSlider.Value = 0;

    % ---------------------------------------------------------------------
    % Spacer
    % ---------------------------------------------------------------------
    uilabel(toolboxGrid,'Text','');

    % ---------------------------------------------------------------------
    % NETWORK SECTION
    % ---------------------------------------------------------------------
    app.LoadHortonButton = uibutton(toolboxGrid,...
        'Text','Load Horton Case');

    app.RunSandboxButton = uibutton(toolboxGrid,...
        'Text','Run Simulation');

end