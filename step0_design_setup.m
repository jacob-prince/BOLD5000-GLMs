
%%

close all; clear; clc;

%%

homedir = '/media/tarrlab/scenedata2/BOLD5000_GLMs/git/';
cd(homedir)

addpath(genpath('GLMdenoise'))
addpath(genpath('vistasoft'))
addpath(genpath('knkutils'))
addpath(genpath('fracridge'))

%% hyperparameters

subj = 'CSI2';

% define
sessionstorun = [1:15];
stimdur = 1;
tr = 2;

nses = 15;
runimgs = 37;

method = 'kendrick_pipeline_v1';

dataset = 'BOLD5000';
basedir = fullfile('/media','tarrlab','scenedata2');
eventdir = fullfile(basedir,'5000_BIDS',['sub-' subj]);
datadir = fullfile(basedir,'5000_BIDS','derivatives','fmriprep',['sub-' subj]);
savedir = fullfile(homedir);

%%

allses_events = [];


ses_event_table = [];

ses_nruns = [];

for ses = sessionstorun
    
    
    absolute_run = 1;
    
    if ses < 10
        sesstr = ['0' num2str(ses)];
    else
        sesstr = num2str(ses);
    end
    
    disp(['loading session ' sesstr])
    
    subeventdir = fullfile(eventdir,['ses-' sesstr],'func');
    
    eventfiles = struct2table(dir(subeventdir));
    eventfiles = eventfiles(~eventfiles.isdir,:).name;
    eventfiles = eventfiles(contains(eventfiles,'events.tsv') & ~contains(eventfiles,'localizer'));
    
    ses_nruns(ses) = length(eventfiles);
    
    events = cell(1,length(eventfiles));
    design = cell(1,length(eventfiles));
    
    nconditions = runimgs * length(design);
    
    for i = 1:length(eventfiles)
        
        % load event info, compute onset TRs
        rundur = 194; %size(events{i},4);
        events{i} = tdfread(fullfile(subeventdir,eventfiles{i}));
        events{i}.ImgType = cell(size(events{i}.ImgType,1),1);
        ses_event_table = [ses_event_table; struct2table(events{i})];
        onsetTRs = round(events{i}.onset./tr)+1;
        
        % for now, treat each image as its own condition
        conds = events{i}.Trial + (runimgs * (absolute_run-1));
        
        % sanity
        assert(length(onsetTRs) == length(conds))
        
        % populate design matrix for that run
        design{i} = sparse(rundur, nconditions);
        
        for j = 1:runimgs
            design{i}(onsetTRs(j), conds(j)) = 1; % important, for single trial every entry gets its cond
        end
        
        absolute_run = absolute_run + 1;
        
    end
    
    tmp = [];
    for k = 1:length(events)
        tmp = [tmp; events{k}.ImgName];
    end
    
    allses_events{ses} = tmp;
    
end


%%

reps = zeros(size(ses_event_table,1),1);
idx = 1;
labels = zeros(size(ses_event_table,1),1);
seen_imgs = {};

for i = 1:size(ses_event_table,1)
    
    curr = ses_event_table(i,:).ImgName;
    
    if i > 1 && ismember(curr,seen_imgs)
        repidx = find(ismember(seen_imgs,curr),1);
        labels(i) = repidx;
        reps(repidx) = reps(repidx) + 1;
    else
        labels(i) = idx;
        reps(idx) = reps(idx) + 1;
        idx = idx + 1;          
    end
    
    if i == 1
        seen_imgs = {curr};
    else
        seen_imgs = [seen_imgs; curr];
    end
   
end

%%

allses_design = [];

for ses = sessionstorun
    
    output_design = [];
    
    n = ses_nruns(ses);
    
    for i = 1:n
        
        runidx = ses_event_table.Sess == ses & ses_event_table.Run == i;
        
        conds = labels(runidx);
        
        % load event info, compute onset TRs
        rundur = 194; %size(events{i},4);
        
        onsetTRs = round(ses_event_table(runidx,:).onset./tr)+1;
        
        % sanity
        assert(length(onsetTRs) == length(conds))
        
        % populate design matrix for that run
        output_design{i} = sparse(rundur, length(unique(labels)));
        
        for j = 1:length(conds)
            output_design{i}(onsetTRs(j), conds(j)) = 1; % important, for single trial every entry gets its cond
        end
        
    end
    
    allses_design{ses} = output_design;
    
end
