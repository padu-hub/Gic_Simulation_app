function draw_schematic(subName, ax, L, T, GIC, timeIndex) 
    cla(ax);
    hold(ax, 'on');
    axis(ax, [0 10 0 10]);
    axis(ax, 'off');

    ypos = 9; dy = 2.2;

    % === Lines ===
    for i = 1:length(L)
        if isfield(L(i), 'fromSub') && isfield(L(i), 'toSub')
            fromMatch = strcmpi(L(i).fromSub, subName);
            toMatch = strcmpi(L(i).toSub, subName);
            isOutgoing = fromMatch && ~toMatch;
            isIncoming = toMatch && ~fromMatch;

            if isIncoming || isOutgoing
                x1 = isIncoming * 1 + isOutgoing * 9;
                x2 = 4.5;
                line(ax, [x1 x2], [ypos ypos], 'Color','b','LineWidth',2);
                text(ax, x1 - 0.3*(isIncoming) + 0.3*(isOutgoing), ypos + 0.2, ...
                    sprintf('%s\n%.2f A', L(i).Name, GIC.Lines(i,timeIndex)), 'FontSize', 10);
                ypos = ypos - dy;
            end
        end
    end

    % === Transformers ===
    tIndices = find(strcmpi({T.Sub}, subName));
    if isempty(tIndices)
        text(ax, 5, ypos, 'No transformers found', 'HorizontalAlignment', 'center');
    else
        ypos = 9;
        for i = 1:length(tIndices)
            ti = tIndices(i);
            gicVal = GIC.Trans(ti, 1, timeIndex);
            connStr = lower(T(ti).HV_Type) + "_" + lower(T(ti).LV_Type);

            % Transformer name and GIC value
            text(ax, 5, ypos + 0.4, T(ti).Name, 'HorizontalAlignment','center', 'FontWeight', 'bold');
            text(ax, 5, ypos - 0.5, sprintf('%.2f A', gicVal), 'HorizontalAlignment','center');

            % Draw symbolic transformer
            draw_transformer_symbol(ax, connStr, 4.25, ypos);
            ypos = ypos - dy;
        end
    end

    title(ax, sprintf('GIC Connections at %s', subName));
end
