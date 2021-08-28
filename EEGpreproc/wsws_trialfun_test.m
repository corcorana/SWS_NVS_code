function [trl, event] = wsws_trialfun_test(cfg)

% triggers
load(cfg.triggerfile)
% behav
load(cfg.behavfile)

event=[];
trl=[];
begsample_PTB=[];
nc=0;
StimLabels={'SWS','NVS'};
CondLabels={'P+','P-','P0'};

for nTr=1:size(Stim_onset,1)
    thisList=block_conditions(Stim_onset(nTr,1),Stim_onset(nTr,2),5);
    if thisList~=0
        thisStim=block_conditions(Stim_onset(nTr,1),Stim_onset(nTr,2),2);
        thisPair=block_conditions(Stim_onset(nTr,1),Stim_onset(nTr,2),6);
        thisType=block_conditions(Stim_onset(nTr,1),Stim_onset(nTr,2),4);
        thisCond=block_conditions(Stim_onset(nTr,1),Stim_onset(nTr,2),3);
        
        begsample     = Stim_onset(nTr,4) - cfg.trialdef.prestim*cfg.Fs;
        endsample     = Stim_onset(nTr,4) + cfg.trialdef.poststim*cfg.Fs - 1;
        offset        = -cfg.trialdef.prestim*cfg.Fs;
        
        nc=nc+1;
        if Stim_onset(nTr,3)==1
            begsample_PTB(nc)     = block_timeS1(Stim_onset(nTr,1),Stim_onset(nTr,2));
        elseif Stim_onset(nTr,3)==2
            begsample_PTB(nc)     = block_timeS2(Stim_onset(nTr,1),Stim_onset(nTr,2));
        end
        
        trl(nc, :) = [round([begsample endsample offset])];
        event(nc).type=sprintf('%s_%s_%g',StimLabels{thisType},CondLabels{thisCond},Stim_onset(nTr,3));
        event(nc).value=sprintf('Block%g_Stim%g_Pres%g_List%g_StID%g_Pair%g_Type%g',Stim_onset(nTr,1),Stim_onset(nTr,2),Stim_onset(nTr,3),thisList,thisStim,thisPair,thisType);%sprintf('Stim%g_Pair%g_Type%g',thisStim,thisPair,thisType);
        event(nc).sample=Stim_onset(nTr,4);
    end
end
fprintf('mean abs ISI difference %g s (min: %g | max: %g)\n',mean(abs(diff(begsample_PTB')-diff(trl(:,1)+trl(:,3))/500)),min((diff(begsample_PTB')-diff(trl(:,1)+trl(:,3))/500)),max((diff(begsample_PTB')-diff(trl(:,1)+trl(:,3))/500)))
