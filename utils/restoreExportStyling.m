function restoreExportStyling(ax, styleInfo)
%RESTOREEXPORTSTYLING Reverts axes and legend styles after export

    ax.Color = styleInfo.AxesColor;
    ax.XColor = styleInfo.XColor;
    ax.YColor = styleInfo.YColor;
    ax.ZColor = styleInfo.ZColor;
    ax.Title.Color = styleInfo.TitleColor;

    % Restore legend if it existed
    legend(ax, ...
    'Color', ax.Color, ...          % Legend background
    'TextColor', ax.XColor, ...    % Legend font color
    'EdgeColor', ax.XColor, ...    % Border color
    'Box', 'on', ...               % include border
    'Location', 'southwest'); 
    
    
    % Position

    drawnow;
end
