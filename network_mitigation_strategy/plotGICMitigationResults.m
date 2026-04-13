function plotGICMitigationResults(results)
% PLOTGICMITIGATIONRESULTS
% ============================================================
% Generates two plots:
%   1. Sum of substation GIC vs mitigation step
%   2. Max transformer GIC vs mitigation step
%
% INPUT:
%   results - struct returned by runGreedyGICMitigation
% ============================================================

    nSteps  = numel(results.sumGICSubs);
    x       = 0:(nSteps-1);   % 0 = baseline

    % ---------- Plot 1: Sum of GIC at Substations  -----------
    figure;
    plot(x, results.sumGICSubs, '-', 'LineWidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', 'auto');
    grid on;
    xlabel('Number of Mitigations Applied');
    ylabel('Total Substation GIC Sum (A/phase)');
    %title(sprintf('Total GIC vs Mitigations (%s)', results.modeStr));
    title(sprintf('Total GIC vs Mitigations (Lines Open)'));
    set(gca,'FontSize',12);

    % ---------- Plot 2: Max Transformer GIC ------------------
    figure;
    plot(x, results.maxTransGIC, 'o', 'LineWidth', 2, 'MarkerSize', 5, 'Color',[0.2 0.4 1]);
    hold on;
    for i = 1:nSteps
        plot([x(i) x(i)], [0 results.maxTransGIC(i)], '-', 'Color', [0.2 0.4 1]);
    end
    hold off;
    grid on;
    xlabel('Number of Mitigations Applied');
    ylabel('Max Transformer GIC (A/phase)');
    %title(sprintf('Max Transformer GIC vs Mitigations (%s)', results.modeStr));
    title(sprintf('Max Transformer GIC vs Mitigations (Lines open)'));
    set(gca,'FontSize',12);

    
    % ---------- Plot 3: Max Line GIC -----------------------
    figure;
    plot(x, results.maxLinesGIC, 's', 'LineWidth', 2, 'MarkerSize', 5, 'Color',[1 0.5 0]);
    hold on;
    for i = 1:nSteps
        plot([x(i) x(i)], [0 results.maxLinesGIC(i)], '-', 'Color', [1 0.5 0]);
    end
    hold off;
    grid on;
    xlabel('Number of Mitigations Applied');
    ylabel('Max Line GIC (A)');
    %title(sprintf('Max Line GIC vs Mitigations (%s)', results.modeStr));
    title(sprintf('Max Line GIC vs Mitigations (Lines Open)'));
    set(gca,'FontSize',12);

end
