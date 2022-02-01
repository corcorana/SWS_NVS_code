%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_figs) 

timeCol=17;

%% Loop on subjects
subj_name=405:425;
ns=0;
for nS=1:length(subj_name)
    %%% load data 
    behav_name=dir([behav_path filesep 'SWS_NVS_results_S' num2str(subj_name(nS)) '*.mat']);
    if isempty(behav_name)
        fprintf('... Sub %g SKIPPED: no behav file\n', subj_name(nS))
        continue;
    else
        fprintf('... Sub %g\n', subj_name(nS))
    end
    load([behav_path filesep behav_name.name]);
    
    save_name=sprintf('SWS_NVS_tobii_s%g',subj_name(nS));
    if ~exist([eyet_path filesep save_name '.mat'], 'file')
        fprintf('... ... SKIPPED: no pupil data\n')
        continue;
    end
    load([eyet_path filesep save_name]);
    numB=find_trials(cellstr((events{3})),'^block [1-9] $');
    
    % detect and clean blinks
    param=[];
    param.fs=fs;
    param.mindur=0;
    param.maxdur=5;
    param.mindist=0.1;
    param.paired=0;
    blinks=eyet_detect_blinks(data(:,11:12),param);
    blinks1=blinks(blinks(:,6)==1,:);
    
    data_pupil1=get_Tobii_cleanpupil(data(:,13)',fs,data(:,17)',blinks);
    blinks2=blinks(blinks(:,6)==2,:);
    data_pupil2=get_Tobii_cleanpupil(data(:,14)',fs,data(:,17)',blinks);
    
    low_or_nan1=find(isnan(data_pupil1) | data_pupil1<2.5);
    low_or_nan2=find(isnan(data_pupil2) | data_pupil2<2.5);
    
    data_pupil1(low_or_nan1)=nan;
    data_pupil2(low_or_nan2)=nan;
    
    data_pupil1_int=fillmissing(data_pupil1,'linear');
    filt_pupil1=lpfilt(data_pupil1_int, fs, 6, 4);
    data_pupil2_int=fillmissing(data_pupil2,'linear');
    filt_pupil2=lpfilt(data_pupil2_int, fs, 6, 4);
    
    pup_clean=nanmean([filt_pupil1 ; filt_pupil2]);
    
    pupilSize_firstpres=[];
    pupilSize_secondpres=[];
    pupilSize_firstQ=[];
    res_mat2=[];
    for nB=1:length(numB)
        for nT=1:16
            % select 1st and 2nd presentation (seq 1 and seq 4);
            thisSeq=find_trials(events{3},sprintf('^block %g trial %g seq 1 $',nB,nT));
            if isempty(thisSeq)
                continue;
            end
            thisTime=double(events{1}(thisSeq));
            [thisTime2,thisIdx]=findclosest(data(:,timeCol),thisTime);
            
            thisSeq2=find_trials(events{3},sprintf('^block %g trial %g seq 4 $',nB,nT));
            if isempty(thisSeq2)
                continue;
            end
            thisTime3=double(events{1}(thisSeq2));
            [thisTime4,thisIdx2]=findclosest(data(:,timeCol),thisTime3);
            
            if abs(thisTime2-thisTime)<0.1 && abs(thisTime4-thisTime3)<0.1
                bsline=nanmean(pup_clean((-1*fs:0*fs)+thisIdx));
                pupilSize_firstpres=[pupilSize_firstpres ; pup_clean((-1*fs:11*fs)+thisIdx)-bsline];
                pupilSize_secondpres=[pupilSize_secondpres ; pup_clean((-1*fs:11*fs)+thisIdx2)-bsline];
                res_mat2=[res_mat2 ; res_mat(res_mat(:,1)==nB & res_mat(:,2)==nT,:)];
            else
                continue;
            end
                        
        end
    end
    
    % Average by category
    if size(res_mat2,1)==size(pupilSize_firstpres,1) && size(res_mat2,1)==size(pupilSize_secondpres,1)
        ns=ns+1;
        for ncat=1:2
            for ncond=1:3
                tridx=find(res_mat2(:,6)==ncat & res_mat2(:,5)==ncond);
                avpupilSize_firstpres(ns,ncat,ncond,:)=nanmean(pupilSize_firstpres(tridx,:));
                avpupilSize_secondpres(ns,ncat,ncond,:)=nanmean(pupilSize_secondpres(tridx,:));
            end
        end
    end
end


%% plot cluster permutation contrasting P+/P- vs P0
figure; set(gcf,'Position',[193   170   528   727])
timeP=-1:1/fs:11;
transpF=0.3;
for ncat=1:length(StimCat)
    subplot(2,1,ncat); format_fig; hold on;
    for ncond=1:2
        pV{ncat,ncond} = simpleTplot(timeP,squeeze(nanmean(avpupilSize_secondpres(:,ncat,ncond,:),2))-...
            squeeze(nanmean(avpupilSize_secondpres(:,ncat,3,:),2)),0,ColorCond(ncond,:),[2 0.025 0.05 1000],'-',transpF,1,[],[],3);
    end
    xlim([-1 10.5])
    line([0,0], ylim, 'LineStyle', '--', 'Color', 'k')
    if ncat==2
        xlabel('Time (s)')
    end  
    ylabel('Pupil size')
end

%% plot Figure 4B
figure; set(gcf,'Position',[193   170   528   727])
transpF=0.3;
for ncat=1:length(StimCat)
    subplot(2,1,ncat); format_fig; hold on;
    for ncond=1:2
        simpleTplot(timeP,squeeze(nanmean(avpupilSize_secondpres(:,ncat,ncond,:),2)),...
            0,ColorCond(ncond,:),0,'-',transpF,1,[],[],3);
        hold on
        l = pV{ncat,ncond}.realpos{1}.clusters==find(pV{ncat,ncond}.realpos{1}.pmonte<.025);
        t = timeP(l);
        line([t(1), t(end)], [-.2, -.2]+ncond/60, 'LineStyle', '-', 'Color', ColorCond(ncond,:), 'LineWidth', 2)
    end
    for ncond=3
        simpleTplot(timeP,squeeze(nanmean(avpupilSize_secondpres(:,ncat,ncond,:),2)),...
            0,ColorCond(ncond,:),0,'-',transpF,1,[],[],3);
    end
    xlim([-1 10.5])
    ylim([-0.2 0.2])
    line([0,0], ylim*1.1, 'LineStyle', '--', 'Color', 'k')
    if ncat==2
        xlabel('Time (s)')
    end
    set(gca,'LineWidth',2);
    ylabel('Pupil size (a.u.)')
    title(StimCat{ncat}, 'FontSize', 24, 'FontWeight', 'Bold', 'Color',  ColorStim(ncat,:))
end
hl = legend({'' 'P+' '' '' 'P-' '' '' 'P0'}, 'Box', 'off', 'Location', 'northeast');
pos_hl = get(hl, 'Position');
set(hl, 'Position', [pos_hl(1)+0.125, pos_hl(2)+.09, pos_hl(3), pos_hl(4)]);

% export
try
    export_fig( [path_figs filesep 'fig4B.png'] )
catch
    hgexport(gcf, [path_figs filesep 'fig4B'], hgexport('factorystyle'), 'Format', 'png')
end
