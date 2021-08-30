%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

%%
allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};
try
    badEpochs = readtable([SWS 'EEGpreproc' filesep 'wsws_badEpochs.csv']);    
    badEpochs = table2array(badEpochs);
catch
    warning('No bad epoch logfile detected, consider performing manual artifact rejection')
    badEpochs = nan;
end

% time-frequency bounds
timwin = [0.5, 3];
frex = [1,3; 4,9; 10,15; 16,30];

% codes for item ID
run([SWS 'EEGstimrec' filesep 'make_stimuliList'])
Lcode = '_List';
Scode = '_StID';
Pcode = '_Pair';
    
long = nan(length(allfiles)*length(StimCat)*length(CondCat)*16*62*size(frex,1), 12); % subj, stim, cond, trial, chan, frex
item_id = cell(length(long),1);
cnt = 1;
for n=1:length(allfiles)
    %%% Loading data
    fprintf('... loading %s\n',allfiles{n})
    load([preproc_path filesep 'nlhie_ft_test_SWSNVS' allfiles{n}],'event','layout'); % updated event structure
    load([preproc_path filesep 'TF_nlhie_ft_SWSNVS' allfiles{n}], 'TFR','time','freq','label');
    behav_name=dir([behav_path filesep 'SWS_NVS_results_S' allfiles{n} '*.mat']);
    load([behav_path filesep behav_name.name], 'res_mat', 'res_mat_headers');

    % indices for rejected epochs
    rejected_trials = badEpochs(badEpochs(:,1)==str2double(allfiles{n}),2:end);
    badtrials = ceil(rejected_trials(~isnan(rejected_trials))/2);
    
    % get stimulus event codes [& relevant logfile columns]
    trial_type = {event.type};
    trial_label = {event.value};
    for nStim=1:length(StimCat)
        for nCond=1:length(CondCat)
            tidx = find_trials(trial_type,sprintf('%s_%s_%g',StimCat{nStim},CondCat{nCond},1));
            for nTr = 1:length(tidx)
                thisList = str2double(trial_label{tidx(nTr)}(strfind(trial_label{tidx(nTr)},Lcode)+length(Lcode)));                        
                thisStim = str2double(trial_label{tidx(nTr)}(strfind(trial_label{tidx(nTr)},Scode)+length(Scode):strfind(trial_label{tidx(nTr)},Pcode)-1));
                thisPair = str2double(trial_label{tidx(nTr)}(strfind(trial_label{tidx(nTr)},Pcode)+length(Pcode)));
                thisItem = code_stimuli{thisList,thisStim,thisPair};
                for nChan = 1:length(label)                            
                    for nBand = 1:size(frex,1)                             
                        % obtain power estimates from TFR
                        pow1 = mean( mean(log10(TFR{1,nStim,nCond}(nTr,nChan,freq>=frex(nBand,1)&freq<=frex(nBand,2),time>=timwin(1)&time<=timwin(2))), 4), 3);
                        try
                            pow2 = mean( mean(log10(TFR{2,nStim,nCond}(nTr,nChan,freq>=frex(nBand,1)&freq<=frex(nBand,2),time>=timwin(1)&time<=timwin(2))), 4), 3);
                        catch
                            pow2 = nan;
                        end

                        % recover clarity/congruence ratings from res_mat using unique stim codes
                        ridx = res_mat(:,strcmp(res_mat_headers, 'nList'))==thisList &...
                            res_mat(:,strcmp(res_mat_headers, 'nOriStim'))==thisStim &...
                            res_mat(:,strcmp(res_mat_headers, 'Pair'))==thisPair;
                        if sum(ridx)~=1
                            [ridx, block, trial, clar1, clar2, cong] = deal(nan); 
                        else
                            block = res_mat(ridx,strcmp(res_mat_headers, 'nBlock'));
                            trial = find(ridx);
                            clar1 = res_mat(ridx,strcmp(res_mat_headers, 'Resp1'));
                            clar2 = res_mat(ridx,strcmp(res_mat_headers, 'Resp2'));
                            cong = res_mat(ridx,strcmp(res_mat_headers, 'Resp3'));
                        end
                        item_id{cnt} = thisItem;
                        long(cnt,:) = [str2double(allfiles{n}), block, trial, nStim, nCond,...
                             str2double(label(nChan)), nBand, pow1, pow2, clar1, clar2, cong];
                        cnt=cnt+1;
                    end
                end
            end
        end
    end
end

t1 = array2table(long);
t1.Properties.VariableNames = {'subj_id' 'block' 'trial' 'stim' 'cond' 'chan' 'freq' 'logpow1' 'logpow2' 'clarity1' 'clarity2' 'congruence'};
t2 = array2table(item_id);
T = [t1,t2];
writetable(T, [path_stats filesep 'wsws_timefrq.csv'])
