# Rgrains

Rgrains is an image analysis software equipped with a series of functions for extracting contours from images, measuring shapes, and outputting results as images or tables. Rgrains can calculate the area, circularity, major and minor axis lengths of particles. Furthermore, this software, drawing upon [Zheng & Hryciw (2015)](https://www.icevirtuallibrary.com/doi/abs/10.1680/geot.14.P.192)'s innovative techniques, can also calculate "Roundness" according to Wadell's definition.

Rgrains equips researchers with a nuanced understanding of particle dynamics, facilitating a deeper exploration of particle behaviour. We sincerely hope that this application, Rgrains, will significantly expand the horizons of scientific inquiry, opening new avenues for research and fostering a deeper, more comprehensive understanding in the field.

<img src=https://github.com/keitaroyamada/Rgrains/assets/146403785/1b86cd8b-ebb0-4097-a318-6111d179a578 width="500" >


---
## Install
The Rgrains has three versions: CUI and GUI(exective format and matapp format).
### CUI version
1. Download all files in this repository
2. After unzipped, add downloaded repository to the matlab path. 

### GUI version (matlab app)
1. Download installer file from releases.
2. Install from "Apps" tab in the Matlab.

### GUI version (executable file)
1. Download the executable file from Releases.
2. Follow the wizard to install.

---
## Requirements (test emvironments)
### CUI version and GUI version (matlab app)
- Matlab > 9.13 
- Image processing toolbox > 11.6
- Curve Fitting Toolbox > 3.8
- ~~Statistics and Machine Learning Toolbox > 12.4~~ (Rgrains>5.0.3)
- ~~Computer Vision Toolbox > 10.3~~ (Rgrains>5.0.3)

### GUI version (executable file) 
- Windows 10, 11 (Intel)
- Matlab Runtime (Rgrains includes this online installer)

---
## Usage
The Rgrains has three versions: CUI and GUI(exective format and matapp format). 
Instructions on how to use each version is available in the Rgrains Usage (**[English](https://github.com/keitaroyamada/Rgrains/wiki)** / [日本語](https://github.com/keitaroyamada/Rgrains/wiki/Rgrains%E3%81%AE%E4%BD%BF%E3%81%84%E6%96%B9)).

---
## References
- [Wadell (1932) Volume, Shape, and Roundness of Rock Particles](https://www.journals.uchicago.edu/doi/10.1086/623964)
- [Krumbein (1941) Measurement and geological significance of shape and roundness of sedimentary particles](https://pubs.geoscienceworld.org/sepm/jsedres/article-abstract/11/2/64/94958/Measurement-and-geological-significance-of-shape)
- [Zheng & Hryciw (2015) Traditional soil particle sphericity, roundness and surface roughness by computational geometry](https://www.icevirtuallibrary.com/doi/abs/10.1680/geot.14.P.192)
  - [source code](https://jp.mathworks.com/matlabcentral/fileexchange/60651-particle-roundness-and-sphericity-computation)
- [Ishimura & Yamada (2019) Palaeo-tsunami inundation distances deduced from roundness of gravel particles in tsunami deposits](https://www.nature.com/articles/s41598-019-46584-z)
---
