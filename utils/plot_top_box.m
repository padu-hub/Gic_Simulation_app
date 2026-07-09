function plot_top_box(rankTable, K, samplesCell, names, figTitle)

    if isempty(rankTable)
        return;
    end

    valid = ~isnan(rankTable.Sum);
    ranked = sortrows(rankTable(valid,:), 'Rank', 'ascend');

    K = min(K,height(ranked));
    if K == 0
        return;
    end

    topNames = ranked.Name(1:K);
    idx = arrayfun(@(s)find(names==s,1),topNames);

    % Build long-form data and group labels
    Y = [];
    G = categorical();

    for k = 1:K
        vals = samplesCell{idx(k)}(:);

        Y = [Y; vals];

        G = [G;
             categorical( ...
                 repmat(string(topNames(k)),length(vals),1), ...
                 string(topNames), ...
                 string(topNames))];
    end

    figure('Name',figTitle);

    vp = violinplot(G,Y,...
        DensityWidth=0.8,...
        DensityScale="width");

    % Make all violins the same color
    blue = [0 0.4470 0.7410];

    for k = 1:numel(vp)
        vp(k).FaceColor = blue;
    end

    title(figTitle)
    ylabel('15-min mean |GIC|')

    % Optional for GIC data
    % set(gca,'YScale','log')

    xtickangle(45)
    grid on

end