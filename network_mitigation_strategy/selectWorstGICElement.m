function [type, idx, val] = selectWorstGICElement(GIC, candLines, candWind)
    type = []; idx = []; val = NaN;
    vals = []; types = {}; idxs = {};

    % Lines
    for i = candLines(:)'
        mx = max(abs(GIC.Lines(i,:)),[],'omitnan');
        vals(end+1) = mx;
        types{end+1} = 'line';
        idxs{end+1}  = i;
    end

    % Windings
    for n = 1:size(candWind,1)
        k = candWind(n,1); w = candWind(n,2);
        mx = max(abs(GIC.Trans(k,:,:)),[],'omitnan');
        vals(end+1) = mx;
        types{end+1} = 'winding';
        idxs{end+1}  = [k w];
    end

    if isempty(vals), return; end

    [val, m] = max(vals);
    type = types{m};
    idx  = idxs{m};
end
