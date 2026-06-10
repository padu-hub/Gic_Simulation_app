function resetSandbox(app)

 % =====================================================
    % Default Substation Coordinates
    % =====================================================
    xy = [
        -10   0 ;   % S1
         10   0 ;   % S2
         30  25 ;   % S3
         30 -25 ;   % S4
        -30 -25 ;   % S5
        -30  25     % S6
        ];
    % =====================================================
    % Fix S Structure
    % =====================================================
    for k = 1:6
        app.SandboxS(k).Latitude = xy(k,2);
        app.SandboxS(k).Longitude = xy(k,1);
        app.SandboxS(k).Loc = ...
            [xy(k,2) xy(k,1)];

    end
    
    redrawSandboxNetwork(app);
    
end