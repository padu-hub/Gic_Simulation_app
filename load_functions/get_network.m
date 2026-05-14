function [L, S, T, L_plot] = get_network(networkPath)
% Function to load network data (L, S, T) from individual or combined file.
% Inputs is the full paths to:
% - A combined file (any one of the inputs), or


data = load(networkPath);
if isfield(data, 'L') && isfield(data, 'S') && isfield(data, 'T')
    L_plot = data.L;
    S = data.S;
    T = data.T;
else
    error('Combined file must contain variables L, S, and T.');
end

% Auto-generate buses if missing
if ~isfield(L_plot, 'fromBus')
    [L_plot, T] = get_buses(L_plot, S);
end

% Downsample and prepare line data
segLength = 5000;
L = get_downsampled_line(L_plot, segLength);
L = calc_line_length(L, S);

if ~isfield(L, 'Resistance')
    L = calc_line_resistance(L);
end
end
