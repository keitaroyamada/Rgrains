function [ T] = HMS_m(t, varargin )
    %t:秒
    %T:時，分，秒
    H=fix(t/3600);
    M=fix((t-3600*H)/60);
    S=t-60*M-3600*H;

    %numel(varargin)
    if numel(varargin)==0
        T=[H,M,S];
    else
        T = strcat(num2str(H,'%02d'),':', num2str(M,'%02d'),':',num2str(round(S),'%02d'));
    end
end

