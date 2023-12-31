clear;

%make instance
rgrains = rcalculator();

%load image
[im_name, im_dir] = uigetfile();
rgrains.loadImage(fullfile(im_dir, im_name))
figure
imshow(rgrains.im_in)
title('Input image')

%binarise image
rgrains.opts_binarise = struct('upconvert', true,...
                               'particle_color', 'Dark',...
                               'method', 'Otsu',...%['Adaptive', 'Otsu']
                               'adaptive_sensitivity', 0.35,...
                               'noise_thresholds', [490 Inf],...
                               'ignore_particles_on_borders', true);
rgrains.binariseImage();
figure
subplot(1,2,1)
    imshow(rgrains.im_in)
    title('Input image')
subplot(1,2,2)
    imshow(rgrains.im_bw)
    title('Binarised image')

%calculate roundness 
rgrains.opts_roundness = struct('trace_precision', 0.0600,...
                                'corner_sensitivity', 0.0170,...
                                'circle_precision', 0.9960,...
                                'image_scale', 340,...
                                'PCD_normarisation', true,...
                                'PCD_size', 200);
f = uifigure();
rgrains.calcRoundness(f);%with showing progressbar
close(f)

%show results
rgrains.opts_plot = struct ('base_image','original',...
                            'colour_smoothed_particle_boundaries','green',...
                            'colour_max_inscribed_circle', 'red',...
                            'colour_corner_circles', 'cyan',...
                            'colour_info_text', 'magenta',...
                            'font', 'Arial',...
                            'plot_info', 'Particlenumber');

figure
rgrains.makeResultImage(gca)

%make results table
results = rgrains.makeResultTable();

%make summary
SS = get(0, 'ScreenSize');
figure('visible','on','Position',[SS(1) SS(2) SS(3) SS(4)]);
rgrains.makeSummaryImage(gca)

%export results
rgrains.opts_export = struct('save_bw_image',true,...
                         'save_fitted_image_with_No',true,...
                         'save_fitted_image_with_Roundness',true,...
                         'save_fitted_image_vector',true,...
                         'save_summary_image',true,...
                         'save_csv',true,...
                         'save_settings',true);

[save_dir] =uigetdir()
rgrains.export(save_dir)
