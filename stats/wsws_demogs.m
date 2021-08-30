%%
clear all
close all
run(['..' filesep 'def_local'])

allfiles={'405','406','407','408','409','410','411','412','413','414','415',...
    '416','417','418','419','420','421','422','423','424','425'};

age = nan(1, length(allfiles));
gen = cell(1, length(allfiles));
for n=1:length(allfiles)
    %%% Loading data
    fprintf('... loading %s\n',allfiles{n})
    behav_name=dir([behav_path filesep 'SWS_NVS_results_S' allfiles{n} '*.mat']);
    load([behav_path filesep behav_name.name])

    age(n) = str2double(subjectAge);
    gen{n} = subjectGender;

end

table(mean(age), std(age), min(age), max(age), sum(ismember(upper(gen), 'F')), sum(ismember(gen, 'M')),...
    'VariableNames', {'mean age' 'sd age' 'min age' 'max age' 'n female' 'n male'})

