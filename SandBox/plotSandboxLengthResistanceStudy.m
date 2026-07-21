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

DeltaPeak = zeros(length(dVals),nSubs);
len2 = zeros(length(dVals),1);

app.sandBoxMode = 1;
app.theta = 0:app.SandboxAngleStep:app.SandboxAngle;

for i = 1:length(dVals)
    d = dVals(i);

    S = S0;
    L = L0;
    T = T0;

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
    [~,~,~,GIC_conn,~,~,~,~] = calc_gic_main(app, Ssim, Lsim, Tsim, app.EfieldValueEditField.Value, [], latq, lonq, [], Lsim, Tsim);

    % Disconnected case (line 2 removed)
    Ldisc = L;
    Ldisc(2).ResKm = NaN;
    len2(i) = Ldisc(2).Length;

    [Ssim,Lsim,Tsim,latq,lonq] = buildSandboxSimulationNetwork(app, S, Ldisc, T);
    [~,~,~,GIC_disc,~,~,~,~] = calc_gic_main(app, Ssim, Lsim, Tsim, app.EfieldValueEditField.Value, [], latq, lonq, [], Lsim, Tsim);

    % Peak difference per subsystem
    cur  = abs(GIC_disc.Subs);
    base = abs(GIC_conn.Subs);
    for s = 1:nSubs
        DeltaPeak(i,s) = max(cur(s,:)) - max(base(s,:));
    end
end

DP = squeeze(DeltaPeak);        % result: N x M (N=length(dVals), M=number of subs)
len2 = len2(:);

% Remove columns that are all zeros or all NaN
allZero = all(DP == 0, 1);
allNaN  = all(isnan(DP), 1);
keepMask = ~(allZero | allNaN);
DP = DP(:, keepMask);
origIdx = find(keepMask);       % original subsystem indices kept

% Remove duplicate columns (exact match, NaNs matched position-wise)
keep = false(1, size(DP,2));
keptIdx = [];
for c = 1:size(DP,2)
    col = DP(:,c);
    isDup = false;
    tol = 1e-9;
    for k = keptIdx
        other = DP(:,k);
        if colsEqual(col, other, tol)
            isDup = true; break
        end
    end

    if ~isDup
        keptIdx(end+1) = c; 
        keep(c) = true;
    end
end
DP = DP(:, keep);
origIdx = origIdx(keep);

% Plot remaining unique, non-empty subs
figure; hold on;
for ii = 1:size(DP,2)
    sidx = origIdx(ii);           % original substation index
    plot(len2, DP(:,ii), '-o', 'DisplayName', sprintf('Sub %d', sidx));
end
hold off;
xlabel('Ldisc(2).Length (m)');
ylabel('Delta Peak (A)');
grid on;
legend('show','Location','best');

end





function tf = colsEqual(col, other, tol)
% tf = colsEqual(col, other, tol)
% Returns true if col and other are equal elementwise within tol,
% treating NaNs at the same positions as equal and -0 equal to +0.
% col, other: vectors (will be linearized). tol: scalar >=0 (default 0).

if nargin < 3 || isempty(tol), tol = 0; end


% Positions where both are NaN
nanBoth = isnan(col) & isnan(other);

% Positions where neither is NaN -> compare numerically
numPos = ~(isnan(col) | isnan(other));
if tol == 0
    % exact numeric comparison (0 == -0 is true)
    numerEq = all(col(numPos) == other(numPos));
else
    numerEq = all(abs(col(numPos) - other(numPos)) <= tol);
end

% They are equal if numeric positions match and NaN positions align
tf = numerEq && all(nanBoth | ~(isnan(col) | isnan(other)));
end


