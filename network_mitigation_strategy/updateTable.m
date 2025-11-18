function updateTable(app, Tadd)
    % Update the app table with new data and refresh the spreadsheet table

    % Merge into app table
    if isempty(app.MitigationResults)
        app.MitigationResults = Tadd;
    else
        app.MitigationResults = [app.MitigationResults; Tadd];
    end

    % Push to Spreadsheet Results table
    if isvalid(app.SpreadsheetTable)
        app.SpreadsheetTable.Data = app.MitigationResults;
    end
    drawnow;
end