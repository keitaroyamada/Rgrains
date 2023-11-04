function obj = nonparametric_fitting_m(obj, span)
    
    for k = 1:obj.NumObjects
    phi = obj.objects(k).polar(:, 1);
    ro =  obj.objects(k).polar(:, 2);
    ctd = obj.objects(k).centroid;
    
    ro_mean = smooth(phi,ro,span,'loess');
    [X, Y] = mypolar2carte(ro_mean, phi, ctd, 2);
    
    X(end) = X(1);
    Y(end) = Y(1);
    obj.objects(k).cartesian = [X, Y];
    end

end