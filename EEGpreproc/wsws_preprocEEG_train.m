%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

if ~exist(preproc_path, 'dir')
    mkdir(preproc_path)
end

%%

manualRej = 0;      % set flag to 1 in order to perform manual artefact rejection
if manualRej ~=1
    fprintf('Manual artifact rejection switched off, loading bad channel logfile...\n')
    try
        badChans = readtable('wsws_badChans_train.csv', 'ReadVariableNames', false);    
        badChans = table2array(badChans);
    catch
        warning('No bad channel logfile detected, consider performing manual artifact rejection')
        badChans = nan;
    end
end

allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};
for n=1:length(allfiles)
    %%% load data
    file=dir([raweeg_path filesep '*' allfiles{n} '*.eeg']);
    file_behav=dir([behav_path filesep 'SWS_NVS_results_S' allfiles{n} '*']);
    File_Name = file.name;
    File_Behav = [file_behav.folder filesep file_behav.name];
    File_Path = file.folder;
    fprintf('... processing %s (%g/%g)\n',File_Name,n,length(allfiles))
    hdr=ft_read_header([File_Path filesep File_Name]);
    
    %%% Retrieve layout
    elec = ft_read_sens(path_chanlocs);
    cfg=[];
    cfg.elec = elec;
    cfg.channel = hdr.label(1:64);
    [layout] = ft_prepare_layout(cfg);
        
    %%% Define epochs
    cfg=[];
    cfg.trialfun            = 'wsws_trialfun_train';
    cfg.behavfile           = File_Behav;
    cfg.triggerfile         = [behav_path filesep 'SWS_NVS_triggers_S' allfiles{n}];
    cfg.Fs                  = hdr.Fs;
    cfg.dataset             = [File_Path filesep File_Name];
    cfg.trialdef.eventtype  = '';
    cfg.trialdef.eventvalue = '';
    cfg.trialdef.prestim    = 5;
    cfg.trialdef.poststim   = 5;
    cfg.nSamples            = hdr.nSamples;
    cfg = ft_definetrial(cfg);
    cfg.channel             = hdr.label(1:64);
    cfg.layout              = layout;
    data                    = ft_preprocessing(cfg); % read raw data
    event=data.cfg.event;
    
    %%% filters
    cfg = [];
    cfg.demean          = 'yes';

    cfg.hpfilter        = 'yes';        % enable high-pass filtering
    cfg.hpfilttype      = 'but';
    cfg.hpfiltord       = 4;
    cfg.hpfreq          = 1;
    
    cfg.lpfilter        = 'yes';        % enable low-pass filtering
    cfg.lpfilttype      = 'but';
    cfg.lpfiltord       = 4;
    cfg.lpfreq          = 125;
    
    cfg.dftfilter       = 'yes';        % enable notch filtering to eliminate power line noise
    cfg.dftfreq         = [50 100]; % set up the frequencies for notch filtering
    data = ft_preprocessing(cfg,data);

    if manualRej == 1 
        % manually identify bad channels / epochs
        cfg          = [];
        cfg.method   = 'summary';
        trim_data    = ft_rejectvisual(cfg,data);
        
        badchannel_labels = setdiff(data.label, trim_data.label);
        [badtrialsp, badtrialnum] = setdiff(data.sampleinfo(:,1), trim_data.sampleinfo(:,1));
        
        % keep a record of channels/epochs marked for rejection
        dlmwrite('wsws_badChans_train.csv',[str2double(allfiles{n}), str2double(badchannel_labels)'],'delimiter',',','-append');
    else
        % drop prespecified channels/trials
        rejected_channels = badChans(badChans(:,1)==str2num(allfiles{n}),2:end);
        rejected_channels = rejected_channels(~isnan(rejected_channels));
        badchannel_labels = data.label(rejected_channels);
        
    end
    
   
    if ~isempty(badchannel_labels)
        % find neighbours
        cfg=[];
        cfg.method        = 'triangulation';
        cfg.layout        = layout;
        cfg.feedback      = 'no';
        [neighbours] = ft_prepare_neighbours(cfg);
        
        % interpolate channels
        cfg=[];
        cfg.method         = 'weighted';
        cfg.badchannel     = badchannel_labels;
        cfg.missingchannel = [];
        cfg.neighbours     = neighbours;
        cfg.trials         = 'all';
        cfg.layout         = layout;
        [data] = ft_channelrepair(cfg, data);
    end

    %%% Re-reference
    cfg=[];    
    cfg.reref      = 'yes';
    cfg.refchannel = 'all';
    data = ft_preprocessing(cfg,data);
    
    rankICA = rank(data.trial{1,1});
    save([preproc_path filesep 'nlhie_ft_training_SWSNVS' allfiles{n}],'data','event','layout','hdr','rankICA')
    
end
