function restoreExportStyling(ax, styleInfo)
%RESTOREEXPORTSTYLING Reverts axes and legend styles after export

    % Restore axes colors
    ax.Color = styleInfo.AxesColor;
    ax.XColor = styleInfo.XColor;
    ax.YColor = styleInfo.YColor;
    ax.ZColor = styleInfo.ZColor;
    ax.Title.Color = styleInfo.TitleColor;
    ax.XLabel.Color = styleInfo.XLabelColor;
    ax.YLabel.Color = styleInfo.YLabelColor;

    % Restore parent figure color if saved
    if isfield(styleInfo, 'FigureColor') && ...
       isprop(ax, 'Parent') && isprop(ax.Parent, 'Color')
        ax.Parent.Color = styleInfo.FigureColor;
    end

    % Restore legend if it exists
    lg = legend(ax);
    if ~isempty(lg) && isvalid(lg)
        if isfield(styleInfo, 'LegendColor') && ~isempty(styleInfo.LegendColor)
            lg.Color = styleInfo.LegendColor;
        end
        if isfield(styleInfo, 'LegendTextColor') && ~isempty(styleInfo.LegendTextColor)
            lg.TextColor = styleInfo.LegendTextColor;
        end
        if isfield(styleInfo, 'LegendEdgeColor') && ~isempty(styleInfo.LegendEdgeColor)
            lg.EdgeColor = styleInfo.LegendEdgeColor;
        end
        lg.Box = 'on';
    end

    drawnow;
end