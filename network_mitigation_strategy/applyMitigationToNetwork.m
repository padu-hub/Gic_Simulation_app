function [app, lineOpen, windingBlocked, desc] = ...
    applyMitigationToNetwork(app, type, idx, lineOpen, windingBlocked)

    switch type
        case 'line'
            i = idx;
            lineOpen(i) = true;
            if isfield(app.L,'ResKm')
                app.L(i).ResKm = 1000000000;
                app.L(i).Resistance = 1000000000;
            end
            desc = sprintf('Turned OFF line %s\n', app.L(i).Name);
            
            


        case 'winding'
            k = idx(1); w = idx(2);
            windingBlocked(k,w) = true;

            if w == 1
                if isfield(app.T,'W1')
                    app.T(k).W1 = NaN;
                end
            else
                if isfield(app.T,'W2')
                    app.T(k).W2 = NaN;
                end
            end

            desc = sprintf('Blocked transformer %d winding W%d\n', app.T(k).Name, w);

        otherwise
            error('Unknown mitigation type.');
    end
end
