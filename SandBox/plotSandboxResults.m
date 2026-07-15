function plotSandboxResults( ...
    app,...
    theta,...
    GICSubsResults,...
    GICLinesResults,...
    I_indResults,...
    GICLinesResultsOld,...
    GICSubsResultsOld, ...
    I_indResultsOld)

    % Clear Existing Plots
    cla(app.SBUIAxes, 'reset')
    cla(app.SBUIAxes2, 'reset')
    cla(app.SBUIAxes3, 'reset')

    showPrev = (isprop(app,'ShowPreviousResultCheckBox') && ...
                app.ShowPreviousResultCheckBox.Value == 1);
    % Note: showPrev == true means DO NOT show previous results per request

    % Decide how many substations to show (based on current results size)
    if app.ShowAllCheckBox.Value == 1
        nSubs = size(GICSubsResults,1);
    else
        nSubs = 2;
    end

    % -------------------------
    % Substation GICs
    % -------------------------
    ax = app.SBUIAxes;
    hold(ax,'on')
    colorOrder = ax.ColorOrder;
    nColors = size(colorOrder,1);

    n = numel(app.SandboxL);
    for k = 1:nSubs
        % always plot 1 and 2
        if k <= 2
            doPlot = true;
        else
            prev = k - 1;
            % only check SandboxL(prev) when prev is in range
            if prev <= n && isnan(app.SandboxL(prev).Resistance)
                doPlot = false;
            else
                doPlot = true;
            end
        end
    
        if ~doPlot
            continue
        end
    
        col = colorOrder(mod(k-1,nColors)+1,:);

        if showPrev && ~isempty(GICSubsResultsOld)
            plot(ax, theta, GICSubsResultsOld(k,:), ...
                'LineWidth',1.5, 'LineStyle',':', ...
                'Color', col, 'HandleVisibility','off', 'DisplayName','');
        end
    
        pCurr = plot(ax, theta, GICSubsResults(k,:), ...
            'LineWidth',1.5, 'LineStyle','-', ...
            'Color', col, 'DisplayName', app.SandboxS(k).Name);
        uistack(pCurr,'top');
    end
    hold(ax,'off')
    grid(ax,'on')
    xlabel(ax,'E-Field Orientation (deg)')
    ylabel(ax,'GIC (A)')
    title(ax,'Substation GIC vs E-Field Orientation')
    legend(ax,'show')

    % -------------------------
    % Line GICs
    % -------------------------
    ax = app.SBUIAxes2;
    hold(ax,'on')
    colorOrder = ax.ColorOrder;
    nColors = size(colorOrder,1);
    nLines = size(GICLinesResults,1);
    for k = 1:nLines
        if ~isnan(app.SandboxL(k).Resistance)
            col = colorOrder(mod(k-1,nColors)+1,:);    
            pCurr = plot(ax, theta, GICLinesResults(k,:), ...
                'LineWidth',1.5, 'LineStyle','-', ...
                'Color', col, 'DisplayName', app.SandboxL(k).Name);
            uistack(pCurr,'top');
        end
    end
    if showPrev && ~isempty(GICLinesResultsOld)
        nLinesOld = size(GICLinesResultsOld,1);
        for k = 1:nLinesOld
            if ~isnan(app.OldSandboxL(k).Resistance)
                col = colorOrder(mod(k-1,nColors)+1,:);    
                plot(ax, theta, GICLinesResultsOld(k,:), ...
                    'LineWidth',1.5, 'LineStyle',':', ...
                    'Color', col, 'HandleVisibility','off', 'DisplayName','');
            end
        end
    end
    hold(ax,'off')
    grid(ax,'on')
    xlabel(ax,'E-Field Orientation (deg)')
    ylabel(ax,'GIC (A)')
    title(ax,'Line GIC vs E-Field Orientation')
    legend(ax,'show')

    % -------------------------
    % Induced Currents
    % -------------------------
    ax = app.SBUIAxes3;
    hold(ax,'on')
    colorOrder = ax.ColorOrder;
    nColors = size(colorOrder,1);
    nEMFcols = size(I_indResults,2);
    for k = 1:nEMFcols
        if ~isnan(app.SandboxL(k).Resistance)
            col = colorOrder(mod(k-1,nColors)+1,:);            
            pCurr = plot(ax, theta, I_indResults(:,k), ...
            'LineWidth',1.5, 'LineStyle','-', ...
            'Color', col, 'DisplayName', app.SandboxL(k).Name);
            uistack(pCurr,'top');
        end
    end

    if showPrev && ~isempty(I_indResultsOld)
        nEMFcolsOld = size(I_indResultsOld, 2);
        for k = 1:nEMFcolsOld
            if ~isnan(app.OldSandboxL(k).Resistance)
                col = colorOrder(mod(k-1,nColors)+1,:);            
                plot(ax, theta, I_indResultsOld(:,k), ...
                    'LineWidth',1.5, 'LineStyle',':', ...
                    'Color', col, 'HandleVisibility','off', 'DisplayName','');
            end
        end
    end

    hold(ax,'off')
    grid(ax,'on')
    xlabel(ax,'E-Field Orientation (deg)')
    ylabel(ax,'Induced Current (A)')
    title(ax,'Induced current vs E-Field Orientation')
    legend(ax,'show')


    % plotSandboxPolar(theta,...
    %     I_indResults,I_indResultsOld,...
    %     GICLinesResults,GICLinesResultsOld,...
    %     GICSubsResults,GICSubsResultsOld, app)
    plotSandboxSchematicDifferences( ...
    theta, ...
    I_indResults, I_indResultsOld, ...
    GICLinesResults, GICLinesResultsOld, ...
    GICSubsResults, GICSubsResultsOld, app)
end




