function plotGICMitigationResults(results)
% PLOTGICMITIGATIONRESULTS
% ============================================================
% ---------- Combined Plot: Total Substation GIC + Max Transformer GIC + Max Line GIC ----------
% ==================== COMBINED GIC PLOT ====================
% 1) Plot all three metrics on one figure:% 1) Total substation GIC sum as a line on the left y-axis
% 2) Max transformer GIC as a wide background bar on the right y-axis
% 3) Max line GIC as a narrower overlapping bar on the right y-axis

% % Save results to a .mat file with timestamp
% timestamp = datestr(now, 'yyyymmdd_HHMMSS');
% saveFilename = sprintf('GICResults_%s.mat', timestamp);
% try
%     save(saveFilename, 'results');
% catch
%     % Fallback: save to current folder with generic name
%     warning('Failed to save to %s. Saving to GICResults.mat instead.', saveFilename);
%     save('GICResults.mat', 'results');
% end
figure;
nSteps  = numel(results.sumGICSubs);
x       = 0:(nSteps-1);   % 0 = baseline
    %% Bottom axes for BAR GRAPHS
    axBar = axes;
    
    % Plot on bottom axes
    yyaxis(axBar, 'right')
    b1 = bar(axBar, x, results.maxTransGIC, 0.75, ...
        'FaceColor', [1.00 0.65 0.65], ...
        'EdgeColor', [0.80 0.25 0.25], ...
        'LineWidth', 1.0);
    hold(axBar, 'on')
    
    b2 = bar(axBar, x, results.maxLinesGIC, 0.45, ...
        'FaceColor', [0.35 0.55 1.00], ...
        'EdgeColor', [0.10 0.25 0.80], ...
        'LineWidth', 1.0);
    
    axBar.YColor = [0.15 0.15 0.15];
    ylabel(axBar, 'Max Transformer / Line GIC (A/phase)');
    
    xlim(axBar, [min(x)-0.5, max(x)+0.5]);
    % set x-ticks every 20
    xt = min(x):20:max(x);
    axBar.XTick = xt;
    axLine.XTick = xt;
    axBar.FontSize = 16;
    grid(axBar, 'on')
    hold(axBar, 'on')
    
    % Remove left-side y-axis from bottom axes
    axBar.YAxis(1).Visible = 'off';
    
    % Keep right-side y-axis visible
    axBar.YAxis(2).Visible = 'on';
    
    
    %% Top axes for LINE GRAPH
    axLine = axes('Position', axBar.Position);
    
    % Plot line on top axes
    p1 = plot(axLine, x, results.sumGICSubs, '-k', ...
        'LineWidth', 2.5, ...
        'MarkerSize', 4, ...
        'MarkerFaceColor', 'k');
    hold(axLine, 'on')
    
    % Transparent background for top axes only
    axLine.Color = 'none';
    
    %% Formarting
    % Put y-axis of top axes on left
    axLine.YAxisLocation = 'left';
    axLine.XAxisLocation = 'bottom';
    axLine.YColor = [0 0 0];
    ylabel(axLine, 'Total Substation GIC Sum (A/phase)');
    
    % Keep same x range
    xlim(axLine, [min(x)-0.5, max(x)+0.5]);
    
    % Match x ticks
    axLine.XTick = axBar.XTick;
    axLine.FontSize = 16;

    
    % Turn off duplicate box if needed
    box(axLine, 'off')
    % Link axes
    linkaxes([axBar, axLine], 'x');
    % Labels and title
    xlabel(axBar, 'Number of Mitigations Applied');
    % Legend    
    legend(axLine, [p1, b1, b2], ...
        {'Substations: total GIC sum', ...
         'Transformers: max |GIC|', ...
         'Lines: max |GIC|'}, ...
         'Location', 'northeast', ...
         'FontSize', 16);
    
end

