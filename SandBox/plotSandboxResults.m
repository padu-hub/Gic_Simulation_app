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
        app.SandboxL,...
        app.OldSandboxL,...
        lineColor,...
        showPrev,...
        'Line GIC (A)',...
        'Line GIC vs E-Field Orientation');
    
    plotLineResults(...
        app.SBUIAxes3,...
        theta,...
        I_indResults,...
        I_indResultsOld,...
        app.SandboxL,...
        app.OldSandboxL,...
        lineColor,...
        showPrev,...
        'Induced Current (A)',...
        'Induced Current vs E-Field Orientation');
    
    if showPrev == 1
        plotSandboxComparison(theta,...
            I_indResults,I_indResultsOld,...
            GICLinesResults,GICLinesResultsOld,...
            GICSubsResults,GICSubsResultsOld,...
            app);
    end
    
    % plotSandboxSchematicDifferences( ...
    % theta, ...
    % I_indResults, I_indResultsOld, ...
    % GICLinesResults, GICLinesResultsOld, ...
    % GICSubsResults, GICSubsResultsOld, app)
end









function plotLineResults(ax,theta,currentData,oldData,...
    currentLines,oldLines,...
    lineColor,showPrev,...
    yLabel,plotTitle)

% -------------------------------------------------------
% Clear axis
% -------------------------------------------------------
cla(ax)
hold(ax,'on')
grid(ax,'on')

% -------------------------------------------------------
% Build list of all line names
% -------------------------------------------------------
currNames = {currentLines.Name};

if isempty(oldLines)
    oldNames = {};
else
    oldNames = {oldLines.Name};
end

allNames = unique([currNames oldNames],'stable');

nTheta = numel(theta);

% -------------------------------------------------------
% Plot every line
% -------------------------------------------------------
for k = 1:numel(allNames)

    lineName = allNames{k};

    %---------------------------------------
    % Colour
    %---------------------------------------
    if ~isfield(lineColor,lineName)
        continue
    end

    col = lineColor.(lineName);

    %---------------------------------------
    % Start as zero vectors
    %---------------------------------------
    curr = zeros(nTheta,1);
    old  = zeros(nTheta,1);

    %---------------------------------------
    % Current network
    %---------------------------------------
    idxCurr = find(strcmp(currNames,lineName),1);

    if ~isempty(idxCurr)

        if ~isnan(currentLines(idxCurr).Resistance)

            % Data stored as theta x lines
            if size(currentData,1) == nTheta
                curr = currentData(:,idxCurr);

            % Data stored as lines x theta
            else
                curr = currentData(idxCurr,:)';
            end

        end

    end

    %---------------------------------------
    % Previous network
    %---------------------------------------
    idxOld = find(strcmp(oldNames,lineName),1);

    if ~isempty(idxOld)

        if ~isnan(oldLines(idxOld).Resistance)

            % Data stored as theta x lines
            if size(oldData,1) == nTheta
                old = oldData(:,idxOld);

            % Data stored as lines x theta
            else
                old = oldData(idxOld,:)';
            end

        end

    end

    %---------------------------------------
    % Skip if both are zero
    %---------------------------------------
    if isAllZero(curr) && isAllZero(old)
        continue
    end

    %---------------------------------------
    % Plot previous
    %---------------------------------------
    if showPrev

        plot(ax,...
            theta,...
            old,...
            ':',...
            'Color',col,...
            'LineWidth',1.5,...
            'HandleVisibility','off');

    end

    %---------------------------------------
    % Plot current
    %---------------------------------------
    h = plot(ax,...
        theta,...
        curr,...
        'Color',col,...
        'LineWidth',1.5,...
        'DisplayName',lineName);

    uistack(h,'top')

end

% -------------------------------------------------------
% Formatting
% -------------------------------------------------------
xlabel(ax,'E-Field Orientation (deg)')
ylabel(ax,yLabel)
title(ax,plotTitle)
legend(ax,'show','Location','eastoutside')

hold(ax,'off')

end


%========================================================
% Helper
%========================================================
function tf = isAllZero(x)

tol = 1e-12;

if isempty(x)
    tf = true;
    return
end

x = x(~isnan(x));

tf = isempty(x) || all(abs(x)<tol);

end

















function c = lighten(c0,factor)

% factor = 0 -> original colour
% factor = 1 -> white

c = c0 + factor*(1-c0);

end


