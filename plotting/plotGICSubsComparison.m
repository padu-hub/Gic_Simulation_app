function plotGICSubsComparison(results1, results2)
figure;
hold on;

n1 = numel(results1.sumGICSubs);
n2 = numel(results2.sumGICSubs);
x1 = 0:(n1-1);
x2 = 0:(n2-1);

p1 = plot(x1, results1.sumGICSubs, '-', 'LineWidth', 2, ...
    'MarkerSize', 6, 'Color', [0 0.4470 0.7410]);
p2 = plot(x2, results2.sumGICSubs, '-', 'LineWidth', 2, ...
    'MarkerSize', 6, 'Color', [0.8500 0.3250 0.0980]);

xlabel('Number of Mitigations Applied');
ylabel('Total Substation GIC Sum (A/phase)');
title('Comparison of Total Substation GIC Sum');
legend([p1 p2], {'With Rank', 'Without Rank'}, 'Location', 'northeast');
grid on;

% ensure both lines share same x-range
xlim([0, max(n1,n2)-1] + [-0.5, 0.5]);

set(gca, 'FontSize', 14);
hold off;
end
