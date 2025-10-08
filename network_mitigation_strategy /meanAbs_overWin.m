function m = meanAbs_overWin(vec, tidx)
    % Average absolute value over the window
    v = vec(tidx);
    m = mean(abs(v), 'omitnan');
end
