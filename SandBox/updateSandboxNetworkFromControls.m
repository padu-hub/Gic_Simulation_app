% -------------------------------------------------------------------------
% Update Sandbox Network From Controls
% -------------------------------------------------------------------------
function updateSandboxNetworkFromControls(app)

    % =====================================================
    % Update Substations
    % =====================================================
    for k = 1:length(app.SandboxS)

        app.SandboxS(k).Resistance = ...
            app.SubGroundEdit(k).Value;

    end

    % =====================================================
    % Update Transformers
    % =====================================================
    for k = 1:length(app.SandboxT)

        app.SandboxT(k).W1 = ...
            app.SubWindingEdit(k).Value;

        app.SandboxT(k).W2 = ...
            app.SubWindingEdit(k).Value;

        tfType = ...
            app.SubTypeDropDown(k).Value;

        switch tfType

            case 'Wye-Wye'

                app.SandboxT(k).HV_Type = 'wye';
                app.SandboxT(k).LV_Type = 'wye';

            case 'Wye-Delta'

                app.SandboxT(k).HV_Type = 'wye';
                app.SandboxT(k).LV_Type = 'delta';

            case 'Auto'

                app.SandboxT(k).HV_Type = 'auto';
                app.SandboxT(k).LV_Type = 'auto';

        end

    end

    % =====================================================
    % Rebuild Line Structure
    % =====================================================
    
    baseL = app.OriginalSandboxL;
    
    app.SandboxL = struct([]);
    
    idx = 1;
    
    for k = 1:length(baseL)
    
        % -------------------------------------------------
        % Substations connected by this corridor
        % -------------------------------------------------
        fromSub = sscanf( ...
            baseL(k).fromSub,...
            '%*[^0-9]%d');
    
        toSub = sscanf( ...
            baseL(k).toSub,...
            '%*[^0-9]%d');
    
        % -------------------------------------------------
        % Current Coordinates
        % -------------------------------------------------
        p1 = [
            app.SandboxS(fromSub).Longitude
            app.SandboxS(fromSub).Latitude
            ];
    
        p2 = [
            app.SandboxS(toSub).Longitude
            app.SandboxS(toSub).Latitude
            ];
    
        len = norm(p2-p1);
    
        loc = [
            p1(2) p1(1)
            p2(2) p2(1)
            ];
    
        % -------------------------------------------------
        % Number of Circuits
        % -------------------------------------------------
        nCircuits = ...
            str2double(app.LineCircuitDropDown(k).Value);
    
        % -------------------------------------------------
        % Resistance Inputs
        % -------------------------------------------------
        Rvals = [ ...
            app.LineR1Edit(k).Value,...
            app.LineR2Edit(k).Value,...
            app.LineR3Edit(k).Value];
    
        suffix = {'','_ii','_iii'};
    
        % -------------------------------------------------
        % Create Circuits
        % -------------------------------------------------
        for c = 1:nCircuits
    
            % ---------------------------------------------
            % Name
            % ---------------------------------------------
            app.SandboxL(idx).Name = ...
                [baseL(k).Name suffix{c}];
    
            % ---------------------------------------------
            % Electrical Data
            % ---------------------------------------------
            app.SandboxL(idx).Voltage = ...
                baseL(k).Voltage;
    
            app.SandboxL(idx).fromSub = ...
                baseL(k).fromSub;
    
            app.SandboxL(idx).toSub = ...
                baseL(k).toSub;
    
            app.SandboxL(idx).fromBus = ...
                baseL(k).fromBus;
    
            app.SandboxL(idx).toBus = ...
                baseL(k).toBus;
    
            % ---------------------------------------------
            % Geometry
            % ---------------------------------------------
            app.SandboxL(idx).Length = len;
    
            app.SandboxL(idx).Loc = loc;
    
            % ---------------------------------------------
            % Resistance
            % ---------------------------------------------
            if isnan(baseL(k).ResKm)||~app.LineConnectedCheck(k).Value
    
                app.SandboxL(idx).ResKm = NaN;
    
                app.SandboxL(idx).Resistance = NaN;
    
            else
    
                app.SandboxL(idx).ResKm = ...
                    Rvals(c);
    
                app.SandboxL(idx).Resistance = ...
                    Rvals(c) * len;
    
            end
    
            idx = idx + 1;
    
        end
    
    end
end