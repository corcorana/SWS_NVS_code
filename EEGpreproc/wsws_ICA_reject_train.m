%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

%%

load wsws_badComps_train

allfiles = {'405','406','407','408','409','410','411','412','413','414',...
    '415','416','417','418','419','420','421','422','423'};

for n=1:length(allfiles)

    %%% load training data & components
    File_Name = allfiles{n};
    load([preproc_path filesep 'nlhie_ft_training_SWSNVS' allfiles{n}])
    load([preproc_path filesep 'ICAcomp_ft_training_SWSNVS' allfiles{n}])
    fprintf('... processing %s (%g/%g)\n',File_Name,n,length(allfiles))
    
    % find components for rejection
    badEye = badComps_train{[0, badComps_train{2:end,1}] == str2double(File_Name),2};
    badHeart = badComps_train{[0, badComps_train{2:end,1}] == str2double(File_Name),3};
    badOther = badComps_train{[0, badComps_train{2:end,1}] == str2double(File_Name),4};
    
    cfg = [];
    cfg.component = [badEye, badHeart, badOther];
    
    % remove the bad components, backproject & save
    fprintf('... rejecting %g components\n',length(cfg.component))  
    data = ft_rejectcomponent(cfg, comp, data);
    save([preproc_path filesep 'ICAcomp_rej_ft_training_SWSNVS' File_Name], 'data');
    
end
