function [trl, event] = wsws_trialfun_train(cfg)

% triggers
load(cfg.triggerfile)
% behav
load(cfg.behavfile)

event=[];
trl=[];
nTr=1;
if ~isempty(findstr(cfg.triggerfile,'S416'))
    trl(nTr, :) = [round([Trai_onset(1)-cfg.trialdef.prestim*cfg.Fs cfg.nSamples -cfg.trialdef.prestim*cfg.Fs])];
else
    trl(nTr, :) = [round([Trai_onset(1)-cfg.trialdef.prestim*cfg.Fs Trai_onset(2)+cfg.trialdef.poststim*cfg.Fs -cfg.trialdef.prestim*cfg.Fs])];
end
event(nTr).type='training';
event(nTr).value='training';%sprintf('Stim%g_Pair%g_Type%g',thisStim,thisPair,thisType);
event(nTr).sample=Stim_onset(nTr,4);
