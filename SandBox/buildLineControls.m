% -------------------------------------------------------------------------
% Build Controls For L1-L5 Tabs
% -------------------------------------------------------------------------
function buildLineControls(app)

    tabs = [
        app.L1Tab
        app.L2Tab
        app.L3Tab
        app.L4Tab
        app.L5Tab
        ];

    % ---------------------------------------------------------------------
    % Preallocate Handle Arrays
    % ---------------------------------------------------------------------
    app.LineConnectedCheck = gobjects(5,1);

    app.LineVoltageDropDown = gobjects(5,1);

    app.LineCircuitDropDown = gobjects(5,1);

    app.LineR1Edit = gobjects(5,1);
    app.LineR2Edit = gobjects(5,1);
    app.LineR3Edit = gobjects(5,1);

    app.LineLengthLabel = gobjects(5,1);
    app.LineBearingLabel = gobjects(5,1);

    % ---------------------------------------------------------------------
    % Create Controls
    % ---------------------------------------------------------------------
    for k = 1:5

        g = uigridlayout(tabs(k));

        g.RowHeight = {20,20,20,22,20,20};
        g.ColumnWidth = {55,'1x'};

        g.Padding = [5 2 5 5];
        g.RowSpacing = 0;
        g.ColumnSpacing = 2;

        % =============================================================
        % Connected
        % =============================================================
        lbl = uilabel(g);

        lbl.Text = 'On';
        lbl.FontSize = 10;

        lbl.Layout.Row = 1;
        lbl.Layout.Column = 1;

        app.LineConnectedCheck(k) = uicheckbox(g);

        app.LineConnectedCheck(k).Value = true;

        app.LineConnectedCheck(k).Layout.Row = 1;
        app.LineConnectedCheck(k).Layout.Column = 2;
        
        app.LineConnectedCheck(k).ValueChangedFcn = ...
            @(src,event) lineCheckboxChanged(app,k);

        % =============================================================
        % Voltage
        % =============================================================
        lbl = uilabel(g);

        lbl.Text = 'kV';
        lbl.FontSize = 10;

        lbl.Layout.Row = 2;
        lbl.Layout.Column = 1;

        app.LineVoltageDropDown(k) = uidropdown(g);

        app.LineVoltageDropDown(k).Items = {'240','500'};
        app.LineVoltageDropDown(k).Value = '500';

        app.LineVoltageDropDown(k).FontSize = 10;

        app.LineVoltageDropDown(k).Layout.Row = 2;
        app.LineVoltageDropDown(k).Layout.Column = 2;

        % =============================================================
        % Circuits
        % =============================================================
        lbl = uilabel(g);

        lbl.Text = 'Circ';
        lbl.FontSize = 10;

        lbl.Layout.Row = 3;
        lbl.Layout.Column = 1;

        app.LineCircuitDropDown(k) = uidropdown(g);

        app.LineCircuitDropDown(k).Items = {'1','2','3'};
        app.LineCircuitDropDown(k).Value = '1';

        app.LineCircuitDropDown(k).FontSize = 10;

        app.LineCircuitDropDown(k).Layout.Row = 3;
        app.LineCircuitDropDown(k).Layout.Column = 2;

        % =============================================================
        % Resistance Row
        % =============================================================
        rGrid = uigridlayout(g);

        rGrid.RowHeight = {'1x'};
        rGrid.ColumnWidth = {40,30,40,30,40,30};

        rGrid.Padding = [0, 0, 0, 0];
        rGrid.RowSpacing = 0;
        rGrid.ColumnSpacing = 2;

        rGrid.Layout.Row = 4;
        rGrid.Layout.Column = [1 2];

        % -------------------------
        % R1
        % -------------------------
        uilabel(rGrid,...
            'Text','R1/km:',...
            'FontSize',10);

        app.LineR1Edit(k) = ...
            uieditfield(rGrid,'numeric');

        app.LineR1Edit(k).Value = 0.01;
        app.LineR1Edit(k).FontSize = 10;

        % -------------------------
        % R2
        % -------------------------
        uilabel(rGrid,...
            'Text','R2/km:',...
            'FontSize',10);

        app.LineR2Edit(k) = ...
            uieditfield(rGrid,'numeric');

        app.LineR2Edit(k).Value = 0.01;
        app.LineR2Edit(k).FontSize = 10;
        

        % -------------------------
        % R3
        % -------------------------
        uilabel(rGrid,...
            'Text','R3/km:',...
            'FontSize',10);

        app.LineR3Edit(k) = ...
            uieditfield(rGrid,'numeric');

        app.LineR3Edit(k).Value = 0.01;
        app.LineR3Edit(k).FontSize = 10;

    end

end