function multiple_diffRuns

    % Load multiple .mat files and store variables in cell arrays
    [fileNames, pathName] = uigetfile('*.mat', 'Select the .mat files', 'MultiSelect', 'on');
    if isequal(fileNames, 0)
        error('No files selected.');
    end
    
    % Ensure fileNames is a cell array
    if ischar(fileNames)
        fileNames = {fileNames};
    end
    
    nFiles = numel(fileNames);
    
    % Initialize cell arrays
    ex   = cell(nFiles, 1);
    ey   = cell(nFiles, 1);
    latq = cell(nFiles, 1);
    lonq = cell(nFiles, 1);
    tind = cell(nFiles, 1);
    
    % Load variables from each selected .mat file
    for i = 1:nFiles
        filePath = fullfile(pathName, fileNames{i});
        S = load(filePath);
    
        % Validate expected structure
        if ~isfield(S, 'data')
            error('File "%s" does not contain a variable named "data".', fileNames{i});
        end
    
        data = S.data;
    
        % Validate required fields
        req = {'ex','ey','latq','lonq','tind'};
        for r = 1:numel(req)
            if ~isfield(data, req{r})
                error('File "%s": data.%s is missing.', fileNames{i}, req{r});
            end
        end
    
        % Assign loaded variables
        ex{i}   = data.ex;
        ey{i}   = data.ey;
        latq{i} = data.latq;
        lonq{i} = data.lonq;
        tind{i} = data.tind;
    end
    
    % Initialize output variables
    GIC = cell(length(fileNames), 1);
    % Loop through each loaded dataset and call the calc_gic_main function
    for i = 1:length(fileNames)
        [~, ~, ~, GIC{i}, ~, ~, ~, ~] = ...
            calc_gic_main(app, S, L, T, ex{i}, ey{i}, latq{i}, lonq{i}, tind{i}, false, L, T);
    end


    

    

end
