function draw_transformer_symbol(ax, connType, xpos, ypos)
% Draws a simplified transformer symbol with HV/LV coloring and type label.

    r = 0.2; % coil radius
    theta = linspace(0, 2*pi, 100);
    xc = r * cos(theta);
    yc = r * sin(theta);

    % Draw coils (2 side-by-side)
    fill(ax, xpos + xc, ypos + yc, 'k');
    fill(ax, xpos + 1 + xc, ypos + yc, 'k');

    % HV (left terminal)
    line(ax, [xpos-0.5 xpos], [ypos ypos], 'Color', 'b', 'LineWidth', 2);

    % LV (right terminal)
    line(ax, [xpos+2 xpos+2.5], [ypos ypos], 'Color', 'r', 'LineWidth', 2);

    % Draw connection type indicators
    switch lower(connType)
        case 'wye_wye'
            plot(ax, xpos - 0.6, ypos - 0.6, 'v', 'Color', 'b', 'MarkerSize', 6, 'LineWidth', 1.5);
            plot(ax, xpos + 2.6, ypos - 0.6, 'v', 'Color', 'r', 'MarkerSize', 6, 'LineWidth', 1.5);
            label = 'Y-Y';

        case 'wye_delta'
            plot(ax, xpos - 0.6, ypos - 0.6, 'v', 'Color', 'b', 'MarkerSize', 6, 'LineWidth', 1.5);
            patch(ax, xpos + 2.6 + [0 -0.2 0.2], ypos + [0.2 -0.2 -0.2], 'r');
            label = 'Y-Δ';

        case 'delta_wye'
            patch(ax, xpos - 0.6 + [0 -0.2 0.2], ypos + [0.2 -0.2 -0.2], 'b');
            plot(ax, xpos + 2.6, ypos - 0.6, 'v', 'Color', 'r', 'MarkerSize', 6, 'LineWidth', 1.5);
            label = 'Δ-Y';

        case 'auto_auto'
            % Single winding w/ tap and ground
            line(ax, [xpos xpos+1], [ypos ypos], 'Color', 'k', 'LineWidth', 2);
            rectangle(ax, 'Position', [xpos+0.4, ypos-0.15, 0.2, 0.3], ...
                      'Curvature', [1 1], 'EdgeColor', 'k');
            plot(ax, xpos+0.5, ypos-0.4, 'kv', 'MarkerSize', 6, 'LineWidth', 1.5);
            label = 'Auto';

        otherwise
            % Placeholder box
            rectangle(ax, 'Position', [xpos, ypos-0.4, 1.5, 0.8], ...
                      'FaceColor', [0.85 0.85 0.85], 'EdgeColor', 'k');
            text(ax, xpos+0.75, ypos, '???', 'HorizontalAlignment','center');
            label = 'Unknown';
    end

    % Draw connection type label below the symbol
    text(ax, xpos + 0.75, ypos - 1.1, label, ...
         'HorizontalAlignment', 'center', 'FontAngle', 'italic', 'FontSize', 10);
end
