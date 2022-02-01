%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

%%
allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};

timwin = [0.5, 3]; % time-window for analysis
nc=0;
for n=1:length(allfiles)
    %%% Loading data
    fprintf('... loading %s\n',allfiles{n})
    load([preproc_path filesep 'TF_nlhie_ft_SWSNVS' allfiles{n}]);
    nc=nc+1;
    for nStim=1:2
        for nCond=1:3
            for nRep=1:2                   
                TFR{nRep,nStim,nCond} = TFR{nRep,nStim,nCond}(:,:,:,time>=timwin(1) & time<=timwin(2));
                av_TFR{nRep,nStim,nCond}(nc,:,:) = squeeze(log10(mean(mean(TFR{nRep,nStim,nCond},4),1)));                                   
            end
        end
    end
end


%% cluster permutation
cfg = [];
cfg.elec             = ft_read_sens(path_chanlocs);
cfg.channel          = 'all';
cfg.frequency        = [1,30];
cfg.avgoverchan      = 'no';
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.025;
cfg.numrandomization = 1000;
% prepare_neighbours determines what sensors may form clusters
cfg_neighb.method    = 'distance';
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, cfg.elec);

% design
nLev            = 2;
subjs           = repmat(1:nc,1,nLev);
conds           = repmat(1:nLev, nc, 1);
cfg.design      = [subjs; conds(:)'];
cfg.uvar        = 1;
cfg.ivar        = 2;

% create contrasts
TF.elec = cfg.elec;
TF.label = label;
TF.dimord = 'subj_chan_freq';
TF.freq = freq;
TF1 = TF;    TF2 = TF;
for nStim = 1:2
    for nCond = 1:3
        TF1.powspctrm = av_TFR{1,nStim,nCond};  % Rep1
        TF2.powspctrm = av_TFR{2,nStim,nCond};  % Rep2
         
        % R2-R1 contrast for interactions
        diffRep{nStim, nCond} = TF2.powspctrm - TF1.powspctrm;
    end
end

% pairwise Cond & Rep2-Rep1 by Stim
for nStim = 1:2
    
    TF1.powspctrm = diffRep{nStim,1};
    TF2.powspctrm = diffRep{nStim,2};    
    diffCond{nStim, 1} = ft_freqstatistics(cfg, TF1, TF2);
    
    TF1.powspctrm = diffRep{nStim,1};
    TF2.powspctrm = diffRep{nStim,3};    
    diffCond{nStim, 2} = ft_freqstatistics(cfg, TF1, TF2);
    
    TF1.powspctrm = diffRep{nStim,2};
    TF2.powspctrm = diffRep{nStim,3};    
    diffCond{nStim, 3} = ft_freqstatistics(cfg, TF1, TF2);
    
end

%% plot Figure 3B
addpath(path_figs)
cm = dlmread('brewermapOrRd');

if exist(path_eeglab, 'dir')
    addpath(genpath(path_eeglab))
    load eeglab_chanlocs
    chans = chanlocs(find(ismember({chanlocs.labels}, label)));
else
    warning('Unable to load chanlocs')
    cfg = [];
    cfg.parameter = 'mask';
    cfg.cm = cm;
end

% contrasts for plotting (vs. P0)
Ctrst = { 'P+ vs. P0'; 'P- vs. P0'; 'P+ vs. P0' };

% plot power contrast with channels marked
frx = 10:15;
spex =  {   1, 2, frx;
            1, 3, frx;
            2, 2, frx  };
        
figure; set(gcf,'units','centimeters', 'Position', [1 1 25.5 8])      
try
    ax = tight_subplot(1,3,[.01 .01]);
catch
    warning('Consider downloading `tight_subplot` function from MATLAB Central')
end

for sx = 1:size(spex, 1)
    try
        axes(ax(sx))
    catch
        ax(sx) = subplot(1,3,sx);
    end
    try
        mu_p = mean(diffCond{spex{sx,1}, spex{sx,2}}.mask(:,spex{sx,3}),2);
        topoplot(mu_p, chans, 'colormap', cm, 'whitebk', 'on', 'shading', 'flat' ); 

    catch % use fieldtrip function
        cfg.xlim = [spex{sx,3}(1), spex{sx,3}(end)];
        ft_topoplotTFR(cfg, diffCond{spex{sx,1},spex{sx,2}});

    end
    caxis([0 1])
    format_fig
    title(['\color[rgb]{',num2str(ColorStim(spex{sx,1},:)),'}', StimCat{spex{sx,1}},...
        ' ','\color{black}', Ctrst{sx}], 'FontSize', 24, 'FontWeight', 'Bold', 'interpreter', 'tex')
end

% Get positions of all the subplot
posa = get(ax,'position');
h    = colorbar('Ticks',[0,.2,.4,.6,.8,1], 'TickLabels',{'0','.2','.4','.6','.8','1'}, 'LineWidth', 1.5);
ylabel(h, '{\it P} (inclusion)', 'rotation',270, 'VerticalAlignment','bottom', 'FontSize', 20);
% Reset ax(3) position to before colorbar
set(ax(3),'position',posa{3})
% Set everything to units pixels (avoids dynamic reposition)
set(ax,'units','pix')
% Widen figure by a factor of 1.1 (tweak it for needs)
posf = get(gcf,'position');
set(gcf,'position',[posf(1:2) posf(3)*1.1 posf(4)*1.1])

% export
try
    export_fig( [path_figs filesep 'fig3B.png'] )
catch
    hgexport(gcf, [path_figs filesep 'fig3B'], hgexport('factorystyle'), 'Format', 'png'); 
end

rmpath(genpath(path_eeglab))
