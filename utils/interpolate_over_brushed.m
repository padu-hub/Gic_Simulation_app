function new_data = interpolate_over_brushed(data, brush_mask)
    new_data = data;
    N = length(data);
    indices = find(brush_mask(:));  % Brushed indices

    for i = indices(:)'  % Loop over brushed points
        if i < 1 || i > N
            continue;
        end

        % Look left and right for valid unbrushed points
        prev = find(~brush_mask(1:i-1), 1, 'last');
        next = find(~brush_mask(i+1:end), 1, 'first');

        if ~isempty(prev); prev = i - (i - prev); end
        if ~isempty(next); next = i + next; end

        if ~isempty(prev) && ~isempty(next)
            new_data(i) = mean([data(prev), data(next)], 'omitnan');
        elseif ~isempty(prev)
            new_data(i) = data(prev);
        elseif ~isempty(next)
            new_data(i) = data(next);
        else
            new_data(i) = NaN; % fallback
        end
    end
end
