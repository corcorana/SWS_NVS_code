%% define local paths

% raw and preprocessed data -- direct to directory containing data from OSF
dat_path = 'D:\SWS_NVS\data\';
if ~exist(dat_path, 'dir')
    dat_path = '/Users/thandrillon/Data/SWS/';
    if ~exist(dat_path, 'dir')
        warning('Unable to locate Data directory... need to update path in `def_local` ?')
    end
end

% MATLAB -- direct to local MATLAB directory (code may be stored elsewhere)
mat_path = 'C:\Users\acor0004\Documents\MATLAB\';
if ~exist(mat_path, 'dir')
    mat_path = '/Users/thandrillon/Work/local/';
    if ~exist(mat_path, 'dir')
        warning('Unable to locate MATLAB directory... need to update path in `def_local` ?')
    end
end

% MATLAB toolboxes -- update versions as required
path_fieldtrip = [mat_path, 'fieldtrip-20200623']; % necessary for EEG pipeline
path_mTRF = [mat_path, 'mTRF-Toolbox-2.0']; % necessary for stimulus reconstruction
path_eeglab = [mat_path, 'eeglab2019_1'];   % optional for Fig 3B topographies
path_figexport = [mat_path, 'export_fig'];  % optional for figure export (can be downloaded on GitHub: https://github.com/altmany/export_fig)

if ~exist(path_fieldtrip, 'dir')
    path_fieldtrip = [mat_path, 'fieldtrip'];
    if  ~exist(path_fieldtrip, 'dir')
        warning('Unable to locate FieldTrip toolbox... need to update path in `def_local` ?')
    end
end
if ~exist(path_mTRF, 'dir')
    path_mTRF = '/Users/thandrillon/WorkGit/projects/ext/mTRF-Toolbox';
    if  ~exist(path_mTRF, 'dir')
        warning('Unable to locate mTRF toolbox... need to update path in `def_local` ?')
    end
end
if exist(path_figexport, 'dir')
    addpath(path_figexport)
else
    warning('Unable to locate export_fig... will default to hgexport')
end

%% following paths should not require re-definition (directory structure should mirror GitHub repository)

% code paths
if ~exist('def_local.m', 'file')
    warning('`def_local` not found, change current folder to `SWS_NVS_code`')
else
    SWS = [pwd, filesep];
    path_stats = [SWS, 'stats'];
    path_figs = [SWS, 'figures'];
    path_chanlocs = [SWS, 'EasyCap64_MBI.sfp'];
end

% data paths
raweeg_path = [dat_path, 'rawEEG'];
behav_path = [dat_path, 'behav'];
stim_path = [dat_path, 'stimuli'];
eyet_path = [dat_path, 'eyeTrack'];
preproc_path = [dat_path, 'preprocEEG'];


%% define factor levels/labels & associated RGB codes
StimCat = {'SWS', 'NVS'};
CondCat={'P\+','P-','P0'};
Conds = {'P+','P-','P0'};
ColorStim = [191,61,49; 94,155,216]/256;
ColorCond = [27,158,119; 217,95,2; 117,112,179]/256;

