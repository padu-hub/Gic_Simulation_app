% -------------------------------------------------------------------------
% Build Controls For S1-S6 Tabs
% -------------------------------------------------------------------------
function buildSubstationControls(app)

    tabs = [
        app.S1Tab
        app.S2Tab
        app.S3Tab
        app.S4Tab
        app.S5Tab
        app.S6Tab
        ];

    % ---------------------------------------------------------------------
    % Preallocate Handle Arrays
    % ---------------------------------------------------------------------
    app.SubGroundEdit = gobjects(6,1);
    app.SubTypeDropDown = gobjects(6,1);
    app.SubWindingEdit = gobjects(6,1);

    % ---------------------------------------------------------------------
    % Create Controls For Each Substation Tab
    % ---------------------------------------------------------------------
    for k = 1:6

        % -------------------------------------------------------------
        % Compact Grid Layout
        % -------------------------------------------------------------
        g = uigridlayout(tabs(k));

        g.RowHeight = {20,20,20};
        g.ColumnWidth = {55,'1x'};

        g.Padding = [5 2 5 5];
        g.RowSpacing = 0;
        g.ColumnSpacing = 2;

        % -------------------------------------------------------------
        % Ground Resistance
        % -------------------------------------------------------------
        lbl = uilabel(g);

        lbl.Text = 'Ground R';
        lbl.FontSize = 10;

        lbl.Layout.Row = 1;
        lbl.Layout.Column = 1;

        app.SubGroundEdit(k) = ...
            uieditfield(g,'numeric');

        app.SubGroundEdit(k).Layout.Row = 1;
        app.SubGroundEdit(k).Layout.Column = 2;

        app.SubGroundEdit(k).Value = 0.2;
        app.SubGroundEdit(k).FontSize = 10;

        % -------------------------------------------------------------
        % Transformer Type
        % -------------------------------------------------------------
        lbl = uilabel(g);

        lbl.Text = 'Type';
        lbl.FontSize = 10;

        lbl.Layout.Row = 2;
        lbl.Layout.Column = 1;

        app.SubTypeDropDown(k) = ...
            uidropdown(g);

        app.SubTypeDropDown(k).Layout.Row = 2;
        app.SubTypeDropDown(k).Layout.Column = 2;

        app.SubTypeDropDown(k).Items = ...
            {'Wye-Wye','Wye-Delta','Auto'};

        app.SubTypeDropDown(k).Value = 'Wye-Wye';
        app.SubTypeDropDown(k).FontSize = 10;

        % -------------------------------------------------------------
        % Winding Resistance
        % -------------------------------------------------------------
        lbl = uilabel(g);

        lbl.Text = 'Wind R';
        lbl.FontSize = 10;

        lbl.Layout.Row = 3;
        lbl.Layout.Column = 1;

        app.SubWindingEdit(k) = ...
            uieditfield(g,'numeric');

        app.SubWindingEdit(k).Layout.Row = 3;
        app.SubWindingEdit(k).Layout.Column = 2;

        app.SubWindingEdit(k).Value = 0.1;
        app.SubWindingEdit(k).FontSize = 10;

    end

end