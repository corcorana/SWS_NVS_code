# SWS_NVS_code


Welcome to the GitHub repository for a combined EEG-pupillometry study of degraded speech processing, entitled: 
**Expectations boost the reconstruction of auditory features from electrophysiological responses to noisy speech**.

This repository contains the code required to reproduce analyses reported in the manuscript associated with this study.
You can access the datafiles on which these scripts operate from the [OSF platform](https://osf.io/5qxds/).


## Directions
In order to reproduce the analyses reported in the manuscript, first download/clone this repository into a suitable directory and navigate to the `def_local.m` script.
You will need to modify this script in order to define local paths to the data and stimulus materials (which you will need to download from the [OSF repository](https://osf.io/5qxds/)), as well as the requisite MATLAB toolboxes.
You will need the FieldTrip toolbox installed in order to reproduce the EEG-based analyses; the mTRF toolbox is required for the stimulus reconstruction analysis only (scripts will warn you if these toolboxes cannot be located).
Optional toolboxes for figure plotting include EEGlab and export_fig.

### EEG preprocessing
To reproduce the EEG analysis pipeline from scratch (i.e. raw data only), first navigate to the `EEGpreproc` subdirectory to perform preprocessing.
The entire pipeline can be conveniently run from a single high-level script `wsws_run_preproc.m`, which will invoke each subcomponent of the pipeline in sequence (refer to this script to ensure correct ordering of operations if running individual scripts manually).
Note that running this script will mean that bad channels, epochs, and independent components will be rejected according to the information stored in the corresponding `wsws_bad*.csv` and `wsws_badComps_t*.mat` files.

You may manually review the raw data for bad channels and epochs by setting `manualRej = 1`. 
Note that this will lead to the modification of the `wsws_bad*.csv` files that are invoked when the pipeline is run in automated mode.
You may also manually review the ICA decompositions produced by `wsws_ICA.m` by invoking the `wsws_ICA_plot.m` function, specifying the appropriate subject number and file type.
IC rejection can then be altered by updating the contents of `wsws_badComps_t*.mat` prior to running `wsws_ICA_reject_t*.m`. 

### Spectral power analyses
The time-frequency and event-related (de)synchronisation analyses can be run from the scripts contained within the `EEGtimefrq` subdirectory.
For both kinds of analysis, first extract frequency-domain estimates using `wsws_extract_EEG_*.m`, before conducting cluster-based permutation analysis using `wsws_cluster_EEG_*.m`.
Grand-average time-frequency compositions can also be computed and plotted with `wsws_average_EEG_TF.m`.
`wsws_prep_EEG_LMM.m` collates trial-level spectral power estimates for statistical analysis. 

### Stimulus reconstruction analysis
Stimulus reconstruction can be run independently of the spectral analysis.
This analysis can be run from scratch by invoking the `wsws_run_stimrec.m` script.

### Pupil diameter
The pupillometry data are preprocessed and analysed in a single script, `wsws_pupil_ERP.m`.
Note that this analysis is completely independent of the EEG pipeline and can therefore be invoked at any time.

### Statistical modelling
The outputs tables generated from the spectral power (`wsws_timefrq.csv`) and stimulus reconstruction (`wsws_stimrec.csv`) analyses have been provided in the `stats` subdirectory so that statistical analyses can be performed in *R* without needing to run any component of the *MATLAB* pipeline.
Note that rerunning the analysis pipeline will overwrite these files, potentially altering model results if new parameters have been specified.
This subdirectory also contains a `MATLAB` script for collating and summarising basic demographic data (`wsws_demogs.m`).

Pease ensure you have the appropriate packages installed on your system prior to running either `R` script (listed at the beginning of each script).

`wsws_timefrq.R` models subjective clarity ratings and mean spectral power estimates for each analysed frequency band.
It also visualises the frequency band models.
`wsws_stimrec.R` models the stimulus reconstruction data and reruns the clarity rating analysis including  reconstruction score as a predictor in the model.
Note that each script performs nested model comparisons; hence, to reduce processing time, you might want to consider fitting only the winning model from each analysis.


## Citation
If the materials archived here are useful for your own research, please cite this repository including the appropriate release version information (year and doi; see below for details):

> Corcoran, A.W. & Andrillon, T.A. {*year*}. SWS_NVS_code {*version*} [Software]. Retrieved from https://github.com/corcorana/SWS_NVS_code. {*doi*}

Please also cite the accompanying manuscript:

> Corcoran, A.W., [...]


## Current release -- to be assigned when repo made public
`v1.0.0` [![DOI](https://zenodo.org/badge/DOI/[...].svg)](https://doi.org/[...])


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



**R version 3.6.2 (2019-12-12)**

**Platform:** x86_64-w64-mingw32/x64 (64-bit) 

**attached base packages:** 
_stats_, _graphics_, _grDevices_, _utils_, _datasets_, _methods_ and _base_

**other attached packages:** 
_RVAideMemoire(v.0.9-79)_, _ordinal(v.2019.12-10)_, _performance(v.0.5.0)_, _emmeans(v.1.5.1)_, _car(v.3.0-10)_, _carData(v.3.0-4)_, _lme4(v.1.1-23)_, _Matrix(v.1.2-18)_, _forcats(v.0.5.0)_, _stringr(v.1.4.0)_, _dplyr(v.1.0.2)_, _purrr(v.0.3.4)_, _readr(v.1.4.0)_, _tidyr(v.1.1.2)_, _tibble(v.3.0.4)_, _ggplot2(v.3.3.2)_ and _tidyverse(v.1.3.0)_

**loaded via a namespace (and not attached):** 
_TH.data(v.1.0-10)_, _minqa(v.1.2.4)_, _colorspace(v.1.4-1)_, _ellipsis(v.0.3.1)_, _rio(v.0.5.16)_, _rsconnect(v.0.8.16)_, _estimability(v.1.3)_, _fs(v.1.5.0)_, _rstudioapi(v.0.11)_, _rstan(v.2.21.2)_, _fansi(v.0.4.1)_, _mvtnorm(v.1.1-1)_, _lubridate(v.1.7.9)_, _xml2(v.1.3.2)_, _codetools(v.0.2-16)_, _splines(v.3.6.2)_, _knitr(v.1.30)_, _jsonlite(v.1.7.1)_, _nloptr(v.1.2.2.2)_, _packrat(v.0.5.0)_, _broom(v.0.7.1)_, _dbplyr(v.1.4.4)_, _compiler(v.3.6.2)_, _httr(v.1.4.2)_, _backports(v.1.1.10)_, _assertthat(v.0.2.1)_, _cli(v.2.1.0)_, _htmltools(v.0.5.0)_, _prettyunits(v.1.1.1)_, _tools(v.3.6.2)_, _coda(v.0.19-4)_, _gtable(v.0.3.0)_, _glue(v.1.4.2)_, _V8(v.3.2.0)_, _Rcpp(v.1.0.5)_, _cellranger(v.1.1.0)_, _vctrs(v.0.3.4)_, _nlme(v.3.1-149)_, _insight(v.0.12.0)_, _xfun(v.0.18)_, _ps(v.1.4.0)_, _openxlsx(v.4.2.2)_, _rvest(v.0.3.6)_, _lifecycle(v.0.2.0)_, _statmod(v.1.4.34)_, _MASS(v.7.3-53)_, _zoo(v.1.8-8)_, _scales(v.1.1.1)_, _hms(v.0.5.3)_, _parallel(v.3.6.2)_, _sandwich(v.3.0-0)_, _inline(v.0.3.16)_, _curl(v.4.3)_, _gridExtra(v.2.3)_, _pander(v.0.6.3)_, _loo(v.2.3.1)_, _StanHeaders(v.2.21.0-6)_, _stringi(v.1.4.6)_, _ucminf(v.1.1-4)_, _bayestestR(v.0.7.2)_, _boot(v.1.3-25)_, _pkgbuild(v.1.1.0)_, _zip(v.2.1.1)_, _matrixStats(v.0.57.0)_, _rlang(v.0.4.8)_, _pkgconfig(v.2.0.3)_, _evaluate(v.0.14)_, _lattice(v.0.20-41)_, _tidyselect(v.1.1.0)_, _processx(v.3.4.4)_, _magrittr(v.1.5)_, _R6(v.2.4.1)_, _generics(v.0.0.2)_, _multcomp(v.1.4-14)_, _DBI(v.1.1.0)_, _pillar(v.1.4.6)_, _haven(v.2.3.1)_, _foreign(v.0.8-76)_, _withr(v.2.3.0)_, _survival(v.3.2-7)_, _abind(v.1.4-5)_, _modelr(v.0.1.8)_, _crayon(v.1.3.4)_, _rmarkdown(v.2.4)_, _grid(v.3.6.2)_, _readxl(v.1.3.1)_, _data.table(v.1.13.0)_, _blob(v.1.2.1)_, _callr(v.3.5.1)_, _reprex(v.0.3.0)_, _digest(v.0.6.25)_, _xtable(v.1.8-4)_, _numDeriv(v.2016.8-1.1)_, _RcppParallel(v.5.0.2)_, _stats4(v.3.6.2)_ and _munsell(v.0.5.0)_> 
