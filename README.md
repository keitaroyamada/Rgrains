# Rgrains

Rgrains is image analysis software equipped with a series of functions for extracting contours from images, measuring particle shapes, and exporting results as images or tables. Rgrains can calculate particle area, circularity, major and minor axis lengths, and other shape parameters. Furthermore, based on the innovative techniques of [Zheng & Hryciw (2015)](https://www.icevirtuallibrary.com/doi/abs/10.1680/geot.14.P.192), Rgrains can also calculate “roundness” according to Wadell’s definition. Rgrains provides researchers with a detailed understanding of particle dynamics and supports deeper exploration of particle behaviour. We hope that Rgrains will broaden the scope of scientific inquiry, open new avenues for research, and contribute to a deeper and more comprehensive understanding of particle shape analysis.  

Rgrainsは、画像から輪郭を抽出し、粒子形状を計測し、結果を画像または表として出力するための各種機能を備えた画像解析ソフトウェアです。粒子の面積、円形度、長軸長、短軸長などの形状パラメータを計算できます。さらに、[Zheng & Hryciw (2015)](https://www.icevirtuallibrary.com/doi/abs/10.1680/geot.14.P.192) の革新的な手法に基づき、Wadellの定義に従った「円磨度（roundness）」も計算できます。本アプリは、粒子動態を詳細に理解するための情報を研究者に提供し、粒子挙動のより深い探究を支援します。本アプリケーションが科学的探究の幅を広げ、新たな研究の可能性を開き、粒子形状解析に関するより深く包括的な理解に貢献することを期待しています。

<img src="https://github.com/keitaroyamada/Rgrains/assets/146403785/1b86cd8b-ebb0-4097-a318-6111d179a578" width="500">

---

## Install / インストール

Rgrains is available in three versions: a CUI add-on, a MATLAB app, and a standalone GUI application ([Downloads](https://github.com/keitaroyamada/Rgrains/releases)).  
Note that the GUI version implements only a subset of the available options. For more advanced operations, please use the CLI version.  

Rgrainsには、CUIアドオン、MATLABアプリ、スタンドアロンGUIアプリケーションの3つのバージョンがあります（[Downloads](https://github.com/keitaroyamada/Rgrains/releases)）。
GUI版には一部のオプションのみが実装されています。より高度な操作には、CLI版をご活用ください。

### MATLAB app and CUI version / MATLABアプリ・CUI版

1. Download the toolbox installer file from [Releases](https://github.com/keitaroyamada/Rgrains/releases).  
   [Releases](https://github.com/keitaroyamada/Rgrains/releases) からツールボックスインストーラーファイルをダウンロードします。
2. Install it from the “Apps” tab in MATLAB.  
   MATLABの「Apps」タブからインストールします。

### GUI version (executable file) / GUI版（実行ファイル）

1. Download the executable file from [Releases](https://github.com/keitaroyamada/Rgrains/releases).  
   [Releases](https://github.com/keitaroyamada/Rgrains/releases) から実行ファイルをダウンロードします。

#### For Windows / Windowsの場合

2. Run the executable file and follow the setup wizard.  
   実行ファイルを起動し、セットアップウィザードに従ってインストールします。

#### For Mac / Macの場合

2. Download and install MATLAB Runtime from [here](https://jp.mathworks.com/products/compiler/matlab-runtime.html).  
   [こちら](https://jp.mathworks.com/products/compiler/matlab-runtime.html) からMATLAB Runtimeをダウンロードし、インストールします。
3. Run the executable file.  
   実行ファイルを起動します。

---

## Requirements / 必要環境

### CUI version and GUI version (MATLAB app) / CUI版・GUI版（MATLABアプリ）

- MATLAB > R2025a
- Image Processing Toolbox
- Curve Fitting Toolbox
- ~~Statistics and Machine Learning Toolbox > 12.4~~ (Rgrains > 5.0.3)
- ~~Computer Vision Toolbox > 10.3~~ (Rgrains > 5.0.3)

### GUI version (executable file) / GUI版（実行ファイル）

- Windows 10 or 11 (Intel)
- Mac (Apple Silicon)
- MATLAB Runtime (Rgrains includes the online installer)

---

## Usage / 使い方

Rgrains is available in three versions: CUI, standalone GUI, and MATLAB app.  
Rgrainsには、CUI版、スタンドアロンGUI版、MATLABアプリ版の3つのバージョンがあります。

Instructions for each version are available in the Rgrains Usage wiki: [English](https://github.com/keitaroyamada/Rgrains/wiki).  
各バージョンの使用方法は、Rgrains Usage wiki:（[日本語](https://github.com/keitaroyamada/Rgrains/wiki/Rgrains%E3%81%AE%E4%BD%BF%E3%81%84%E6%96%B9)）を参照してください。

---

## References / 参考文献

- [Wadell (1932) Volume, Shape, and Roundness of Rock Particles](https://www.journals.uchicago.edu/doi/10.1086/623964)
- [Krumbein (1941) Measurement and geological significance of shape and roundness of sedimentary particles](https://pubs.geoscienceworld.org/sepm/jsedres/article-abstract/11/2/64/94958/Measurement-and-geological-significance-of-shape)
- [Zheng & Hryciw (2015) Traditional soil particle sphericity, roundness and surface roughness by computational geometry](https://www.icevirtuallibrary.com/doi/abs/10.1680/geot.14.P.192)
  - [Source code](https://jp.mathworks.com/matlabcentral/fileexchange/60651-particle-roundness-and-sphericity-computation)
- [Ishimura & Yamada (2019) Palaeo-tsunami inundation distances deduced from roundness of gravel particles in tsunami deposits](https://www.nature.com/articles/s41598-019-46584-z)

---

## Publications using this application / 本アプリケーションを使用した研究
- [Taya et al. (2026): Suitable Grain Size for Distinguishing Mainstem and Tributary Gravelly Deposits in Riverbeds and Terraces Using Roundness Image Analysis](https://doi.org/10.1111/iar.70051)
- [Kaida et al. (2026): Source estimation of the 1703 Genroku tsunami through geological surveys and numerical simulations on Hachijo Island](https://doi.org/10.1186/s40645-026-00798-8)
- [Takahashi et al. (2025): Shape evolution of bulk sediment in headwater streams: effects of rock type and particle size](https://doi.org/10.5194/esurf-13-959-2025)
- [Ishimura & Hiramine (2025): Dispersion, fragmentation, abrasion, and organism attachment of drift pumice from the 2021 Fukutoku-Oka-no-Ba eruption in Japan](https://doi.org/10.1186/s40645-024-00678-z)
- [石村・平峯（2024）: 十和田中掫テフラの漂着軽石と降下軽石の円磨度の違い─漂着軽石を特徴付ける指標の検討─](https://doi.org/10.4116/jaqua.63.2310)
- [Ishimura & Yamada (2021): Integrated lateral correlation of tsunami deposits during the last 6000 years using multiple indicators at Koyadori, Sanriku Coast, northeast Japan](https://doi.org/10.1016/j.quascirev.2021.106834)
- [Ishimura & Yamada (2019): Palaeo-tsunami inundation distances deduced from roundness of gravel particles in tsunami deposits](https://doi.org/10.1038/s41598-019-46584-z)

---
