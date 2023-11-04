function [z, r, range] = fit_small_circles_m(sz, pixel_list, convex, boundary_points, R, factor, minPoints)
    warning('off','all')
    z = [];
    r = [];
    
    cv = convex;
    range = [];
    fp = 1;                % Indices of first and last points in edge
    lp =length(cv);
    
    while lp >= fp+minPoints
        [zc, rc] = fitcircle(cv(fp:lp, :)');
        
        min_dis = min(euclidian_distance_m(boundary_points, ones(size(boundary_points, 1),1)*zc'));
        if lp > fp+minPoints&&(min_dis < factor*rc||rc >= R||...
                zc(2) < 1 || zc(2) > sz(1) ||...
                zc(1) <1 || zc(1) > sz(2) ||...  
                ~any(pixel_list ==  sub2ind(sz, round(zc(2)), round(zc(1)))))
            lp = lp-1;
            continue
        elseif lp == fp+minPoints&&(min_dis < factor*rc||rc >= R||...
                zc(2) < 1 || zc(2) > sz(1) ||...
                zc(1) <1 || zc(1) > sz(2) ||...  
                ~any(pixel_list ==  sub2ind(sz, round(zc(2)), round(zc(1)))))
            fp = fp +1;
            lp =length(cv);
            continue
            
        end
        z = [z, zc];
        r = [r, rc];
        
        range = [range; fp, lp];
        
        
        fp = lp+1;
        lp = length(cv);
    end
    warning('on');
end