%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

%%
allfiles = {'405','406','407','408','409','410','411','412','413','414',...
    '415','416','417','418','419','420','421','422','423'};

for n=1:length(allfiles)

    %%% load training data
    File_Name = allfiles{n};
    load([preproc_path filesep 'nlhie_ft_training_SWSNVS' allfiles{n}])
    fprintf('... processing %s (%g/%g)\n',File_Name,n,length(allfiles))
    
    %%% run ICA
    cfg = [];
    cfg.method = 'runica'; % this is the default and uses the implementation from EEGLAB
    cfg.numcomponent = rankICA;
    
    comp = ft_componentanalysis(cfg, data);
    save([preproc_path filesep 'ICAcomp_ft_training_SWSNVS' File_Name], 'comp', 'rankICA');
    
    %%% load test data
    load([preproc_path filesep 'nlhie_ft_test_SWSNVS' allfiles{n}])
    
    %%% run ICA
    cfg.numcomponent = rankICA;
    
    comp = ft_componentanalysis(cfg, data);
    save([preproc_path filesep 'ICAcomp_ft_test_SWSNVS' File_Name], 'comp', 'rankICA');
    
end
