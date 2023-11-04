function [concave, convex] = concave_convex_m(seglist, center, display)

concave = [];
convex = [];
indicator = zeros(size(seglist, 1), 1);
seglist2 = [seglist(end-1, :); seglist];
cx = center(1);
cy = center(2);
for i = 1:size(seglist2, 1)-2
    %          plot(seglist2(i:i+2,1), seglist2(i:i+2,2),'c*','LineWidth', 3);
    x1 = seglist2(i, 1); y1 =  seglist2(i, 2);
    x2 = seglist2(i+1, 1); y2 =  seglist2(i+1, 2);
    x3 = seglist2(i+2, 1); y3 =  seglist2(i+2, 2);
    
    % calculate the intersection between two lines
    % the line equation y = [x 1]*[a b]'
    % the intersection between two lines are
    % intersection = [1 ,-ab1(1); 1, -ab2(1)] \ [ab1(2); ab2(2)];
    ab1 = [(y3 - y1)/(x3 - x1), (x3*y1 - x1*y3)/(x3 - x1)];
    ab2 = [(y2 - cy)/(x2 - cx), (x2*cy - cx*y2)/(x2 - cx)];
    inset = [1 ,-ab1(1); 1, -ab2(1)] \ [ab1(2); ab2(2)];  %the order is (y x);
%              plot(inset(2), inset(1),'c*','LineWidth', 3); %plot order is (x y)
    
    %
    d2Ct = euclidian_distance([x2, y2], [cx, cy]);% distance from point 2 to center
    dInter2Ct = euclidian_distance([inset(2), inset(1)], [cx, cy]); %distance from intersection to center
    %          d2Ct = sqrt((x2 - cx)^2 + (y2 - cy)^2); % distance from point 2 to center
    %          dInterCt = sqrt((inset(2) - cx)^2 + (inset(1) - cy)^2); %distance from intersection to center
    
    
    
    if d2Ct <= dInter2Ct
        concave = [concave; seglist2(i+1, :)];
        %              plot(concave(:,1), concave(:,2),'yx','LineWidth', 2);
    else
        convex = [convex; seglist2(i+1, :)];
        indicator(i) = 1;
        %              plot(convex(:,1), convex(:,2),'bd', 'LineWidth', 3);
    end
    
end
if display
    plot(convex(:,1), convex(:,2),'bo', 'LineWidth', 2);
%     if ~isempty(concave)
%         plot(concave(:,1), concave(:,2),'kx','LineWidth', 2);
%     end
end
end