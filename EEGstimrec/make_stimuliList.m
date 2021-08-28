%%
PairStrings='AB';
audioTypes={'SWS.wav','_voc_6Bds.wav'};
stimlist_filename=[stim_path filesep 'list_stimuli_102018.csv'];
delimiter = ',';
formatSpec = '%q%q%q%q%q%q%[^\n\r]';
fileID = fopen(stimlist_filename,'r','n','UTF-8');
if ~ismac
    StimList = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'ReturnOnError', false);
elseif ismac
    StimList = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);
end
fclose(fileID);
for nL=1:5
    for nSt=1:16
        for nPair=1:2
            find_idx=intersect(match_str(StimList{2},sprintf('L%g',nL)),match_str(StimList{3},sprintf('%g',nSt)));
            find_idx=intersect(find_idx,match_str(StimList{4},sprintf('%s',PairStrings(nPair))));
            
            if ismac
                text_stimuli{nL,nSt,nPair}=string(StimList{5}{find_idx});
                code_stimuli{nL,nSt,nPair}=StimList{6}(find_idx);
            elseif ispc
                text_stimuli{nL,nSt,nPair}=(StimList{5}{find_idx});
                code_stimuli{nL,nSt,nPair}=StimList{6}{find_idx};
            end
        end
    end
end