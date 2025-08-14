function h = draw_schematic(subName, ax, L, T, GIC, timeIndex)
%DRAW_SCHEMATIC  Substation one-page schematic with GIC flows.
%  h = draw_schematic(subName, ax, L, T, GIC, timeIndex)
%
%  Inputs
%    subName   : char/str — substation name to plot (match against L.fromSub/L.toSub and T.Sub)
%    ax        : axes handle to draw into (created/cleared by caller)
%    L         : struct array of lines with fields:
%                  .Name, .fromSub, .toSub  (case-insensitive)
%                (optional helpful fields, if present: .Voltage)
%    T         : struct array of transformers with fields:
%                  .Name, .Sub, .HV_Type, .LV_Type  (used only for label)
%    GIC       : struct with fields (any non-required field is handled gracefully):
%                  .Lines (nLines x nTime) — line GIC; positive flows from fromSub→toSub
%                  .Trans (nTrans x nWindings x nTime) — transformer GIC per winding
%                        Convention assumed: winding #1 = HV(series), #2 = LV(common/neutral)
%                  .Subs  (nSubs x nTime) — OPTIONAL, total substation neutral current if available
%    timeIndex : scalar time step index
%
%  Output
%    h         : struct of handles for customization (lines, texts, symbols)
%
%  Notes/assumptions
%    • Line direction: GIC.Lines(i,t) > 0 means current flows from L(i).fromSub to L(i).toSub.
%      At the "from" end this is OUTGOING; at the "to" end it is INCOMING.
%    • Ground/neutral flow: If GIC.Subs is unavailable, we estimate substation ground current as
%      the sum of the LV/common (winding #2 when present, otherwise #1) currents of the
%      transformers at that substation, at timeIndex.
%    • All magnitudes are plotted in amperes and arrows point in the physical flow direction
%      with respect to the plotted substation node (center bus).

    if nargin < 6, error('draw_schematic:args','Need subName, ax, L, T, GIC, timeIndex'); end

    % ---- Setup canvas ----------------------------------------------------
    cla(ax); hold(ax,'on'); axis(ax,[0 10 0 10]); axis(ax,'off'); daspect(ax,[1 1 1]);
    h = struct('lines',[],'lineText',[],'xfers',[],'xfText',[],'ground',[],'notes',[]);

    title(ax, sprintf('GIC Schematic — %s (t = %d)', subName, timeIndex), ...
         'FontWeight','bold','FontSize',12);

    % Center "bus" bar for the substation node
    plot(ax,[4.2 5.8],[6.5 6.5],'k-','LineWidth',3);  % thick node
    text(ax,5,7.0, subName,'HorizontalAlignment','center','FontWeight','bold');

    % Small helper colors
    cLine = [0 0.45 0.85]; % blue
    cXfr  = [0.85 0.33 0.1]; % orange
    cGrnd = [0.2 0.6 0.2];   % green
    yTop  = 9.2; dy = 1.1; yLines = yTop;
    yXfr  = 4.8;            % start lower block for transformers

    % ---- Collect incident lines for this substation ----------------------
    nL = numel(L);
    incoming = []; outgoing = []; labelsIn = {}; labelsOut = {}; valsIn = []; valsOut = [];

    for i = 1:nL
        if ~isfield(L(i),'fromSub') || ~isfield(L(i),'toSub'), continue; end
        isFrom = strcmpi(L(i).fromSub, subName);
        isTo   = strcmpi(L(i).toSub,   subName);
        if ~(isFrom || isTo), continue; end

        I = NaN;
        if isfield(GIC,'Lines') && size(GIC.Lines,1) >= i && size(GIC.Lines,2) >= timeIndex
            I = GIC.Lines(i, timeIndex); % +ve: from -> to
        end

        if isTo   % at "to" end, +ve means INCOMING
            incoming(end+1) = i; %#ok<AGROW>
            valsIn(end+1)   = I; %#ok<AGROW>
            labelsIn{end+1} = safestr(getfieldor(L(i),'Name',sprintf('Line %d',i))); %#ok<GFLD,AGROW>
        elseif isFrom % at "from" end, +ve means OUTGOING
            outgoing(end+1) = i; %#ok<AGROW>
            valsOut(end+1)  = I; %#ok<AGROW>
            labelsOut{end+1}= safestr(getfieldor(L(i),'Name',sprintf('Line %d',i))); %#ok<AGROW>
        end
    end

    % ---- Draw incoming (left) and outgoing (right) lines -----------------
    % Incoming on left (x from 1 -> node), Outgoing on right (node -> 9)
    % Arrows point toward the node for incoming; away from node for outgoing.
    for k = 1:numel(incoming)
        i = incoming(k);
        y = yLines; yLines = yLines - dy;
        plot(ax,[1 4.2],[y y],'Color',cLine,'LineWidth',2);
        draw_arrow(ax, 3.6, y, 4.2, y, cLine); % towards node
        I = valsIn(k);
        unit = 'A';
        t = text(ax, 1.1, y+0.25, sprintf('%s\n%.1f %s', labelsIn{k}, I), ...
                 'Color',cLine,'FontSize',9,'HorizontalAlignment','left','VerticalAlignment','bottom');
        h.lines = [h.lines; i];
        h.lineText = [h.lineText; t];
    end

    % reset for right side stacking separately so counts don't collide if many on each side
    yLinesR = yTop;
    for k = 1:numel(outgoing)
        i = outgoing(k);
        y = yLinesR; yLinesR = yLinesR - dy;
        plot(ax,[5.8 9],[y y],'Color',cLine,'LineWidth',2);
        draw_arrow(ax, 5.8, y, 6.4, y, cLine); % away from node
        I = valsOut(k);
        t = text(ax, 8.9, y+0.25, sprintf('%.1f A\n%s', I, labelsOut{k}), ...
                 'Color',cLine,'FontSize',9,'HorizontalAlignment','right','VerticalAlignment','bottom');
        h.lines = [h.lines; i]; %#ok<AGROW>
        h.lineText = [h.lineText; t]; %#ok<AGROW>
    end

    % dashed droppers to node (visual)
    if ~isempty(incoming), plot(ax,[4.2 4.2],[yLines 6.5],'k:'); end
    if ~isempty(outgoing), plot(ax,[5.8 5.8],[yLinesR 6.5],'k:'); end

    % ---- Transformers block ---------------------------------------------
    % Find transformers at this substation
    tIdx = find(strcmpi({T.Sub}, subName));
    if isempty(tIdx)
        text(ax,5, yXfr, 'No transformers found','HorizontalAlignment','center');
    else
        y = yXfr;
        for kk = 1:numel(tIdx)
            ti = tIdx(kk);
            % Try to retrieve winding GICs robustly
            I_HV = NaN; I_LV = NaN;
            if isfield(GIC,'Trans') && size(GIC.Trans,1) >= ti && size(GIC.Trans,3) >= timeIndex
                % Detect number of windings dimension
                nW = size(GIC.Trans,2);
                if nW >= 1, I_HV = GIC.Trans(ti,1,timeIndex); end
                if nW >= 2, I_LV = GIC.Trans(ti,2,timeIndex); else, I_LV = I_HV; end
            end

            % Symbol & labels
            conn = sprintf('%s/%s', safestr(getfieldor(T(ti),'HV_Type','?')), safestr(getfieldor(T(ti),'LV_Type','?')));
            draw_transformer_symbol(ax, 4.8, y, cXfr);
            plot(ax,[4.8 5.0],[y+0.6 6.5],'Color',[0.3 0.3 0.3],'LineStyle','-'); % lead to node

            text(ax, 5.0, y+0.85, safestr(getfieldor(T(ti),'Name',sprintf('T%d',ti))), ...
                 'HorizontalAlignment','left','FontWeight','bold','Color',cXfr);
            text(ax, 5.0, y+0.55, conn, 'HorizontalAlignment','left','Color',[0.25 0.25 0.25]);

            txt = sprintf('HV(series): %.1f A\nLV(common): %.1f A', I_HV, I_LV);
            tx = text(ax, 5.0, y+0.15, txt, 'HorizontalAlignment','left','Color',cXfr,'FontSize',9);
            h.xfers = [h.xfers; ti]; %#ok<AGROW>
            h.xfText = [h.xfText; tx]; %#ok<AGROW>

            y = y - 1.1;
        end
    end

    % ---- Ground / neutral current for the substation ---------------------
    Iground = NaN;
    % Preferred: use provided substation total if available (requires mapping).
    if isfield(GIC,'Subs') && ~isempty(GIC.Subs)
        % Build a simple name->index map from transformers if possible
        subsList = unique(lower(strtrim({T.Sub})));
        subIdx = find(strcmpi(subsList, subName), 1);
        if ~isempty(subIdx) && size(GIC.Subs,1) >= subIdx && size(GIC.Subs,2) >= timeIndex
            Iground = GIC.Subs(subIdx, timeIndex);
        end
    end
    % Fallback: sum LV/common winding currents of xfmrs at this sub
    if isnan(Iground)
        if exist('tIdx','var') && ~isempty(tIdx) && isfield(GIC,'Trans')
            lvCol = min(2, max(1, size(GIC.Trans,2))); % use 2 if exists, else 1
            vals = arrayfun(@(ii) safeTrans(GIC.Trans, ii, lvCol, timeIndex), tIdx);
            Iground = nansum(vals);
        end
    end
    % Draw ground symbol below node
    plot(ax,[5 5],[6.5 5.6],'k-','LineWidth',1.5);
    draw_ground(ax, 5, 5.4, cGrnd);
    text(ax, 5.2, 5.75, sprintf('To ground: %.1f A', Iground), ...
         'Color',cGrnd,'HorizontalAlignment','left','FontWeight','bold');

    % ---- KCL / balance note (incoming to node counted +, outgoing −, minus ground) ----
    sigIn  = sum_signed(valsIn, +1);  % + toward node
    sigOut = sum_signed(valsOut, -1); % − away from node
    residual = (sigIn + sigOut) - Iground; % should ~ 0
    h.notes = text(ax, 5, 4.6, sprintf('KCL residual ≈ %.2f A', residual), ...
                   'HorizontalAlignment','center','Color',[0.2 0.2 0.2]);

    % ---- Nice legend cue (optional voltage badges if present) ------------
    if any(isfield(L,{'Voltage'}))
        text(ax, 1.0, 0.8, 'Line colors: blue; Xfmrs: orange; Ground: green', 'FontSize',8,'Color',[0.2 0.2 0.2]);
    end

    hold(ax,'off');

    %-------------------- nested helpers -----------------------------------
    function s = safestr(x)
        if isempty(x) || (isstring(x) && strlength(x)==0), s = '?'; else, s = char(string(x)); end
    end
    function v = getfieldor(st, f, dv)
        if isfield(st,f), v = st.(f); else, v = dv; end
    end
    function val = safeTrans(A, ii, jj, tt)
        try
            val = A(ii,jj,tt);
        catch
            val = NaN;
        end
    end
    function s = sum_signed(v, signToward)
        % signToward = +1 for incoming vals (toward node), −1 for outgoing vals (away)
        v = v(:);
        s = nansum(signToward * v);
    end
end

% ======= local drawing utilities (file-local subfunctions) ================

function draw_transformer_symbol(ax, x, y, col)
% Two-coil simplistic symbol centered at (x,y), size ~ 0.8 × 0.8
    r = 0.15; dx = 0.22; n = 70;
    th = linspace(pi*0.15, pi*1.85, n);
    xc1 = x - dx; xc2 = x + dx;
    plot(ax, xc1 + r*cos(th), y + r*sin(th), 'Color',col,'LineWidth',1.5);
    plot(ax, xc2 + r*cos(th), y + r*sin(th), 'Color',col,'LineWidth',1.5);
    % small terminals top/bottom
    plot(ax, [xc1 xc1],[y+r y+r+0.25],'Color',col,'LineWidth',1);
    plot(ax, [xc2 xc2],[y+r y+r+0.25],'Color',col,'LineWidth',1);
    plot(ax, [xc1 xc1],[y-r y-r-0.25],'Color',col,'LineWidth',1);
    plot(ax, [xc2 xc2],[y-r y-r-0.25],'Color',col,'LineWidth',1);
end

function draw_ground(ax, x, y, col)
% Simple ground symbol centered at (x,y)
    plot(ax,[x x],[y y-0.15],'Color',col,'LineWidth',1.5);
    lw = 1.2;
    plot(ax,[x-0.18 x+0.18],[y-0.18 y-0.18],'Color',col,'LineWidth',lw);
    plot(ax,[x-0.12 x+0.12],[y-0.25 y-0.25],'Color',col,'LineWidth',lw);
    plot(ax,[x-0.06 x+0.06],[y-0.32 y-0.32],'Color',col,'LineWidth',lw);
end

function draw_arrow(ax, x1, y1, x2, y2, col)
% Draw a short line with a triangular arrowhead pointing from (x1,y1)->(x2,y2)
    plot(ax,[x1 x2],[y1 y2],'Color',col,'LineWidth',2);
    v = [x2-x1, y2-y1]; L = hypot(v(1),v(2)); if L==0, return; end
    v = v / L;
    % Arrowhead dimensions in axis units
    ah = 0.18; aw = 0.12;
    % Build a small triangle at endpoint
    n = [-v(2), v(1)]; % left normal
    p3 = [x2, y2];
    p1 = p3 - ah*v + aw*n;
    p2 = p3 - ah*v - aw*n;
    patch('Parent',ax,'XData',[p1(1) p3(1) p2(1)],'YData',[p1(2) p3(2) p2(2)], ...
          'FaceColor',col,'EdgeColor','none');
end
