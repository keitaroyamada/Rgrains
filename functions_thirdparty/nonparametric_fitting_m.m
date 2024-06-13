function obj = nonparametric_fitting_m(obj, span)
    
    for k = 1:obj.NumObjects
        phi = obj.objects(k).polar(:, 1);
        ro =  obj.objects(k).polar(:, 2);
        ctd = obj.objects(k).centroid;
        
        ro_mean = smooth(phi,ro,span,'loess');%curve fitting toolbox
        %ro_mean = smooth_loess(phi,ro,span); %This method differs from 'smooth' in how it handles endpoints.
    
        [X, Y] = polar2carte_m(ro_mean, phi, ctd, 2);
        
        X(end) = X(1);
        Y(end) = Y(1);
        obj.objects(k).cartesian = [X, Y];
    end

end