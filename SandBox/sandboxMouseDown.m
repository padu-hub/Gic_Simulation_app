function sandboxMouseDown(app)

    cp = app.SandboxAxes.CurrentPoint;

    x = cp(1,1);
    y = cp(1,2);

    app.SelectedNode = [];

    for k = 1:length(app.SandboxS)

        x0 = app.SandboxS(k).Longitude;
        y0 = app.SandboxS(k).Latitude;

        d = hypot(x-x0,y-y0);

        if d < 3

            app.SelectedNode = k;
            app.IsDragging = true;

            break

        end


    end

end