% -------------------------------------------------------------------------
% Update Existing Sandbox Graphics
% Called During Dragging
% -------------------------------------------------------------------------
function redrawSandboxNetwork(app)

    % =============================================================
    % Update Substations + Labels
    % =============================================================
    for k = 1:length(app.SandboxS)

        x = app.SandboxS(k).Longitude;
        y = app.SandboxS(k).Latitude;

        % ---------------------------------------------------------
        % Move Substation Marker
        % ---------------------------------------------------------
        app.SandboxNodeHandles(k).XData = x;
        app.SandboxNodeHandles(k).YData = y;

        % ---------------------------------------------------------
        % Move Label
        % ---------------------------------------------------------
        app.SandboxTextHandles(k+6).Position = ...
            [x+3 y 0];

    end

    % =============================================================
    % Update Line Coordinates
    % =============================================================
    for k = 1:length(app.OriginalSandboxL)

        fromSub = app.OriginalSandboxL(k).fromSub;
        toSub   = app.OriginalSandboxL(k).toSub;
        
        % fromSub and toSub are always chars like 'Sub12' - extract trailing number
        fromSub = sscanf(fromSub, '%*[^0-9]%d');
        toSub   = sscanf(toSub,   '%*[^0-9]%d');

        x1 = app.SandboxS(fromSub).Longitude;
        y1 = app.SandboxS(fromSub).Latitude;

        x2 = app.SandboxS(toSub).Longitude;
        y2 = app.SandboxS(toSub).Latitude;

        % ---------------------------------------------------------
        % Update Line Graphics
        % ---------------------------------------------------------
        app.SandboxLineHandles(k).XData = [x1 x2];
        app.SandboxLineHandles(k).YData = [y1 y2];

        % Create text label for the line (midpoint of the segment)
        midX = mean([x1 x2]);
        midY = mean([y1 y2]);

        % Store text handle
        app.SandboxTextHandles(k).Position = ...
            [midX midY+4 0];

        % ---------------------------------------------------------
        % Update Length
        % ---------------------------------------------------------
        dx = x2 - x1;
        dy = y2 - y1;

        app.OriginalSandboxL(k).Length = ...
            sqrt(dx^2 + dy^2);

        % ---------------------------------------------------------
        % Update Total Resistance
        % ---------------------------------------------------------
        if isfield(app.OriginalSandboxL(k),'ResKm')

            app.OriginalSandboxL(k).Resistance = ...
                app.OriginalSandboxL(k).ResKm * ...
                app.OriginalSandboxL(k).Length;

        end

    end

    drawnow limitrate

end