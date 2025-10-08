function [S0,L0,T0,GIC0] = runBaselineOnce(app)
% runBaselineOnce
% ---------------
% Purpose:
%   Run a single baseline GIC solution with current app.L/app.T (should be reset).
%
% Notes:
%   Uses your provided signature for calc_gic_main. All other inputs live on app.
%
% Returns:
%   S0, L0, T0   - struct arrays with fields holding baseline |GIC| series
%   GIC0         - any time series/arrays returned by calc_gic_main (unused here but kept)

    [S0, L0, T0, GIC0, ~, ~, ~, ~] = ...
        calc_gic_main(app, app.S, app.L, app.T, ...
                      app.ex, app.ey, app.latq, app.lonq, ...
                      app.tind, app.uniform, app.OriginalL, app.OriginalT);
end
