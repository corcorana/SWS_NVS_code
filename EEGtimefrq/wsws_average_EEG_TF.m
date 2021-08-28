%%
clear all
close all

run(['..' filesep 'def_local'])
addpath(path_fieldtrip)
ft_defaults

%%
allfiles={'405','406','407','408','409','410','411','412','413','414','415','416','417','418','419','420','421','422','423'};

nc=0;
for n=1:length(allfiles)
    
    %%% Loading data
    fprintf('... loading %s\n',allfiles{n})
    load([preproc_path filesep 'TF_nlhie_ft_SWSNVS' allfiles{n}]); 
    nc=nc+1;
    for nRep=1:2
        for nStim=1:2
            for nCond=1:3
                av_TFR{nRep,nStim,nCond}(nc,:,:,:)=squeeze(log10(mean(TFR{nRep,nStim,nCond},1))); % average trials & log transform
                Grand_TFR{nRep,nStim,nCond} = squeeze(mean(av_TFR{nRep,nStim,nCond},1));
            end
        end
    end
end

%% plot TFR
addpath(path_figs)

% define colour map
cm = dlmread('brewermapRdBu');

set(gcf,'units','centimeters', 'Position', [1 1 21 9])
for nCond = 1:3
    meanSWS = squeeze(mean(Grand_TFR{2,1,nCond}, 1)) - squeeze(mean(mean(Grand_TFR{1,1,nCond}(:,:, time>=0 & time<=10.5), 1), 3))';
    meanNVS = squeeze(mean(Grand_TFR{2,2,nCond}, 1)) - squeeze(mean(mean(Grand_TFR{1,2,nCond}(:,:, time>=0 & time<=10.5), 1), 3))';
    meanpow = mean(cat(3, meanSWS, meanNVS), 3);

    % finer time/frequency axes
    tim_interp = time(time>=-1 & time<=11);
    Grand_TFR_interp = linspace(freq(1), freq(end), length(tim_interp));

    % make a time/frequency grid of both the original and interpolated coordinates
    [tim_grid_orig, Grand_TFR_grid_orig] = meshgrid(time, freq);
    [tim_grid_interp, Grand_TFR_grid_interp] = meshgrid(tim_interp, Grand_TFR_interp);

    % interpolate
    pow_interp = interp2(tim_grid_orig, Grand_TFR_grid_orig, meanpow,...
        tim_grid_interp, Grand_TFR_grid_interp, 'spline');

    ax(nCond) = subplot(1,3,nCond);
    imagesc(tim_interp, Grand_TFR_interp, pow_interp);
    hold on;
    line([0, 0], [Grand_TFR_interp(1), Grand_TFR_interp(end)], 'LineStyle', '--', 'Color', 'k')
    axis xy;
    caxis([-.23 .23]);

    title(['\color[rgb]{',num2str(ColorCond(nCond,:)),'}' Conds{nCond}], 'interpreter', 'tex');
    colormap(cm);

    xlim([-1, 10.5]);
    xticks(0:2:10)
    xlabel('Time (s)')
    ylim([Grand_TFR_interp(1) Grand_TFR_interp(end)])
    if nCond == 1
        ylabel('Frequency (Hz)');
    end
    format_fig
end

% run separately after figure rendered (otherwise resizes beyond figure margins)
set(ax,'units','pix')
posa = get(ax,'position');
h    = colorbar('Ticks', -.2:.1:.2, 'TickLabels',{'-.2','-.1','0','.1','.2'}, 'LineWidth', 1.5);
ylabel(h, 'Power (a.u.)', 'rotation',270, 'VerticalAlignment','bottom', 'FontSize', 20);
% Reset ax(3) position to before colorbar
ax(3).Position(3) = posa{3}(3);
% Widen figure by a factor of 1.1 (tweak it for needs)
posf = get(gcf,'position');
set(gcf,'position',[posf(1:2) posf(3)*1.1 posf(4)*1])

% export
try
    export_fig( [path_figs filesep 'fig3A.png'] )
catch
    hgexport(gcf, [path_figs filesep 'fig3A'], hgexport('factorystyle'), 'Format', 'png')
end
close
