function updateGICBarPlot(app)
    idx = round(app.GICTimeSlider.Value);
    cla(app.GICMapAxes);

    gic = app.GIC_Subs(:, idx);
    bar(app.GICMapAxes, gic, 'FaceColor', [0.1 0.6 0.8]);
    xticks(app.GICMapAxes, 1:numel(app.S));
    xticklabels(app.GICMapAxes, {app.S.Name});
    xtickangle(app.GICMapAxes, 45);
    ylabel(app.GICMapAxes, 'GIC (A)');
    %title(app.GICMapAxes, ['Substation GIC @ ', datestr(app.T(idx))]);
end
