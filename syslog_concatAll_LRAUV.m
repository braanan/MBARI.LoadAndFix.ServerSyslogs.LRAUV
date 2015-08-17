% syslog_concatAll_LRAUV.m
% Last modified Dec 31, 2014
% Ben Raanan

clear

workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
yr=2010:2015;
vh={'Tethys','Daphne','Makai'};

for v=1:length(vh);
    
    load([workd 'syslog_' vh{v} '_comp.mat']);
    
    syslogs.(vh{v}) = syslog;
    
    filename1 = [workd vh{v} 'logCount2014.csv'];
    writetable(syslogs.(vh{v}).y2014.Fault.logCountTable,filename1)
    filename2 = [workd vh{v} 'compFilt2014.csv'];
    writetable(syslogs.(vh{v}).y2014.Fault.compFiltTable,filename2)
    
end; clear v

% save
%
save('~/Documents/MATLAB/MBARI/mat/syslog/syslog_AllVehicles_comp.mat',...
    'syslogs')
%}