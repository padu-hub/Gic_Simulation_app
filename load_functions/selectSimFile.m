function filePath = selectSimFile(app, fileType, allowedExt)
    % Universal file picker for all file types
    if nargin < 3
        allowedExt = {'*.mat;*.zip'};  % default
    end

    [file, path] = uigetfile(allowedExt, sprintf("Select %s File", fileType));
    
    if isequal(file, 0)
        filePath = '';
        app.StatusTextArea.Value = sprintf('%s file selection canceled.', fileType);
    else
        filePath = fullfile(path, file);
        app.StatusTextArea.Value = sprintf('%s file selected: %s', fileType, filePath);
    end
end
