%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(genpath(path_mTRF));
addpath('ERBfilter');
addpath(path_fieldtrip)
ft_defaults

run make_stimuliList.m


%%
all_CorrEnv=[];
StimProfiles_freq=[2 8];
Lists={'A','B'};
Types={'SWS','_voc_7Bds',''};
for nStim=1:80
    for nList=1:length(Lists)
        StimProfiles=cell(1,size(StimProfiles_freq,1));
        for nType=1:2
            % Hilbert transform to get the envelope of the sound
            stim_name=sprintf('%s%s%g%s%s.wav',stim_path,filesep,nStim,Lists{nList},Types{nType});
  
            if exist(sprintf('%s%sfiltEnv_%g%s%s.mat',stim_path,filesep,nStim,Lists{nList},Types{nType}), 'file')
                load(sprintf('%s%sfiltEnv_%g%s%s',stim_path,filesep,nStim,Lists{nList},Types{nType}));
            else
                stim_env=[];
            end
                
            [stim, FSaudio]=audioread(stim_name);

            [ERB,xf,cf,t] = ERBgram2(stim',FSaudio,0,100,128,100,100,0);
            env_stim = sum(ERB,1);
            for nFreq=1:size(StimProfiles_freq,1)
                name_band=sprintf('env%g_%ghz',StimProfiles_freq(nFreq,:));
                if isfield(stim_env,name_band)==0
                    fprintf('... stim: %g ... list: %s ... type: %s ... freq: [%g, %g] Hz\n',nStim,Lists{nList},Types{nType},StimProfiles_freq(nFreq,:))
                    env_stim_filt = ft_preproc_bandpassfilter(env_stim,FSaudio,StimProfiles_freq(nFreq,:),[],'fir','twopass');
                    env_stim_filt = resample(env_stim_filt,100,FSaudio);
                    env_stim_filt = env_stim_filt(1:1050);
                    StimProfiles{nType,nFreq} = env_stim_filt;
                    stim_env.(name_band) = env_stim_filt;
                end
            end
            env_stim=resample(env_stim,100,FSaudio);
            env_stim=env_stim(1:1050);
            stim_env.envOri=env_stim;
            save(sprintf('%s%sfiltEnv_%g%s%s',stim_path,filesep,nStim,Lists{nList},Types{nType}), 'stim_env');
        end
        
    end
end

