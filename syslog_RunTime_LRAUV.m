function syslog_RunTime_LRAUV(vh,workd)
% Lats modified April,24 2014
% Ben Raanan

% This script calculates run time and MTBCF for each log and mission

% workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
% yr=2010:2014;
% vh={'Tethys','Daphne','Makai'};
% global vh workd

if ischar(vh)
    vh = {vh};
end

for v=1:numel(vh)
    
    vhc = vh{v};
    % clearvars -except workd yr vh q v vhc syslog filePath logName compHeader
    load([workd 'syslog_' vhc '_comp.mat']);
    fname = fieldnames(syslog);
    fname(strcmp(fname,'nosyslog'))=[];
    
    for q=1:numel(fname)
        
        yfield = fname{q};

        % get mission names
        ms = fieldnames(syslog.(yfield));
        ms(strcmp(ms,'Fault'))=[];
        
        for c = 1:length(ms)
            
            % get log names
            log = fieldnames(syslog.(yfield).(ms{c}));
            log(strcmp(log,'dlist'))=[];
            
            mrt = NaN(size(log));
            for j=1:length(log)
                
                chek = fieldnames(syslog.(yfield).(ms{c}).(log{j}));
                if any(strcmp(chek,'runTime'))
                    clear X
                    X = syslog.(yfield).(ms{c}).(log{j}).runTime;
                else
                    warning([vhc filesep yfield filesep ms{c} filesep log{j} ': NO runTime'])
                end
                
                if length(X)==2 && sum(cellfun(@isempty,X))==0
                    
                    % convert to syslog timestamp to matlab time
                    t = syslog2datenum(X);
                    
                    % compute log runtime
                    mrt(j) = 24*(t(2)-t(1));
                    
                    % log runtime in log struct
                    syslog.(yfield).(ms{c}).(log{j}).RUNTIME = [t(1),t(2),mrt(j)];
                    
                    % calc run-time in logCount struct
                    fl = log{j}; 
                    
                    f = strcmp(syslog.(yfield).Fault.data.logCount(:,logCi(q)),fl(2:end));
                    if any(f)
                        syslog.(yfield).Fault.data.logCount{f,logCi(q)+2} = mrt(j);
                    end; clear f fl mtbcf
                else
                    warning([vhc '/' yfield '/' ms{c} '/' log{j} ': NO runTime'])
                    
                end
            end; clear j f fl t X chek mrt

            
            if isfield(syslog.(yfield).Fault.data,'missionCount')
                syslog.(yfield).Fault.missionCountTable = array2table(syslog.(yfield).Fault.data.missionCount,...
                    'VariableNames',{'Mission','Fault_count'});
            end
        end; clear c ms
        
    end; clear q
    
    % save
    %
    save([workd 'syslog_' vhc '_comp.mat'],'filePath','logName',...
        'syslog','compHeader','logCi')
    %}
end; clear v


