function [ stats ] = boundary_regionprops( B, parameters )
%B:line data(X,Y)
%parameters: calculate parameters
X=B(:, 1);
Y=B(:, 2);

%make bw image from boundary
m=poly2mask(1+(Y-min(Y)),1+(X-min(X)),1+round((max(X)-min(X))),1+round((max(Y)-min(Y))));

%calc params from parameters
stats = regionprops(m,parameters);

end

