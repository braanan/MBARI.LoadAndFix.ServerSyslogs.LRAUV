% run_syslog_LRAUV.m
% Last modified Dec 30, 2014
% Ben Raanan

% This script runs a sequence of scripts designed to create a record of all
% CRITICAL failiures found in smb://atlas.shore.mbari.org/LRAUV/ syslogs


clear 

workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
yr    = 2010:2015;
vh    = { 'Tethys','Daphne','Makai' };

%% Section 1: query server smb://atlas.shore.mbari.org/LRAUV/

% 1) Locate syslog files from server folders and logs thier paths:
find_syslog_LRAUV(vh,yr,workd) 
% Comment: output is saved to: syslog_(vehicle).mat


% 2) Scan syslog files for CRITICAL messeges (updates syslog_(vehicle).mat)
get_syslog_CRITICAL_LRAUV(vh,yr,workd,'fresh')
% Comment: this script (2) takes the longest to run

%% Section 2: process data

% 3) Sort syslog critical faults by component and extract

% time-stamp for each log
process_syslog_CRITICAL_LRAUV(vh,workd)
% Comment: output is saved to syslog_(vehicle)_comp.mat


% 4) Get mission info from .dlist file (smb://atlas.shore.mbari.org/LRAUV/)
syslog_getMissionName_LRAUV(vh,workd)


% 5) Eliminate redundent critical faults and count critical 
% errors by log, mission and component (updates syslog_(vehicle)_comp.mat)
syslog_eliminateRedundant_LRAUV(vh,workd)


% 6) Locate and log "dropping drop weight" critical messages
%    (updates syslog_(vehicle)_comp.mat)
syslog_dropweight_LRAUV(vh,workd)


% 7) Calculate run time and MTBCF for each log and mission 
%    (updates syslog_(vehicle)_comp.mat)
syslog_RunTime_LRAUV(vh,workd)


% 8) Calculate annual TBCF and MTBCF in logs and compute  
% stats for vertical plain critical errors (updates syslog_(year)_comp.mat)
syslog_stats_LRAUV(vh,workd)


% 9) Consolidate data into single struct and export to .csv file
syslog_concatAll_LRAUV
% output is saved to: syslog_All_comp.mat

writetable(table(vertcat(syslogs.Tethys.nosyslog,syslogs.Daphne.nosyslog)),...
    [workd 'nosyslog_list.csv'])

%%
MTBCF_BARPLOTS
compCountPlot
% -> compleated for 2010-2014 (Dec, 31 2014)