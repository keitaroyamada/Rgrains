function [ ROI_im ] = imROI_m(im, ROI, padding)
%ROI: [x0,y0, w, h]
    
    %measure image size
    S=size(im);
    
    %check [left]
    if ROI(1)<1
        if padding==1
            %padding
            s=size(im);
            x1=1-ROI(1);
            im=[zeros(s(1),(x1),s(3)),im];
            
            ROI(1)=1;
        else
            %cut off
            ROI(3) = ROI(3) + ROI(1);
            ROI(1) = 1;
        end
    end
        
    %check [top]
    if ROI(2)<1
        if padding==1
            %padding
            s=size(im);
            y1=1-ROI(2);
            im=[zeros(y1,s(2),s(3));im];
            
            ROI(2)=1;
        else
            %cut off
            ROI(4) = ROI(4) + ROI(2);
            ROI(2) = 1;
        end
    end
    
    %check [right]
    if ROI(1)+ROI(3)>S(2)
        if padding==1
            %padding
            s=size(im);
            x2=ROI(1)+ROI(3)-S(2);
            im=[im,zeros(s(1),x2,s(3))];
        else
            %cut off
            ROI(3) = S(2) - ROI(1);
        end
    end
    
    %check [bottom]
    if ROI(2)+ROI(4)>S(1)
        if padding==1
            s=size(im);
            y2=ROI(2)+ROI(4)-S(2);
            im=[im;zeros(y2,s(2),s(3))];
        else
            ROI(4) = S(1) - ROI(2);
        end
    end
    
    %crop image
    ROI_im = im(ROI(2):ROI(2)+ROI(4)-1, ROI(1):ROI(1)+ROI(3)-1,:);

end

