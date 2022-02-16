# SWS_NVS_code

Welcome to the GitHub repository for 
**Expectations boost the reconstruction of auditory features from electrophysiological responses to noisy speech**, a combined EEG-pupillometry study of degraded speech processing.

This repository contains the scripts and functions required to reproduce the analyses reported in the  associated [manuscript](https://www.biorxiv.org/content/10.1101/2021.09.06.459160v2).
You can access the data files on which these scripts operate from the accompanying [OSF repository](https://osf.io/5qxds/).

## Directions
In order to reproduce the analyses reported in the manuscript, first download/clone this repository into a suitable directory and navigate to the `def_local.m` script.
You will need to modify this script in order to define local paths to the data and stimulus materials (which you will need to download from the [OSF repository](https://osf.io/5qxds/)), as well as the requisite *MATLAB* toolboxes.
You will need [FieldTrip](https://www.fieldtriptoolbox.org/) installed in order to reproduce the EEG-based analyses; the [mTRF toolbox](https://github.com/mickcrosse/mTRF-Toolbox) is required for the  [stimulus reconstruction](#stimulus-reconstruction) analysis only (scripts will warn you if these toolboxes cannot be located).
Optional toolboxes for figure plotting include [EEGLAB](https://sccn.ucsd.edu/eeglab/index.php) and [export_fig](https://au.mathworks.com/matlabcentral/fileexchange/23629-export_fig/).

### EEG preprocessing
To reproduce the EEG analysis pipeline from scratch (i.e. from raw data), first navigate to the `EEGpreproc` subdirectory to perform preprocessing.
The entire preprocessing pipeline can be conveniently run from the high-level script `wsws_run_preproc.m`, which will invoke each subcomponent of the pipeline in sequence (refer to this script to ensure correct ordering of operations if running scripts individually).
Note that running this script will mean that bad channels, epochs, and independent components will be rejected according to the information stored in the corresponding `wsws_bad*.csv` and `wsws_badComps_t*.mat` files.

You may manually review the raw data for bad channels and epochs by setting `manualRej = 1`. 
Note that this will modify the `wsws_bad*.csv` files that are invoked when the pipeline is run in the default (automated rejection) mode.
You may also manually review the ICA decompositions produced by `wsws_ICA.m` by invoking the `wsws_ICA_plot.m` function, specifying the appropriate subject number and file type ('train' or 'test').
ICs that are marked for rejection can be altered by updating the contents of `wsws_badComps_t*.mat` prior to running `wsws_ICA_reject_t*.m`. 

### Spectral power
The time-frequency and event-related (de)synchronisation analyses can be run from the scripts contained within the `EEGtimefrq` subdirectory.
For both kinds of analysis, first extract frequency-domain estimates using `wsws_extract_EEG_*.m`, before conducting cluster-based permutation analysis using `wsws_cluster_EEG_*.m`.
(Note that these scripts can be run on the preprocessed files provided in the [OSF repository](https://osf.io/5qxds/), thereby obviating the need to run the preprocessing pipeline first.)

Grand-average time-frequency compositions can be computed and plotted with `wsws_average_EEG_TF.m`.
`wsws_prep_EEG_LMM.m` collates trial-level spectral power estimates for [statistical modelling](#statistical-modelling). 

### Stimulus reconstruction
The stimulus reconstruction analysis can be performed independently of the spectral analysis.
This pipeline can be run from the high-level script `wsws_run_stimrec.m`.

### Pupil diameter
The pupillometry data are preprocessed and analysed by running `wsws_pupil_ERP.m`.
Note that this analysis is independent of the EEG pipeline and can therefore be performed at any time.

### Statistical modelling
The outputs tables generated from the spectral power (`wsws_timefrq.csv`) and stimulus reconstruction (`wsws_stimrec.csv`) analyses have been provided in the `stats` subdirectory so that statistical modelling can be performed in *R* without needing to run any component of the *MATLAB* pipeline.
Note that rerunning analysis pipelines will overwrite these files, potentially altering model results if new parameters have been specified.

`wsws_timefrq.R` models subjective clarity ratings and mean spectral power estimates for each analysed frequency band.
It also visualises the predictions of the frequency band models.
`wsws_stimrec.R` models the stimulus reconstruction data and reruns the clarity rating analysis with  reconstruction score included as a predictor in the model.

Note that each script performs nested model comparisons; hence, to reduce processing time, you might want to consider fitting only the winning model from each analysis.
Please ensure you have the appropriate packages installed on your system prior to running these *R* scripts (packages are listed at the beginning of each script; see [System Information](#system-information) for further details that might be useful for ensuring reproducibility).

The `stats` subdirectory also contains a *MATLAB* script for collating and summarising basic demographic information (`wsws_demogs.m`) stored in `SWS_NVS_results_*.mat` files.

## Citation
If the materials archived here are useful for your own research, please cite this repository including the appropriate [release version](#current-release) information (year and doi; see below for details):

> Corcoran, A.W., Perera, R., Koroma, M., Kouider, S., Hohwy, J., & Andrillon, T. {*year*}. SWS_NVS_code {*version*} [Software]. Retrieved from https://github.com/corcorana/SWS_NVS_code. {*doi*}

Please also cite the accompanying manuscript:

> Corcoran, A.W., Perera, R., Koroma, M., Kouider, S., Hohwy, J., & Andrillon, T. (2022). Expectations boost the reconstruction of auditory features from electrophysiological responses to noisy speech. *Cerebral Cortex*, bhac094. doi: 10.1093/cercor/bhac094


## Current release
`v0.1.0` [![DOI](https://zenodo.org/badge/400722791.svg)](https://zenodo.org/badge/latestdoi/400722791)

## License
This software is freely available for redistribution and/or modification under the terms of the GNU General Public Licence.
It is distributed WITHOUT WARRANTY; without even the implied warranty of merchantability or fitness for a particular purpose. 
See the [GNU General Public License](https://github.com/corcorana/SWS_NVS_code/blob/main/LICENSE) for more details.


## System information
The preprocessing and analysis pipeline archived here was built and tested on a 64-bit system running Microsoft Windows 10 Enterprise Version 10.0 (Build 18363).
*MATLAB* and *R* software version details, and attached toolboxes/packages, etc., are listed below.


**MATLAB version 9.7.0.1319299 (R2019b) Update 5**

**Java Version**: Java 1.8.0_202-b08 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode

|MATLAB                                               | Version 9.7       |  (R2019b)|
|-----------------------------------------------------|-------------------|----------|
|Simulink                                             | Version 10.0      |  (R2019b)|
|Curve Fitting Toolbox                                | Version 3.5.10    |  (R2019b)|
|DSP System Toolbox                                   | Version 9.9       |  (R2019b)|
|Image Processing Toolbox                             | Version 11.0      |  (R2019b)|
|MATLAB Compiler                                      | Version 7.1       |  (R2019b)|
|MATLAB Compiler SDK                                  | Version 6.7       |  (R2019b)|
|Parallel Computing Toolbox                           | Version 7.1       |  (R2019b)|
|Signal Processing Toolbox                            | Version 8.3       |  (R2019b)|
|Statistics and Machine Learning Toolbox              | Version 11.6      |  (R2019b)|
|Symbolic Math Toolbox                                | Version 8.4       |  (R2019b)|
|Wavelet Toolbox                                      | Version 5.3       |  (R2019b)|



**R version 4.1.1 (2021-08-10)**

**Platform:** x86_64-w64-mingw32/x64 (64-bit)

**attached base packages:**
stats     graphics  grDevices utils     datasets  methods   base     

**other attached packages:**

RVAideMemoire_0.9-81 ordinal_2019.12-10   performance_0.8.0    emmeans_1.7.1-1      car_3.0-12          
carData_3.0-4        lme4_1.1-27.1        Matrix_1.3-4         forcats_0.5.1        stringr_1.4.0       
dplyr_1.0.7          purrr_0.3.4          readr_2.1.0          tidyr_1.1.4          tibble_3.1.6        
ggplot2_3.3.5        tidyverse_1.3.1      here_1.0.1          

**loaded via a namespace (and not attached):**

Rcpp_1.0.7          lubridate_1.8.0     mvtnorm_1.1-3       lattice_0.20-44     assertthat_0.2.1   
rprojroot_2.0.2     utf8_1.2.2          R6_2.5.1            cellranger_1.1.0    backports_1.4.0    
reprex_2.0.1        httr_1.4.2          pillar_1.6.4        rlang_0.4.12        readxl_1.3.1       
rstudioapi_0.13     minqa_1.2.4         nloptr_1.2.2.3      splines_4.1.1       munsell_0.5.0      
broom_0.7.10        numDeriv_2016.8-1.1 compiler_4.1.1      modelr_0.1.8        pkgconfig_2.0.3    
insight_0.14.5      tidyselect_1.1.1    fansi_0.5.0         ucminf_1.1-4        crayon_1.4.2       
tzdb_0.2.0          dbplyr_2.1.1        withr_2.4.3         MASS_7.3-54         grid_4.1.1         
nlme_3.1-152        jsonlite_1.7.2      xtable_1.8-4        gtable_0.3.0        lifecycle_1.0.1    
DBI_1.1.1           magrittr_2.0.1      scales_1.1.1        estimability_1.3    cli_3.1.0          
stringi_1.7.6       fs_1.5.0            xml2_1.3.2          ellipsis_0.3.2      generics_0.1.1     
vctrs_0.3.8         boot_1.3-28         tools_4.1.1         glue_1.5.0          hms_1.1.1          
abind_1.4-5         colorspace_2.0-2    rvest_1.0.2         haven_2.4.3    
