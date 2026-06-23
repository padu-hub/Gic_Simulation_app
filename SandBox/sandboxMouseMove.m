function sandboxMouseMove(app)

    if ~app.IsDragging
        return
    end

    if ~strcmp(app.UIFigure.SelectionType,'normal')

        app.IsDragging = false;
        app.SelectedNode = [];

        return

    end

    cp = app.SandboxAxes.CurrentPoint;

    x = cp(1,1);
    y = cp(1,2);

    k = app.SelectedNode;

    app.SandboxS(k).Longitude = x;
    app.SandboxS(k).Latitude  = y;

    app.SandboxS(k).Loc = [y x];

    redrawSandboxNetwork(app);

end