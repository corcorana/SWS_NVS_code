%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

%%

allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};

% params
frqBand = [1,3; 4,9; 10,15; 15,30];

filt = [];
filt.hpfilter   = 'yes';  
filt.hpfilttype = 'firws';
filt.hpfiltdir  = 'onepass-zerophase';
filt.lpfilter   = 'yes'; 
filt.lpfilttype = 'firws';
filt.lpfiltdir  = 'onepass-zerophase';

rsFac = 50;     % down/resampling factor (Fs/rsFac)

nc=0;
for n=1:length(allfiles)
    
    %%% Loading data
    fprintf('... loading %s\n',allfiles{n})
    load([preproc_path filesep 'nlhie_ft_test_SWSNVS' allfiles{n}],'event');
    load([preproc_path filesep 'ICAcomp_rej_ft_test_SWSNVS' allfiles{n}])

    % reref to linked mastoids 
    cfg = [];    
    cfg.reref      = 'yes';
    cfg.channel    = 'all';
    cfg.refchannel = {'17', '22'};
    data = ft_preprocessing(cfg,data);
    
    fs = data.fsample;
    nc=nc+1;
    trial_labels={event.type};
    label=data.label;
    
    for nRep=1:2
        for nStim=1:2
            for nCond=1:3         
                filt.trials = find_trials(trial_labels,sprintf('%s_%s_%g',StimCat{nStim},CondCat{nCond},nRep));
                fprintf('... ... ... extracting ERD for %s %s %g (n=%g trials)\n',StimCat{nStim},CondCat{nCond},nRep,length(filt.trials))
                for nFilt=1:size(frqBand,1)

                    % high & low-pass filters
                    filt.hpfreq = frqBand(nFilt,1);
                    filt.lpfreq = frqBand(nFilt,2);
                    tmp = ft_preprocessing(filt,data);
                    
                    
                    % calculate the unreferenced ERD (classic power method)
                    pow = mean(cat(3, tmp.trial{:}).^2, 3);
                    smoo = movmean(log10(pow), fs/2, 2);
                    rsS = resample(smoo', fs/rsFac, fs)';
                    ERD{nRep,nStim,nCond,nFilt}(nc,:,:) = rsS;
                    
                    % calculate unreferenced ERD (intertrial variance for induced power) 
                    erp = mean(cat(3, tmp.trial{:}), 3);
                    pow = mean((cat(3, tmp.trial{:}) - erp).^2, 3);
                    smoo = movmean(log10(pow), fs/2, 2);
                    rsS = resample(smoo', fs/rsFac, fs)';
                    ERDi{nRep,nStim,nCond,nFilt}(nc,:,:) = rsS;
                                      
                    % downsampled time vector
                    t = downsample( data.time{1,1}, rsFac);
                    
                end
            end
        end
    end
end
save('wsws_ERD.mat','ERD','ERDi','t','fs','label');

