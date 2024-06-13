function [ro, phi] = carte2polar_m(X, Y, center, start)

deltaXY = bsxfun(@minus, [X, Y], center);
deltaX = deltaXY(:, 1);
deltaY = deltaXY(:, 2);
ro = sqrt(deltaX.^2 + deltaY.^2 );

n = length(deltaX);
phi = zeros(n, 1);

if start == 1  % start from the first quadrant
    for i = 1:n
        
        if deltaX(i)>0&&deltaY(i)<0
            phi(i) = atan(abs(deltaY(i)/deltaX(i)));
            
        elseif deltaX(i)==0&&deltaY(i)<0
            phi(i) = pi/2;
            
        elseif deltaX(i)<0&&deltaY(i)<0
            phi(i) = pi - atan(abs(deltaY(i)/deltaX(i)));
            
        elseif deltaX(i)<0&&deltaY(i)==0
            phi(i) = pi;
            
        elseif deltaX(i)<0&&deltaY(i)>0
            phi(i) = atan(abs(deltaY(i)/deltaX(i))) + pi;
            
        elseif deltaX(i)==0&&deltaY(i)>0
            phi(i) = 3*pi/2;
            
        elseif deltaX(i)>0&&deltaY(i)>0
            phi(i) = 2*pi - atan(abs(deltaY(i)/deltaX(i)));
            
        elseif deltaX(i)>0&&deltaY(i)==0
            phi(i) = 0;
        end
        
        
    end
end
if start == 2 % start from the second quadrant
    for i = 1:n
        
        if deltaX(i)<0&&deltaY(i)>0
            phi(i) = atan(abs(deltaY(i)/deltaX(i)));
            
        elseif deltaX(i)==0&&deltaY(i)>0
            phi(i) = pi/2;
            
        elseif deltaX(i)>0&&deltaY(i)>0
            phi(i) = pi - atan(abs(deltaY(i)/deltaX(i)));
            
        elseif deltaX(i)>0&&deltaY(i)==0
            phi(i) = pi;
            
        elseif deltaX(i)>0&&deltaY(i)<0
            phi(i) = atan(abs(deltaY(i)/deltaX(i))) + pi;
            
        elseif deltaX(i)==0&&deltaY(i)<0
            phi(i) = 3*pi/2;
            
        elseif deltaX(i)<0&&deltaY(i)<0
            phi(i) = 2*pi - atan(abs(deltaY(i)/deltaX(i)));
            
        elseif deltaX(i)<0&&deltaY(i)==0
            phi(i) = 0;
        end
        
        
    end
end
if phi(end) == 0;
    phi(end) = 2*pi;
end

