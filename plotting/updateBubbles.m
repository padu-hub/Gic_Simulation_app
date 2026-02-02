function updateBubbles(h, idxMax,currentData, titleStr)
    % bubble size scaling
    gicVals = arrayfun(@(i) currentData(i, idxMax(i)), 1:size(currentData,1))';
    cVals = gicVals;

    child = h.bubbles.Children;   

    % Find the child that supports SizeData
    idx = find(arrayfun(@(c) isprop(c,'SizeData') && isprop(c,'CData'), child), 1, 'first');
    
    if isempty(idx)
        error("Could not find a child object with SizeData/CData inside the scatterm group.");
    end
    
    child(idx).SizeData = 30 + 30*abs(gicVals);
    child(idx).CData    = cVals;

    % keep color scaling sensible
    clim = max(abs(cVals), [], 'omitnan');
    if isempty(clim) || ~isfinite(clim) || clim == 0, clim = 1; end
    caxis([-clim clim]);

    title(titleStr);
    drawnow limitrate;
end
