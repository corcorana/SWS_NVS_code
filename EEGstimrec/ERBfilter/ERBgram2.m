function [y,xf,cf,t] = ERBgram2(x,fs,compress,lowfreq,numchan,smoothcut,envcut,toPlot)
% function [y,xf,cf] = ERBgram2(x,fs,compress,lowfreq,numchan,smoothcut,envcut,toPlot)
% Plots a gammatone filterbank output of signal x, plus marginal spectrum
% and envelope.
% fs: sampling frequency [default 44100]
% compress: apply compression [0.5]. If negative, log compression
% lowfreq: lowest centre frequency in the filterbank [100]
% numchan: number of channels [128]
% smoothcut: the lowpass filter for the display [100]
% envcut: the lowpass filter for the broadband envelope [100]
% toPlot: plot the result? [1]

    
if nargin < 8
  toPlot = 1;
end

if nargin < 7
  envcut = 100;
end

if nargin < 6
  smoothcut = 100;
end

if nargin < 5
  numchan = 128;
end

if nargin < 4
  lowfreq = 100;
end

if nargin < 3
  compress = 0.5;
end

if nargin < 2
  fs = 44100;
end

% external middle ear
[Bext,Aext] = butter(1,[400 8500]*2/fs);
x = filter(Bext,Aext,x);

% compute coefs
[fcoefs,cf] = MakeERBFilters2(fs,numchan,lowfreq);
[B,A] = butter(2,smoothcut*2/fs);


% erb filtering
xf = ERBFilterBank2(x,fcoefs);

% clean up data
%y = max(xf,0);
y= sqrt(xf.^2);

% smoothing
y = filter(B,A,y');
y = y';

% compress
if compress > 0
    y = y.^compress;
else
    y = log10(max(abs(y),1e-3));
end


    t = [0:1:size(y,2)-1]/fs*1000;
if toPlot
    %lastcf = round(cf2erb(16000,lowfreq,fs,numchan));
    lastcf = 1;
    clf
 
    % build time axis
    %  imagesc(t,[1:1:length(cf)],20*log10(y))
    axgram = axes('position',[0.14 0.14 0.7 0.7]);
    imagesc(t,[1:1:length(cf)],y); % plot compressed version
    f = [100 1000 10000];
    fticks = cf2erb(f,lowfreq,fs,numchan);
    [fticks,ifticks] = sort(fticks);
%     set(gca,'ydir','normal');
    set(gca,'ytick',fticks);
    set(gca,'yticklabel',f(ifticks)/1000);
    set(gca,'fontsize',18)
    xlabel('Time (ms)');
    ylabel('Centre Frequency (kHz)')
    axis([0 Inf lastcf length(cf)])
    
    
    axep = axes('position',[0.84 0.14 0.15 0.7]);
    set(gca,'box','off')
    if compress < 0
        yep = abs(y-min(min(y))); % add the logs for ep
        ep =sum(yep,2);               
    else
        ep =sum(y,2);               
    end
    
    plot(ep,[numchan:-1:1],'k','linewidth', 1.5);
    set(gca,'xtick',[]);
    set(gca,'ytick',[]);
    axis([0 Inf lastcf length(ep)])
  
    axenv = axes('position',[0.14 0.84 0.7 0.15]);
    set(gca,'box','off')
    [Benv,Aenv] = butter(2,envcut*2/fs);

   env = filter(Benv,Aenv,max(x,0));
   %  env = sum(y,1);
   plot(env,'linewidth', 1.5, 'color','k')
   set(gca,'xtick',[]);
   set(gca,'ytick',[]);
%   axis([1 length(env) 0 axmaxenv])
  
end
