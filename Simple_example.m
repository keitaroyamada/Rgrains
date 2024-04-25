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
rg.opts_binarise = struct('upconvert', true,...
                     'particle_color', 'Dark',...
                             'method', 'Otsu',...%['Adaptive', 'Otsu', 'Absolute', 'Edge', 'None']
               'adaptive_sensitivity', 0.35,...
                   'noise_thresholds', [490 Inf],...
        'ignore_particles_on_borders', true);
rg.binariseImage();

figure
imshow(imfuse(rg.im_in, rg.im_bw))

%calculate roundness 
rg.opts_roundness = struct('calc_roundness',true, ...
                          'trace_precision', 0.0600,...
                       'corner_sensitivity', 0.0170,...
                         'circle_precision', 0.9960,...
                              'image_scale', 340,...
                        'PCD_normarisation', true,...
                                 'PCD_size', 200);
f = uifigure();
rg.calcRoundness(f);%with showing progressbar
close(f)

%show results
rg.opts_plot = struct(                      'base_image', 'original',... %['original', 'bw']
                   'colour_smoothed_particle_boundaries', 'magenta',...
                'thickness_smoothed_particle_boundaries', 1.5,...
                           'colour_max_inscribed_circle', 'red',...
                        'thickness_max_inscribed_circle', 1.5,...
                                 'colour_corner_circles', 'cyan',...
                              'thickness_corner_circles', 0.5,...
                                      'colour_info_text', 'yellow',...
                                   'font_size_info_text', 15,...
                                                  'font', 'Arial',...
                                             'plot_info', 'Particlenumber');

figure
rg.makeResultImage(gca)

%make results table
results = rg.makeResultTable();

%make summary
SS = get(0, 'ScreenSize');
figure('visible','on','Position',[SS(1) SS(2) SS(3) SS(4)]);
rg.makeSummaryImage(gca)

%export results
rg.opts_export = struct('save_bw_image', true,...
            'save_fitted_image_with_No', true,...
     'save_fitted_image_with_Roundness', true,...
             'save_fitted_image_vector', true,...
                   'save_summary_image', true,...
                             'save_csv', true,...
                      'save_annotation', true,...
                    'annotation_target', 'Roundness',...
                        'save_settings', true);

[save_dir] =uigetdir()
rg.export(save_dir)
