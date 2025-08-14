function animate_gic_mag_map(S, L, b, GIC_Subs, T, timeIndices, delay)
%ANIMATE_GIC_MAG_MAP Animate GIC and magnetic vectors over time.
%
% Inputs:
%   S, L, b, GIC_Subs, T    - same as plot_gic_mag_map
%   timeIndices             - vector of time indices to loop over
%   delay                   - pause in seconds between frames (e.g., 0.2)

    if nargin < 7
        delay = 0.25; % default frame delay
    end

    f = figure('Name','GIC + Magnetic Animation','NumberTitle','off');

    for k = 1:length(timeIndices)
        if ~isvalid(f)
            disp('Animation stopped by user (figure closed).');
            break;
        end

        clf(f);  % Clear figure
        plot_gic_mag_map(S, L, b, GIC_Subs, T, timeIndices(k));
        drawnow;
        pause(delay);
    end
end
