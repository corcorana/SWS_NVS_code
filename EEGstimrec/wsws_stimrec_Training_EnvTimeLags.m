%%
clear all
close all

run(['..', filesep, 'def_local'])
addpath(genpath(path_mTRF));

%%
allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};
StimProfiles_freq=([2 8]);

% Model hyperparameters
myLags=-(-0:1:30);
FreqFilt=[2 8];

direction = -1;
tmin = -0;
tmax = 300;
lambdas = 10.^(-6:2:6);
for n=1:length(allfiles)
    
    %%% Loading data
    fprintf('... loading %s\n',allfiles{n})
    % EEG
    load([preproc_path filesep 'stimrec_SWSNVS' allfiles{n} '_filtEnv']);
    % behaviour
    behav_file=dir([behav_path filesep 'SWS_NVS_results_S' allfiles{n} '*.mat']);
    load([behav_path filesep behav_file.name]);
    
    for nFreq=1:size(StimProfiles_freq,1)
        
        name_band=sprintf('env%g_%ghz',StimProfiles_freq(nFreq,:));
        
        % Generate training/test sets
        trai_stim=stimrec.trai_stim_env{1}.(name_band);
        trai_stim=trai_stim(length(myLags):end-length(myLags))';
        trai_resp=stimrec.trai_eeg_env{1}.(name_band);
        trai_resp=trai_resp(:,length(myLags):end-length(myLags))';
        
        % Normalize data
        trai_resp = trai_resp/std(trai_resp(:));
        trai_stim = zscore(trai_stim);
        
        % Train model
        model = mTRFtrain(trai_stim,trai_resp,Fs,direction,tmin,tmax,100,'zeropad',0);

        % Run single-lag cross-validation
        model_byL = mTRFtrain(trai_stim,trai_resp,Fs,direction,tmin,tmax,...
            100,'type','single','zeropad',0);
        
        % Test model
        [pred,test] = mTRFpredict(trai_stim,trai_resp,model_byL,'zeropad',0);
        
        save([preproc_path filesep 'model_trainingOnTale_Env_SWSNVS' allfiles{n} '_MTRF_',...
            num2str(tmax), 'ms' '_' name_band],'model','model_byL','myLags')
        
    end
end

