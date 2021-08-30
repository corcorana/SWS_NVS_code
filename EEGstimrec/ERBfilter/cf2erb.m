function erb = cf2erb(cf,lowFreq,fs,numChannels);
% function erb = cf2erb(cf,lowFreq,fs,numChannels);

humanfactor = 1;
EarQ = 9.26449*humanfactor;               %  Glasberg and Moore Parameters
minBW = 24.7;

EB =EarQ*minBW;

erbnum = log( (cf+EB)/(fs/2+EB) );
erbden = ( -log(fs/2 + EB) + log(lowFreq + EB))/numChannels;

erb = erbnum/erbden;