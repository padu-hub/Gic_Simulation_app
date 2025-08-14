function addGraphToStorage(app, axHandle, graphName)
    existingNames = {app.StoredAxes.Name};

    if ~any(strcmp(existingNames, graphName))
        % Add new graph
        app.StoredAxes(end+1) = struct('Name', graphName, 'Axes', axHandle);

        % Update dropdown
        app.GraphDropdown.Items = [existingNames, {graphName}];
    else
        % Update existing graph handle (e.g., replotting)
        idx = find(strcmp(existingNames, graphName));
        app.StoredAxes(idx).Axes = axHandle;
    end

    % Always set the selected value to the new or updated one
    app.GraphDropdown.Value = graphName;
end
