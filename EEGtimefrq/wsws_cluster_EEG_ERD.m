%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

%%
load wsws_ERD

elec = ft_read_sens(path_chanlocs);
cfg_neighb          = [];
cfg_neighb.method   = 'distance';
neighbours          = ft_prepare_neighbours(cfg_neighb, elec);

cfg                  = [];
cfg.method           = 'montecarlo'; % use the Monte Carlo Method to calculate the significance probability
cfg.statistic        = 'depsamplesT'; 
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;       % alpha level of the sample-specific test statistic that
                                   % will be used for thresholding
cfg.clusterstatistic = 'maxsum';   % test statistic that will be evaluated under the
                                   % permutation distribution.
cfg.minnbchan        = 2;          % minimum number of neighborhood channels that is
                                   % required for a selected sample to be included
                                   % in the clustering algorithm (default=0).
cfg.neighbours       = neighbours;  % the neighbours specify for each sensor with
                                 % which other sensors it can form clusters
cfg.tail             = 0;          % -1, 1 or 0 (default = 0); one-sided or two-sided test
cfg.clustertail      = 0;
cfg.alpha            = 0.025;      % alpha level of the permutation test
cfg.numrandomization = 1000;        % number of draws from the permutation distribution


Nsubj           = size(ERD{1}, 1);
design          = zeros(2, Nsubj*2);
design(1,:)     = [1:Nsubj 1:Nsubj];
design(2,:)     = [ones(1,Nsubj) ones(1,Nsubj)*2];
cfg.design      = design; % design matrix
cfg.uvar        = 1;
cfg.ivar        = 2; % number or list with indices indicating the independent variable(s)

cfg.channel     = {'all', '-17', '-22'};     % cell-array with selected channel labels
cfg.latency     = [-1 11];    


erd = struct('time', t, 'fsample', fs, 'dimord', 'subj_chan_time', 'elec', elec, 'label', {label} );
pos = erd; neg = erd; zer = erd;
stat = cell(size(ERDi));
for nRep = 2
    for nStim = 1:2
        for nFrq = 3
            
            pos.avg = ERDi{nRep,nStim,1,nFrq};
            neg.avg = ERDi{nRep,nStim,2,nFrq};
            zer.avg = ERDi{nRep,nStim,3,nFrq};

            stat{nRep, nStim, 1, nFrq} = ft_timelockstatistics(cfg, pos, zer );
            stat{nRep, nStim, 2, nFrq} = ft_timelockstatistics(cfg, neg, zer );
            stat{nRep, nStim, 3, nFrq} = ft_timelockstatistics(cfg, pos, neg );

        end
    end
end

%% plot Figure 4A
addpath(path_figs)

nRep = 2;
nFrq = 3;
chans = [23:32, 56:64];     % parieto-occipital electrodes per channel number

figure; set(gcf,'Position',[193   170   408   627])
for nStim = 1:2
    sp = subplot(2,1,nStim);
    for nCond = 1:3
        simpleTplot(t, squeeze( mean(ERDi{nRep,nStim,nCond,nFrq}(:,chans,:), 2) ), 0,ColorCond(nCond,:),0,'-',.3,1,0,[],1);
        hold on
    end
    for ctrst = 1:2
        chan_idx = ismember(str2double(stat{nRep,nStim,ctrst,nFrq}.label), chans);  % channel index in array
        
        pos_cluster_pvals = [stat{nRep,nStim,ctrst,nFrq}.posclusters(:).prob];
        pos_clust = find(pos_cluster_pvals < 0.025);
        pos = sum(ismember(stat{nRep,nStim,ctrst,nFrq}.posclusterslabelmat(chan_idx,:), pos_clust))>0;
        tbins = stat{nRep,nStim,ctrst,nFrq}.time(pos);
        try
            line([tbins(1), tbins(end)], [.6, .6]+ctrst/30, 'LineStyle', '-', 'Color', ColorCond(ctrst,:), 'LineWidth', 2)
        catch
            warning('no significant pos cluster detected for %s contrast #%g', StimCat{nStim}, ctrst)
        end
        neg_cluster_pvals = [stat{nRep,nStim,ctrst,nFrq}.negclusters(:).prob];
        neg_clust = find(neg_cluster_pvals < 0.025);
        neg = sum(ismember(stat{nRep,nStim,ctrst,nFrq}.negclusterslabelmat(chan_idx,:), neg_clust))>0;
        tbins = stat{nRep,nStim,ctrst,nFrq}.time(neg);
        try
            line([tbins(1), tbins(end)], [.6, .6]+ctrst/30, 'LineStyle', '-', 'Color', ColorCond(ctrst,:), 'LineWidth', 2)
        catch
            warning('no significant neg cluster detected for %s contrast #%g', StimCat{nStim}, ctrst)
        end
    end
    line([0,0], [0.5,1.5], 'LineStyle', '--', 'Color', 'k')
    xlim([-1, 10.5])
    ylim([.6 1.3])
    ylabel('Alpha Power')
    title(StimCat{nStim}, 'FontSize', 20, 'FontWeight', 'Bold', 'Color', ColorStim(nStim,:))
    format_fig
    
    % add channel layout
    if nStim == 1
        axes('Position',[.7 .8 .2 .2])
    elseif nStim == 2
        axes('Position',[.7 .3 .2 .2])
    end
    ft_plot_layout(layout, 'chanindx', chans,'pointsymbol','.','pointcolor','k','pointsize',16,'box','no','label','no' )
    format_fig 
end
xlabel('Time (s)')


% export
try
    export_fig( [path_figs filesep 'fig4A.png'] )
catch
    hgexport(gcf, [path_figs filesep 'fig4A'], hgexport('factorystyle'), 'Format', 'png')
end

