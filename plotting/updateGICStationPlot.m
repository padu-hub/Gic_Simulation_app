function updateGICStationPlot(app)
    subName = app.SubstationDropDown.Value;
    idx = find(strcmpi({app.S.Name}, subName));
    if isempty(idx), return; end

    cla(app.GICStationAxes);
    plot(app.GICStationAxes, app.T, app.GIC_Subs(idx, :), '-k');
    title(app.GICStationAxes, ['GIC at ', subName]);
    xlabel(app.GICStationAxes, 'Time'); ylabel(app.GICStationAxes, 'GIC (A)');
end
