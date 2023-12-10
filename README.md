# Rgrains

## Definition
The roundness is one of the useful parameters for grain shapes. The definition is extremely simple as below.

$$Roundness = \left({1 \over n} \sum_{k=1}^n r_k \right)/R_{max}$$

where $R_{max}$ is the radious of maximum inscribed circle, $n$ is number of corners in the circumference and $r_i$ is the radious of $i$ th corner concaveture.

![roundness model](https://github.com/keitaroyamada/RoundnessForAI/assets/146403785/0a3172fc-6112-4394-b69b-33ba2825e3aa)

red: maximum inscribed circle

orange: corner concaveture

green: small circles that fits in the corner concaveture

## Install

## Usage
The Rgrains has two versions: CUI and GUI. Rgains is encapsulated by object-oriented. Both versions depend on this encapsulated core process of "rcalculator". The usage of each version is as follows.

### CUI version
Rgains is encapsulated by object-oriented. The simple usage is shown in the example code in the link below. Below is an explanation of this example.

[simple_example.m](https://github.com/keitaroyamada/Rgrains/blob/5f6a46785e832ffa46798b60db9925339448d1b3/Simple_example.m)

#### 1. make Rgrains instance
First, it must be create Rgrains instance, because Rgrains is encapsulated.Creating an instance of MATLAB is simple as follows

```
%make instance
rgrains = rcalculator();
```

#### 2. load target image
%load image
rgrains.loadImage('image full path')
figure
imshow(rgrains.im_in)
title('Input image')

#### 3. binarise
R binarizes the image. Binarization depends on GG. Binarization is performed adaptively by GG by default, but depending on the contrast of the image, it may not reproduce the exact particle contours. You should always check the binarized image for the best settings for each image. Binarization is controlled using opts_binarise.


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

rgrains.export('save directory path')
### GUI version

