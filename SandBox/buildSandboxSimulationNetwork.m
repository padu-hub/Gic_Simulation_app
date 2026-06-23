% -------------------------------------------------------------------------
% Build Sandbox Simulation Network
% -------------------------------------------------------------------------
function [Ssim,Lsim,Tsim,latq,lonq] = ...
    buildSandboxSimulationNetwork(app,Ssim,Lsim,Tsim)

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
        % Convert Sandbox -> UTM (m)
        % -------------------------------------------------
        easting = ...
            500000+(x * app.SandboxScaleKm * 1000);

        northing = ...
            y * app.SandboxScaleKm * 1000;

        % -------------------------------------------------
        % Convert UTM -> Lat/Lon
        % -------------------------------------------------
        [lon,lat] = utm2geo( ...
            easting,...
            northing,...
            app.SandboxCentralLongitude,...
            app.SandboxOriginLatitude);

        % -------------------------------------------------
        % Store Coordinates
        % -------------------------------------------------
        Ssim(k).Latitude  = lat;
        Ssim(k).Longitude = lon;

        Ssim(k).Loc = [lat lon];

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
        % Geographic Coordinates
        % -------------------------------------------------
        lat1 = Ssim(fromSub).Latitude;
        lon1 = Ssim(fromSub).Longitude;

        lat2 = Ssim(toSub).Latitude;
        lon2 = Ssim(toSub).Longitude;

        % -------------------------------------------------
        % Compute Distance From Lat/Lon
        % Great-circle distance
        % -------------------------------------------------
        
        d = distance( ...
            lat1, lon1,...
            lat2, lon2);

        len = deg2km(d);

        % -------------------------------------------------
        % Update Length
        % -------------------------------------------------
        Lsim(k).Length = len;

        % -------------------------------------------------
        % Update Location
        % -------------------------------------------------
        Lsim(k).Loc = [ ...
            lat1 lon1;
            lat2 lon2 ];

        % -------------------------------------------------
        % Update Resistance
        % -------------------------------------------------
        Lsim(k).Resistance = Lsim(k).ResKm * len;

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
    % Sandbox -> UTM
    % -----------------------------------------------------
    easting = ...
        500000+ (X(:) * app.SandboxScaleKm * 1000);

    northing = ...
        Y(:) * app.SandboxScaleKm * 1000;

    % -----------------------------------------------------
    % UTM -> Lat/Lon
    % -----------------------------------------------------
    [lonq,latq] = utm2geo(easting, northing, app.SandboxCentralLongitude, app.SandboxOriginLatitude);
    lonq = reshape(lonq, nGrid, nGrid);
    latq = reshape(latq, nGrid, nGrid);


end