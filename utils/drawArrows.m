%% === Arrow Drawing Helper ===
function drawArrows(app, x, y, u, v, n, scale)
    for i = 1:n            
        % Calculate scaled components
        scaledU = scale * u(i);
        scaledV = scale * v(i);
        
        % Calculate base and tip positions for the shaft
        baseX = x(i); baseY = y(i);
        tipX = baseX + scaledU; tipY = baseY + scaledV;

        % Update shaft handles
        app.shaftHandles(i).XData = [baseX, tipX];
        app.shaftHandles(i).YData = [baseY, tipY];
        
        % Arrowhead size (same scale units as u/v)
        headLength = 0.05;   % along shaft
        headWidth = 0.025;   % perpendicular to shaft
        tipX = baseX + u(i); tipY = baseY + v(i);

        % Direction unit vector
        len = sqrt(u(i)^2 + v(i)^2);
        if len == 0, continue; end  % skip zero-length arrows
        ux = u(i) / len;
        uy = v(i) / len;
        
        % Perpendicular unit vector
        nx = -uy;
        ny = ux;

        % Arrowhead corners (triangle)
        leftX  = tipX + headLength * ux + headWidth * nx;
        leftY  = tipY + headLength * uy + headWidth * ny;
        rightX = tipX + headLength * ux - headWidth * nx;
        rightY = tipY + headLength * uy - headWidth * ny;

        
        % Update arrow handles
        app.arrowHandles(i).XData = [tipX, leftX, rightX];
        app.arrowHandles(i).YData = [tipY, leftY, rightY];
    end
end