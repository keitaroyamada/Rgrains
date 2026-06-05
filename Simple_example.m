clear;

%make instance
rg = rgrains();

%load image
[im_name, im_dir] = uigetfile('*.jpg');
rg.loadImage(fullfile(im_dir, im_name))

figure
imshow(rg.im_in)
title('Input image')

%binarise image
rg.opts_binarise.upconvert            = true;
rg.opts_binarise.particle_color       = 'Dark'; %['Dark', 'Bright']
rg.opts_binarise.method               = 'Otsu'; %['Adaptive', 'Otsu', 'Absolute', 'Edge', 'None']
rg.opts_binarise.adaptive_sensitivity = 0.35; % [0-1]
rg.opts_binarise.noise_thresholds     = [490 Inf]; % [0-Inf]
rg.opts_binarise.ignore_particles_on_borders = true; % [true, false]

rg.binariseImage();

figure
imshow(imfuse(rg.im_in, rg.im_bw))

%calculate roundness 
rg.opts_roundness.calc_roundness            = true; % [true, false]
rg.opts_roundness.trace_precision           = 0.0600;
rg.opts_roundness.corner_sensitivity        = 0.0170;
rg.opts_roundness.circle_precision          = 0.9960; %[0-1]
rg.opts_roundness.image_scale               = 340; % pix/cm
rg.opts_roundness.PCD_normalisation         = true; %[true, false]
rg.opts_roundness.PCD_size                  = 200; % PCD normalisation size[pix]
rg.opts_roundness.filter_inaccurate_outline = true; %[true, false]
rg.opts_roundness.circularity_type          = 'legacy'; % ['legacy', 'new']

f = uifigure();
rg.calcRoundness(f);%with showing progressbar
close(f)

%show results
rg.opts_plot.base_image                             = 'original'; %['original', 'bw']
rg.opts_plot.colour_smoothed_particle_boundaries    = 'magenta';
rg.opts_plot.thickness_smoothed_particle_boundaries = 1.5; 
rg.opts_plot.colour_max_inscribed_circle            = 'red';
rg.opts_plot.thickness_max_inscribed_circle         = 1.5;
rg.opts_plot.colour_corner_circles                  = 'cyan';
rg.opts_plot.thickness_corner_circles               = 0.5;
rg.opts_plot.colour_info_text                       = 'yellow';
rg.opts_plot.font_size_info_text                    = 15;
rg.opts_plot.font                                   = 'Arial';
rg.opts_plot.plot_info                              = 'Particlenumber';

figure
rg.makeResultImage(gca)

%make results table
results = rg.makeResultTable();

%make summary
SS = get(0, 'ScreenSize');
figure('visible','on','Position',[SS(1) SS(2) SS(3) SS(4)]);
rg.makeSummaryImage(gca)

%export results
rg.opts_export.save_bw_image     = true;
rg.opts_export.save_fitted_image_with_No        = true;
rg.opts_export.save_fitted_image_with_Roundness = true;
rg.opts_export.save_fitted_image_vector         = true;
rg.opts_export.save_summary_image               = true;
rg.opts_export.save_csv                         = true;
rg.opts_export.save_each_circles_csv            = true;
rg.opts_export.save_annotation                  = true;
rg.opts_export.save_edge_annotation             = true;
rg.opts_export.annotation_target                = 'Roundness';
rg.opts_export.save_settings                    = true;

[save_dir] =uigetdir()
rg.export(save_dir)
