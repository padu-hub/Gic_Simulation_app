function editClickedPoint(app, src, ax, siteIdx, comp)
        % Get the data and index of clicked point
        [xClick, yClick] = ginput(1);

        % Get b_cleaned data
        b = app.b_cleaned;
        tidx = app.tidx;

        % Trim tidx safely
        nt = min([length(tidx), length(b(siteIdx).times)]);
        tvals = b(siteIdx).times(tidx(1:nt));
        datay = b(siteIdx).(comp)(tidx(1:nt));

        % Find index of nearest time
        [~, id] = min(abs(datenum(tvals) - datenum(xClick)));

        % Set NaN
        b(siteIdx).x(tidx(id)) = NaN;
        b(siteIdx).y(tidx(id)) = NaN;
        b(siteIdx).z(tidx(id)) = NaN;

        % Inpaint
        b(siteIdx).x = inpaint_nans(b(siteIdx).x, 4);
        b(siteIdx).y = inpaint_nans(b(siteIdx).y, 4);
        b(siteIdx).z = inpaint_nans(b(siteIdx).z, 4);

        % Save updated
        app.b_cleaned = b;

        % Replot
        isEditable = strcmp(app.CleanModeSwitch.Value, "On");
        selectedNames = app.SiteListBox.Value;
        [~, selectedIndices] = ismember(selectedNames, string({b.site}));
        plot_mag_sites(app, b, app.tidx, selectedIndices, app.MagneticBPlotsPanel, isEditable);
end