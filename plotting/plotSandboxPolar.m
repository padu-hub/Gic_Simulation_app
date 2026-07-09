function plotSandboxPolar(theta, ...
    I_indResults, I_indResultsOld, ...
    GICLinesResults, GICLinesResultsOld, ...
    GICSubsResults, GICSubsResultsOld, ...
    app)

theta = theta(:);
if isempty(app) || ~isprop(app,'OldSandboxL') || isempty(app.OldSandboxL)
    oldLineNames = {};
else
    oldLineNames = {app.OldSandboxL.Name};
end

if isempty(I_indResultsOld) || ...
   isempty(GICLinesResultsOld) || ...
   isempty(GICSubsResultsOld)
    return
end

tol = 1e-12;

isSame = @(A,B) ...
    isequal(size(A),size(B)) && ...
    all(abs(A(:)-B(:)) < tol);

if isSame(I_indResults,I_indResultsOld) && ...
   isSame(GICLinesResults,GICLinesResultsOld) && ...
   isSame(GICSubsResults,GICSubsResultsOld)

    return
end


%% Merge duplicate OLD entries
[I_indResultsOld, indNames] = mergeDuplicateNames(I_indResultsOld, oldLineNames);
[I_indResults,    ~]        = mergeDuplicateNames(I_indResults,    {app.SandboxL.Name});

[GICLinesResultsOld, lineNames] = mergeDuplicateNames(GICLinesResultsOld, oldLineNames);
[GICLinesResults,    ~]         = mergeDuplicateNames(GICLinesResults,    {app.SandboxL.Name});

%% Calculate differences
dInd  = abs(I_indResults)  - abs(I_indResultsOld);
dLine = abs(GICLinesResults) - abs(GICLinesResultsOld);
dSub  = abs(GICSubsResults)  - abs(GICSubsResultsOld);



%% Figure
figure( ...
    'Color','w',...
    'Name','Sandbox Difference',...
    'NumberTitle','off');

t = tiledlayout(3,1,...
    'TileSpacing','compact',...
    'Padding','compact');

co = lines(7);

%% ============================================================
% Induced Current
%% ============================================================

ax1 = nexttile;
hold(ax1,'on')
grid(ax1,'on')
box(ax1,'on')

for k = 1:size(dInd,2)
    y = dInd(:,k);
    if all(~any(isfinite(y))) || all(abs(y(~isnan(y))))
        continue
    end
    h = plot(ax1, theta, y, 'LineWidth',2, 'Color',co(k,:));
    % assign DisplayName only if there's something to show in legend
    if any(isfinite(y)) && any(abs(y(~isnan(y)))>=tol)
        set(h,'DisplayName',indNames{k});
    end
end
title(ax1,'Induced Current Difference')
ylabel(ax1,'\Delta Current (A)')
legend(ax1,'Location','eastoutside')

%% ============================================================
% Line GIC
%% ============================================================

ax2 = nexttile;
hold(ax2,'on')
grid(ax2,'on')
box(ax2,'on')

% Line GIC
for k = 1:size(dLine,1)
    y = dLine(k,:);
    if all(~any(isfinite(y))) || all(abs(y(~isnan(y))))
        continue
    end
    h = plot(ax2, theta, y, 'LineWidth',2, 'Color',co(k,:));
    if any(isfinite(y)) && any(abs(y(~isnan(y)))>=tol)
        set(h,'DisplayName',lineNames{k});
    end
end

title(ax2,'Line GIC Difference')
ylabel(ax2,'\Delta GIC (A)')
legend(ax2,'Location','eastoutside')

%% ============================================================
% Substation GIC
%% ============================================================

ax3 = nexttile;
hold(ax3,'on')
grid(ax3,'on')
box(ax3,'on')

coSub = lines(size(dSub,1));

for k = 1:size(dSub,1)
    y = dSub(k,:);
    if all(~any(isfinite(y))) || all(abs(y(~isnan(y))))
        continue
    end
    h = plot(ax3, theta, y, 'LineWidth',2, 'Color',coSub(k,:));
    if any(isfinite(y)) && any(abs(y(~isnan(y)))>=tol)
        set(h,'DisplayName',app.SandboxS(k).Name);
    end
end

title(ax3,'Substation GIC Difference')
xlabel(ax3,'E-Field Orientation (deg)')
ylabel(ax3,'\Delta GIC (A)')
legend(ax3,'Location','eastoutside')

%% Common formatting
linkaxes([ax1 ax2 ax3],'x')

xlim([min(theta) max(theta)])

xticks(ax1,0:30:max(theta))
xticks(ax2,0:30:max(theta))
xticks(ax3,0:30:max(theta))

end
