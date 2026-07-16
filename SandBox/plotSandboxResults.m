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
    % -------------------------
    % Fixed colour for each base transmission line
    % -------------------------
    co = lines(5);
    
    lineColor.Line1      = co(1,:);
    lineColor.Line1_ii   = lighten(co(1,:),0.35);
    lineColor.Line1_iii  = lighten(co(1,:),0.65);
    
    lineColor.Line2      = co(2,:);
    lineColor.Line2_ii   = lighten(co(2,:),0.35);
    lineColor.Line2_iii  = lighten(co(2,:),0.65);
    
    lineColor.Line3      = co(3,:);
    lineColor.Line3_ii   = lighten(co(3,:),0.35);
    lineColor.Line3_iii  = lighten(co(3,:),0.65);
    
    lineColor.Line4      = co(4,:);
    lineColor.Line4_ii   = lighten(co(4,:),0.35);
    lineColor.Line4_iii  = lighten(co(4,:),0.65);
    
    lineColor.Line5      = co(5,:);
    lineColor.Line5_ii   = lighten(co(5,:),0.35);
    lineColor.Line5_iii  = lighten(co(5,:),0.65);

    plotLineResults(...
        app.SBUIAxes2,...
        theta,...
        GICLinesResults,...
        GICLinesResultsOld,...
        app,...
        lineColor,...
        showPrev,...
        'Line GIC (A)',...
        'Line GIC vs E-Field Orientation');
    
    plotLineResults(...
        app.SBUIAxes3,...
        theta,...
        I_indResults,...
        I_indResultsOld,...
        app,...
        lineColor,...
        showPrev,...
        'Induced Current (A)',...
        'Induced Current vs E-Field Orientation');


    % plotSandboxPolar(theta,...
    %     I_indResults,I_indResultsOld,...
    %     GICLinesResults,GICLinesResultsOld,...
    %     GICSubsResults,GICSubsResultsOld, app)
    % plotSandboxSchematicDifferences( ...
    % theta, ...
    % I_indResults, I_indResultsOld, ...
    % GICLinesResults, GICLinesResultsOld, ...
    % GICSubsResults, GICSubsResultsOld, app)
end



























function c = lighten(c0,factor)

% factor = 0 -> original colour
% factor = 1 -> white

c = c0 + factor*(1-c0);

end


