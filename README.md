# Rgrains

## Definition
The roundness is one of the useful parameters for grain shapes. The definition is extremely simple as below.

$$Roundness = \left({1 \over n} \sum_{k=1}^n r_k \right)/R_{max}$$

where $R_{max}$ is the radious of maximum inscribed circle, $n$ is number of corners in the circumference and $r_i$ is the radious of $i$ th corner concaveture.

![roundness model](https://github.com/keitaroyamada/RoundnessForAI/assets/146403785/0a3172fc-6112-4394-b69b-33ba2825e3aa)

red: maximum inscribed circle

orange: corner concaveture

green: small circles that fits in the corner concaveture

## Methods

## Install
The Rgrains has three versions: CUI and GUI(exective format and matapp format).

## Usage
The Rgrains has three versions: CUI and GUI(exective format and matapp format). Rgains is encapsulated by object-oriented. Both versions depend on this encapsulated core process of "rcalculator". The usage of each version is as follows.

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
Next, load the target image to be analysed. Loading images into Rgrains is simple, just use "loadImage" method to specify the path to the image. The supported image formats are not restricted by Rgrains itself, but depend on MATLAB function of "[imread](https://jp.mathworks.com/help/matlab/ref/imread.html)". See the link for supported formats.　If necessary, use "uigetfile" to obtain the image path. The loaded image is stored in "im_in" property.

```
% get image path
[im_name, im_dir] = uigetfile();

%load image
rgrains.loadImage(fullfile(im_dir, im_name));

%show loaded image
figure
imshow(rgrains.im_in)
title('Input image')
```

#### 3. binarise
Rgains requires binarisation to measure particle shape. Binarisation depends on "[imbinarize](https://jp.mathworks.com/help/images/ref/imbinarize.html)". Binarisation is performed adaptively by imbinarize by default settings, but depending on the contrast of the image, it may not reproduce the particle edges. You should always check the binarised image for the best settings for each image. Binarisation is able to be controlled using "opts_binarise". The binarised image is stored in "im_bw" property. The supported options are as follows.
##### 'upconvert' ["true", "false" (default: "true")] (heavy option)
To reduce the effects of image jaggies, Rgrains stretch(x2) and interpolate the image by using "[imresize](https://jp.mathworks.com/help/matlab/ref/imresize.html)" This process is not always necessary.
##### 'particle_color' ["Dark", "Bright" (default: "Dark")]
Specifies the relative brightness of particles in the image to distinguish between background and particles.
##### 'method' ['Adaptive', 'Otsu' (default: "Adaptive")]
Specifies the binarisation method. See link for more information.
[imbinarize](https://jp.mathworks.com/help/images/ref/imbinarize.html)
##### 'adaptive_sensitivity', [0-1 (default: 0.35)]
Specifies the binarisation threshold. See link for more information.
[imbinarize](https://jp.mathworks.com/help/images/ref/imbinarize.html)
##### 'noise_thresholds'[0-Inf (default: [490 Inf])] ($pix^2$)
Specify the size of particles to be detected by using lower and upper area($pix^2$) limits.
##### 'ignore_particles_on_borders' ["true", "false" (default: "true")]
Specifies whether to exclude particles that are located at the boundaries of the image from which the overall shape cannot be extracted.

```
% set binarisation options
rgrains.opts_binarise = struct('upconvert', true,...
                               'particle_color', 'Dark',...
                               'method', 'Otsu',...%['Adaptive', 'Otsu']
                               'adaptive_sensitivity', 0.35,...
                               'noise_thresholds', [490 Inf],...
                               'ignore_particles_on_borders', true);

% apply binarisation
rgrains.binariseImage();

% shwo binarise results
figure
subplot(1,2,1)
    imshow(rgrains.im_in)
    title('Input image')
subplot(1,2,2)
    imshow(rgrains.im_bw)
    title('Binarised image')

```

#### 4. calculate roundness and other properties
Roundness is calculated from the binarised image. See [Definituion](#Definituion) and [Methods](#Methods) for calculation detail methods and reference. Particularly,trace_precision, corner_sensitivity and circle_precisio are critical parameters for culculating roundness of the paticles. Therefore, these parameters must be carefully determined using support tools ([RoundnessForAi](https://github.com/keitaroyamada/RoundnessForAI)).

The supported options are as follows.
##### 'trace_precision' [0-1 (default: 0.0600)] 
Parameters required to make a discrete edge composed of pixels a smooth function. See link for more information.
[smooth](https://jp.mathworks.com/help/curvefit/smooth.html#mw_7695cbca-640d-4029-a239-81c9dd8192d0)
##### 'corner_sensitivity' [0-1 (default: 0.0170)]
Sensitivity to detect convex corners from smooth contours.
##### 'circle_precision' [0-1 (default: 0.9960)]
Fitting accuracy of the small circle that fits the detected convex corner.
##### 'image_scale' [0-Inf (default: 340)] ($pix/cm$)
Rgrains returns results with dimensions such as area($cm^2$) and major axis($cm$) as well as dimensionless such as Roundness and aspect ratio. To give these results an actual length, it is necessary to give how many pixels 1 cm is.
##### 'PCD_normarisation'["true", "false" (default: "true")]
Too large a difference in particle size can affect calculation performance and results. To avoid this effect, normalise the particle image size using the particle's circumscribed circle diameter. This can be expected to improve fitting of small particles and speed up the process for large particles.
##### 'PCD_size' [0-Inf (default: 200)]($pix$)
The circumscribed circle diameter to be normalised. It is recommended to use a value of at least 200pix for the diameter of the circumscribed circle.

```
%calculate roundness 
rgrains.opts_roundness = struct('trace_precision', 0.0600,...
                                'corner_sensitivity', 0.0170,...
                                'circle_precision', 0.9960,...
                                'image_scale', 340,...
                                'PCD_normarisation', true,...
                                'PCD_size', 200);

%with showing progressbar
f = uifigure();
rgrains.calcRoundness(f);
close(f)
```

#### 5. show the calculation results


```
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
```

#### 6. export the results
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

