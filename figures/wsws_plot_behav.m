%%
clear all
close all

run(['..' filesep 'def_local'])

%% 
allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};

nc=0;
allres_clarity=[];
for n=1:length(allfiles)
    files=dir([behav_path filesep 'SWS_NVS_results_S' allfiles{n} '*.mat']);
    load([behav_path filesep files.name]);
    subID=allfiles{n};
    fprintf('... ... %s (%g trials)\n',subID,size(res_mat,1));

    nc=nc+1;
    
    %%% Recognising Congruent and Incongruent trials
    res_congruency=[];
    for nbl=1:6
        thisblock=squeeze(block_conditions(nbl,:,:));
        if sum(sum(thisblock))==0
            mat_congruency(nc,nbl,:,:)=nan(2,2);
            continue;
        end
        thisblockres=squeeze(res_resp_Q(nbl,:,:));
        for ncat=1:2
            for ncond=1:2
                tridx=find(thisblock(:,4)==ncat & thisblock(:,3)==ncond);
                if ~isempty(tridx)
                    res_congruency=[res_congruency ; [repmat([nbl ncat ncond],length(tridx),1) thisblockres(tridx,3)]];
                end
            end
        end
        for ncat=1:2
            for ncond=1:2
                mat_congruency(nc,nbl,ncat,ncond)=100*nanmean(res_congruency(res_congruency(:,1)==nbl & res_congruency(:,2)==ncat & res_congruency(:,3)==ncond,end)==1);
            end
        end
    end
    
    
    %%% Clarity ratings
    res_clarity=[];
    for nbl=1:6
        thisblock=squeeze(block_conditions(nbl,:,:));
        if sum(sum(thisblock))==0
            mat_clarity1(nc,nbl,:,:)=nan(2,3);
            mat_clarity2(nc,nbl,:,:)=nan(2,3);
            mat_claritydiff(nc,nbl,:,:)=nan(2,3);
            continue;
        end
        thisblockres=squeeze(res_resp_Q(nbl,:,:));
        for ncat=1:2
            for ncond=1:3
                tridx=find(thisblock(:,4)==ncat & thisblock(:,3)==ncond);
                if ~isempty(tridx)
                    res_clarity=[res_clarity ; [repmat([nbl ncat ncond],length(tridx),1) thisblockres(tridx,1) thisblockres(tridx,2)]];
                end
            end
        end
        for ncat=1:2
            for ncond=1:3
                mat_clarity1(nc,nbl,ncat,ncond)=nanmean(res_clarity(res_clarity(:,1)==nbl & res_clarity(:,2)==ncat & res_clarity(:,3)==ncond,4));
                mat_clarity2(nc,nbl,ncat,ncond)=nanmean(res_clarity(res_clarity(:,1)==nbl & res_clarity(:,2)==ncat & res_clarity(:,3)==ncond,5));
                mat_claritydiff(nc,nbl,ncat,ncond)=nanmean(res_clarity(res_clarity(:,1)==nbl & res_clarity(:,2)==ncat & res_clarity(:,3)==ncond,5)-res_clarity(res_clarity(:,1)==nbl & res_clarity(:,2)==ncat & res_clarity(:,3)==ncond,4));
            end
        end
    end
    allres_clarity=[allres_clarity ; [n*ones(size(res_clarity,1),1) res_clarity]];
end

%% Congruency judgement
Markers={'o','d'};
width=0.5;
figure; set(gcf,'Position',[680   541   339   437]);
for nStim=1:2
    for nCond=1:2
        tempCong{nStim,nCond}=squeeze(nanmean(mat_congruency(:,:,nStim,nCond),2));
        simpleDotPlot(nCond+(2*nStim-3)*0.15,tempCong{nStim,nCond},288,ColorCond(nCond,:),width,'k',Markers{nStim},[],3,1);
    end
end
ylabel('% ''yes''')
xlim([0.5 2.5]);
ylim([0 100])
format_fig;
set(gca,'XTick',1:2,'XTickLabel',{'P+','P-'});
title('Correct Prior?')


%% Figure 1C
figure
set(gcf,'Position',[440   429   803   368])
format_fig;
for nStim=1:2
    subplot(1,2,nStim)
    for nCond=1:3
        for nRep=1:2
            if nRep==1
                temp=squeeze(nanmean(mat_clarity1(:,:,nStim,nCond),2));
                hdot{nRep}=simpleDotPlot(nCond+(2*nRep-3)*0.15,temp,288,[1 1 1 ; ColorCond(nCond,:)],width,'k',Markers{nStim},[],3,1);
            elseif nRep==2
                temp=squeeze(nanmean(mat_clarity2(:,:,nStim,nCond),2));
                hdot{nRep}=simpleDotPlot(nCond+(2*nRep-3)*0.15,temp,288,ColorCond(nCond,:),width,'k',Markers{nStim},[],3,1);
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
    end
    
    set(gca,'XTick',1:3,'XTickLabel',{'P+','P-','P0'},'YTick',1:4)
    ylabel('Clarity')
    xlim([0.5 3.5])
    ylim([1 4])
    title(StimCat{nStim})
    set(gca,'LineWidth',2,'XColor','k','FontSize',24);
    
end


% export
try
    export_fig( [path_figs filesep 'fig1C.png'] )
catch
    hgexport(gcf, [path_figs filesep 'fig1C'], hgexport('factorystyle'), 'Format', 'png')
end

