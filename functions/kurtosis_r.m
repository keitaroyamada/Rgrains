function kr = kurtosis_r(data, varargin)
    flag = 1;
    if isempty(varargin)==0
        flag = varargin{1};
    end

    n = length(data);
    m = mean(data);

    %main
    if flag==1
        kr =  (sum((data - m).^4)/n) / ((sum((data - m).^2)/n).^2);

    elseif flag==0
        kr = ((n-1)/((n-2)*(n-3))) * ((n+1) * ((sum((data - m).^4)/n) / ((sum((data - m).^2)/n).^2)) -3 * (n-1))+3;
    else
        kr=[];
        return;
    end
end