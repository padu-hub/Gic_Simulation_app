% -------------------------------------------------------------------------
% Toggle Line Connection
% -------------------------------------------------------------------------
function toggleLineConnection(app,lineID)

    % -------------------------------------------------------------
    % Currently Connected
    % -------------------------------------------------------------
    if ~isnan(app.SandboxL(lineID).ResKm)

        % Disconnect

        app.SandboxL(lineID).ResKm = NaN;

        app.SandboxL(lineID).Resistance = NaN;

        app.SandboxLineHandles(lineID).Color = ...
            [0.6 0.6 0.6];

        app.SandboxLineHandles(lineID).LineStyle = '--';

        app.LineConnectedCheck(lineID).Value = false;

    else

        % Reconnect

        reskm = app.LineR1Edit(lineID).Value;

        app.SandboxL(lineID).ResKm = reskm;

        app.SandboxL(lineID).Resistance = ...
            reskm * app.SandboxL(lineID).Length;

        app.SandboxLineHandles(lineID).Color = ...
            [1 0 0];

        app.SandboxLineHandles(lineID).LineStyle = '-';

        app.LineConnectedCheck(lineID).Value = true;

    end

end