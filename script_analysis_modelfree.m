
%% Load data and perform simple first-level analyses
%
%  This cell performs simple analyses: the reversal curves and the repetition
%  curves, for each subject and condition. It also creates a massive data array
%  storing the data of all subjects and conditions, such that empirical group-
%  wise priors for model parameters (next cell) can be easily computed.

% clear MATLAB workspace
clear all
close all
clc

tasktype = 'taskid'; % task type (taskid or tasknu)
blcktype = 'test'; % block type (test or prac)

% list of block indices to be analyzed
switch blcktype
    case 'test', blcklist = [2,3,5,6]; % test blocks
    case 'prac', blcklist = [1,4]; % practice blocks
    otherwise, error('Undefined block type!');
end

% list of healthy controls
ctrllist = [ ...
    04,08,10,12,15,20,21,22,24,25, ...
    26,27,29,30,33,34,35,36,37,38, ...
    45,46,47,48,50,52,54,56,57,59, ...
    62,63,65,96];

% list of GTS patients
ptntlist = [ ...
    01,02,03,05,06,07,09,11,13,14, ...
    16,17,18,23,28,31,32,39,40,41, ...
    42,43,44,49,51,53,55,58,60,61, ...
    64,66,67,68,69,70,71,72,73,74, ...
    75,76,77,78,79,80,81,82,83,84, ...
    85,86,87,88,89,90,91,92,93,94, ...
    95,97];

% sublist of medicated patients
ptntlist_med = [ ...
    01,02,03,05,07,09,11,17,18,28, ...
    32,39,40,42,51,61,74,77,78,79, ...
    81,82,83,88,89,91];

% sublist of patients with Obsessive-Compulsive Disorder (OCD)
ptntlist_ocd = [ ...
    02,03,05,07,13,17,32,42,51,53, ...
    55,58,68,71,73,83,85,86,87,89];

% sublist of patients with Generalized Anxiety Disorder (GAD)
ptntlist_gad = [ ...
    05,13,14,17,32,42,60,67,68,77, ...
    79,80,83,85,86,87,89];

% Yale Global Tic Severity Scale (YGTSS)
% 1/ total tic severity score (over 50)
ygtss50 = [ ... % not measured for healthy controls
    08,08,20,00,19,19,15,00,18,00, ...
    25,00,12,25,00,17,08,11,09,00, ...
    00,00,14,00,00,00,00,10,00,00, ...
    23,09,00,00,00,00,00,00,16,22, ...
    26,11,05,03,00,00,00,00,15,00, ...
    20,00,06,00,30,00,00,14,00,06, ...
    14,00,00,26,00,20,12,04,12,06, ...
    08,18,26,28,28,20,18,19,19,18, ...
    17,26,10,17,10,08,08,28,16,15, ...
    23,17,09,23,22,00,24];
% 2/ total tic severity score + impairment (over 100)
ygtss100 = [ ... % not measured for healthy controls
    08,08,30,00,39,29,35,00,28,00, ...
    35,00,32,35,00,47,28,21,09,00, ...
    00,00,24,00,00,00,00,20,00,00, ...
    43,09,00,00,00,00,00,00,26,52, ...
    56,31,15,03,00,00,00,00,35,00, ...
    50,00,26,00,60,00,00,34,00,16, ...
    44,00,00,36,00,50,32,04,12,16, ...
    28,38,36,58,38,30,18,29,29,28, ...
    27,46,20,37,10,18,08,38,26,15, ...
    33,47,09,33,32,00,44];

% list of all subjects (controls and patients)
subjlist = sort([ctrllist,ptntlist]);
nsubj = numel(subjlist);

% subject type
subjtype = nan(size(subjlist));
subjtype(ismember(subjlist,ctrllist)) = 0; % healthy control
subjtype(ismember(subjlist,ptntlist)) = 1; % GTS patient

% filter YGTSS scores
ygtss50 = ygtss50(subjlist);
ygtss100 = ygtss100(subjlist);

% identify data folder
foldname = '../Data';
d = dir(foldname);

% columnize array
col = @(x)x(:);

% create big data array
dat      = [];
dat.subj = []; % subject number
dat.task = []; % task condition (1:Cb 2:Ob)
dat.esum = []; % log-odds of current sequence (>0:consistent <0:inconsistent)
dat.rept = []; % response repetition after current sequence? (1:repeat 0:switch)
dat.raft = []; % response given after current sequence (1:left 2:right)
dat.rbef = []; % response given before current sequence
dat.taft = []; % response time after current sequence (s)

for isubj = 1:nsubj 
    % locate and load datafile
    filename = [];
    for ifile = 1:length(d)
        s = sscanf(d(ifile).name,'ACTOBS_S%02d');
        if numel(s) == 1 && s == subjlist(isubj)
            filename = sprintf('../Data/%s',d(ifile).name);
            break
        end
    end
    if isempty(filename)
        error('Could not find data!');
    end
    load(filename);
    disp(filename);
    
    % load data
    blkind = []; % block index within experiment
    seqind = []; % sequence index within current block
    epinum = []; % episode number within current block
    seqpos = []; % sequence position within current episode
    taskid = []; % task identifier (1:Cb 2:Ob)
    tasknu = []; % task number (1:1st 2:2nd)
    seqdir = []; % generative direction of current sequence (1:left 2:right)
    seqllr = []; % log-odds of current sequence (>0:leftwards <0:rightwards)
    befllr = []; % log-odds of previous sequence
    seqlen = []; % sequence length
    raft   = []; % response given after current sequence (1:left 2:right)
    rbef   = []; % response given before current sequence
    taft   = []; % response time after current sequence
    jblck  = 0;
    for iblck = blcklist
        jblck = jblck+1;
        nseq = numel(expe.blck(iblck).seqdir);
        ncor = sum(expe.blck(iblck).seqdir == expe.rslt(iblck).resp(2:end));
        if strcmp(blcktype,'test')
            % check whether subject likely used flipped response mapping...
            if binocdf(ncor,nseq,0.5) < 0.05
                % ...in which case correct by flipping responses
                expe.rslt(iblck).resp = 3-expe.rslt(iblck).resp;
                pcor_blck(isubj,jblck) = 1-ncor/nseq;
                fprintf('    flipped responses for block %d!\n',jblck);
            else
                pcor_blck(isubj,jblck) = ncor/nseq;
            end
        end
        % append block information
        blkind = cat(2,blkind,jblck*ones(1,nseq));
        epinum = cat(2,epinum,expe.blck(iblck).epinum);
        seqpos = cat(2,seqpos,expe.blck(iblck).epipos);
        taskid = cat(2,taskid,expe.blck(iblck).taskid(ones(1,nseq)));
        switch blcktype
            case 'test', tasknu = cat(2,tasknu,ceil(jblck/2)*ones(1,nseq));
            case 'prac', tasknu = cat(2,tasknu,jblck*ones(1,nseq));
        end
        seqind = cat(2,seqind,(1:nseq));
        seqdir = cat(2,seqdir,expe.blck(iblck).seqdir);
        seqllr = cat(2,seqllr,expe.blck(iblck).seqllr);
        befllr = cat(2,befllr,nan,expe.blck(iblck).seqllr(1:end-1));
        seqlen = cat(2,seqlen,expe.blck(iblck).seqlen);
        raft   = cat(2,raft,expe.rslt(iblck).resp(2:end));
        rbef   = cat(2,rbef,expe.rslt(iblck).resp(1:end-1));
        taft   = cat(2,taft,expe.rslt(iblck).rt(2:end));
    end
    
    for itask = 1:2
        
        % define task type
        switch tasktype
            case 'taskid', task = taskid; % task identifier (Cb/Ob)
            case 'tasknu', task = tasknu; % task number (1st/2nd)
            otherwise, error('Undefined task type!');
        end
        
        % filter trials of interest
        ifilt = (task == itask); % include task of interest
        jfilt = ifilt & seqind > 1; % exclude first trial of each block
        nfilt = nnz(jfilt);
        
        % compute accuracy information
        pcor_task(isubj,itask) = mean(raft(ifilt) == seqdir(ifilt)); % p(correct)
        ncor_task(isubj,itask) = nnz(raft(ifilt) == seqdir(ifilt)); % n(correct)
        ntot_task(isubj,itask) = nnz(ifilt); % n(total)
        
        % update big data array
        dat.subj = cat(1,dat.subj,subjlist(isubj)*ones(nfilt,1));
        dat.task = cat(1,dat.task,itask*ones(nfilt,1));
        dat.esum = cat(1,dat.esum,col(seqllr(jfilt).*(3-2*rbef(jfilt))));
        dat.rept = cat(1,dat.rept,col(raft(jfilt) == rbef(jfilt)));
        dat.raft = cat(1,dat.raft,col(raft(jfilt)));
        dat.rbef = cat(1,dat.rbef,col(rbef(jfilt)));
        dat.taft = cat(1,dat.taft,col(taft(jfilt)));

        % compute repeat curves
        x = col(seqllr(jfilt).*(3-2*rbef(jfilt)));
        y = col(raft(jfilt) == rbef(jfilt));
        t = col(taft(jfilt));
        xmin = [-inf,  -2,  -1,   0,  +1,  +2];
        xmax = [  -2,  -1,   0,  +1,  +2,+inf];
        nbin = numel(xmax);
        for i = 1:nbin
            kfilt = x > xmin(i) & x < xmax(i);
            prept(isubj,i,itask) = mean(y(kfilt));
        end
        
        % compute reversal curves
        i = find(epinum(ifilt) > 1 & seqpos(ifilt) == 1);
        sdir = seqdir(ifilt);
        rsup = raft(ifilt);
        rsub = [];
        for j = 1:length(i)
            k = i(j)+(-4:+3);
            if sdir(i(j)) == 1
                rsub = cat(1,rsub,rsup(k) == 1);
            else
                rsub = cat(1,rsub,rsup(k) == 2);
            end
        end
        prvrs(isubj,:,itask) = mean(rsub,1);
        
    end
    
end

%%

isubj = ismember(subjlist,ctrllist);
pctrl = squeeze(mean(prvrs(isubj,:,:),1));

isubj = ismember(subjlist,setdiff(ptntlist,ptntlist_gad));
pptnt_woocd = squeeze(mean(prvrs(isubj,:,:),1));

isubj = ismember(subjlist,ptntlist_gad);
pptnt_wtocd = squeeze(mean(prvrs(isubj,:,:),1));

figure;
hold on
ylim([0.1,0.9]);
plot(pctrl(:,1),'b--');
plot(pptnt_woocd(:,1),'bx-','MarkerSize',12);
plot(pptnt_wtocd(:,1),'bo-','MarkerSize',12,'MarkerFaceColor','b');
hold off

figure;
hold on
ylim([0.1,0.9]);
plot(pctrl(:,2),'r--');
plot(pptnt_woocd(:,2),'rx-','MarkerSize',12);
plot(pptnt_wtocd(:,2),'ro-','MarkerSize',12,'MarkerFaceColor','r');
hold off

%%

isubj = ismember(subjlist,ctrllist);
pctrl = squeeze(mean(prept(isubj,:,:),1));

isubj = ismember(subjlist,setdiff(ptntlist,ptntlist_gad));
pptnt_woocd = squeeze(mean(prept(isubj,:,:),1));

isubj = ismember(subjlist,ptntlist_gad);
pptnt_wtocd = squeeze(mean(prept(isubj,:,:),1));

figure;
hold on
ylim([0,1]);
plot(pctrl(:,1),'b--');
plot(pptnt_woocd(:,1),'bx-','MarkerSize',12);
plot(pptnt_wtocd(:,1),'bo-','MarkerSize',12,'MarkerFaceColor','b');
hold off

figure;
hold on
ylim([0,1]);
plot(pctrl(:,2),'r--');
plot(pptnt_woocd(:,2),'rx-','MarkerSize',12);
plot(pptnt_wtocd(:,2),'ro-','MarkerSize',12,'MarkerFaceColor','r');
hold off

%%

isubjctrl = 1*ismember(subjlist,ctrllist);
isubjptntgts_ocd = 2*ismember(subjlist,setdiff(ptntlist,ptntlist_ocd));
isubjptntgts = 3*ismember(subjlist,ptntlist_ocd);


datamat = prvrs; % subject x position x task (#1 = Cb, #2 = Ob)
databtw = col(isubjctrl + isubjptntgts + isubjptntgtsocd); % #1 = Ctrl, #2 = GTS, #3 = GTS+OCD
[tbl,rm] = simple_mixed_anova(datamat,databtw,{'position', 'task'},{'group'});

writetable(tbl,'simple_anova_posxtaskxgp')

%%

isubjctrl = 1*ismember(subjlist,ctrllist);
isubjptntgtsocd = 2*ismember(subjlist,setdiff(ptntlist,ptntlist_ocd));
isubjptntgts = 3*ismember(subjlist,ptntlist_ocd);

datamat = prept; % subject x position x task (#1 = Cb, #2 = Ob)
databtw = col(isubjctrl + isubjptntgts + isubjptntgtsocd); % #1 = Ctrl, #2 = GTS, #3 = GTS+OCD
[tbl,rm] = simple_mixed_anova(datamat,databtw,{'information', 'task'},{'group'});

csvwrite('simple_anova_infoxtaskxgp.csv', tbl)



