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


    



%% ============================================================
% Heatmaps of GIC Difference (New - Old)
% Rows    : Lines/Substations/Induced Currents
% Columns : E-field angle
% Values  : New GIC - Previous GIC
%% ============================================================

fig = figure('Name','GIC Difference Heatmaps','NumberTitle','off');
t = tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

%% ------------------------------------------------------------
% 1. Induced Current Heatmap
%% ------------------------------------------------------------

nexttile

dInd = I_indResults' - I_indResultsOld';

% Keep only rows that contain non-zero data
keep = any(abs(dInd)>0,2);
dInd = dInd(keep,:);

indNames = {app.SandboxL(keep).Name};

imagesc(theta,1:size(dInd,1),dInd)

set(gca,'YDir','normal')
yticks(1:length(indNames))
yticklabels(indNames)

xlabel('E-Field Angle (deg)')
ylabel('Lines')
title('Induced Current Difference (New - Old)')

colorbar
colormap(redblue(30))

%% ------------------------------------------------------------
% 2. Line GIC Heatmap
%% ------------------------------------------------------------

nexttile

dLine = GICLinesResults - GICLinesResultsOld;

keep = any(abs(dLine)>0,2);
dLine = dLine(keep,:);

lineNames = {app.SandboxL(keep).Name};

imagesc(theta,1:size(dLine,1),dLine)

set(gca,'YDir','normal')
yticks(1:length(lineNames))
yticklabels(lineNames)

xlabel('E-Field Angle (deg)')
ylabel('Lines')
title('Line GIC Difference (New - Old)')

colorbar
colormap(redblue(30))

%% ------------------------------------------------------------
% 3. Substation GIC Heatmap
%% ------------------------------------------------------------

nexttile

dSub = GICSubsResults - GICSubsResultsOld;

% Only show substations that ever have non-zero GIC
keep = any(abs(GICSubsResults)>0,2);

dSub = dSub(keep,:);

subNames = {app.SandboxS(keep).Name};

imagesc(theta,1:size(dSub,1),dSub)

set(gca,'YDir','normal')
yticks(1:length(subNames))
yticklabels(subNames)

xlabel('E-Field Angle (deg)')
ylabel('Substations')
title('Substation GIC Difference (New - Old)')

colorbar
colormap(redblue(30))

end




