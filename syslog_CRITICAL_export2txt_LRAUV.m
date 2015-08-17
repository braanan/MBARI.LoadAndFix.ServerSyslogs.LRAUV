% syslog_CRITICAL_export2txt_LRAUV.m
% Lats modified Dec 31, 2014
% Ben Raanan

workd='~/Documents/MATLAB/MBARI/mat/';
outd='~/Documents/MBARI/project/syslog/filtered/';


% year of interest
yr=2010:2014;

for n=1:length(yr)
    % load
    load([workd num2str(yr(n)) '-int-CRITICAL.mat']);
    
    % save to .txt
    outfile = [outd num2str(yr(n)) '-int-CRITICAL.txt'];
    data = compFilt;
    header = compHeader;
    dlmcell(outfile,header,',');
    dlmcell(outfile,data,',','-a');
end