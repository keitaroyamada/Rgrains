%!git push --force-with-lease 
classdef rgrains < handle
    %RCALCULATOR provides calculation of roundness from a image
    
    properties (SetAccess = public, GetAccess = public)
        opts_binarise;
        opts_roundness;
        opts_plot;
        opts_export;
        opts_rgrains;

        im_dir;
        im_name;
        im_ext;
        im_in;
        im_bw;
        im_bw_overlay;

        rprops;
    end
    
    methods (Access=public)
        function obj = rgrains()
            %initiarise;
            obj.opts_rgrains   = struct('version','v5.1.1 (2024 Nov 30)');%this version is used for update check. DONOT change the format.
            obj.opts_binarise  = struct('upconvert',false,...
                                        'particle_color', 'Dark',...
                                        'method','Adaptive',...
                                        'adaptive_sensitivity',0.35,...
                                        'noise_thresholds',[490, Inf],...
                                        'ignore_particles_on_borders',true);
            obj.opts_roundness = struct('calc_roundness',true,...%calc roundness or not
                                        'trace_precision',0.060,...%span
                                        'corner_sensitivity',0.017,...%tol
                                        'circle_precision',0.996,...%factor
                                        'image_scale',340,...%real scale of image[pix/cm]
                                        'PCD_normalisation',true,...%size normalising by PCD
                                        'PCD_size',300,...%target size of PCD
                                        'Circularity_type','legacy');%type of circularity ['new', 'legacy']
            obj.opts_plot      = struct('base_image','original',... %['original', 'bw']
                                        'colour_smoothed_particle_boundaries','magenta',...
                                        'thickness_smoothed_particle_boundaries',1.5,...
                                        'colour_max_inscribed_circle','red',...
                                        'thickness_max_inscribed_circle',1.5,...
                                        'colour_corner_circles','cyan',...
                                        'thickness_corner_circles',0.5,...
                                        'colour_info_text','yellow',...
                                        'font_size_info_text',15,...
                                        'font','Arial',...
                                        'plot_info','Particlenumber'); %['Particlenumber', 'Roundness']
            obj.opts_export    = struct('save_bw_image',true,...
                                        'save_fitted_image_with_No',true,...
                                        'save_fitted_image_vector',false,...
                                        'save_fitted_image_with_Roundness',true,...
                                        'save_summary_image',true,...
                                        'save_csv',true,...
                                        'save_annotation',false,...
                                        'annotation_target','Roundness',...%[supports params stored in rprops]
                                        'save_settings',false);%save settings for each image 
        end
        
        function [] = loadSettings(obj, load_path)
            %setting file is saved 'mat' format as '*.rgrains'
            [~,~,ex] = fileparts(load_path);
            if ex ~='.rgrains'
                disp('File extension is not suported.');
                return
            end

            load(load_path,"-mat");

            if exist('opts_binarise','var')
                obj.opts_binarise = opts_binarise;
            else
                disp('There is no binarise settings.');
            end
            if exist('opts_export','var')
                obj.opts_export   = opts_export;
            else
                disp('There is no export settings.');
            end
            if exist('opts_plot','var')
                obj.opts_plot     = opts_plot;
            else
                disp('There is no plot settings.');
            end
            if exist('opts_roundness','var')
                obj.opts_roundness= opts_roundness;
            else
                disp('There is no roundness settings.');
            end
            disp('Setting file loaded.');
        end

        function [] = loadLegacySettings(obj, load_path)
            %Legacy setting file is saved 'csv'
            [~,~,ex] = fileparts(load_path);
            if ex ~=".csv"
                disp('File extension is not suported.');
                return
            end
            data = readtable(load_path);
            
            switch data.Upconvert{1}
                case 'off'
                    obj.opts_binarise.upconvert = false;
                case 'on'
                    obj.opts_binarise.upconvert = true;
            end
            
            obj.opts_binarise.method = data.BW_method{1};
            obj.opts_binarise.adaptive_sensitivity = data.BW_threshold;
            obj.opts_binarise.noise_thresholds = [data.Noise_threshold,data.Noise_threshold_2];

            obj.opts_roundness.trace_precision = data.Alpha_Loess;
            obj.opts_roundness.corner_sensitivity = data.Delta_corner;
            obj.opts_roundness.circle_precision = data.T_R;
            obj.opts_roundness.image_scale = data.Imagescale;

            switch data.Size_normalization{1}
                case 'off'
                    obj.opts_roundness.PCD_normalisation = false;
                case 'on'
                    obj.opts_roundness.PCD_normalisation = true;
            end
            disp('Legacy setting file loaded.');
        end

        function [] = saveSettings(obj, save_path)
            %setting file is saved 'mat' format as '*.rgrains'
            [~,~,ex] = fileparts(save_path);
            if ex ~='.rgrains'
                disp('File extension is not suported.');
                return
            end

            opts_binarise  = obj.opts_binarise;
            opts_export    = obj.opts_export;
            opts_plot      = obj.opts_plot;
            opts_roundness = obj.opts_roundness;
            opts_rgrains   = obj.opts_rgrains;
            SaveDate       = datetime("today");
            save(save_path, 'opts_binarise','opts_plot','opts_export','opts_roundness','opts_rgrains', 'SaveDate');
            disp('Rraings setting file is saved.');
        end
        
        function [] = loadImage(obj, im_path)
            fprintf('Loading image...');
            [obj.im_dir, obj.im_name, obj.im_ext] = fileparts(im_path);

            %upconverting
            if obj.opts_binarise.upconvert==true
                obj.im_in = imresize(imread(im_path),2);
            else
                obj.im_in = imread(im_path);
            end
            fprintf('Done.\n');
        end
        
        function [] = binariseImage(obj)
            fprintf('Binarising image...');
    
            %check background color
            switch obj.opts_binarise.particle_color
                case 'Dark'
                    im_in = imcomplement(obj.im_in);%complement image colour
                case 'Bright'
                    im_in = obj.im_in;
            end

            %rgb to grey 
            %check image type
            if size(size(im_in),2)==3
                %case rgb image
                im_grey = rgb2gray(im_in);%rgb2gray(im2double(im_in));
            elseif size(size(im_in),2)==2
                %case bw or gray image
                im_grey = im_in;
            else
                %otherwise
                disp('\n Input data is potentially non image data.');
                obj.im_bw = [];
                return;
            end

            %binarise
            switch obj.opts_binarise.method
                case 'Adaptive'
                    %apply adaptive binarisation using matlab function
                    %adaptive method
                    im_bw = logical(imbinarize(im_grey, 'adaptive',...
                                               'ForegroundPolarity', 'bright',...
                                               'Sensitivity',obj.opts_binarise.adaptive_sensitivity));
                case 'Otsu'
                    %colour image to gray image
                    %global(Otsu) method
                    im_bw = logical(imbinarize(im_grey, 'global'));
                case 'Absolute'
                    th = obj.opts_binarise.adaptive_sensitivity;
                    im_bw = im2double(im_grey);
                    im_bw(im_bw >= th)  = 1;
                    im_bw(im_bw < th) = 0;
                    im_bw = logical(im_bw);
                case 'Edge'
                    se = strel("disk",5);
                    im_grey_close = imclose(im_grey, se);
                    im_edge = edge(im_grey,"canny",[0.03, obj.opts_binarise.adaptive_sensitivity]);
                    im_edge = imclose(im_edge, se);
                    im_edge = imfill(im_edge,'holes');
                    se = strel("disk",10);
                    im_edge = imopen(im_edge,se);
                    se = strel("disk",5);
                    im_edge = imclose(im_edge,se);
                    
                    im_bw = imbinarize(im_grey, "global");
                    im_bw = im_bw + im_edge;
                    im_bw(im_bw>=1)=1;
                    im_bw = logical(im_bw);

                case 'None'
                    %without binarization
                    if islogical(im_grey)==1
                        im_bw = im_grey;
                    else
                        im_bw = logical(imbinarize(im_in,'global'));
                    end
            end

            %remove small dots   
            im_bw = bwareafilt(im_bw, obj.opts_binarise.noise_thresholds, 4);
            
            if obj.opts_binarise.ignore_particles_on_borders == true
                im_bw = imclearborder(im_bw, 4); %remove edge-touched particles
            end

            im_bw = imfill(im_bw, 'holes'); %fill holes
            
            if obj.opts_binarise.upconvert==true
                im_bw = bwareaopen(im_bw, obj.opts_binarise.noise_thresholds(1) *4); %remove small dots
            else
                im_bw = bwareaopen(im_bw, obj.opts_binarise.noise_thresholds(1)); %remove small dots
            end

            obj.im_bw = im_bw;
            fprintf('Done.\n');
        end

        function [] = calcRoundness(obj, ax)
            disp('Calculating...');
            %numbering conected pixcels
            world_cc = bwconncomp(obj.im_bw, 4);
            world_particle_props = discrete_boundary_m(world_cc);
            
            %mod image scale
            if obj.opts_binarise.upconvert ==true
                image_scale = obj.opts_roundness.image_scale * 2;
            else
                image_scale = obj.opts_roundness.image_scale;
            end

            %initiarise
            rprops = [];%initiarise
            rprop  = struct('SourceImage',[],       'ROI', [],         'ResolutionScale', [],...
                            'Particlenumber',[],    'Originaledges',[],'Edges',[],...
                            'Centroid',[],          'Area',[],         'Orientation',[],...
                            'Roundness',[],         'R',[],            'Smallcircles',[],...
                            'Majorlength',[],       'Minorlength',[],  'Aspect',[],...
                            'Circularity',[],       'PCD',[],          'delta0',[],...
                            'Lval',[],              'aval', [],        'bval',[]);
            rprops = repmat(rprop, world_cc.NumObjects, 1);

            if isempty(ax)==false
                d = uiprogressdlg(ax, 'Title','Calculating...','Message','Start computing','Cancelable','on');
                tic;
            end

            %main process
            for i = 1:world_cc.NumObjects
                %add image name
                rprops(i).SourceImage = strcat(obj.im_name, obj.im_ext);

                %add particle number
                rprops(i).Particlenumber = i;

                %extract each particle image
                im_mask = zeros(size(obj.im_bw));
                im_mask(world_cc.PixelIdxList{1,i})=1;
                im_masked = logical(obj.im_bw .* im_mask);%masked image
                im_mask_nan = im_mask;
                im_mask_nan(im_mask_nan==0)=NaN;

                roi       = world_particle_props.objects(i).bbox;
                roi       = [round(roi(1)-2), round(roi(2)-2), round(roi(3)+4), round(roi(4)+4)];%expanding
                im_trimed = imROI_m(im_masked, roi, 0);%trimed image
                rprops(i).ROI = roi;

                %get colours
                im_trimed_lab = rgb2lab(imROI_m(obj.im_in,roi,0));
                im_trimed_rgb = cat(3, im_trimed_lab(:,:,1) .* imROI_m(im_mask_nan, roi, 0), im_trimed_lab(:,:,2) .* imROI_m(im_mask_nan, roi, 0), im_trimed_lab(:,:,3) .* imROI_m(im_mask_nan, roi, 0));
                lab = mean(mean(im_trimed_rgb,"omitnan"),"omitnan");
                rprops(i).Lval = lab(1);
                rprops(i).aval = lab(2);
                rprops(i).bval = lab(3);

                %scaling image resolution 
                if obj.opts_roundness.PCD_normalisation == true
                    %calc original PCD
                    world_xy  = world_particle_props.objects(i).rawXY;
                    world_x   = world_xy(:, 1);
                    world_y   = world_xy(:, 2);
                    [~,rcum]  = min_circum_circle_m(world_x,world_y);
                    world_PCD = 2 * rcum;
                    resolution_scale = obj.opts_roundness.PCD_size ./ world_PCD; %normalise using PCD
                else
                    resolution_scale = 1;
                end
            
                rprops(i).ResolutionScale = resolution_scale;
                final_scale = image_scale * resolution_scale;
                im_trimed   = imresize(im_trimed, resolution_scale);%resolution-rescaled image

                %measuring morphology & numbering of each particle
                im_size = size(im_trimed);%image size
                dist_map = bwdist(~im_trimed);%distance convert
                cc = bwconncomp(im_trimed, 8);%detect particle conection

                %estimate particle edges
                particle_props = discrete_boundary_m(cc);%boundary line segmentation 
                fitted_particle_props = nonparametric_fitting_m(particle_props, obj.opts_roundness.trace_precision);%estimate smooth edges
                rprops(i).Originaledges = particle_props.objects(1).rawXY;%original segmentations
                rprops(i).Orientation = particle_props.objects(1).orientation;%particle Orientation
                
                %make boundary data
                ob = cc.PixelIdxList{1};%pixcel list of each aparticle
                [R, RInd] = max(dist_map(ob)); %Radius and center pixcel location of maximum inscribed circle 
                [cy, cx] = ind2sub(im_size, ob(RInd));%centre of particle
                rprops(i).Centroid = [cy, cx];
                rprops(i).R = R;

                boundary_points = fitted_particle_props.objects(1).cartesian;%smoothed particle edge
                rprops(i).Edges = boundary_points;

                X = boundary_points(:, 1);
                Y = boundary_points(:, 2);

                %estimate other parameters
                stats = boundary_regionprops(boundary_points, {'Area','Centroid','Perimeter','MajorAxisLength','MinorAxisLength','EquivDiameter','Circularity'});
                if isempty(stats)==1
                    disp(strcat('Empty detected. Particle No',num2str(i),'is skipped'))
                    rprops(i).Majorlength = nan;
                    rprops(i).Minorlength = nan;
                    rprops(i).Aspect      = nan;
                    rprops(i).Area        = nan;
                    rprops(i).Circularity = nan;
                    rprops(i).Smallcircles= nan;
                    rprops(i).Roundness   = nan;
                    rprops(i).PCD         = nan;
                    rprops(i).delta0      = nan;
                
                    %export results
                    obj.rprops = rprops;
                    continue
                end

                perimeter = stats(1).Perimeter;
                equivdiameter = stats(1).EquivDiameter;
                %area=stats(1).Area;
                rprops(i).Majorlength = stats(1).MajorAxisLength / final_scale;%[pix->cm]
                rprops(i).Minorlength = stats(1).MinorAxisLength / final_scale;%[pix->cm]
                rprops(i).Aspect      = stats(1).MinorAxisLength / stats(1).MajorAxisLength;%[]
                rprops(i).Area        = stats(1).Area / (final_scale^2);%[cm^2]
                switch obj.opts_roundness.Circularity_type 
                    case 'legacy'
                        rprops(i).Circularity = round(4*pi*(( pi*((equivdiameter/2)-0.5)^2)/((perimeter)^2)),5);%Circularity
                    case 'new'
                        rprops(i).Circularity = stats(1).Circularity;%[]
                end

                if obj.opts_roundness.calc_roundness ==false
                    %skip calculation of roundness
                    continue
                end
                %segmentted boundary
                seglist = segment_boundary_m(X, Y, obj.opts_roundness.corner_sensitivity, 0);

                %detection of concave and convex
                [concave, convex] = concave_convex_m(seglist, [cx, cy], 0);

                %estimate Circumscribed small circles
                minpoints = 3;%def:3

                %Probably an error will occur if it is a perfect circle
                try
                    [z, r] = compute_corner_circles_m(im_size, ob, convex, boundary_points, R, obj.opts_roundness.circle_precision, minpoints);%r:radius of small circles,z:centre of circles
                catch ME
                    %z = 
                    %r = R;
                    continue
                end

                rprops(i).Smallcircles = [z, r];

                %calculate roundness
                Roundness = mean(r) / R;
                rprops(i).Roundness = Roundness;

                %estimate PCD(minimum circum circle for valuation)
                [~,rcum] = min_circum_circle_m(X,Y);
                rprops(i).PCD = 2*rcum;
                pcd = (2*rcum(2*rcum~=0));
                delta0_th = (obj.opts_roundness.corner_sensitivity ./ pcd)*100;
                rprops(i).delta0 = delta0_th;

                %progress bar
                if isempty(ax)==false
                    d.Value = (i / world_cc.NumObjects);
                    RT = HMS_m((world_cc.NumObjects-i) * (toc/i));
                    d.Title = strcat('Calculating (remaining time:',num2str(RT(1)),'h',num2str(RT(2)),'m',num2str(round(RT(3))),'s)');
                    d.Message = strcat('[',num2str(i),'/',num2str(world_cc.NumObjects),']: Calculating...',num2str(round(i / world_cc.NumObjects*100,1)),'%');
                    if d.CancelRequested
                        selection = uiconfirm(ax,'Cancel process?','Confirm Cancel','Icon','warning');
                        switch selection
                            case'OK'
                                return
                            case 'cancel'
                        end
                    end
                end
                textprogress_m( i, world_cc.NumObjects, obj.im_name)
            end

            obj.rprops = rprops;
            disp('Calculating...Done.')
        end

        function [] = makeResultImage(obj, ax)
            %base image
            switch obj.opts_plot.base_image
                case 'original'
                    imshow(obj.im_in, 'Parent',ax)
                case 'bw'
                    imshow(obj.im_bw, 'Parent',ax)
            end
            hold(ax, 'on')

            %add results
            for i=1:length(obj.rprops)
                if ~isempty(obj.rprops(i).Roundness)
                    if ~isnan(obj.rprops(i).R)
                        %reconstruction of resolution
                        rs = (1/obj.rprops(i).ResolutionScale);
            
                        %smooth particle edges
                        X = obj.rprops(i).ROI(1) + obj.rprops(i).Edges(:,1) .* rs;
                        Y = obj.rprops(i).ROI(2) + obj.rprops(i).Edges(:,2) .* rs;
                        plot(ax, X, Y, 'Color', obj.opts_plot.colour_smoothed_particle_boundaries,'LineWidth', obj.opts_plot.thickness_smoothed_particle_boundaries);
                        hold(ax,'on')
                        
                        %Maximum inscribed circle
                        R = obj.rprops(i).R .* rs;
                        theta = [linspace(0,2*pi, 100)];
                        cx = obj.rprops(i).ROI(1) + obj.rprops(i).Centroid(:,2) .* rs; 
                        cy = obj.rprops(i).ROI(2) + obj.rprops(i).Centroid(:,1) .* rs;
                        plot(ax, cos(theta)*R+cx, sin(theta)*R+cy, 'Color', obj.opts_plot.colour_max_inscribed_circle,'LineWidth', obj.opts_plot.thickness_max_inscribed_circle);
                        hold(ax,'on')
                        
                        %small inscribed circles
                        if isnan(obj.rprops(i).Smallcircles)==0
                            zx = obj.rprops(i).ROI(1) + obj.rprops(i).Smallcircles(:,1) .* rs;%cetre of circels
                            zy = obj.rprops(i).ROI(2) + obj.rprops(i).Smallcircles(:,2) .* rs;%cetre of circels
                            r  = obj.rprops(i).Smallcircles(:,3) .* rs;%radius of circles
                            for ss = 1:size(r,1)
                                plot(ax, zx(ss), zy(ss),...   % plot the center of circles
                                    zx(ss)  + r(ss)  * cos(theta), zy(ss)  + r(ss) * sin(theta),...
                                    'Color',obj.opts_plot.colour_corner_circles,'LineWidth', obj.opts_plot.thickness_corner_circles);
                                hold(ax,'on')
                            end
                        end
                    end
                end

                %show information
                cx = obj.rprops(i).ROI(1) + obj.rprops(i).Centroid(:,2) .* (1/obj.rprops(i).ResolutionScale); 
                cy = obj.rprops(i).ROI(2) + obj.rprops(i).Centroid(:,1) .* (1/obj.rprops(i).ResolutionScale);
                text(ax, cx, cy, num2str(round(obj.rprops(i).(obj.opts_plot.plot_info),2)), 'Color', obj.opts_plot.colour_info_text,'FontSize',obj.opts_plot.font_size_info_text);
            end
            fontname(ax, obj.opts_plot.font);
        end

        function [result_table] = makeResultTable(obj)
            if height(obj.rprops)==1
                result_table = struct2table(obj.rprops,AsArray=true);
            else
                result_table = struct2table(obj.rprops);
            end

            result_table = result_table(:,{'Particlenumber','Roundness','Circularity','Majorlength','Minorlength','Aspect','Area','Orientation', 'Lval','aval','bval','PCD','delta0'});
            result_table.Properties.VariableNames = {'No','Roundness','Circularity','MajorLength_cm','MinorLength_cm','Aspect','Area_cm2','Orientation', 'L*','a*','b*','PCD','delta0'};
        end
    
        function [] = makeSummaryImage(obj, ax)
            subplot(ax);
            fontname(ax, "Arial");
            if height(obj.rprops)==1
                temp = struct2table(obj.rprops,AsArray=true);
            else
                temp = struct2table(obj.rprops);
            end

            subplot(2,3,1)
                obj.histogramWithStats(temp.Roundness, [0:0.05:1], 'Roundness', 'Roundness',strcat('Probability(N=',num2str(size(temp.Roundness,1)),')'))
                xlim([-0.05 1.05])
            subplot(2,3,2)
                obj.histogramWithStats(temp.Circularity, [0:0.05:1], 'Circularity', 'Circularity',strcat('Probability(N=',num2str(size(temp.Circularity,1)),')'))
                xlim([-0.05 1.05])
            subplot(2,3,3)
                obj.histogramWithStats(temp.Aspect, [0:0.05:1], 'Aspect ratio', 'Aspect ratio',strcat('Probability(N=',num2str(size(temp.Aspect,1)),')'))
                xlim([-0.05 1.05])
            subplot(2,2,3)
                obj.histogramWithStats(-log2(temp.Majorlength*10), [-6:0.25:4], 'Major Axis Length(\phi)', 'Major Axis Length(\phi)',strcat('Probability(N=',num2str(size(temp.Majorlength,1)),')'))
                xlim([-6 4])
            subplot(2,2,4)
                obj.histogramWithStats(-log2(temp.Minorlength*10), [-6:0.25:4], 'Minor Axis Length(\phi)', 'Minor Axis Length(\phi)',strcat('Probability(N=',num2str(size(temp.Minorlength,1)),')'))
                xlim([-6 4])
        end
    
        function [] = export(obj, save_dir, varargin)
            if exist(save_dir)~=7
                disp("There is no such a directory.")
                return
            end

            if length(varargin)==1
                ax = varargin{1};
                if isempty(ax)==false
                    d = uiprogressdlg(ax, 'Title','Exporting results...','Message','Exporting...','Cancelable','off','Indeterminate','on');
                end
            end
            
            warning('off')
            mkdir(save_dir);
            warning('on')

            if obj.opts_export.save_bw_image
                if length(varargin)==1
                    if isempty(ax)==false
                        d.Message = "Saving binarised image...";
                    end
                end

                imwrite(obj.im_bw,fullfile(save_dir, strcat(obj.im_name,'_BW.jpg')))
                disp('BW image is saved.');
            end

            if obj.opts_export.save_summary_image
                if length(varargin)==1
                    if isempty(ax)==false
                        d.Message = "Saving summary image...";
                    end
                end

                SS = get(0, 'ScreenSize');
                f = figure('visible','off','Position',[SS(1) SS(2) SS(3) SS(4)]);
                ax = gca;
                obj.makeSummaryImage(ax);
                exportgraphics(f, fullfile(save_dir,strcat(obj.im_name,'_summary.png')),'Resolution',300);
                close(f)
                disp('Summary figure is saved.');
            end
            
            if obj.opts_export.save_fitted_image_with_No
                if length(varargin)==1
                    if isempty(ax)==false
                        d.Message = "Saving fitted image with No...";
                    end
                end

                obj.opts_plot.base_image = 'original';%['original', 'bw']
                obj.opts_plot.plot_info  = 'Particlenumber';%['Particlenumber', 'Roundness']

                SS = get(0, 'ScreenSize');
                f = figure('visible','off','Position',[SS(1) SS(2) SS(3) SS(4)]);
                ax = gca;
                obj.makeResultImage(ax);
                exportgraphics(f, fullfile(save_dir,strcat(obj.im_name,'_fitted_No.jpg')));
                close(f)
                disp('Number image is saved.');
            end

            if obj.opts_export.save_fitted_image_vector
                if length(varargin)==1
                    if isempty(ax)==false
                        d.Message = "Saving fitted vector image...";
                    end
                end

                obj.opts_plot.base_image = 'original';%['original', 'bw']
                obj.opts_plot.plot_info  = 'Particlenumber';%['Particlenumber', 'Roundness']

                SS = get(0, 'ScreenSize');
                f = figure('visible','off','Position',[SS(1) SS(2) SS(3) SS(4)]);
                ax = gca;
                obj.makeResultImage(ax);
                warning('off')
                exportgraphics(f, fullfile(save_dir,strcat(obj.im_name,'_fitted_vector.eps')),'ContentType','vector');
                warning('on')
                close(f)
                disp('Vector image is saved.');
            end

            if obj.opts_export.save_fitted_image_with_Roundness
                if length(varargin)==1
                    if isempty(ax)==false
                        d.Message = "Saving fitted image with roundness...";
                    end
                end

                obj.opts_plot.base_image = 'original';%['original', 'bw']
                obj.opts_plot.plot_info  = 'Roundness';%['Particlenumber', 'Roundness']

                SS = get(0, 'ScreenSize');
                f = figure('visible','off','Position',[SS(1) SS(2) SS(3) SS(4)]);
                ax = gca;
                obj.makeResultImage(ax);
                exportgraphics(f, fullfile(save_dir,strcat(obj.im_name,'_fitted_R.jpg')));
                close(f)
                disp('Roundness image is saved.');
            end

            if obj.opts_export.save_csv
                if length(varargin)==1
                    if isempty(ax)==false
                        d.Message = "Saving results table...";
                    end
                end

                T = obj.makeResultTable();
                writetable(T, fullfile(save_dir,strcat(obj.im_name,'_results.csv')));
                disp('Results csv is saved.');
            end

            if obj.opts_export.save_settings
                if length(varargin)==1
                    if isempty(ax)==false
                        d.Message = "Saving settings...";
                    end
                end

                obj.saveSettings(fullfile(save_dir,strcat(obj.im_name,'_settings.rgrains')));
            end

            if obj.opts_export.save_annotation
                if length(varargin)==1
                    if isempty(ax)==false
                        d.Message = "Saving annotation xml...";
                    end
                end

                docNode = make_annotation_m(obj);
                
                %save as xml
                xmlwrite(fullfile(save_dir,strcat(obj.im_name,'.xml')), docNode);
                disp('Annotation xml is saved.');
            end


            disp('Exporting...Done.');
            
            if length(varargin)==1
                if isempty(ax)==false
                    close(d);
                end
            end
        end
    end
    
    methods (Access=private)

        function [] = histogramWithStats(obj, raw_data, X_bins, tname, xname, yname)
            if isnumeric(raw_data)==false
                %case of no roundness
                return
            end
            %base data
            [sorted_data, sorted_idx] = sort(raw_data);%min->max
            h = histogram(sorted_data, X_bins,'Normalization','probability');
            Y_hist = h.BinCounts;
            colororder([0.10 0.40 0.99; 0.357 0.435 0.22]);

            %plot base data
            %yyaxis('right'); 
            %        ylabel('Cumlative [%]', 'interpreter','none');
            %        ylim([0 100]);
            %yyaxis('left'); 
            bar(X_bins(2:end), Y_hist, 'FaceColor',[0.5843    0.8157    0.9882], 'EdgeColor', 'none', 'FaceAlpha',0.7); %main data
                ylabel(yname, 'interpreter','none');
                xlabel(xname, 'interpreter','tex');
                grid('on');
                xlim([0, 1]);
            title(tname);

            %plot STD
            p  = [0, 15.85, 50, 84.15, 100]';%1 sigma points
            Yp = prctile(sorted_data,p);
            %Yp = sorted_data(cumpercentile(sorted_data, p/100));
            ty = (max(Y_hist) * 0.05) * ones(5,1);

            %yyaxis('left');
                hold('on')
            plot(Yp([1,5]), ty([1,5]),'-k','linewidth',1.5);%Full range
                hold('on')
            plot(Yp([2,4]), ty([2,4]),'-r','linewidth',1.5);%1 sigma range
                hold('on')
            scatter(Yp([2:4]), ty([2:4]),'+','k','linewidth',0.5);%point
                hold('on')
             
            xdf = 0.030*(abs(X_bins(end)-X_bins(1)));
            ydf = 0.025*(max(Y_hist));
            text(Yp(2)-xdf, ty(2)-ydf, num2str(round(Yp(2),2)));%lower std
                hold('on')
            text(Yp(4)-xdf, ty(4)-ydf, num2str(round(Yp(4),2)));%upper std
                hold('on')
            text(Yp(3)-xdf, ty(3)+ydf, num2str(round(Yp(3),2)));%median

            %plot statistics info
            Y_median   = median(sorted_data);
            Y_mean     = mean(sorted_data);
            Y_skewness = skewness_r(sorted_data);
            Y_kurtosis = kurtosis_r(sorted_data);
            [~,Midx]   = max(Y_hist);
            Y_mode     = X_bins(Midx);
            Y_95error  = 1.96*sqrt((std(sorted_data)^2)/numel(sorted_data));%95.5 2, 99.7 3, 95 1.96, 99 2.58
            Y_99error  = 2.58*sqrt((std(sorted_data)^2)/numel(sorted_data));
            
            tx = X_bins(1) + abs(X_bins(1))*0.05;
            tx = repmat(tx,10,1);
            ty = (max(Y_hist) - [1:10]*(max(Y_hist)*0.05))';
            
            %yyaxis('left');
            hold('on')
                text(tx(1),ty(1),strcat('SE(95%):    [±',num2str(Y_95error ),']'));
            %hold('on')
                %text(tx(2),ty(2),strcat('SE(99%) =±',num2str(Y_99error )));    
            hold('on')
                text(tx(2),ty(2),strcat('Mean:       [',num2str(Y_mean),']'));
            hold('on')
                text(tx(3),ty(3),strcat('Median:     [',num2str(Y_median),']'));
            hold('on')
                text(tx(4),ty(4),strcat('Mode:       [',num2str(Y_mode),']'));
            hold('on')
                text(tx(5),ty(5),strcat('Skewness: [',num2str(Y_skewness),']'));
            hold('on')
                text(tx(6),ty(6),strcat('Kurtosis:   [',num2str(Y_kurtosis),']'));
            hold('off')
        end
    end
end

