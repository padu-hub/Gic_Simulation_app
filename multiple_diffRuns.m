function multiple_diffRuns(app, S, L, T)
    % multiple_diffRuns
    % Loads multiple E-field event MAT files (each contains struct "data")
    % Runs calc_gic_main once per minute and updates a bubble plot live.
    %
    % Bubble color/value = running average of (per-minute max |GIC|) so far
    % within the CURRENT event.
    [fileNames, pathName] = uigetfile('*.mat', 'Select E-field event .mat files', 'MultiSelect', 'on');
    if isequal(fileNames,0), return; end
    if ischar(fileNames), fileNames = {fileNames}; end

    OriginalL = L;
    OriginalT = T;

    % Init map ONCE
    h = initAlbertaMap(S, L);

    nSubs = numel(h.subLat);

    for i = 1:numel(fileNames)
        loaded = load(fullfile(pathName, fileNames{i}));
        if ~isfield(loaded,'data')
            warning('Skipping "%s": missing data struct.', fileNames{i});
            continue;
        end
        data = loaded.data;
        req = {'ex','ey','latq','lonq','tind'};
        if any(~isfield(data, req))
            warning('Skipping "%s": missing fields.', fileNames{i});
            continue;
        end

        ex   = data.ex;   ey   = data.ey;
        latq = data.latq; lonq = data.lonq;
        tind = data.tind;

        % reset running average per EVENT
        sumMinuteMax = zeros(nSubs,1);
        nMinutesDone = 0;

        nMin = ceil(numel(tind)/60);
        [~, baseName, ~] = fileparts(fileNames{i});

        for m = 1:nMin
            idx1 = (m-1)*60 + 1;
            idx2 = min(m*60, numel(tind));
            currentTind = tind(idx1:idx2);

            % Run per-minute
            [~,~,~,GIC_temp,~,~,~,~] = ...
                calc_gic_main(app, S, L, T, ex, ey, latq, lonq, currentTind, false, OriginalL, OriginalT);

            subsMat = GIC_temp.Original_Subs;  % nSubs x nChunkTime
            
            if m == 1
                allSubsMat = subsMat;  % Initialize on first minute
            else
                allSubsMat = [allSubsMat; subsMat];  % Concatenate new subsMat to previous
            end

            if size(subsMat,1) ~= nSubs
                warning('Event "%s" minute %d: subs mismatch (%d vs %d).', baseName, m, size(subsMat,1), nSubs);
                continue;
            end

            [~, gicMax] = max(abs(allSubsMat), [], 2, 'omitnan');  % minuteMax is nRows×1
 
            updateBubbles(h, gicMax, allSubsMat, sprintf('%s  — minute %d/%d', baseName, m, nMin));
        end
    end
end
