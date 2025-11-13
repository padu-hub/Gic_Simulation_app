function Tadd = batch_applyNeutralBlockers(app, GICbase, tidx)
% BATCH_APPLYNEUTRALBLOCKERS
% ----------------------------------------------------------
% For each AUTO transformer:
%   - Reset network to OriginalL/OriginalT
%   - Apply NB by setting THIS transformer's W2 = NaN
%   - Run GIC (GIC1)
%   - Record two rows:
%       (1) transformer-level (neutral = W2)
%       (2) substation-level (from GIC.Subs)
% Z metric: Avg Δ|GIC| over tidx  (edit - orig)
% Filter metric stored: % change of max |GIC| over tidx
% ----------------------------------------------------------

    % --- small helpers (vector/time-window safe)
    meanAbs  = @(x) mean(abs(x), 'all', 'omitnan');        % avg |.| over tidx
    maxAbs   = @(x)  max(abs(x), [], 'all', 'omitnan');    % max |.| over tidx
    pctChange = @(origMax,editMax) (origMax>0) .* (100*(editMax-origMax)./origMax) + ...
                                    (origMax==0).*NaN;

    rows  = [];                                 
    simID = height(app.MitigationResults) + 1;   

    % --- find AUTO transformers by type flags
    isAuto = arrayfun(@(t) strcmpi(t.HV_Type,'auto') || strcmpi(t.LV_Type,'auto'), app.T);
    autoIdx = find(isAuto);

    for k = autoIdx(:).'
        % ===== 1) Reset network, apply NB to THIS transformer only =====
        resetAllNetwork(app);            
        app.T(k).W2 = NaN;                

        % ===== 2) Run edited network =====
        [~, ~, ~, GIC1] = runGIC_now(app);

        % ===== 3) Transformer-level metrics (use W2 channel = 2) =====
        % GICbase.Trans / GIC1.Trans have shape: [nTrans x 2 x nTime]
        g0_tr_avg = meanAbs( squeeze(GICbase.Trans(k, 2, tidx)) );  
        g1_tr_avg = meanAbs( squeeze(GIC1.   Trans(k, 2, tidx)) );  
        g0_tr_max =  maxAbs( squeeze(GICbase.Trans(k, 2, tidx)) ); 
        g1_tr_max =  maxAbs( squeeze(GIC1.   Trans(k, 2, tidx)) );  

        pctMax_tr = pctChange(g0_tr_max, g1_tr_max);        % %Δ of max |GIC|
        dAvg_tr   = g1_tr_avg - g0_tr_avg;                  % Avg Δ|GIC| (A)

        rows(end+1) = makeRowNB(simID, 'NB_W2_OFF', app.T(k).Name, k, ...   
                                'transformer', app.T(k).Name, k, ...
                                g0_tr_avg, g1_tr_avg, dAvg_tr, pctMax_tr);

        % ===== 4) Substation-level metrics =====
        sid        = app.T(k).Sub;                          
        g0_sub_avg = meanAbs( GICbase.Subs(sid, tidx) );    
        g1_sub_avg = meanAbs( GIC1.   Subs(sid, tidx) );   
        g0_sub_max =  maxAbs( GICbase.Subs(sid, tidx) );    
        g1_sub_max =  maxAbs( GIC1.   Subs(sid, tidx) );    

        pctMax_sub = pctChange(g0_sub_max, g1_sub_max);
        dAvg_sub   = g1_sub_avg - g0_sub_avg;

        rows(end+1) = makeRowNB(simID, 'NB_W2_OFF', app.T(k).Name, k, ...   
                                'substation', app.S(sid).Name, sid, ...
                                g0_sub_avg, g1_sub_avg, dAvg_sub, pctMax_sub);

        % ===== 5) Next scenario column =====
        simID = simID + 1;
    end

    % --- convert to table for appending/plotting
    Tadd = rows2table(rows);
end
