function seglist = segment_boundary_m(X, Y, tolerance, display)
    fst = 1;                % Indices of first and last points in edge
    lst = length(X);        % segment being considered.
    
    
    seglist = [];
    Npts = 1;
    seglist(Npts,:) = [X(fst) Y(fst)];
    
    while  fst<lst
        [m,i] = maxlinedev(X(fst:lst),Y(fst:lst));  % Find size & posn of
        % maximum deviation.
        
        while m > tolerance       % While deviation is > tol
            lst = i+fst-1;  % Shorten line to point of max deviation by adjusting lst
            [m,i] = maxlinedev(X(fst:lst),Y(fst:lst));
        end
        
        Npts = Npts+1;
        seglist(Npts,:) = [X(lst) Y(lst)];
        
        fst = lst;        % reset fst and lst for next iteration
        lst = length(X);
    end
    if display ==1
        
     plot(seglist(:,1), seglist(:,2),'bd', 'LineWidth', 1.0);
     plot(seglist(:,1), seglist(:,2),'b','linestyle','- -','linewidth',1.5);
         ax = gca;
    ax.YDir = 'reverse';
    axis off
    axis image
    end
end