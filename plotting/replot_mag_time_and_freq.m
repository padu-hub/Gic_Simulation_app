function replot_mag_time_and_freq(app, siteIndices, magPanel)
% Replots only the time series and frequency plots for each site (fast refresh)

    delete(allchild(magPanel));
    n = length(siteIndices);
    rowHeight = 480;
    totalHeight = max(rowHeight * n, magPanel.Position(4));
    innerPanel = uipanel(magPanel, 'Units', 'pixels', ...
        'Position', [0 0 magPanel.Position(3) totalHeight]);
    magPanel.Scrollable = 'on';

    b = app.b_cleaned;



    for k = 1:n
        is = siteIndices(k);
        if is == 0 || is > length(b); continue; end

        tvals = b(is).times;
        xvals = b(is).x;
        yvals = b(is).y;
        yBase = totalHeight - k * rowHeight + 20;

        % Time Series Plot
        ax1 = uiaxes(innerPanel);
        ax1.Position = [20, yBase + 240, magPanel.Position(3)-40, 180];
        plot(ax1, tvals, xvals - mean(xvals, 'omitnan'), '-b'); hold(ax1, 'on');
        plot(ax1, tvals, yvals - mean(yvals, 'omitnan'), '-r');
        title(ax1, ['Time Series for ', upper(b(is).site)]);
        ylabel(ax1, 'B (nT)'); 
        legend(ax1, 'Bx', 'By','Location','southwest');
        
        % Frequency Plot
        ax2 = uiaxes(innerPanel);
        ax2.Position = [20, yBase, magPanel.Position(3)-40, 180];     
        bfreq = app.b_freq(is);
        nf = length(bfreq.f);
        loglog(ax2, bfreq.f, abs(bfreq.X(1:nf)), '-b'); hold(ax2, 'on');
        loglog(ax2, bfreq.f, abs(bfreq.Y(1:nf)), '-r');
        title(ax2, ['Spectrum for ', upper(bfreq.site)]);
        xlabel(ax2, 'Frequency (Hz)'); ylabel(ax2, '|B|');
        
        addGraphToStorage(app, ax1, ['Time Series for ', upper(b(is).site)]) %store name of graph in dropdown column
        addGraphToStorage(app, ax2, ['Spectrum for ', upper(bfreq.site)]) %store name of graph in dropdown column
        
    end
end
