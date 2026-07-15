function plotSandboxSchematicDifferences( ...
    theta, ...
    I_indResults, I_indResultsOld, ...
    GICLinesResults, GICLinesResultsOld, ...
    GICSubsResults, GICSubsResultsOld, app)

% Visualize differences (mitigated - original) for six E-field angles
% 0,36,72,108,144,180 deg in a 3x2 schematic layout with consistent map.

% --- Basic checks ---
theta = theta(:);
if isempty(I_indResultsOld) || isempty(GICLinesResultsOld) || isempty(GICSubsResultsOld)
    return
end
if isempty(app) || ~isprop(app,'OldSandboxL') || isempty(app.OldSandboxL)
    oldLineNames = {};
else
    oldLineNames = {app.OldSandboxL.Name};
end

% Force shapes: rows = orientations, cols = lines/subs when possible
if size(I_indResults,1) ~= numel(theta) && size(I_indResults,2) == numel(theta)
    I_indResults = I_indResults';
end
if size(I_indResultsOld,1) ~= numel(theta) && size(I_indResultsOld,2) == numel(theta)
    I_indResultsOld = I_indResultsOld';
end
if size(GICLinesResults,2) ~= numel(theta) && size(GICLinesResults,1) == numel(theta)
    GICLinesResults = GICLinesResults';
end
if size(GICLinesResultsOld,2) ~= numel(theta) && size(GICLinesResultsOld,1) == numel(theta)
    GICLinesResultsOld = GICLinesResultsOld';
end
if size(GICSubsResults,2) ~= numel(theta) && size(GICSubsResults,1) == numel(theta)
    GICSubsResults = GICSubsResults';
end
if size(GICSubsResultsOld,2) ~= numel(theta) && size(GICSubsResultsOld,1) == numel(theta)
    GICSubsResultsOld = GICSubsResultsOld';
end

% --- Select six angles of interest (closest in theta) ---
angles = [0 45 90 120 145 180];
[~, idxAngles] = arrayfun(@(a) min(abs(theta - a)), angles);

%% Merge duplicate OLD entries
[I_indResultsOld, indNames] = mergeDuplicateNames(I_indResultsOld, oldLineNames);
[I_indResults,    ~]        = mergeDuplicateNames(I_indResults,    {app.SandboxL.Name});

[GICLinesResultsOld, lineNames] = mergeDuplicateNames(GICLinesResultsOld, oldLineNames);
[GICLinesResults,    ~]         = mergeDuplicateNames(GICLinesResults,    {app.SandboxL.Name});

%% Calculate differences
dIind  = abs(I_indResults)  - abs(I_indResultsOld);
dLine = abs(GICLinesResults) - abs(GICLinesResultsOld);
dSub  = abs(GICSubsResults)  - abs(GICSubsResultsOld);  % orientations x substations

% If inputs are transposed shapes, ensure dims: orient x lines/subs
if size(dIind,2) == 1 && size(I_indResults,2) ~= 1
    dIind = dIind'; % fallback
end

% --- Schematic: fixed substation coords and line connectivity ---
% Example schematic for 6 substations (x,y)
subX = [0 1 2 0 1 2];
subY = [2 2 2 0 0 0];
nSub = numel(subX);

% Hard-coded line connectivity as pairs of substation indices
% (ensure coverage of typical network; adjust as needed)
lines = [1 2; 2 3; 1 4; 2 5; 3 6; 4 5; 5 6; 2 4; 3 5]; % m x 2
nLines = size(lines,1);

% Precompute per-line geometry (endpoints)
lineX1 = subX(lines(:,1));
lineY1 = subY(lines(:,1));
lineX2 = subX(lines(:,2));
lineY2 = subY(lines(:,2));

% Global color scale based on max abs substation difference across all selected angles
globalMax = max(abs(dSub(:)));
if isempty(globalMax) || globalMax == 0
    globalMax = 1; % avoid zero-range colormap
end

cMap = redbluecmap(256); % custom fallback below if necessary


% Figure & tiled layout 3x2
figure('Color','w','Name','Schematic Differences','NumberTitle','off');
t = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

% Common plotting parameters
maxBubbleArea = 1000;    % max scatter 'SizeData' (area)
arrowScale = 0.15;       % fraction of axes height used to draw arrow length scaling
offsetFrac = 0.03;       % perpendicular offset fraction to avoid overplotting
labelOffset = 0.02;      % offset for numeric label near arrow
textFmt = '%.1f';        % numeric label format

% Axis limits (consistent)
xmin = min(subX)-0.5; xmax = max(subX)+0.5;
ymin = min(subY)-0.5; ymax = max(subY)+0.5;

% Loop panels
for p = 1:6
    ax = nexttile;
    hold(ax,'on')
    axis(ax,[xmin xmax ymin ymax])
    axis(ax,'equal')
    axis(ax,'off')

    % draw identical lines (network schematic)
    for L = 1:nLines
        plot(ax, [lineX1(L) lineX2(L)], [lineY1(L) lineY2(L)], '-k', 'LineWidth', 1.5);
    end

    % Substation bubble colors and sizes for this orientation
    dsub_p = dSub(p,:);   % 1 x nSub (might be longer/shorter depending input)
    % If dsub_p length differs from nSub, truncate or pad with zeros
    if numel(dsub_p) < nSub
        dsub_p = [dsub_p zeros(1,nSub-numel(dsub_p))];
    elseif numel(dsub_p) > nSub
        dsub_p = dsub_p(1:nSub);
    end

    % Omit zero-change substations
    nonzeroMask = (dsub_p ~= 0) & isfinite(dsub_p);
    absVals = abs(dsub_p);
    % Map color from blue (decrease negative) to red (increase positive)
    % Normalize to [-globalMax, globalMax] -> colormap index
    normVals = (dsub_p + globalMax) / (2*globalMax);    % 0..1
    cmapIdx = max(1, round(normVals*(size(cMap,1)-1))+1);
    % Plot bubbles (scale area)
    for s = 1:nSub
        if ~nonzeroMask(s), continue; end
        area = (absVals(s)/globalMax) * maxBubbleArea;
        scatter(ax, subX(s), subY(s), area, cMap(cmapIdx(s),:), 'filled', 'MarkerEdgeColor','k');
    end

    % For each line, compute two annotation points at 1/3 and 2/3 and draw arrows
    dI_line_p = dIind(p,:); % orient x lines
    dG_line_p = dLine(p,:);  % orient x lines
    % Ensure length matches nLines
    if numel(dI_line_p) < nLines, dI_line_p(end+1:nLines) = 0; end
    if numel(dG_line_p) < nLines, dG_line_p(end+1:nLines) = 0; end

    for L = 1:nLines
        x1 = lineX1(L); y1 = lineY1(L);
        x2 = lineX2(L); y2 = lineY2(L);
        % points at 1/3 and 2/3
        t1 = 1/3; t2 = 2/3;
        px1 = x1 + t1*(x2-x1); py1 = y1 + t1*(y2-y1);
        px2 = x1 + t2*(x2-x1); py2 = y1 + t2*(y2-y1);
        % perpendicular offset
        dx = x2-x1; dy = y2-y1;
        Llen = hypot(dx,dy);
        if Llen == 0, continue; end
        ux = -dy / Llen; uy = dx / Llen; % unit perp vector
        off = offsetFrac * (max(xmax-xmin, ymax-ymin)); % absolute offset
        px1o = px1 + ux*off; py1o = py1 + uy*off;
        px2o = px2 + ux*off; py2o = py2 + uy*off;

        % Arrow for induced current difference (red) at first location
        valI = dI_line_p(L);
        if isfinite(valI) && valI ~= 0
            % arrow length proportional to magnitude (scaled)
            arrowLen = sign(valI) * arrowScale * (max(ymax-ymin, xmax-xmin)) * (abs(valI)/max(abs(dIind(:)),1));
            % draw vertical arrow centered at px1o,py1o
            axArrowBase = [px1o, py1o];
            axArrowTip = [px1o, py1o + arrowLen];
            plot(ax, [axArrowBase(1) axArrowTip(1)], [axArrowBase(2) axArrowTip(2)], '-r', 'LineWidth', 1.8);
            % arrow head
            ah = 0.02 * (xmax-xmin);
            plot(ax, [axArrowTip(1)-ah axArrowTip(1) axArrowTip(1)+ah], ...
                     [axArrowTip(2)-sign(arrowLen)*ah axArrowTip(2) axArrowTip(2)-sign(arrowLen)*ah], '-r', 'LineWidth',1.2);
            % numeric label to right of arrow
            text(ax, axArrowTip(1)+labelOffset, axArrowTip(2), sprintf(['+' textFmt ' A'], valI), 'Color','r', 'FontSize',9, 'HorizontalAlignment','left');
        end

        % Arrow for line GIC difference (blue) at second location
        valL = dG_line_p(L);
        if isfinite(valL) && valL ~= 0
            arrowLen = sign(valL) * arrowScale * (max(ymax-ymin, xmax-xmin)) * (abs(valL)/max(abs(dLine(:)),1));
            axArrowBase = [px2o, py2o];
            axArrowTip = [px2o, py2o + arrowLen];
            plot(ax, [axArrowBase(1) axArrowTip(1)], [axArrowBase(2) axArrowTip(2)], '-b', 'LineWidth', 1.8);
            ah = 0.02 * (xmax-xmin);
            plot(ax, [axArrowTip(1)-ah axArrowTip(1) axArrowTip(1)+ah], ...
                     [axArrowTip(2)-sign(arrowLen)*ah axArrowTip(2) axArrowTip(2)-sign(arrowLen)*ah], '-b', 'LineWidth',1.2);
            text(ax, axArrowTip(1)+labelOffset, axArrowTip(2), sprintf(['+' textFmt ' A'], valL), 'Color','b', 'FontSize',9, 'HorizontalAlignment','left');
        end
    end

    title(ax, sprintf('%d°', angles(p)));
    hold(ax,'off')
end

% --- Shared colorbar for substation bubbles ---
% Create an invisible scatter to anchor colorbar scale
hcbAx = axes('Position',[0 0 1 1],'Visible','off');
colormap(cMap);
caxis([-globalMax globalMax]);
h = colorbar(t,'eastoutside');
h.Label.String = '\Delta Substation GIC (A)';
h.Ticks = linspace(-globalMax, globalMax, 5);

end

% --- Helper colormap fallback: red-blue ---
function cmap = redbluecmap(n)
if nargin<1, n=256; end
t = linspace(0,1,n)';
cmap = [interp1([0;0.5;1],[0 0 1;1 1 1;1 0 0],t), ...
        interp1([0;0.5;1],[0 1 1;1 1 1;0 0 0],t), ...
        interp1([0;0.5;1],[1 1 0;1 1 1;0 0 0],t)];
% simple approximate blue->white->red
end

% Note: If you have the "brewermap" function available you can remove the
% fallback and use brewermap(256,'RdBu').
