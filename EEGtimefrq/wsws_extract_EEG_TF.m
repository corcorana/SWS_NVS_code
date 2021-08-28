%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

%%
allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};

% TFR params
tlen = 1;
fres = 1/tlen;
minf = fres;
maxf = 30;
tstep = tlen/10;
twin = [-2, 12];

nc=0;
for n=1:length(allfiles)
    
    %%% Loading data
    fprintf('... loading %s\n',allfiles{n})
    % EEG
    load([preproc_path filesep 'nlhie_ft_test_SWSNVS' allfiles{n}],'event','layout')
    load([preproc_path filesep 'ICAcomp_rej_ft_test_SWSNVS' allfiles{n}])
    
    % reref to linked mastoids 
    cfg = [];    
    cfg.reref      = 'yes';
    cfg.channel    = 'all';
    cfg.refchannel = {'17', '22'};
    data = ft_preprocessing(cfg,data);
    
    % get TFRs
    cfg             = [];
    cfg.output      = 'pow';
    cfg.channel     = {'all', '-17', '-22'};
    cfg.method      = 'mtmconvol';
    cfg.taper       = 'hanning';
    cfg.foi         = minf:fres:maxf;
    cfg.t_ftimwin   = ones(length(cfg.foi),1).*tlen;
    cfg.toi         = twin(1):tstep:twin(2);
    cfg.keeptrials  = 'yes';
        
    if size(event,2)~=size(data.trial,2)
        warning('PROBLEM ALIGNMENT DATA AND LABELS FOR TRIALS');
                 continue;
    end
    nc=nc+1;
    trial_labels={event.type};
    
    for nRep=1:2
        for nStim=1:2
            for nCond=1:3
                cfg.trials = find_trials(trial_labels,sprintf('%s_%s_%g',StimCat{nStim},CondCat{nCond},nRep));
                fprintf('... ... ... extracting TF for %s %s %g (n=%g trials)\n',StimCat{nStim},CondCat{nCond},nRep,length(cfg.trials))
                temp_TRF = ft_freqanalysis(cfg, data);
                TFR{nRep,nStim,nCond} = temp_TRF.powspctrm;
            end
        end
    end
    
    time=temp_TRF.time;
    freq=temp_TRF.freq;
    label=temp_TRF.label;

    save([preproc_path filesep 'TF_nlhie_ft_SWSNVS'  allfiles{n}],'TFR','event','layout','time','freq','label'); 


end
