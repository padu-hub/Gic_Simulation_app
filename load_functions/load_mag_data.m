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
% --- Group all files by site code first ---
group = {};
type = {};
for i = 1:length(magfile)
    [~, name, ext] = fileparts(magfile{i});
    ext = lower(ext);
    switch ext
        case '.sec'
            siteCode = upper(name(1:3));
        case '.f01'
            siteCode = upper(name(9:12));
        case '.min'
            siteCode = upper(name(1:3));
        case '.mag'
            siteCode = upper(name(9:12));
        otherwise
            continue
    end

    if ~isfield(group, siteCode)
        group.(siteCode) = {};
        type.(siteCode) = ext;
    end
    group.(siteCode){end+1} = magfile{i};
end


% --- Then load each site once, with all its files ---
count = 0;
siteNames = fieldnames(group);

for s = 1:numel(siteNames)
    sc = siteNames{s};
    files = group.(sc);
    ext = type.(sc);

    switch ext
        case '.sec'
            sample_rate = 1;
            b(s) = load_IAGA_site(sc, files, sample_rate);
        case '.f01'
            b(s) = load_CARISMA_site(sc, files);
        case '.min'
            sample_rate = 1/60;
            b(s) = load_IAGA_site(sc, files, sample_rate);
        case '.mag'
            b(s) = load_CANOPUS_site_MAG(sc, files);
    end
end
toc

%Delete duplicates
inddelb = find(cellfun(@isempty,({b(:).x})));
b(inddelb) = [];
