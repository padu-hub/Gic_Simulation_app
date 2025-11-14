function saveSpreadsheetTableAsCSV(app)
    % Check if app.SpreadsheetTable is not empty
    if isempty(app.SpreadsheetTable)
        error('The SpreadsheetTable is empty. Nothing to save.');
    end
    
    % Prompt user to select a location and filename for saving
    [fileName, pathName] = uiputfile('*.csv', 'Save Spreadsheet Table as CSV');
    
    % Check if the user canceled the operation
    if isequal(fileName, 0) || isequal(pathName, 0)
        disp('User canceled the operation.');
        return;
    end
    
    % Construct the full file path
    fullFileName = fullfile(pathName, fileName);
    
    % Write the table to a CSV file
    writetable(app.SpreadsheetTable, fullFileName);
end