%%
clear all
close all

run ../def_local.m
addpath(genpath(path_mTRF));
addpath(genpath(path_LSCPtools));

table=readtable([path_stats filesep 'wsws_stimrec.csv']);
table.Type=categorical(table.Type);
table.Cond=categorical(table.Cond);
table.SubID=categorical(table.SubID);


%%
figure;
set(gcf,'Position',[539         504        1157         366])
% tight_subplot(1,2);
for nCond=1:3
    for nType=1:2
        subplot(1,2,nType); format_fig;
        hdot=[];
        for nRep=1:2
            nBand=1;
            tempRec=table.Rec_Chunk1(table.Type==Types{nType} & table.Rep==nRep & table.Band==nBand & table.Cond==Conds{nCond});
            tempID=table.SubID(table.Type==Types{nType} & table.Rep==nRep & table.Band==nBand & table.Cond==Conds{nCond});
            tempMean2{nType,nRep}(:,nCond)=grpstats(tempRec,tempID);
            width=0.5;
            %                 simpleDotPlot(nBand+(2*nRep-3)*0.15,tempMean,72,ColorCond(nCond,:),0.5,'k');
            %                 simpleDotPlot(pos,tempMean,144,ColorCond(nCond,:),width,'k',Markers{nRep},[],3,1);
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
            set(gca,'YTick',0:0.1:0.2);
        elseif nType==2
            ylim([-0.1 0.12])
              set(gca,'YTick',-0.1:0.1:0.1);
      end
                line(xlim,[0 0],'Color',[1 1 1]*0.7,'LineStyle','--')
title(Types{nType})
        set(gca,'FontSize',24)
      set(gca,'LineWidth',2,'XColor','k');
  end
end

export_fig([path_figs filesep 'StimRec_Rec_Chunk1_perCond.eps'],'-r 300')

%%
Types={'SWS','NVS'};
Markers={'o','d'};

figure; set(gcf,'Position',[160         556        1080         422]);
this_table=table;
clear all_means
for nT=1:2
    subplot(1,2,nT); hold on;
    all_means{nT}=[];
    all_resp{nT}=[];
    for nRep=2
    for nC=1:3
        temp1=this_table.Clarity(this_table.Type==Types{nT} & this_table.Cond==Conds(nC) & this_table.Rep==nRep);
        temp2=this_table.Rec_Chunk1(this_table.Type==Types{nT} & this_table.Cond==Conds(nC) & this_table.Rep==nRep);
        tempS=this_table.SubID(this_table.Type==Types{nT} & this_table.Cond==Conds(nC) & this_table.Rep==nRep);
        mean1=grpstats(temp1,tempS);
        mean2=grpstats(temp2,tempS);
        all_means{nT}=[all_means{nT} ; [mean1 mean2 nC*ones(size(mean1,1),1)]];
        all_resp{nT}=[all_resp{nT} ; [temp1 temp2 nC*ones(size(temp1,1),1)]];
        
        line([1 1]*mean(mean1),[-1 1].*sem(mean2)+mean(mean2),'Color',ColorCond(nC,:),'LineWidth',2);
        line([-1 1].*sem(mean1)+mean(mean1),[1 1]*mean(mean2),'Color',ColorCond(nC,:),'LineWidth',2);
        if nRep==1
            scatter(mean1,mean2,'MarkerEdgeColor',ColorCond(nC,:),'MarkerFaceColor','w','Marker',Markers{nT},'SizeData',122,'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5);
%             scatter(mean(mean1),mean(mean2),'MarkerEdgeColor','k','MarkerFaceColor','w','Marker',Markers{nT},'SizeData',314,'MarkerFaceAlpha',1);
        elseif nRep==2
            scatter(mean1,mean2,'MarkerEdgeColor',ColorCond(nC,:),'MarkerFaceColor',ColorCond(nC,:),'Marker',Markers{nT},'SizeData',122,'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5);
%             scatter(mean(mean1),mean(mean2),'MarkerEdgeColor','k','MarkerFaceColor',ColorCond(nC,:),'Marker',Markers{nT},'SizeData',314,'MarkerFaceAlpha',1);
        end
        %         for k=1:4
        %             scatter(k,mean(temp2(temp1==k)),'MarkerEdgeColor',ColorCond(nC,:),'MarkerFaceColor',ColorCond(nC,:),'Marker',Markers{nT},'SizeData',122,'MarkerFaceAlpha',0.7);
        %             line([1 1]*k,[-1 1].*sem(temp2(temp1==k))+mean(temp2(temp1==k)),'Color',ColorCond(nC,:),'LineWidth',2);
        %         end
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
            temp1=this_table.Clarity(this_table.Type==Types{nT} & this_table.Cond==Conds(nC) & this_table.Rep==nRep);
            temp2=this_table.Rec_Chunk1(this_table.Type==Types{nT} & this_table.Cond==Conds(nC) & this_table.Rep==nRep);
            tempS=this_table.SubID(this_table.Type==Types{nT} & this_table.Cond==Conds(nC) & this_table.Rep==nRep);
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
                %             scatter(mean1,mean2,'MarkerEdgeColor',ColorCond(nC,:),'MarkerFaceColor','w','Marker',Markers{nT},'SizeData',122,'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5);
                scatter(mean(mean1),mean(mean2),'MarkerEdgeColor','k','MarkerFaceColor','w','Marker',Markers{nT},'SizeData',314,'MarkerFaceAlpha',.7,'LineWidth',2);
            elseif nRep==2
                %             scatter(mean1,mean2,'MarkerEdgeColor',ColorCond(nC,:),'MarkerFaceColor',ColorCond(nC,:),'Marker',Markers{nT},'SizeData',122,'MarkerFaceAlpha',0.5,'MarkerEdgeAlpha',0.5);
                scatter(mean(mean1),mean(mean2),'MarkerEdgeColor','k','MarkerFaceColor',ColorCond(nC,:),'Marker',Markers{nT},'SizeData',314,'MarkerFaceAlpha',.7,'LineWidth',2);
            end
            %         for k=1:4
            %             scatter(k,mean(temp2(temp1==k)),'MarkerEdgeColor',ColorCond(nC,:),'MarkerFaceColor',ColorCond(nC,:),'Marker',Markers{nT},'SizeData',122,'MarkerFaceAlpha',0.7);
            %             line([1 1]*k,[-1 1].*sem(temp2(temp1==k))+mean(temp2(temp1==k)),'Color',ColorCond(nC,:),'LineWidth',2);
            %         end
        end
    end
    [r, pV]=corr(all_means{nT}(:,1),all_means{nT}(:,2),'type','spearman');
%             [b,rstats] = robustfit(all_means{nT}(:,1),all_means{nT}(:,2));
% %     plot(xlim,xlim.*b(2)+b(1),'Color',[1 1 1]*.5,'LineWidth',2);
%     patchX=[0 5];
%     patchY=[xlim.*(b(2)-rstats.se(2))+(b(1)-rstats.se(1)) xlim.*(b(2)+rstats.se(2))+(b(1)+rstats.se(1))];
%     patch([patchX patchX(2) patchX(1) patchX(1)],...
%         [patchY(1:2) patchY(4) patchY(3) patchY(1)],[1 1 1]*.5,'FaceAlpha',0.5,'EdgeColor',[1 1 1]*.5);
    fprintf('... correlation between clarity and reconstruction on 2nd presentation: r= %g, p=%g\n',r, pV)

    format_fig;
    xlabel('Clarity'); xlim([.8 4.2]); set(gca,'XTick',1:4);
    ylabel('Rec'); %
    set(gca,'LineWidth',2,'XColor','k');
           set(gca,'FontSize',24)
           if nT==1
           ylim([-0.0800    0.22])
                         set(gca,'YTick',-0.1:0.05:0.2);

           elseif nT==2
           ylim([-0.0800    0.14])
                         set(gca,'YTick',-0.1:0.05:0.2);
           end
 %     ylim([-0.03 0.12]);
end

export_fig([path_figs filesep 'StimRec_Corr_RecClarity.eps'],'-r 300')