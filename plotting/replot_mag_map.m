function replot_mag_map(app, siteIndices, mapPanel)
% Replots only the geographic site marker map

    delete(allchild(mapPanel));
    axMap = geoaxes(mapPanel);
    geoplot(axMap, [app.b_cleaned(:).lat], [app.b_cleaned(:).lon], 'o', ...
        'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k'); hold(axMap, 'on');
    geoplot(axMap, [app.b_cleaned(siteIndices).lat], [app.b_cleaned(siteIndices).lon], 'o', ...
        'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k');
    title(axMap, 'Selected Sites');


end