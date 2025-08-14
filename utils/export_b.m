function export_b(app, b)
% EXPORT_B - Save the magnetic field data 'b' to a .mat file via file dialog.
% 
%   Usage:
%       export_b(b)
%
%   Prompts the user to choose a save location and filename,
%   then saves the variable 'b' to that file.

    % Prompt user to choose a save location
    [file, path] = uiputfile('b_export.mat', 'Save magnetic data as');
    
    % If user cancels, do nothing
    if isequal(file, 0) || isequal(path, 0)
        disp('Export cancelled.');
        return;
    end

    % Build full file path
    fullFileName = fullfile(path, file);

    % Save variable b to the selected .mat file
    try
        save(fullFileName, 'b');
        app.StatusTextArea.Value = sprintf("✅ Variable 'b' successfully saved to:\n%s\n", fullFileName);
        drawnow;
    catch ME
        app.StatusTextArea.Value = sprintf("❌ Error: %s", ME.message);
        drawnow;
    end
end
