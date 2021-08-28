function wsws_ICA_plot(snum, file)
% function to plot IC topographies and timeseries
% snum = subject number (scalar)
% file = 'train' or 'test' data

run(['..', filesep, 'def_local'])
addpath(path_fieldtrip)
ft_defaults

% load hdr & comp struct
if strcmp(file, 'train')
    fprintf('... loading training components from subject %g\n', snum)
    load([preproc_path filesep 'ICAcomp_ft_training_SWSNVS' num2str(snum)], 'comp')
    load([preproc_path filesep 'nlhie_ft_training_SWSNVS' num2str(snum)], 'layout')
        
elseif strcmp(file, 'test')
    fprintf(['... loading test components from subject %g\n', snum,'\n'])
    load([preproc_path filesep 'ICAcomp_ft_test_SWSNVS' num2str(snum)], 'comp')
    load([preproc_path filesep 'nlhie_ft_test_SWSNVS' num2str(snum)], 'layout')

else
    error('Incorrect file type -- please enter ''train'' or ''test''')
end

% plot the component topos for visual inspection
figure('units','normalized','outerposition',[0 0.05 .5 .95])
cfg             = [];
cfg.component   = 1:25;
cfg.layout      = layout;
cfg.comment     = 'no';
ft_topoplotIC(cfg, comp)

% plot the component time series for visual inspection
cfg = [];
cfg.viewmode        = 'component';    
cfg.layout          = layout;
cfg.allowoverlap    = 'true';
ft_databrowser(cfg, comp)
set(gcf,'units','normalized','outerposition',[0.5 0.05 .5 .95]);

