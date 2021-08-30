function [fcoefs,cf]=MakeERBFilters2(fs,numChannels,lowFreq)
% function [fcoefs]=MakeERBFilters(fs,numChannels,lowFreq)
% This function computes the filter coefficients for a bank of 
% Gammatone filters.  These filters were defined by Patterson and 
% Holdworth for simulating the cochlea.  
% 
% The result is returned as an array of filter coefficients.  Each row 
% of the filter arrays contains the coefficients for four second order 
% filters.  The transfer function for these four filters share the same
% denominator (poles) but have different numerators (zeros).  All of these
% coefficients are assembled into one vector that the ERBFilterBank 
% can take apart to implement the filter.
%
% The filter bank contains "numChannels" channels that extend from
% half the sampling rate (fs) to "lowFreq".

% Note this implementation fixes a problem in the original code by
% computing four separate second order filters.  This avoids a big
% problem with round off errors in cases of very small cfs (100Hz) and
% large sample rates (44kHz).  The problem is caused by roundoff error
% when a number of poles are combined, all very close to the unit
% circle.  Small errors in the eigth order coefficient, are multiplied
% when the eigth root is taken to give the pole location.  These small
% errors lead to poles outside the unit circle and instability.  Thanks
% to Julius Smith for leading me to the proper explanation.

% Execute the following code to evaluate the frequency
% response of a 10 channel filterbank.
%	fcoefs = MakeERBFilters(16000,10,100);
%	y = ERBFilterBank([1 zeros(1,511)], fcoefs);
%	resp = 20*log10(abs(fft(y')));
%	freqScale = (0:511)/512*16000;
%	semilogx(freqScale(1:255),resp(1:255,:));
%	axis([100 16000 -60 0])
%	xlabel('Frequency (Hz)'); ylabel('Filter Response (dB)');

% Rewritten by Malcolm Slaney@Interval.  June 11, 1998.
% (c) 1998 Interval Research Corporation  

T = 1/fs;
% Change the following parameters if you wish to use a different
% ERB scale.
humanfactor = 1;
EarQ = 9.26449*humanfactor;               %  Glasberg and Moore Parameters
minBW = 24.7;
order = 1;

% All of the following expressions are derived in Apple TR #35, "An
% Efficient Implementation of the Patterson-Holdsworth Cochlear
% Filter Bank."  See pages 33-34.
cf = -(EarQ*minBW) + exp((1:numChannels)'*(-log(fs/2 + EarQ*minBW) + ...
                            log(lowFreq + EarQ*minBW))/numChannels) ...
                          *(fs/2 + EarQ*minBW);
ERB = ((cf/EarQ).^order + minBW^order).^(1/order);
B=1.019*2*pi*ERB;

A0 = T;
A2 = 0;
B0 = 1;
B1 = -2*cos(2*cf*pi*T)./exp(B*T);
B2 = exp(-2*B*T);

A11 = -(2*T*cos(2*cf*pi*T)./exp(B*T) + 2*sqrt(3+2^1.5)*T*sin(2*cf*pi*T)./exp(B*T))/2;
A12 = -(2*T*cos(2*cf*pi*T)./exp(B*T) - 2*sqrt(3+2^1.5)*T*sin(2*cf*pi*T)./exp(B*T))/2;
A13 = -(2*T*cos(2*cf*pi*T)./exp(B*T) + 2*sqrt(3-2^1.5)*T*sin(2*cf*pi*T)./exp(B*T))/2;
A14 = -(2*T*cos(2*cf*pi*T)./exp(B*T) - 2*sqrt(3-2^1.5)*T*sin(2*cf*pi*T)./exp(B*T))/2;

gain = abs((-2*exp(4*i*cf*pi*T)*T + ...
                 2*exp(-(B*T) + 2*i*cf*pi*T).*T.* ...
                         (cos(2*cf*pi*T) - sqrt(3 - 2^(3/2))* ...
                          sin(2*cf*pi*T))) .* ...
           (-2*exp(4*i*cf*pi*T)*T + ...
             2*exp(-(B*T) + 2*i*cf*pi*T).*T.* ...
              (cos(2*cf*pi*T) + sqrt(3 - 2^(3/2)) * ...
               sin(2*cf*pi*T))).* ...
           (-2*exp(4*i*cf*pi*T)*T + ...
             2*exp(-(B*T) + 2*i*cf*pi*T).*T.* ...
              (cos(2*cf*pi*T) - ...
               sqrt(3 + 2^(3/2))*sin(2*cf*pi*T))) .* ...
           (-2*exp(4*i*cf*pi*T)*T + 2*exp(-(B*T) + 2*i*cf*pi*T).*T.* ...
           (cos(2*cf*pi*T) + sqrt(3 + 2^(3/2))*sin(2*cf*pi*T))) ./ ...
          (-2 ./ exp(2*B*T) - 2*exp(4*i*cf*pi*T) +  ...
           2*(1 + exp(4*i*cf*pi*T))./exp(B*T)).^4);
	
allfilts = ones(length(cf),1);
fcoefs = [A0*allfilts A11 A12 A13 A14 A2*allfilts B0*allfilts B1 B2 gain];


if (0)						% Test Code
  A0  = fcoefs(:,1);
  A11 = fcoefs(:,2);
  A12 = fcoefs(:,3);
  A13 = fcoefs(:,4);
  A14 = fcoefs(:,5);
  A2  = fcoefs(:,6);
  B0  = fcoefs(:,7);
  B1  = fcoefs(:,8);
  B2  = fcoefs(:,9);
  gain= fcoefs(:,10);	
  clf
  hold on
  for chan = 1: size(gain,1)
    x = [1 zeros(1, 2047)];
    y1=filter([A0(chan)/gain(chan) A11(chan)/gain(chan) A2(chan)/gain(chan)],[B0(chan) B1(chan) B2(chan)], x);
    y2=filter([A0(chan) A12(chan) A2(chan)],[B0(chan) B1(chan) B2(chan)], y1);
    y3=filter([A0(chan) A13(chan) A2(chan)],[B0(chan) B1(chan) B2(chan)], y2);
    y4=filter([A0(chan) A14(chan) A2(chan)],[B0(chan) B1(chan) B2(chan)], y3);
    % semilogx((0:(length(x)-1))*(fs/length(x)),20*log10(abs(fft(y4))));
    figure(1)
    cleanfft(y4,fs,'ld');
    % spectrum(y4,2048,0,2048,fs)
    % freqz(y4)
    figure(2)
    plot(y4)
    pause
  end

end

