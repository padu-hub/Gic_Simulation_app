function out = alignRowsByNames(oldMat, oldNames, newMat, newNames, masterNames)
    % sizes
    if isempty(oldMat), oldMat = []; end
    if isempty(newMat), newMat = []; end
    [rNew, cNew] = size(newMat);
    [rOld, cOld] = size(oldMat);
    nCols = max([cNew, cOld, 0]);
    nRows = numel(masterNames);                 % target rows = master length

    out = NaN(nRows, nCols);                    % allocate full-size with NaN

    % Map function: name list to row indices (fall back to 1..n if names empty)
    function idx = mapNames(names)
        if isempty(names)
            idx = []; return
        end
        if iscellstr(names) || isstring(names)
            names = cellstr(names);
            [found, loc] = ismember(names, masterNames);
            % names not in master -> append at end (keep order of those)
            notInMaster = find(~found);
            if ~isempty(notInMaster)
                % extend master mapping: put them after master end in same order
                loc(notInMaster) = nRows + (1:numel(notInMaster));
            end
            idx = loc;
        else
            % no names provided: assume 1:rows
            idx = (1:numel(names))';
        end
    end

    oldIdx = mapNames(oldNames);
    newIdx = mapNames(newNames);

    % copy overlapping old data into out (preserve original positions)
    if ~isempty(oldIdx)
        colsToCopy = 1:min(nCols, cOld);
        out(oldIdx, colsToCopy) = oldMat(:, colsToCopy);
    end
    % copy new data (overwrite corresponding rows/cols)
    if ~isempty(newIdx)
        colsToCopy = 1:min(nCols, cNew);
        out(newIdx, colsToCopy) = newMat(:, colsToCopy);
    end
end