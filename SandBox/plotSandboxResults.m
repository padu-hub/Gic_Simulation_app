% -------------------------------------------------------------------------
% Plot Sandbox Results
% -------------------------------------------------------------------------
function plotSandboxResults( ...
    app,...
    theta,...
    GICSubsResults,...
    GICLinesResults,...
    EMFResults)

    % =============================================================
    % Clear Existing Plots
    % =============================================================
    cla(app.SBUIAxes)
    cla(app.SBUIAxes2)
    cla(app.SBUIAxes3)

    % =============================================================
    % Substation GIC Plot
    % =============================================================
    hold(app.SBUIAxes,'on')

    for k = 1:size(GICSubsResults,1)
        plot(app.SBUIAxes,...
            theta,...
            GICSubsResults(k,:),...
            'LineWidth',1.5,...
            'DisplayName',...
            app.SandboxS(k).Name);
    end

    hold(app.SBUIAxes,'off')

    grid(app.SBUIAxes,'on')

    xlabel(app.SBUIAxes,...
        'E-Field Orientation (deg)')

    ylabel(app.SBUIAxes,...
        'GIC (A)')

    title(app.SBUIAxes,...
        'Substation GIC vs E-Field Orientation')

    legend(app.SBUIAxes,'show')

    % =============================================================
    % Line GIC Plot
    % =============================================================
    hold(app.SBUIAxes2,'on')

    for k = 1:size(GICLinesResults,1)

        plot(app.SBUIAxes2,...
            theta,...
            GICLinesResults(k,:),...
            'LineWidth',1.5,...
            'DisplayName',...
            app.SandboxL(k).Name);

    end

    hold(app.SBUIAxes2,'off')

    grid(app.SBUIAxes2,'on')

    xlabel(app.SBUIAxes2,...
        'E-Field Orientation (deg)')

    ylabel(app.SBUIAxes2,...
        'GIC (A)')

    title(app.SBUIAxes2,...
        'Line GIC vs E-Field Orientation')

    legend(app.SBUIAxes2,'show')

    % =============================================================
    % EMF Plot
    % =============================================================
    hold(app.SBUIAxes3,'on')

    for k = 1:size(EMFResults,2)

        plot(app.SBUIAxes3,...
            theta,...
            EMFResults(:,k),...
            'LineWidth',1.5,...
            'DisplayName',...
            app.SandboxL(k).Name);

    end

    hold(app.SBUIAxes3,'off')

    grid(app.SBUIAxes3,'on')

    xlabel(app.SBUIAxes3,...
        'E-Field Orientation (deg)')

    ylabel(app.SBUIAxes3,...
        'EMF (V)')

    title(app.SBUIAxes3,...
        'Line EMF vs E-Field Orientation')

    legend(app.SBUIAxes3,'show')

end