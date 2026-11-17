function [z, r] = compute_corner_circles_m(sz, pixel_list, convex, boundary_points, R, factor, minPoints, varargin)
    
    fit_method = 'geometric';
    for k = 1:2:length(varargin)
        name  = varargin{k};
        value = varargin{k+1};
    
        switch lower(name)
            case 'fit_method'
                fit_method = value;
            otherwise
                error('Unknown option: %s', name)
        end
    end

    % step 1: start from the first point to chech whether all those convex
    % points can be fitted to a circle
    [z1, r1, range] = fit_small_circles_m(sz, pixel_list, convex, boundary_points, R, factor, minPoints, 'fit_method', fit_method);
    % step 2: the first and the last point is alway cumbersome, they may be fitted to a
    % circle if they are not used. If they are used, thus check whether
    % those two circles can be combined.
    if isempty(z1)
        z = [];
        r = [];
        return;
    else
        z2=[]; z3 = [];
        r2=[]; r3=[];
        if (range(1)-1) >= 1&& (range(end)+1) <= size(convex, 1)&&...
                (range(end) + size(convex, 1) - range(1) -2 >=minPoints)
            cv = [convex(range(end)+1:end, :);convex(1:range(1)-1, :)];
            [z2, r2] = fit_small_circles_m(sz, pixel_list,  cv, boundary_points, R, factor, minPoints, 'fit_method', fit_method);
        elseif range(1) <=2 && range(end) >= size(convex, 1)-1
            cv = [convex(range(end,1):end, :);convex(1:range(1, 2), :)];
            [z3, r3] = fit_small_circles_m(sz, pixel_list,  cv, boundary_points, R, factor, minPoints, 'fit_method', fit_method);
            z1(:, 1) = []; z1(:, end) = [];
            r1(1) = []; r1(end) = [];
        end
        z = [z1, z2, z3]';
        r  =[r1, r2, r3]';
    end

end