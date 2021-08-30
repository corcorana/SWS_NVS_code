function [y,xf,cf,t] = ERBgram_largeFile(x,fs,compress,lowfreq,numchan,smoothcut,resamplefactor)
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

y=nan(size(cf,1),size(x,2)/resamplefactor);
xf=nan(size(cf,1),size(x,2)/resamplefactor);
for nf=1:size(cf,1)
    fprintf('... ... ERBgram: extracting filter %g/%g\n',nf,size(cf,1))
    % erb filtering
    temp_xf = ERBFilterBank2(x,fcoefs(nf,:));
    
    % clean up data
    %y = max(xf,0);
    temp_y= sqrt(temp_xf.^2);
    
    % smoothing
    temp_y = filter(B,A,temp_y');
    temp_y = temp_y';
    
    % compress
    if compress > 0
        temp_y = temp_y.^compress;
    else
        temp_y = log10(max(abs(temp_y),1e-3));
    end
    
    
    t = [0:1:size(temp_y,2)-1]/fs*1000;
    
    y(nf,:)=resample(temp_y,1,resamplefactor);
    xf(nf,:)=resample(temp_xf,1,resamplefactor);
end
