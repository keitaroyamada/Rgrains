function [maxdev, index, D, totaldev] = maxlinedev_m(x,y)

    Npts = length(x);
    
    if Npts == 1
	warning('Contour of length 1');
	maxdev = 0; index = 1;
	D = 1; totaldev = 0;
	return;
    elseif Npts == 0
	error('Contour of length 0');
    end

    %    D = norm([x(1) y(1)] - [x(Npts) y(Npts)]);  % Distance between end points
    D = sqrt((x(1)-x(Npts))^2 + (y(1)-y(Npts))^2); % This runs much faster

    if D > eps    
	
	% Eqn of line joining end pts (x1 y1) and (x2 y2) can be parameterised by
	%    
	%    x*(y1-y2) + y*(x2-x1) + y2*x1 - y1*x2 = 0
	%
	% (See Jain, Rangachar and Schunck, "Machine Vision", McGraw-Hill
	% 1996. pp 194-196)
	
	y1my2 = y(1)-y(Npts);                       % Pre-compute parameters
	x2mx1 = x(Npts)-x(1);
	C = y(Npts)*x(1) - y(1)*x(Npts);
	
	% Calculate distance from line segment for each contour point
	d = abs(x*y1my2 + y*x2mx1 + C)/D;          
	
    else    % End points are coincident, calculate distances from 1st point
    
        d = sqrt((x - x(1)).^2 + (y - y(1)).^2);
	D = 1;  % Now set D to 1 so that normalised error can be used
	
    end						

    [maxdev, index] = max(d);

    if nargout == 4
	totaldev = sum(d.^2);
    end






