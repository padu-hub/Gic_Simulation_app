function parallelGroups = buildParallelGroups(L)
    locMap = containers.Map('KeyType','char','ValueType','any');
    for i = 1:numel(L)
        key = mat2str(L(i).Loc);
        if isKey(locMap,key)
            locMap(key) = [locMap(key) i];
        else
            locMap(key) = i;
        end
    end

    parallelGroups = {};
    vals = values(locMap);
    for k = 1:numel(vals)
        v = vals{k};
        if numel(v) > 1
            parallelGroups{end+1} = v(:);
        end
    end
end
