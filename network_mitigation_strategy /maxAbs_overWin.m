function m = maxAbs_overWin(vec, tidx)
    % Max absolute value over the window
    v = vec(tidx);
    m = max(abs(v), [], 'omitnan');
end