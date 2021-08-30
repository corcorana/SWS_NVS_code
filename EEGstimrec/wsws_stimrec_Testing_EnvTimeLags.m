%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(genpath(path_mTRF))

%%
allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};
StimProfiles_freq=([2 8]);
all_Rec=[];
all_Cond=[];
all_Samples=[];
all_Types=[];
all_CodeStim=[];
direction = -1;
tmin = -0;
tmax = 300;
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
        load([preproc_path filesep 'model_trainingOnTale_Env_SWSNVS' allfiles{n} '_MTRF_' num2str(tmax) 'ms' '_' name_band]);
        
        % Get the model weights
        fmodel = mTRFtransform(model,stimrec.trai_eeg_env{1}.(name_band)');
        trainingweights{nFreq}(n,:,:)=fmodel.w;
        
        trial_labels={event.type};
        trial_specs={event.value};
        
        % Test model
        fprintf('... ... ... test model\n')
        
        nc=0;
        for nTr=1:length(trial_labels)
            tempspecs=trial_specs{nTr};
            if isempty(res_mat(res_mat(:,1)==str2double(tempspecs((strfind(tempspecs,'Block')+5))) & ...
                    res_mat(:,2)==str2double(tempspecs((strfind(tempspecs,'_Stim')+5):(strfind(tempspecs,'_Pres')-1))),:))
                continue;
            end
            nc=nc+1;
            temp_stim=stimrec.test_stim_env{nTr}.(name_band)'; %(length(myLags):end-length(myLags))';
            temp_stim_ori=stimrec.test_stim_env_ori{(nTr)}.(name_band)'; %(length(myLags):end-length(myLags))';
            temp_resp=stimrec.test_eeg_env{nTr}.(name_band)'; %(:,length(myLags):end-length(myLags))';
            % Normalize data
            stimtest = zscore(temp_stim); %sum(temp_stim(:,ERB_trai_freq>boundERB(1) & ERB_trai_freq<boundERB(2)),2);
            stimtest_ori = zscore(temp_stim_ori); %sum(temp_stim(:,ERB_trai_freq>boundERB(1) & ERB_trai_freq<boundERB(2)),2);
            resptest = temp_resp/std(temp_resp(:));
            condtest={trial_labels{nTr}(5:6)};
            condtype2={trial_labels{nTr}(1:3)};
            condtype=str2double(tempspecs(end));
            condrep=str2double(trial_labels{nTr}(end));
            condntr=str2double(tempspecs((strfind(tempspecs,'_Stim')+5):(strfind(tempspecs,'_Pres')-1)));
            condnblock=str2double(tempspecs((strfind(tempspecs,'Block')+5)));
            trialsample=event(nTr).sample;
            behavresp=res_mat(res_mat(:,1)==condnblock & res_mat(:,2)==condntr,14+condrep);
            
            code='_StID'; codeE='_Pair';
            thisStim=str2double(tempspecs(strfind(tempspecs,code)+length(code):strfind(tempspecs,codeE)-1));
            code='_Pair';
            thisPair=str2double(tempspecs(strfind(tempspecs,code)+length(code)));
            code='_List';
            thisList=str2double(tempspecs(strfind(tempspecs,code)+length(code)));
            codestim=sprintf('L%gSt%gP%g',thisList,thisStim,thisPair);
            
            [pred,test] = mTRFpredict(stimtest,resptest,model,'zeropad',1);
            test_acc=test.acc;
            test_mean=mean(abs(zscore(stimtest)-zscore(pred)));
            test_std=std(zscore(stimtest)-zscore(pred));
 
            test_acc_perChunk=[];
            test_mean_perChunk=[];
            test_std_perChunk=[];
            for nChunk=1:3
                [pred,test] = mTRFpredict(stimtest((350*(nChunk-1)+1):(350*nChunk)),...
                    resptest((350*(nChunk-1)+1):(350*nChunk),:),model,'zeropad',1);
                test_acc_perChunk(nChunk)=test.acc;
                test_mean_perChunk(nChunk)=mean(abs(zscore(stimtest((350*(nChunk-1)+1):(350*nChunk)))-zscore(pred)));
                test_std_perChunk(nChunk)=std(zscore(stimtest((350*(nChunk-1)+1):(350*nChunk)))-zscore(pred));
            end
            
            [pred,test] = mTRFpredict(stimtest_ori,resptest,model,'zeropad',0);
            test_acc_ori=test.acc;
            test_acc_perChunk_ori=[];
            for nChunk=1:3
                [pred,test] = mTRFpredict(stimtest_ori((350*(nChunk-1)+1):(350*nChunk)),...
                    resptest((350*(nChunk-1)+1):(350*nChunk),:),model,'zeropad',0);
                test_acc_perChunk_ori(nChunk)=test.acc;
            end          
            
            all_Rec=[all_Rec ; [n condtype nFreq condrep' condnblock' condntr' behavresp' test_acc test_acc_perChunk,...
                test_acc_ori test_acc_perChunk_ori test_mean_perChunk test_std_perChunk test_mean test_std]];
            all_Cond=[all_Cond ; condtest];
            all_Types=[all_Types ; condtype2];
            all_Samples=[all_Samples ; trialsample];
            all_CodeStim=[all_CodeStim ; {codestim}];
        end
    end
end

%% collate data table
tbl=array2table(all_Rec,...
    'VariableNames',{'SubID','Type','Band','Rep','nBlock','nTrial','Clarity','Rec','Rec_Chunk1','Rec_Chunk2','Rec_Chunk3',...
    'RecOri','RecOri_Chunk1','RecOri_Chunk2','RecOri_Chunk3','DiffMean_Chunk1','DiffMean_Chunk2','DiffMean_Chunk3',...
    'DiffSTD_Chunk1','DiffSTD_Chunk2','DiffSTD_Chunk3','DiffMean','DiffSTD'});
tbl.Cond=all_Cond;
tbl.Cond=categorical(tbl.Cond);
tbl.SubID=categorical(allfiles(tbl.SubID)');
tbl.Type=categorical(tbl.Type);
tbl.Type(tbl.Type=='1')='SWS';
tbl.Type(tbl.Type=='2')='NVS';
tbl.Type=removecats(tbl.Type);
tbl.CodeStim=all_CodeStim;
tbl.CodeStim=categorical(tbl.CodeStim);

% export data for modelling
writetable(tbl, [path_stats filesep 'wsws_stimrec.csv'])


%% plot Figure 2A
addpath(path_figs)

if ~exist('tbl', 'var')
    tbl = readtable([path_stats filesep 'wsws_stimrec.csv']);
    tbl.Type = categorical(tbl.Type);
    tbl.Cond = categorical(tbl.Cond);    
end

Types = StimCat;
Markers={'o','d'};

figure; set(gcf,'Position',[539         504        1157         366])
for nCond=1:length(Conds)
    for nType=1:length(Types)
        subplot(1,2,nType); format_fig;
        hdot=[];
        for nRep=1:2
            nBand=1;
            tempRec=tbl.Rec_Chunk1(tbl.Type==Types{nType} & tbl.Rep==nRep & tbl.Band==nBand & tbl.Cond==Conds{nCond});
            tempID=tbl.SubID(tbl.Type==Types{nType} & tbl.Rep==nRep & tbl.Band==nBand & tbl.Cond==Conds{nCond});
            tempMean2{nType,nRep}(:,nCond)=grpstats(tempRec,tempID);
            width=0.5;
            if nRep==1
                hdot{nRep}=simpleDotPlot(nCond+(2*nRep-3)*0.15,tempMean2{nType,nRep}(:,nCond),366,[1 1 1;ColorCond(nCond,:)],width,'k',Markers{nType},[],3,1);
            elseif nRep==2
                hdot{nRep}=simpleDotPlot(nCond+(2*nRep-3)*0.15,tempMean2{nType,nRep}(:,nCond),366,ColorCond(nCond,:),width,'k',Markers{nType},[],3,1);
            end
            
        end
        
        %%% add paired lines
        Xdata1=hdot{1}.ind.XData;
        Ydata1=hdot{1}.ind.YData;
        Xdata2=hdot{2}.ind.XData;
        Ydata2=hdot{2}.ind.YData;
        for j=1:length(Xdata1)
            hold on;
            if Ydata1(j)<Ydata2(j)
                plot([Xdata1(j) Xdata2(j)],[Ydata1(j) Ydata2(j)],'Color',ColorCond(nCond,:),'LineWidth',0.5)
            else
                plot([Xdata1(j) Xdata2(j)],[Ydata1(j) Ydata2(j)],'Color',ColorCond(nCond,:),'LineWidth',0.5,'LineStyle','--')
            end
        end
        for k=1:2
            uistack(hdot{k}.line{1},'top');
            uistack(hdot{k}.line{2},'top');
            uistack(hdot{k}.line{3},'top');
            uistack(hdot{k}.mean,'top');
        end
        
        set(gca,'XTick',1:3,'XTickLabel',{'P+','P-','P0'})
        ylabel('Stim Rec')
        xlim([0.5 3.5])
        if nType==1
            ylim([-0.08 0.28])
        elseif nType==2
            ylim([-0.1 0.12])
        end
        
        line(xlim,[0 0],'Color',[1 1 1]*0.7,'LineStyle','--')
        title(Types{nType})
        set(gca,'FontSize',24)
        set(gca,'LineWidth',2,'XColor','k');
    end
end

% export
try
    export_fig( [path_figs filesep 'fig2A.png'] )
catch
    hgexport(gcf, [path_figs filesep 'fig2A'], hgexport('factorystyle'), 'Format', 'png')
end


%% plot Figure 2B
figure; set(gcf,'Position',[160         556        1080         422]);
for nT=1:2
    subplot(1,2,nT); hold on;
    all_means{nT}=[];
    all_resp{nT}=[];
    for nRep=2
        for nC=1:3
            temp1=tbl.Clarity(tbl.Type==Types{nT} & tbl.Cond==Conds(nC) & tbl.Rep==nRep);
            temp2=tbl.Rec_Chunk1(tbl.Type==Types{nT} & tbl.Cond==Conds(nC) & tbl.Rep==nRep);
            tempS=tbl.SubID(tbl.Type==Types{nT} & tbl.Cond==Conds(nC) & tbl.Rep==nRep);
            mean1=grpstats(temp1,tempS);
            mean2=grpstats(temp2,tempS);
            all_means{nT}=[all_means{nT} ; [mean1 mean2 nC*ones(size(mean1,1),1)]];
            all_resp{nT}=[all_resp{nT} ; [temp1 temp2 nC*ones(size(temp1,1),1)]];

            line([1 1]*mean(mean1),[-1 1].*sem(mean2)+mean(mean2),'Color',ColorCond(nC,:),'LineWidth',2);
            line([-1 1].*sem(mean1)+mean(mean1),[1 1]*mean(mean2),'Color',ColorCond(nC,:),'LineWidth',2);
            if nRep==1
                scatter(mean1,mean2,'MarkerEdgeColor',ColorCond(nC,:),'MarkerFaceColor','w','Marker',Markers{nT},'SizeData',122,'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5);
            elseif nRep==2
                scatter(mean1,mean2,'MarkerEdgeColor',ColorCond(nC,:),'MarkerFaceColor',ColorCond(nC,:),'Marker',Markers{nT},'SizeData',122,'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5);
            end

        end
    end
end
all_robustfit=[];
for nT=1:2
    subplot(1,2,nT); hold on;
    all_means{nT}=[];
    all_resp{nT}=[];
    for nRep=2
        for nC=1:3
            temp1=tbl.Clarity(tbl.Type==Types{nT} & tbl.Cond==Conds(nC) & tbl.Rep==nRep);
            temp2=tbl.Rec_Chunk1(tbl.Type==Types{nT} & tbl.Cond==Conds(nC) & tbl.Rep==nRep);
            tempS=tbl.SubID(tbl.Type==Types{nT} & tbl.Cond==Conds(nC) & tbl.Rep==nRep);
            mean1=grpstats(temp1,tempS);
            mean2=grpstats(temp2,tempS);
            all_means{nT}=[all_means{nT} ; [mean1 mean2 nC*ones(size(mean1,1),1)]];
            all_resp{nT}=[all_resp{nT} ; [temp1 temp2 nC*ones(size(temp1,1),1)]];
            
            [b,rstats] = robustfit(mean1,mean2);
            [r,pV] = corr(mean1,mean2);
            all_robustfit(nT,nRep,nC,1)=rstats.t(1);
            all_robustfit(nT,nRep,nC,2)=rstats.p(1);
            
            line([1 1]*mean(mean1),[-1 1].*sem(mean2)+mean(mean2),'Color',ColorCond(nC,:),'LineWidth',2);
            line([-1 1].*sem(mean1)+mean(mean1),[1 1]*mean(mean2),'Color',ColorCond(nC,:),'LineWidth',2);
            if nRep==1
                scatter(mean(mean1),mean(mean2),'MarkerEdgeColor','k','MarkerFaceColor','w','Marker',Markers{nT},'SizeData',314,'MarkerFaceAlpha',.7,'LineWidth',2);
            elseif nRep==2
                scatter(mean(mean1),mean(mean2),'MarkerEdgeColor','k','MarkerFaceColor',ColorCond(nC,:),'Marker',Markers{nT},'SizeData',314,'MarkerFaceAlpha',.7,'LineWidth',2);
            end
        end
    end
    [r, pV]=corr(all_means{nT}(:,1),all_means{nT}(:,2),'type','spearman');

    fprintf('... correlation between clarity and reconstruction on 2nd presentation: r= %g, p=%g\n',r, pV)

    format_fig;
    xlabel('Clarity'); xlim([.8 4.2]); set(gca,'XTick',1:4);
    ylabel('Stim Rec');
    set(gca,'LineWidth',2,'XColor','k');
    set(gca,'FontSize',24)
    if nT==1
        ylim([-0.0800    0.22])
    elseif nT==2
        ylim([-0.0800    0.14])
    end
end


% export
try
    export_fig( [path_figs filesep 'fig2B.png'] )
catch
    hgexport(gcf, [path_figs filesep 'fig2B'], hgexport('factorystyle'), 'Format', 'png')
end

