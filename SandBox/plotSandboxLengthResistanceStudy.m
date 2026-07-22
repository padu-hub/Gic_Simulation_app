% 
% function plotSandboxLengthResistanceStudy(app)
% S0 = app.SandboxS;
% L0 = app.SandboxL;
% T0 = app.SandboxT;
% 
% % =====================================================
% % Sweep Values
% % =====================================================
% dVals = linspace(0,100,20);
% 
% %rVals = linspace(0.01,0.5,20);
% 
% nSubs = length(S0);
% 
% % DeltaPeak = ...
% %     zeros(length(dVals),...
% %           length(rVals),...
% %           nSubs);
% DeltaPeak = ...
%     zeros(length(dVals),...
%           1,...
%           nSubs);
% app.sandBoxMode = 1;
% app.theta = 0:app.SandboxAngleStep:app.SandboxAngle;
% 
% len2 = zeros(length(dVals),1);
% 
% % =====================================================
% % Parameter Sweep
% % =====================================================
% for i = 1:length(dVals)
% 
%     d = dVals(i);
%     j=1;
%     %for j = 1:length(rVals)
% 
%         %r = rVals(j);
% 
%         S = S0;
%         L = L0;
%         T = T0;
% 
%         % ---------------------------------------------
%         % Stretch Corridor
%         % -----------------------------------
%         % 
%         for k = [1 5 6]
% 
%             S(k).Longitude = ...
%                 S0(k).Longitude - d;
% 
%         end
% 
%         for k = [2 3 4]
% 
%             S(k).Longitude = ...
%                 S0(k).Longitude + d;
% 
%         end
% 
%         % % ---------------------------------------------
%         % % Change Corridor Resistance
%         % % ---------------------------------------------
%         % L(1).ResKm = r;
%         % L(2).ResKm = r;
% 
%         % ---------------------------------------------
%         % Rebuild Lengths
%         % ---------------------------------------------
%         for k = 1:length(L)
% 
%             fromSub = sscanf( ...
%                 L(k).fromSub,...
%                 '%*[^0-9]%d');
% 
%             toSub = sscanf( ...
%                 L(k).toSub,...
%                 '%*[^0-9]%d');
% 
%             p1 = [ ...
%                 S(fromSub).Longitude
%                 S(fromSub).Latitude];
% 
%             p2 = [ ...
%                 S(toSub).Longitude
%                 S(toSub).Latitude];
% 
%             len = norm(p2-p1);
% 
%             L(k).Length = len;
% 
%             L(k).Resistance = ...
%                 L(k).ResKm * len;
% 
%         end
% 
%         % =============================================
%         % Connected Case
%         % =============================================
%         [Ssim,Lsim,Tsim,latq,lonq] = ...
%             buildSandboxSimulationNetwork( ...
%             app,S,L,T);
% 
%         [~,~,~,GIC_conn,~,~,~,~] = ...
%             calc_gic_main( ...
%             app,...
%             Ssim,...
%             Lsim,...
%             Tsim,...
%             app.EfieldValueEditField.Value,...
%             [],...
%             latq,...
%             lonq,...
%             [],...
%             Lsim,...
%             Tsim);
% 
%         % =============================================
%         % Disconnected Case
%         % =============================================
%         Ldisc = L;
% 
%         Ldisc(2).ResKm = NaN;
%         len2(i) = Ldisc(2).Length;
% 
%         [Ssim,Lsim,Tsim,latq,lonq] = ...
%             buildSandboxSimulationNetwork( ...
%             app,S,Ldisc,T);
% 
%         [~,~,~,GIC_disc,~,~,~,~] = ...
%             calc_gic_main( ...
%             app,...
%             Ssim,...
%             Lsim,...
%             Tsim,...
%             app.EfieldValueEditField.Value,...
%             [],...
%             latq,...
%             lonq,...
%             [],...
%             Lsim,...
%             Tsim);
% 
%         % =============================================
%         % Peak Difference
%         % =============================================
%         cur = abs(GIC_disc.Subs);
% 
%         base = abs(GIC_conn.Subs);
% 
%         for s = 1:nSubs
% 
%             DeltaPeak(i,j,s) = ...
%                 max(cur(s,:)) - ...
%                 max(base(s,:));
% 
%         end
% 
% end
% 
% % find subs with any nonzero values across d sweep
% nonzeroSubs = find(any(DeltaPeak(:,:, :) ~= 0, 1)); % returns 1×n vector
% nonzeroSubs = squeeze(nonzeroSubs);
% 
% figure;
% hold on;
% 
% for idx = nonzeroSubs
%     dp = squeeze(DeltaPeak(:, 1, idx));   % vector over dVals
%     plot(len2, dp, '-o', 'DisplayName', sprintf('Sub %d', idx));
% end
% 
% hold off;
% xlabel('Ldisc(2).Length (m)');
% ylabel('Delta Peak (A)');
% grid on;
% legend('Location','best');
% 
% 
% % % =====================================================
% % % Plot
% % % =====================================================
% % [R,D] = meshgrid(rVals,dVals);
% % 
% % figure('Color','w')
% % 
% % for s = 1:nSubs
% % 
% %     subplot(2,ceil(nSubs/2),s)
% % 
% %     surf(R,D,DeltaPeak(:,:,s))
% % 
% %     shading interp
% % 
% %     xlabel('ResKm')
% % 
% %     ylabel('Stretch')
% % 
% %     zlabel('\Delta Peak GIC (A)')
% % 
% %     title(sprintf('Sub %d',s))
% % 
% %     colorbar
% % 
% %     view(135,30)
% % end
% % 
% % sgtitle('Peak GIC Change (Disconnected - Connected)')
% % 
% % end

function plotSandboxLengthResistanceStudy(app)
    S0 = app.SandboxS;
    L0 = app.SandboxL;
    T0 = app.SandboxT;
    
    dVals = linspace(0,100,20);
    nSubs = length(S0);
    
    DeltaPeak = zeros(length(dVals), nSubs);
    len2 = zeros(length(dVals), 1);
    
    app.sandBoxMode = 1;
    app.theta = 0:app.SandboxAngleStep:app.SandboxAngle;
    
    for i = 1:length(dVals)
        d = dVals(i);
        
        S = S0; L = L0; T = T0;
        
        for k = [1 5 6]
            S(k).Longitude = S0(k).Longitude - d;
        end
        for k = [2 3 4]
            S(k).Longitude = S0(k).Longitude + d;
        end
        
        % Rebuild lengths and resistances
        for k = 1:length(L)
            fromSub = sscanf(L(k).fromSub, '%*[^0-9]%d');
            toSub   = sscanf(L(k).toSub,   '%*[^0-9]%d');
            p1 = [S(fromSub).Longitude; S(fromSub).Latitude];
            p2 = [S(toSub).Longitude;   S(toSub).Latitude];
            len = norm(p2 - p1);
            L(k).Length = len;
            L(k).Resistance = L(k).ResKm * len;
        end
        
        % Connected case
        [Ssim,Lsim,Tsim,latq,lonq] = buildSandboxSimulationNetwork(app, S, L, T);
        [~,~,~,GIC_conn,~,~,~,~]  = calc_gic_main(app, Ssim, Lsim, Tsim, app.EfieldValueEditField.Value, [], latq, lonq, [], Lsim, Tsim);
        
        % Disconnected case (line 2 removed)
        Ldisc = L;
        Ldisc(2).ResKm = NaN;
        len2(i) = Ldisc(2).Length;
        
        [Ssim,Lsim,Tsim,latq,lonq] = buildSandboxSimulationNetwork(app, S, Ldisc, T);
        [~,~,~,GIC_disc,~,~,~,~]  = calc_gic_main(app, Ssim, Lsim, Tsim, app.EfieldValueEditField.Value, [], latq, lonq, [], Lsim, Tsim);
        
        % Peak difference per subsystem
        cur  = abs(GIC_disc.Subs);
        base = abs(GIC_conn.Subs);
        for s = 1:nSubs
            DeltaPeak(i,s) = max(cur(s,:)) - max(base(s,:));
        end
    end
    
    DP = squeeze(DeltaPeak);
    len2 = len2(:);
    
    
    % Create 4 distinct colors for plotting
    colors = [0   0.2 0.6;    
          1   0.4 0;      
          0   0.5 0.25;   
          0.8 0   0.6]; 
    
    subsToPlot = [1, 2, 6];   % substations to plot
    figure; hold on;
    for j = 1:numel(subsToPlot)
        s = subsToPlot(j);
        plot(len2, DP(:, s), '-o', 'Color', colors(j,:), ...
             'DisplayName', sprintf('Sub %d', s));
    end
    hold off;
    xlabel('Length (km)');
    ylabel('Delta Peak (A)');
    grid on;
    legend('show','Location','best');

end
