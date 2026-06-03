% -------------------------------------------------------------------------
% Build Sandbox Simulation Network
% -------------------------------------------------------------------------
function [Ssim,Lsim,Tsim,latq,lonq] = ...
    buildSandboxSimulationNetwork(app)

    % =====================================================
    % Copy Sandbox Network
    % =====================================================
    Ssim = app.SandboxS;
    Lsim = app.SandboxL;
    Tsim = app.SandboxT;

    % =====================================================
    % Convert Substations To Real Coordinates
    % =====================================================
    for k = 1:length(Ssim)

        % -------------------------------------------------
        % Sandbox Coordinates
        % -------------------------------------------------
        x = Ssim(k).Longitude;
        y = Ssim(k).Latitude;

        % -------------------------------------------------
        % Convert To Projected Coordinates (m)
        % -------------------------------------------------
        easting = ...
            app.SandboxOriginEasting + ...
            x * app.SandboxScaleKm * 1000;

        northing = ...
            app.SandboxOriginNorthing + ...
            y * app.SandboxScaleKm * 1000;

        % -------------------------------------------------
        % Convert To Lat/Lon
        % -------------------------------------------------
        [lat,lon] = projinv( ...
            app.SandboxProj,...
            easting,...
            northing);

        % -------------------------------------------------
        % Store Real Coordinates
        % -------------------------------------------------
        Ssim(k).Latitude = lat;
        Ssim(k).Longitude = lon;

        Ssim(k).Loc = [lat lon];

        Ssim(k).Easting = easting;
        Ssim(k).Northing = northing;

    end

    % =====================================================
    % Rebuild Line Geometry
    % =====================================================
    for k = 1:length(Lsim)

        fromSub = sscanf( ...
            Lsim(k).fromSub,...
            '%*[^0-9]%d');

        toSub = sscanf( ...
            Lsim(k).toSub,...
            '%*[^0-9]%d');

        % -------------------------------------------------
        % Projected Coordinates
        % -------------------------------------------------
        E1 = Ssim(fromSub).Easting;
        N1 = Ssim(fromSub).Northing;

        E2 = Ssim(toSub).Easting;
        N2 = Ssim(toSub).Northing;

        % -------------------------------------------------
        % Length (km)
        % -------------------------------------------------
        len = sqrt( ...
            (E2-E1).^2 + ...
            (N2-N1).^2 ) / 1000;

        Lsim(k).Length = len;

        % -------------------------------------------------
        % Geographic Coordinates
        % -------------------------------------------------
        Lsim(k).Loc = [ ...
            Ssim(fromSub).Latitude ...
            Ssim(fromSub).Longitude;
            Ssim(toSub).Latitude ...
            Ssim(toSub).Longitude ];

        % -------------------------------------------------
        % Recalculate Resistance
        % -------------------------------------------------
        if ~isnan(Lsim(k).ResKm)

            Lsim(k).Resistance = ...
                Lsim(k).ResKm * len;

        end

    end

    % =====================================================
    % Build E-Field Query Grid
    % =====================================================
    nGrid = ...
        app.NumberofE_fieldpointsEditField.Value;

    x = linspace( ...
        app.SandboxXMin,...
        app.SandboxXMax,...
        nGrid);

    y = linspace( ...
        app.SandboxYMin,...
        app.SandboxYMax,...
        nGrid);

    [X,Y] = meshgrid(x,y);

    % -----------------------------------------------------
    % Convert Grid To Projected Coordinates
    % -----------------------------------------------------
    easting = ...
        app.SandboxOriginEasting + ...
        X(:) * app.SandboxScaleKm * 1000;

    northing = ...
        app.SandboxOriginNorthing + ...
        Y(:) * app.SandboxScaleKm * 1000;

    % -----------------------------------------------------
    % Convert Grid To Lat/Lon
    % -----------------------------------------------------
    [latq,lonq] = projinv( ...
        app.SandboxProj,...
        easting,...
        northing);

end