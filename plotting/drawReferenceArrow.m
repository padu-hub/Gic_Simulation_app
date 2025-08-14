function drawReferenceArrow(scale, ax, shaftHandle, arrowHandle)
% Draws a vertical reference arrow on UIAxes with consistent head size
    % Calculate scaled components
    scaledU = scale * 0;
    scaledV = scale * 1;
    
    % Calculate base and tip positions for the shaft
    baseX = 0.5; baseY = 10;
    tipX = baseX + scaledU; tipY = baseY + scaledV;

    % Update shaft handles
    shaftHandle.XData = [baseX, tipX];
    shaftHandle.YData = [baseY, tipY];
    
    % Arrowhead size (same scale units as u/v)
    headLength = 0.05;   % along shaft
    headWidth = 0.025;   % perpendicular to shaft
    tipX = baseX + 0; tipY = baseY + 1;

    % Direction unit vector
    ux = 0;
    uy = 1;
    
    % Perpendicular unit vector
    nx = -uy;
    ny = ux;

    % Arrowhead corners (triangle)
    leftX  = tipX + headLength * ux + headWidth * nx;
    leftY  = tipY + headLength * uy + headWidth * ny;
    rightX = tipX + headLength * ux - headWidth * nx;
    rightY = tipY + headLength * uy - headWidth * ny;

    % Update arrow handles
    arrowHandle.XData = [tipX, leftX, rightX];
    arrowHandle.YData = [tipY, leftY, rightY];

end
