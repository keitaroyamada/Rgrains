function [] = textprogress_m(n,N,varargin)
    c = 20; % Number of steps
    nstep = N / c;
    p50 = c / 2;
    
    if n<=N
        nnum_curr = round(n/nstep);

        %header
        if n<=1
             if size(varargin,1)==0
                fprintf(strcat('0|', repmat('#',1,nnum_curr)));
            elseif (size(varargin,1)==1)
                fprintf(strcat('[',varargin{1},']:0|', repmat('#',1,nnum_curr)));
            end
            
            if n~=N
                return
            end
        end

        %add #
        if n>=2
            nnum_prev = round((n-1)/nstep);
            nnum_ness = nnum_curr - nnum_prev;
            if nnum_curr>nnum_prev
                if nnum_curr>=p50 && nnum_prev<p50
                    %add # with |
                    fprintf(strcat(repmat('#',1,(nnum_ness-nnum_curr+p50)), '|', repmat('#',1,(nnum_curr-p50))));
                else
                    %add #
                    fprintf(repmat('#',1,nnum_ness));
                end
            end
        end

        %footer
        

        if n==N
            fprintf('|100 \n');
        end
        

    end
end