function onLineTableEdit(app, event)
    idx = event.Indices(1);
    newState = app.LineTable.Data{idx, 'Enabled'};
    toggleLine(app, idx, newState);  % pass the value directly
end
