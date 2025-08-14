function [b] = load_mag_data(folder)
% LOAD_MAG_DATA - Load all magnetic data files from a folder.
% INPUT: folder - full path to folder containing .F01, .sec, .min, .MAG, etc.
% OUTPUT: b - array of magnetic site structures

% === Validate input ===
if nargin == 0 || ~isfolder(folder)
    error("load_mag_data: Provide a valid folder path.");
end

% === Supported file extensions ===
validExt = {'.sec', '.F01', '.min', '.MAG'};

% === Find all relevant files in the folder ===
allFiles = dir(fullfile(folder, '*.*'));
allFiles = allFiles(~[allFiles.isdir]);

magfile = {};
for i = 1:length(allFiles)
    [~, ~, ext] = fileparts(allFiles(i).name);
    if any(strcmpi(ext, validExt))
        fullPath = fullfile(folder, allFiles(i).name);

        % Ensure it's a character vector (not a string object)
        if isstring(fullPath)
            fullPath = char(fullPath);
        end

        magfile{end+1} = fullPath;
    end
end

if isempty(magfile)
    warning("No supported magnetic data files found in folder: %s", folder);
    return;
end

% === Start loading magnetic files ===
tic
siteNames = {''};
count = 0;
for i = length(magfile):-1:1
    fname = magfile{i};
    try
        [~, baseName, ~] = fileparts(fname);  % Get filename without path or extension
        % === NRCan .sec files (3-letter site code at the end) ===
        if endsWith(fname, '.sec', 'IgnoreCase', true)
            if length(baseName) >= 3
                siteCode = baseName(end-2:end);  % Last 3 chars
            else
                warning("Filename too short to extract site code: %s", baseName);
                continue;
            end
    
            if ~any(strcmpi(siteNames, siteCode))
                sample_rate = 1;  % 1 Hz
                siteData = load_IAGA_site(siteCode, {fname}, sample_rate);
                if isstruct(siteData)
                    count = count + 1;
                    b(count) = siteData;
                    siteNames{end+1} = siteCode;
                end
            end
    
        % === CARISMA .F01 (4-letter site code at the end) ===
        elseif endsWith(fname, '.F01', 'IgnoreCase', true)
            if length(baseName) >= 4
                siteCode = baseName(end-3:end);
            else
                warning("Filename too short to extract site code: %s", baseName);
                continue;
            end
    
            if ~any(strcmpi(siteNames, siteCode))
                siteData = load_CARISMA_site(siteCode, {fname});
                if isstruct(siteData)
                    count = count + 1;
                    b(count) = siteData;
                    siteNames{end+1} = siteCode;
                end
            end
    
        % === IAGA .min files (3-letter site code at the end) ===
        elseif endsWith(fname, '.min', 'IgnoreCase', true)
            if length(baseName) >= 3
                siteCode = baseName(end-2:end);
            else
                warning("Filename too short to extract site code: %s", baseName);
                continue;
            end
    
            if ~any(strcmpi(siteNames, siteCode))
                sample_rate = 1/60;  % 1 sample per minute
                siteData = load_IAGA_site(siteCode, {fname}, sample_rate);
                if isstruct(siteData)
                    count = count + 1;
                    b(count) = siteData;
                    siteNames{end+1} = siteCode;
                end
            end
    
        % === CANOPUS .MAG (4-letter site code at the end) ===
        elseif endsWith(fname, '.MAG', 'IgnoreCase', true)
            if length(baseName) >= 4
                siteCode = baseName(end-3:end);
            else
                warning("Filename too short to extract site code: %s", baseName);
                continue;
            end
    
            if ~any(strcmpi(siteNames, siteCode))
                siteData = load_CANOPUS_site_MAG(siteCode, {fname});
                if isstruct(siteData)
                    count = count + 1;
                    b(count) = siteData;
                    siteNames{end+1} = siteCode;
                end
            end
    
        else
            disp(['Skipped unsupported file: ', fname]);
        end
    
    catch ME
        warning('Failed to load %s:\n%s', fname, getReport(ME, 'basic'));
    end

    
    
end
 

%ns = length(b); %Number of Mag sites loaded
toc

%Delete duplicates
inddelb = find(cellfun(@isempty,({b(:).x})));
b(inddelb) = [];
