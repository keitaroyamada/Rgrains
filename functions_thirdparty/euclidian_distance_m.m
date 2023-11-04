function distance = euclidian_distance_m(x1, x2)
    %x1 and x2 are N*2 matrix
    if size(x1, 2) ~= 2
        x1 = x1';
    end
    if size(x2, 2) ~= 2
        x2 = x2';
    end
    distance = sqrt(sum((x1 - x2).^2, 2));
end