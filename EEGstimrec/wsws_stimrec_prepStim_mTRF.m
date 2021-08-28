%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

run make_stimuliList


%%
allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};
StimProfiles_freq=[2 8];

for n=1:length(allfiles)
    stimrec=[];
    %%% Loading data
    fprintf('... loading %s\n',allfiles{n})
    % EEG
    trai=load([preproc_path filesep 'ICAcomp_rej_ft_training_SWSNVS' allfiles{n}]);
    load([preproc_path filesep 'ICAcomp_rej_ft_test_SWSNVS' allfiles{n}])
    load([preproc_path filesep 'nlhie_ft_test_SWSNVS' allfiles{n}],'event');
    trial_label={event.value};
    
    %%% Preparing training data
    ERB_trai_name=sprintf('%s%sfiltEnv_training_tale3.mat',stim_path,filesep);
    if ~exist(ERB_trai_name, 'file')
        [trai_stim,FStrai]=audioread([stim_path filesep 'training_tale3.wav']);
        % Get ERB
        addpath('ERBfilter');
        [ERB_training,xf,cf_trai,t_trai] = ERBgram_largeFile_v2(trai_stim',FStrai,0,100,128,100,2);
        FStrai=FStrai/2;
        
        train_env_stim = sum(ERB_training,1);
        train_stim_env=[];
        for nFreq=1:length(StimProfiles_freq)
            fprintf('... training ... freq: [%g, %g]Hz\n',StimProfiles_freq{nFreq}(1),StimProfiles_freq{nFreq}(2))
            
            [train_env_stim_filt] = ft_preproc_bandpassfilter(train_env_stim,FStrai,[StimProfiles_freq{nFreq}(1) StimProfiles_freq{nFreq}(2)],[],'fir','twopass');
            train_env_stim_filt=resample(train_env_stim_filt,100,FStrai);
                        
            name_band=sprintf('env%g_%ghz',StimProfiles_freq{nFreq}(1),StimProfiles_freq{nFreq}(2));
            train_stim_env.(name_band)=train_env_stim_filt;
        end
        train_env_stim=resample(train_env_stim,100,FStrai);
        train_stim_env.envOri=train_env_stim;
        save(ERB_trai_name,'train_stim_env')
        clear ERB_training trai_stim
    else
        load(ERB_trai_name);
    end
    
    % EEG
    trai_eeg=trai.data.trial{1};
    trai_eeg=trai_eeg-repmat(nanmean(trai_eeg(:,:),1),[64 1]);
    train_eeg_env=[];
    for nFreq=1:size(StimProfiles_freq,1)
        fprintf('... training EEG ... freq: [%g, %g]Hz\n',StimProfiles_freq(nFreq,:))
        
        [trai_env_eeg_filt] = ft_preproc_bandpassfilter(trai_eeg,trai.data.fsample,StimProfiles_freq(nFreq,:),[],'fir','twopass');
        trai_env_eeg_filt=trai_env_eeg_filt(:,trai.data.time{1}>0 & trai.data.time{1}<size(train_stim_env.envOri,2)/100);
        trai_env_eeg_filt=resample(trai_env_eeg_filt',100,trai.data.fsample)';
        
        name_band=sprintf('env%g_%ghz',StimProfiles_freq(nFreq,:));
        train_eeg_env.(name_band)=trai_env_eeg_filt;
    end
    trai_eeg=trai_eeg(:,trai.data.time{1}>0 & trai.data.time{1}<size(train_stim_env.envOri,2)/100);
    trai_eeg=resample(trai_eeg',100,trai.data.fsample)';
    train_eeg_env.envOri=trai_eeg;
    
    stimrec.trai_eeg_env{1}=train_eeg_env;
    stimrec.trai_stim_env{1}=train_stim_env;


    % test trials
    Types={'SWS','_voc_7Bds',''};
    for nTr=1:length(trial_label)
        %  load audio stimuli
        code='_StID'; codeE='_Pair';
        thisStim=str2double(trial_label{nTr}(strfind(trial_label{nTr},code)+length(code):strfind(trial_label{nTr},codeE)-1));
        code='_Pair';
        thisPair=str2double(trial_label{nTr}(strfind(trial_label{nTr},code)+length(code)));
        code='_Type';
        thisType=str2double(trial_label{nTr}(strfind(trial_label{nTr},code)+length(code)));
        code='_List';
        thisList=str2double(trial_label{nTr}(strfind(trial_label{nTr},code)+length(code)));
        code='Block';
        thisBlock=str2double(trial_label{nTr}(strfind(trial_label{nTr},code)+length(code)));
        code='_Stim'; codeE='_Pres';
        thisTrial=str2double(trial_label{nTr}(strfind(trial_label{nTr},code)+length(code):strfind(trial_label{nTr},codeE)-1));
        code='_Pres';
        thisPres=str2double(trial_label{nTr}(strfind(trial_label{nTr},code)+length(code)));
        
        load(sprintf('%s%sfiltEnv_%s%s',stim_path,filesep,code_stimuli{thisList,thisStim,thisPair},Types{3}));
        test_stim_env_ori=stim_env;
        load(sprintf('%s%sfiltEnv_%s%s',stim_path,filesep,code_stimuli{thisList,thisStim,thisPair},Types{thisType}));
        test_stim_env=stim_env;

        load(sprintf('%s%sfiltEnv_%s%s',stim_path,filesep,code_stimuli{thisList,thisStim,setdiff(1:2,thisPair)},Types{3}));
        test_stim_env_ori_pair=stim_env;
        load(sprintf('%s%sfiltEnv_%s%s',stim_path,filesep,code_stimuli{thisList,thisStim,setdiff(1:2,thisPair)},Types{thisType}));
        test_stim_env_pair=stim_env;
        
        % retrieve EEG data and Bandpass Filtering
        raw_data=data.trial{nTr};
        raw_data=raw_data-repmat(mean(raw_data,1),size(raw_data,1),1);
        test_eeg_env=[];
        for nFreq=1:size(StimProfiles_freq,1)
            fprintf('... training EEG ... trial: %g, freq: [%g, %g] Hz\n', nTr, StimProfiles_freq(nFreq,:))
            
            [test_env_eeg_filt] = ft_preproc_bandpassfilter(raw_data,data.fsample,StimProfiles_freq(nFreq,:),[],'fir','twopass');
            test_env_eeg_filt=test_env_eeg_filt(:,data.time{1}>0 & data.time{1}<=10.5);
            test_env_eeg_filt=resample(test_env_eeg_filt',100,data.fsample)';
                        
            name_band=sprintf('env%g_%ghz',StimProfiles_freq(nFreq,:));
            test_eeg_env.(name_band)=test_env_eeg_filt;
        end
        test_eeg=raw_data(:,data.time{1}>0 & data.time{1}<=10.5);
        test_eeg=resample(test_eeg',100,trai.data.fsample)';
        test_eeg_env.envOri=test_eeg;
        
        stimrec.test_eeg_env{nTr}=test_eeg_env;
        stimrec.test_stim_env{nTr}=test_stim_env;
        stimrec.test_stim_env_ori{nTr}=test_stim_env_ori;
        
        stimrec.test_stim_env_ori_pair{nTr}=test_stim_env_ori_pair;
        stimrec.test_stim_env_pair{nTr}=test_stim_env_pair;
        
    end
    
    Fs=100;
    save([preproc_path filesep 'stimrec_SWSNVS' allfiles{n} '_filtEnv'],'stimrec','Fs','event')
end
