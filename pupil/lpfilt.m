function BP = lowpass(timecourse, SamplingRate, f_cut, filterOrder)
% BP = bandpass(timecourse, SamplingRate, low_cut, high_cut, filterOrder)

if (nargin < 4)
    filterOrder = 2;
end

[b, a] = butter(filterOrder, [(f_cut/SamplingRate)*2],'low');
BP = filtfilt(b, a, timecourse );

 
