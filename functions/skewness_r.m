function sk = skewness_r(data, varargin)
    flag = 1;
    if isempty(varargin)==0
        flag = varargin{1};
    end

    n = length(data);
    m = mean(data);

    %main
    if flag==1
        sk =  (sum((data - m).^3)/n) / ((sqrt(sum((data - m).^2)/n)).^3);
    elseif flag==0
        sk = (sqrt(n * (n-1)) / (n-2)) * (sum((data - m).^3)/n) / ((sqrt(sum((data - m).^2)/n)).^3);
    else
        sk=[];
        return;
    end
end