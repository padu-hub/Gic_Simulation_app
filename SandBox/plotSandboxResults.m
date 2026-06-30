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








% --- Main plotting script (assumes combineLegend.m is on path) ---
% Create a separate MATLAB figure with three stacked axes (shared x-axis)
fig = figure('Name','Sandbox Results (Stacked)', 'NumberTitle','off');

% Layout
pad = 0.04;
bot = 0.08;
top = 0.92;
heightTotal = top - bot;
hEach = (heightTotal - 2*pad) / 3;

posInd  = [0.12, bot + 2*(hEach+pad), 0.78, hEach];
posLine = [0.12, bot + (hEach+pad), 0.78, hEach];
posSub  = [0.12, bot, 0.78, hEach];

axInd = axes('Parent', fig, 'Position', posInd, 'Box', 'on');
axLine = axes('Parent', fig, 'Position', posLine, 'Box', 'on');
axSub  = axes('Parent', fig, 'Position', posSub, 'Box', 'on');

linkaxes([axInd, axLine, axSub], 'x');
axInd.XTickLabel = [];
axLine.XTickLabel = [];

ylabel(axInd, 'Induced Current (A)');
title(axInd, 'Induced current vs E-Field Orientation');
ylabel(axLine, 'GIC (A)');
title(axLine, 'Line GIC vs E-Field Orientation');
xlabel(axSub, 'E-Field Orientation (deg)');
ylabel(axSub, 'GIC (A)');
title(axSub, 'Substation GIC vs E-Field Orientation');

grid(axInd,'on'); grid(axLine,'on'); grid(axSub,'on');

co = axInd.ColorOrder;
nC = size(co,1);

% -------------------------
% Induced currents (top)
% -------------------------
hold(axInd,'on')
nIndNew = size(I_indResults,2);
nIndOldAvailable = size(I_indResultsOld,2);

for k = 1:nIndNew
    % skip if the corresponding sandbox entry indicates not present
    if k <= numel(app.SandboxL) && isnan(app.SandboxL(k).Resistance)
        continue
    end
    col = co(mod(k-1,nC)+1,:);
    % skip if new series is all zeros
    if all(I_indResults(:,k) == 0)
        continue
    end

    % plot old if requested and present
    if showPrev && k <= nIndOldAvailable
        if ~all(I_indResultsOld(:,k) == 0)
            % special-case: old index 2 plotted dotted black when old had 6 and new 5
            if k == 2 && nIndNew == 5 && nIndOldAvailable == 6
                plot(axInd, theta, I_indResultsOld(:,k), 'LineWidth',2, 'LineStyle','--', 'Color',[0 0 0], 'HandleVisibility','off');
            else
                plot(axInd, theta, I_indResultsOld(:,k), 'LineWidth',2, 'LineStyle','--', 'Color',col, 'HandleVisibility','off');
            end
        end
    end
        % plot new
    plot(axInd, theta, I_indResults(:,k), 'LineWidth',1.2, 'LineStyle','-', 'Color',col, 'DisplayName', app.SandboxL(k).Name);
end

hold(axInd,'off')
% combine duplicates and ensure Line 1_ii is labelled if present
legend(axInd,'show','Location','bestoutside')

% -------------------------
% Line GICs (middle)
% -------------------------
hold(axLine,'on')
nLinesAvailable = size(GICLinesResults,1);
nLinesOldAvailable = size(GICLinesResultsOld,1);

for k = 1:min(nLinesAvailable)
    % skip if sandbox indicates disconnected
    if k <= numel(app.SandboxL) && isnan(app.SandboxL(k).Resistance)
        continue
    end
    % skip if new series is all zeros
    if all(GICLinesResults(k,:) == 0)
        continue
    end
    col = co(mod(k-1,nC)+1,:);
   
    % plot old if available
    if showPrev
        if k <= nLinesOldAvailable && ~all(GICLinesResultsOld(k,:) == 0)
            if k == 2 && nLinesAvailable == 5 && nLinesOldAvailable == 6
                plot(axLine, theta, GICLinesResultsOld(k,:), 'LineWidth',2, 'LineStyle','--', 'Color',[0 0 0], 'HandleVisibility','off');
            else
                plot(axLine, theta, GICLinesResultsOld(k,:), 'LineWidth',2, 'LineStyle','--', 'Color',col, 'HandleVisibility','off');
            end
        end
    end

    % plot new
    plot(axLine, theta, GICLinesResults(k,:), 'LineWidth',1.2, 'LineStyle','-', 'Color',col, 'DisplayName', app.SandboxL(k).Name);


end

hold(axLine,'off')
% combine duplicates and ensure Line 1_ii is labelled if present
legend(axLine,'show','Location','bestoutside')

% -------------------------
% Substation GICs (bottom)
% -------------------------
hold(axSub,'on')
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
        plot(axSub, theta, GICSubsResultsOld(k,:), 'LineWidth',2, 'LineStyle','--', 'Color',col, 'HandleVisibility','off');
    end

    plot(axSub, theta, GICSubsResults(k,:), 'LineWidth',1.2, 'LineStyle','-', 'Color',col, 'DisplayName', app.SandboxS(k).Name);
end
hold(axSub,'off')
legend(axSub,'show','Location','bestoutside')

% Match x-limits
if ~isempty(theta)
    xlimVal = [min(theta(:)), max(theta(:))];
    xlim(axSub, xlimVal)
    xlim(axLine, xlimVal)
    xlim(axInd, xlimVal)
end


end




