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
        if showPrev
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
    
            if showPrev 
                plot(ax, theta, GICLinesResultsOld(k,:), ...
                    'LineWidth',1.5, 'LineStyle',':', ...
                    'Color', col, 'HandleVisibility','off', 'DisplayName','');
            end
    
            pCurr = plot(ax, theta, GICLinesResults(k,:), ...
                'LineWidth',1.5, 'LineStyle','-', ...
                'Color', col, 'DisplayName', app.SandboxL(k).Name);
            uistack(pCurr,'top');
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
            if showPrev
            plot(ax, theta, I_indResultsOld(:,k), ...
            'LineWidth',1.5, 'LineStyle',':', ...
            'Color', col, 'HandleVisibility','off', 'DisplayName','');
            end
            
            pCurr = plot(ax, theta, I_indResults(:,k), ...
            'LineWidth',1.5, 'LineStyle','-', ...
            'Color', col, 'DisplayName', app.SandboxL(k).Name);
            uistack(pCurr,'top');
        end
    end
    hold(ax,'off')
    grid(ax,'on')
    xlabel(ax,'E-Field Orientation (deg)')
    ylabel(ax,'Induced Current (A)')
    title(ax,'Induced current vs E-Field Orientation')
    legend(ax,'show')

    
% Create a separate MATLAB figure with three stacked axes (shared x-axis)
fig = figure('Name','Sandbox Results (Stacked)', 'NumberTitle','off');

% Base normalized positions within figure for three stacked axes
pad = 0.04; % vertical padding between plots (normalized)
bot = 0.08;
top = 0.92;
heightTotal = top - bot;
hEach = (heightTotal - 2*pad) / 3;

% Positions from top to bottom: Induced (top), Line GIC (middle), Substation GIC (bottom)
posInd = [0.12, bot + 2*(hEach+pad), 0.78, hEach];
posLine = [0.12, bot + (hEach+pad), 0.78, hEach];
posSub  = [0.12, bot, 0.78, hEach];

axInd = axes('Parent', fig, 'Position', posInd, 'Box', 'on');
axLine = axes('Parent', fig, 'Position', posLine, 'Box', 'on');
axSub = axes('Parent', fig, 'Position', posSub, 'Box', 'on');

% Link x-axes so they share the same x range and zoom/pan together
linkaxes([axInd, axLine, axSub], 'x');

% Hide x-tick labels for top and middle axes
axInd.XTickLabel = [];
axLine.XTickLabel = [];

% Labels and titles
ylabel(axInd, 'Induced Current (A)');
title(axInd, 'Induced current vs E-Field Orientation');
ylabel(axLine, 'GIC (A)');
title(axLine, 'Line GIC vs E-Field Orientation');
xlabel(axSub, 'E-Field Orientation (deg)');
ylabel(axSub, 'GIC (A)');
title(axSub, 'Substation GIC vs E-Field Orientation');

grid(axInd,'on'); grid(axLine,'on'); grid(axSub,'on');

% Use color order from a new axes for consistency
co = axInd.ColorOrder;
nC = size(co,1);

% Plot Induced currents (top) - show new vs old
hold(axInd,'on')
nEMFcols = size(I_indResults,2);
for k = 1:nEMFcols
    if ~isnan(app.SandboxL(k).Resistance)
        col = co(mod(k-1,nC)+1,:);
        if showPrev
            plot(axInd, theta, I_indResultsOld(:,k), 'LineWidth',1.2, 'LineStyle',':', 'Color',col, 'HandleVisibility','off');
        end
        plot(axInd, theta, I_indResults(:,k), 'LineWidth',1.5, 'LineStyle','-', 'Color',col, 'DisplayName', app.SandboxL(k).Name);
    end
end
hold(axInd,'off')
legend(axInd,'show','Location','bestoutside')

% Plot Line GICs (middle) - show new vs old
hold(axLine,'on')
nLines = size(GICLinesResults,1);
for k = 1:nLines
    if ~isnan(app.SandboxL(k).Resistance)||k ~= 2
        col = co(mod(k-1,nC)+1,:);
        if showPrev
            plot(axLine, theta, GICLinesResultsOld(k,:), 'LineWidth',1.2, 'LineStyle',':', 'Color',col, 'HandleVisibility','off');
        end
        plot(axLine, theta, GICLinesResults(k,:), 'LineWidth',1.5, 'LineStyle','-', 'Color',col, 'DisplayName', app.SandboxL(k).Name);
    end
end
hold(axLine,'off')
legend(axLine,'show','Location','bestoutside')

% Plot Substation GICs (bottom) - show new vs old
hold(axSub,'on')
%nSubsPlot = size(GICSubsResults,1);
nSandbox = numel(app.SandboxL);
for k = 1:2
    % follow same plotting decision logic as original
    if k <= 2
        doPlot = true;
    else
        prev = k - 1;
        if prev <= nSandbox && isnan(app.SandboxL(prev).Resistance)
            doPlot = false;
        else
            doPlot = true;
        end
    end
    if ~doPlot, continue, end
    col = co(mod(k-1,nC)+1,:);
    if showPrev
        plot(axSub, theta, GICSubsResultsOld(k,:), 'LineWidth',1.2, 'LineStyle',':', 'Color',col, 'HandleVisibility','off');
    end
    plot(axSub, theta, GICSubsResults(k,:), 'LineWidth',1.5, 'LineStyle','-', 'Color',col, 'DisplayName', app.SandboxS(k).Name);
end
hold(axSub,'off')
legend(axSub,'show','Location','bestoutside')

% Ensure x-limits match theta range across all axes
if ~isempty(theta)
    xlimVal = [min(theta(:)), max(theta(:))];
    xlim(axSub, xlimVal)
    xlim(axLine, xlimVal)
    xlim(axInd, xlimVal)
end
end
