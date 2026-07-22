function plotSandboxComparison(theta,...
    I_indResults,I_indResultsOld,...
    GICLinesResults,GICLinesResultsOld,...
    GICSubsResults,GICSubsResultsOld,...
    app)

theta = theta(:);

%-------------------------------------------------------
% Nothing to compare
%-------------------------------------------------------
if isempty(I_indResultsOld) || ...
   isempty(GICLinesResultsOld) || ...
   isempty(GICSubsResultsOld)
    return
end

%-------------------------------------------------------
% Figure
%-------------------------------------------------------
figure(...
    'Color','w',...
    'Name','Sandbox Comparison',...
    'NumberTitle','off');

t = tiledlayout(3,1,...
    'TileSpacing','compact',...
    'Padding','compact');

%=======================================================
% Induced Current
%=======================================================
ax1 = nexttile;

plotComparison(...
    ax1,...
    theta,...
    I_indResults,...
    I_indResultsOld,...
    app.SandboxL,...
    app.OldSandboxL,...
    'Induced Current (A)',...
    'Induced Current');

%=======================================================
% Line GIC
%=======================================================
ax2 = nexttile;

plotComparison(...
    ax2,...
    theta,...
    GICLinesResults,...
    GICLinesResultsOld,...
    app.SandboxL,...
    app.OldSandboxL,...
    'Line GIC (A)',...
    'Line GIC');

%=======================================================
% Substation GIC
%=======================================================
ax3 = nexttile;

plotComparison(...
    ax3,...
    theta,...
    GICSubsResults,...
    GICSubsResultsOld,...
    app.SandboxS,...
    [],...
    'Substation GIC (A)',...
    'Substation GIC');

xlabel(ax3,'E-Field Orientation (deg)')

%-------------------------------------------------------
% Common formatting
%-------------------------------------------------------
linkaxes([ax1 ax2 ax3],'x')

xlim([min(theta) max(theta)])

xticks(ax1,0:30:max(theta))
xticks(ax2,0:30:max(theta))
xticks(ax3,0:30:max(theta))

end







function plotComparison(ax,...
    theta,...
    currentData,...
    oldData,...
    currentObjects,...
    oldObjects,...
    yLabel,...
    plotTitle)

%-------------------------------------------------------
% Clear axis
%-------------------------------------------------------
cla(ax);
hold(ax,'on');
grid(ax,'on');

co = lines(max(7,size(currentData,2)));

%=======================================================
% SUBSTATION LOGIC
%=======================================================
if isempty(oldObjects)

    nObj = numel(currentObjects);

    for k = 1:2

        if size(currentData,1) == numel(theta)
            curr = currentData(:,k);
            old  = oldData(:,k);
        else
            curr = currentData(k,:)';
            old  = oldData(k,:)';
        end
        %-----------------------------------------------
        % Skip if identical
        %-----------------------------------------------
        if max(abs(curr-old)) < 1e-12
            continue
        end

        col = co(mod(k-1,size(co,1))+1,:);

        %-----------------------------------------------
        % Previous
        %-----------------------------------------------
        plot(ax,...
            theta,...
            old,...
            '--',...
            'Color',col,...
            'LineWidth',1.5,...
            'HandleVisibility','off');

        %-----------------------------------------------
        % Current
        %-----------------------------------------------
        plot(ax,...
            theta,...
            curr,...
            '-',...
            'Color',col,...
            'LineWidth',2,...
            'DisplayName',currentObjects(k).Name);

    end

%=======================================================
% LINE LOGIC
%=======================================================
else

    currNames = {currentObjects.Name};
    oldNames  = {oldObjects.Name};

    allNames = unique([currNames oldNames],'stable');

    for k = 1:numel(allNames)
    %for k = 1:2
    if k==1||k==6
        lineName = allNames{k};

        idxCurr = find(strcmp(currNames,lineName),1);
        idxOld  = find(strcmp(oldNames,lineName),1);

        %-----------------------------------------------
        % Current values
        %-----------------------------------------------
        if isempty(idxCurr)
            curr = zeros(numel(theta),1);
        else
            if size(currentData,1) == numel(theta)
                curr = currentData(:,idxCurr);
            else
                curr = currentData(idxCurr,:)';
            end
        end

        %-----------------------------------------------
        % Previous values
        %-----------------------------------------------
        if isempty(idxOld)
            old = zeros(numel(theta),1);
        else
            if size(oldData,1) == numel(theta)
                old = oldData(:,idxOld);
            else
                old = oldData(idxOld,:)';
            end
        end

        %-----------------------------------------------
        % Skip if identical
        %-----------------------------------------------
        % if max(abs(curr-old)) < 1e-12
        %     continue
        % end

        col = co(mod(k-1,size(co,1))+1,:);

        %-----------------------------------------------
        % Previous
        %-----------------------------------------------
        plot(ax,...
            theta,...
            old,...
            '--',...
            'Color',col,...
            'LineWidth',1.5,...
            'HandleVisibility','off');

        %-----------------------------------------------
        % Current
        %-----------------------------------------------
        plot(ax,...
            theta,...
            curr,...
            '-',...
            'Color',col,...
            'LineWidth',2,...
            'DisplayName',lineName);
    end
    end

end

%-------------------------------------------------------
% Labels
%-------------------------------------------------------
xlabel(ax,'E-Field Angle (°)');
ylabel(ax,yLabel);
title(ax,plotTitle);
legend(ax,'show','Location','eastoutside');
set(ax, 'FontSize', 16);

end