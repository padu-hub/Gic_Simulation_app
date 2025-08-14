function [ex, ey, latq, lonq, Bx,By] = initialize_gic_simulation(z_type, zFile, b, app)
%INITIALIZE_GIC_SIMULATION Prepare GIC modeling inputs from geo(b data) and network data.
%   Inputs:
%       z_type - integer indicating Z impedance method
%       zFile  - path to impedance .mat file
%       b      - magnetic data struct
%       lineFile, subFile, transFile - network file paths
%       app    - App Designer instance (used to update StatusTextArea)
%   Outputs:
%       ex, ey  - electric fields in x/y directions
%       latq, lonq - lat/lon coordinates used for E-field interpolation

app.StatusTextArea.Value = [app.StatusTextArea.Value; "Loading impedance data..."];
drawnow;

d = get_Z(z_type, zFile);

latq = d.loc(:,1);
lonq = d.loc(:,2);

app.StatusTextArea.Value = [app.StatusTextArea.Value; "Interpolating b(t) spatially..."];
drawnow;
[bx, by] = interpolate_b(b, latq, lonq);


nf = length(b(1).fAxis);
Bx = complex(zeros(length(latq), nf));
By = complex(zeros(length(latq), nf));

for i = 1:size(bx,1)
    [Bx(i,:), By(i,:)] = calc_fft(bx(i,:)', by(i,:)', b(1).fs, b(1).pad); 
end

[ex, ey] = get_e(d.Z, d.f, Bx, By, b, app);

app.StatusTextArea.Value = [app.StatusTextArea.Value; "Estimating average strike direction..."];
drawnow;
mage = sqrt(ex.^2 + ey.^2);
meanE = mean(mage, 2, 'omitnan');
strike = (180/pi) * mod(atan2(ey, ex), 2*pi);

c = cosd(strike);
s = sind(strike);
avg_c = sum(c,2) / size(strike,2);
avg_s = sum(s,2) / size(strike,2);
avg_strike = atan2d(avg_s, avg_c);

% Calculate GIC time indices
app.StatusTextArea.Value = [app.StatusTextArea.Value; "Computing time window indices..."];
drawnow;
end
