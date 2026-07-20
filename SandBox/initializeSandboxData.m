function initializeSandboxData(app)

    % =====================================================
    % Default E-field settings
    % =====================================================
    app.NumberofE_fieldpointsEditField.Value = 10;
    app.EfieldValueEditField.Value = 1;

    % =====================================================
    % Default Substation Coordinates
    % =====================================================
    % xy = [
    %     -75     0;    % S1
    %      75     0;    % S2
    %     125    90;    % S3
    %     125   -90;    % S4
    %    -125   -90;    % S5
    %    -125    90     % S6
    % ];
    xy = [
       -10     0;    % S1
        10     0;    % S2
        30    25;    % S3
        30   -25;    % S4
       -30   -25;    % S5
       -30    25     % S6
    ];
    
    % =====================================================
    % Build S Structure
    % =====================================================
    for k = 1:6

        app.SandboxS(k).Name = sprintf('Sub%d',k);

        app.SandboxS(k).Latitude = xy(k,2);
        app.SandboxS(k).Longitude = xy(k,1);

        app.SandboxS(k).Resistance = 0.2;

        app.SandboxS(k).Loc = ...
            [xy(k,2) xy(k,1)];

    end

    % =====================================================
    % Build L Structure
    % =====================================================
    linePairs = [
        1 2
        2 3
        2 4
        1 5
        1 6
        ];
    
    lineBusPairs = [
        2 3      % L1
        4 5      % L2
        4 7      % L3
        1 9      % L4
        1 11     % L5
        ];
    
    for k = 1:5
    
        fromSub = linePairs(k,1);
        toSub   = linePairs(k,2);
    
        p1 = xy(fromSub,:);
        p2 = xy(toSub,:);
    
        len = norm(p2-p1);
    
        app.SandboxL(k).Name = ...
            sprintf('Line%d',k);
    
        app.SandboxL(k).Voltage = 500;
    
        app.SandboxL(k).fromSub = ...
            sprintf('Sub%d',fromSub);
    
        app.SandboxL(k).toSub = ...
            sprintf('Sub%d',toSub);
    
        app.SandboxL(k).Loc = [
            p1(2) p1(1)
            p2(2) p2(1)
            ];
    
        app.SandboxL(k).ResKm = 1;
    
        % -----------------------------------------
        % Explicit Bus Assignments
        % -----------------------------------------
        app.SandboxL(k).fromBus = ...
            lineBusPairs(k,1);
    
        app.SandboxL(k).toBus = ...
            lineBusPairs(k,2);
    
        app.SandboxL(k).Length = len;
    
        app.SandboxL(k).Resistance = ...
            app.SandboxL(k).ResKm * len;
    
    end
    
    app.OriginalSandboxL = app.SandboxL;

    % =====================================================
    % Build T Structure
    % =====================================================
    for k = 1:6

        app.SandboxT(k).Name = sprintf('T%d',k);

        app.SandboxT(k).Sub = sprintf('Sub%d',k);

        app.SandboxT(k).W1_Voltage = 500;
        app.SandboxT(k).W2_Voltage = 240;

        app.SandboxT(k).W1Bus = 2*k-1;
        app.SandboxT(k).W2Bus = 2*k;

        app.SandboxT(k).W1 = 0.1;
        app.SandboxT(k).W2 = 0.1;

        app.SandboxT(k).HV_Type = 'GY';
        app.SandboxT(k).LV_Type = 'GY';

    end

end
