function sandBoxMassResults (app)
% =====================================================
% Save Original Network
% =====================================================
S0 = app.SandboxS;
L0 = app.SandboxL;
T0 = app.SandboxT;

% =====================================================
% Mitigation Definition
% =====================================================

% Mit.Name = {'Example Mitigation','Example'};
% Mit.Type = {'L','T'};   %L, S, T
% Mit.Index = {1,1};     %Which sub, line, transformer
% Mit.Field = {'ResKm','W1'}; % S Fields: Resistance, Latitude, Longitude
% % L Fields: Resistance, ResKm, Voltage, Length
% % T Fields: W1, W2, W1_Voltage, W2_Voltage, HV_Type, LV_Type
% Mit.Operation = {'set','set'};   % set / add / multiply
% 
% Mit.Values = {0.1:0.1:2, 0.1:0.2:4};
% %Steps must always equal

d = linspace(0,50,30);

Mit.Name = {'Stretch Centre Corridor'};

Mit.Type = { ...
    'S','S','S', ...
    'S','S','S'};

Mit.Index = { ...
    1,5,6, ...
    2,3,4};

Mit.Field = { ...
    'Longitude','Longitude','Longitude', ...
    'Longitude','Longitude','Longitude'};

Mit.Operation = { ...
    'add','add','add', ...
    'add','add','add'};   % set / add / multiply

Mit.Values = { ...
    -d, -d, -d, ...
     d,  d,  d};


nSteps = numel(Mit.Values{1});
app.sandBoxMode = 1;
app.theta = 0:app.SandboxAngleStep:app.SandboxAngle;
theta= app.theta;

for n = 1:2
Results = struct([]);
for i = 1:nSteps

    S = S0;
    L = L0;
    T = T0;
    
    if n == 2
        L(1).ResKm= NaN;
    end
    % =================================================
    % Apply All Mitigations At This Step
    % =================================================
    for m = 1:numel(Mit.Type)

        val = Mit.Values{m}(i);

        type  = Mit.Type{m};
        idx   = Mit.Index{m};
        field = Mit.Field{m};
        op    = Mit.Operation{m};

        switch type

            % -----------------------------------------
            % Substation
            % -----------------------------------------
            case 'S'

                oldVal = S0(idx).(field);

                switch op

                    case 'set'
                        S(idx).(field) = val;

                    case 'add'
                        S(idx).(field) = ...
                            oldVal + val;

                    case 'multiply'
                        S(idx).(field) = ...
                            oldVal * val;

                end

            % -----------------------------------------
            % Line
            % -----------------------------------------
            case 'L'

                oldVal = L0(idx).(field);

                switch op

                    case 'set'
                        L(idx).(field) = val;

                    case 'add'
                        L(idx).(field) = ...
                            oldVal + val;

                    case 'multiply'
                        L(idx).(field) = ...
                            oldVal * val;

                end

            % -----------------------------------------
            % Transformer
            % -----------------------------------------
            case 'T'

                oldVal = T0(idx).(field);

                switch op

                    case 'set'
                        T(idx).(field) = val;

                    case 'add'
                        T(idx).(field) = ...
                            oldVal + val;

                    case 'multiply'
                        T(idx).(field) = ...
                            oldVal * val;

                end

        end

    end

    % =================================================
    % Update Line Geometry
    % =================================================
    for k = 1:length(L)
    
        % ---------------------------------------------
        % Connected Substations
        % ---------------------------------------------
        fromSub = sscanf( ...
            L(k).fromSub,...
            '%*[^0-9]%d');
    
        toSub = sscanf( ...
            L(k).toSub,...
            '%*[^0-9]%d');
    
        % ---------------------------------------------
        % Current Coordinates
        % ---------------------------------------------
        p1 = [
            S(fromSub).Longitude
            S(fromSub).Latitude
            ];
    
        p2 = [
            S(toSub).Longitude
            S(toSub).Latitude
            ];
    
        % ---------------------------------------------
        % Update Length
        % ---------------------------------------------
        len = norm(p2 - p1);
    
        L(k).Length = len;
    
        % ---------------------------------------------
        % Update Location
        % ---------------------------------------------
        L(k).Loc = [
            p1(2) p1(1)
            p2(2) p2(1)
            ];
    
        % ---------------------------------------------
        % Update Resistance
        % ---------------------------------------------    
        L(k).Resistance = L(k).ResKm * len;        
    end
    % Update Substation Location (Loc) from Latitude/Longitude
    for k = 1:length(S)
        lat = S(k).Latitude;
        lon = S(k).Longitude;
        S(k).Loc = [lat lon];
    end
    

    % =================================================
    % Build Simulation Network
    % =================================================
    [Ssim,Lsim,Tsim,latq,lonq] = buildSandboxSimulationNetwork(app,S,L,T);

    % =================================================
    % Run Simulation
    % =================================================
    [~,~,~,GIC_sandBox,~,~,~,~] = ...
        calc_gic_main( ...
        app,...
        Ssim,...
        Lsim,...
        Tsim,...
        app.EfieldValueEditField.Value,...
        [],...
        latq,...
        lonq,...
        [],...
        Lsim,...
        Tsim);

    % =================================================
    % Store Results
    % =================================================
    Results(i).Step = L(1).Length;

    Results(i).Subs = ...
        GIC_sandBox.Subs;

    Results(i).Lines = ...
        GIC_sandBox.Lines;

    Results(i).iInduced = ...
        GIC_sandBox.iInduced;

    Results(i).MitValues = ...
        cellfun(@(x)x(i), ...
        Mit.Values);
end

if n == 1
    GIC_base = Results;      % original network
else
    currentResults = Results; % mitigated network
end
end

plotSandboxMassResults(currentResults,GIC_base,theta);
plotMaxGICvsStep(currentResults,GIC_base);
app.sandBoxMode = 0;

end


function plotMaxGICvsStep(Results,GIC_base)

% =====================================================
% Dimensions
% =====================================================
nSteps = length(Results);
nSubs  = size(Results(1).Subs,1);

% =====================================================
% Preallocate
% =====================================================
DeltaPeak = zeros(nSteps,nSubs);
stepVals  = zeros(nSteps,1);

% =====================================================
% Compute Peak Difference
% =====================================================
for k = 1:nSteps

    cur  = abs(Results(k).Subs);      % nSubs x nAngles
    base = abs(GIC_base(k).Subs);

    for s = 1:nSubs

        % ---------------------------------------------
        % Peak GIC over all E-field angles
        % ---------------------------------------------
        curPeak  = max(cur(s,:));
        basePeak = max(base(s,:));

        % ---------------------------------------------
        % Difference in peak GIC
        % ---------------------------------------------
        DeltaPeak(k,s) = ...
            curPeak - basePeak;

    end

    stepVals(k) = Results(k).Step;

end

% Sort by line length
[stepVals,idx] = sort(stepVals);

DeltaPeak = DeltaPeak(idx,:);

% Plot
figure( ...
    'Color','w',...
    'Name','Peak GIC Change vs Line Length');

hold on
grid on

colors = lines(nSubs);

tol = 1e-6;

used = false(1,nSubs);

for s = 1:nSubs

    if used(s)
        continue
    end

    % Skip insignificant substations
    if max(abs(DeltaPeak(:,s))) < 1
        continue
    end

    group = s;

    for t = s+1:nSubs

        if max(abs( ...
                DeltaPeak(:,s) - ...
                DeltaPeak(:,t))) < tol

            group(end+1) = t;
            used(t) = true;

        end

    end

    % -----------------------------------------
    % Legend Name
    % -----------------------------------------
    label = sprintf('%d,',group);
    label(end) = [];

    plot( ...
        stepVals,...
        DeltaPeak(:,s),...
        '-',...
        'Color',colors(s,:),...
        'LineWidth',1.5,...
        'DisplayName',...
        ['Sub ' label]);

end

xlabel('Line Length (km)')

ylabel('\Delta Peak |GIC| (A)')

title(['Change in peak |GIC|: ' ...
       'Disconnected - Connected'])

legend('Location','best')

end





function plotSandboxMassResults(Results,GIC_base,theta)

%     =====================================================
%    Dimensions
%     =====================================================
    nSteps = length(Results);
    nSubs = size(Results(1).Subs,1);
    nAngles = size(Results(1).Subs,2);

    %Step Values (e.g. Line Length)
    StepVals = zeros(nSteps,1);

    for i = 1:nSteps
        StepVals(i) = Results(i).Step;
    end

%     =====================================================
%     Build Delta GIC for Each Substation
%     =====================================================
    DeltaSubs = zeros(nSteps,nAngles,nSubs);

    globalMax = 0;

    for step = 1:nSteps

        Current = abs(Results(step).Subs);
        Base    = abs(GIC_base(step).Subs);

        Delta = Current - Base;

        for s = 1:nSubs

            DeltaSubs(step,:,s) = Delta(s,:);

            globalMax = max( ...
                globalMax,...
                max(abs(Delta(s,:))));

        end

    end

    if globalMax == 0
        globalMax = 1;
    end

%     -------------------------------------------------
%     Find Relevant Substations
%     -------------------------------------------------
    relevantSubs = [];

    for s = 1:nSubs

        Z = squeeze(DeltaSubs(:,:,s));

        if max(abs(Z(:))) >= 1
            relevantSubs(end+1) = s;
        end

    end

    nRelevant = length(relevantSubs);

    nRows = floor(sqrt(nRelevant));
    nCols = ceil(nRelevant/nRows);

    if nRows*nCols < nRelevant
        nRows = nRows + 1;
    end
%     Plot Heatmaps
%   =====================================================
%   Plot Heatmaps
%   =====================================================
    figure( ...
        'Color','w',...
        'Name','Substation GIC Change Heatmaps');

    t = tiledlayout(nRows,nCols,...
        'TileSpacing','compact',...
        'Padding','compact');

    title(t,...
        '\Delta|GIC| after diconnecting L1')

    for i = 1:nRelevant
        nexttile
        s = relevantSubs(i);

        Z = squeeze(DeltaSubs(:,:,s));

        imagesc( ...
            theta,...
            StepVals,...
            Z)

        axis xy

        xlabel( ...
            'E-Field Orientation (deg)')

        ylabel( ...
            'Line Length(km)')

        title( ...
            sprintf('Substation %d',s))

        localMax = max(abs(Z(:)));

        if localMax == 0
            localMax = 1;
        end

        clim([-localMax localMax])
        clim([-globalMax globalMax])

        colorbar

    end

    colormap(redblue(30));

end
