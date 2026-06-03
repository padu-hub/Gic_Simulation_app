% -------------------------------------------------------------------------
% Draw Sandbox Network
% -------------------------------------------------------------------------
function drawSandboxNetwork(app)

    cla(app.SandboxAxes)

    hold(app.SandboxAxes,'on')
    grid(app.SandboxAxes,'on')

    axis(app.SandboxAxes,[0 100 0 100])

    app.SandboxAxes.XTick = [];
    app.SandboxAxes.YTick = [];

    % -------------------------------------------------------------
    % Preallocate Handle Arrays
    % -------------------------------------------------------------
    app.SandboxLineHandles = gobjects(length(app.SandboxL),1);

    app.SandboxNodeHandles = gobjects(length(app.SandboxS),1);

    app.SandboxTextHandles = gobjects(length(app.SandboxS),1);

    % -------------------------------------------------------------
    % Draw Lines
    % -------------------------------------------------------------
    for k = 1:length(app.SandboxL)

        fromSub = app.OriginalSandboxL(k).fromSub;
        toSub   = app.OriginalSandboxL(k).toSub;
        
        % fromSub and toSub are always chars like 'Sub12' - extract trailing number
        fromSub = sscanf(fromSub, '%*[^0-9]%d');
        toSub   = sscanf(toSub,   '%*[^0-9]%d');

        x = [
            app.SandboxS(fromSub).Longitude
            app.SandboxS(toSub).Longitude
            ];

        y = [
            app.SandboxS(fromSub).Latitude
            app.SandboxS(toSub).Latitude
            ];
        
        

        app.SandboxLineHandles(k) = ...
            plot(app.SandboxAxes,...
            x,y,...
            'r-',...
            'LineWidth',2);
        
        % Create text label for the line (midpoint of the segment)
        midX = mean(x);
        midY = mean(y);

        % Store text handle
        app.SandboxTextHandles(k) = ...
            text(app.SandboxAxes, ...
            midX, midY+4, app.OriginalSandboxL(k).Name, ...
            'HorizontalAlignment','center', ...
            'BackgroundColor','none', ...
            'FontWeight','normal');

        app.SandboxLineHandles(k).ButtonDownFcn = ...
            @(src,event) toggleLineConnection(app,k);

    end

    % -------------------------------------------------------------
    % Draw Substations
    % -------------------------------------------------------------
    for k = 1:length(app.SandboxS)

        x = app.SandboxS(k).Longitude;
        y = app.SandboxS(k).Latitude;

        app.SandboxNodeHandles(k) = ...
            plot(app.SandboxAxes,...
            x,...
            y,...
            's',...
            'MarkerSize',12,...
            'MarkerFaceColor',[0.2 0.5 1],...
            'MarkerEdgeColor','k',...
            'LineWidth',1.5);
        
        app.SandboxNodeHandles(k).ButtonDownFcn = ...
            @(src,event) sandboxMouseDown(app);
        
        app.SandboxTextHandles(k+6) = ...
            text(app.SandboxAxes,...
            x+3,...
            y,...
            app.SandboxS(k).Name,...
            'FontWeight','bold');

    end

    title(app.SandboxAxes,'Topology Sandbox')
    
    app.SandboxAxes.ButtonDownFcn = ...
    @(src,event) sandboxMouseDown(app);
end