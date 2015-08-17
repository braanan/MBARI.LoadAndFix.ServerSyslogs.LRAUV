function process_syslog_CRITICAL_LRAUV(vh,workd)
% Lats modified Dec. 30, 2014
% Ben Raanan

% This script filters syslog critical faults by component and extracts
% time-stamp for each log

% clear
% workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
% yr=2010:2014;
% vh={'Tethys','Daphne','Makai'};
% global vh workd

if ischar(vh)
    vh = {vh};
end

compHeader={'Component','Mission','Log','Year','Month','Day','HH','MM','SS','Datenum','Msg','Path'};

for v=1:numel(vh)
    
    vhc = vh{v};
    
    clearvars -except workd yr vh v vhc syslog filePath logName compHeader
    load([workd 'syslog_' vhc '.mat']);
    fname = fieldnames(syslog);
    fname(strcmp(fname,'nosyslog'))=[];
    
    for q=1:numel(fname)
        
        yfield = fname{q};
        
        % remove 'Fault' struct if already exists
        if any(strcmpi(fieldnames(syslog.(yfield)),'Fault'))
            syslog.(yfield) = rmfield(syslog.(yfield),'Fault');
        end
        
        % get missions
        clear ms
        ms = fieldnames(syslog.(yfield));
        
        clear comp
        comp = cell(1,12);
        for c = 1:numel(ms)
            
            % get logs
            clear log
            log = fieldnames(syslog.(yfield).(ms{c}));
            log(strcmpi(log,'dlist'))=[];
                
            
            for j=1:numel(log)
                
                clear X
                chek = fieldnames(syslog.(yfield).(ms{c}).(log{j}));
                if any(strcmp(chek,'CRITICAL'))
                    X = syslog.(yfield).(ms{c}).(log{j}).CRITICAL;
                else
                    X = [];
                    warning([vh{v} '/' ms{c} '/' log{j} ': NO CRITICAL'])
                end
                
                if ~isempty(X)
                    com = cell(length(X),12);
                    in = size(comp,1)+1;
                    ind = length(X)+in-1;
                    
                    for k = 1:size(X,1);
                        
                        % reduce to line
                        dataS = X{k,:};
                        
                        % categorize by component and extract message
                        cInd1 = strfind(dataS,'[')+1;
                        cInd2 = strfind(dataS,'](CRITICAL)')-1;
                        cInd  = strfind(dataS,'component: ')+11; % comp name case CBIT
                        wInd  = strfind(dataS,'WATCHDOG');       % flag WATCHDOG reset
                        eInd  = strfind(dataS,'Environmental');
                        mInd = strfind(dataS,'):')+3;
                        
                        % case CBIT/WATCHDOG
                        if strcmp(dataS(cInd1:cInd2),'CBIT')
                            if ~isempty(cInd)
                                com{k,1} = dataS(cInd:end);
                            elseif ~isempty(wInd)
                                com{k,1} = 'WatchDog';
                            elseif ~isempty(eInd)
                                com{k,1} = 'Environmental';
                            else
                                com{k,1} = dataS(cInd1:cInd2);
                            end
                            com{k,11} = ['[CBIT]: ' dataS(mInd:end)];
                        else
                            com{k,1} = dataS(cInd1:cInd2);
                            com{k,11} = dataS(mInd:end);
                        end; clear cInd cInd1 cInd2 wInd
                        
                        % extract mission, log and path
                        com{k,2}  = ms{c};
                        com{k,3}  = log{j};
                        com{k,12} = syslog.(yfield).(ms{c}).(log{j}).path;
                        
                        
                        % extract date/time
                        indT = strfind(dataS,'T'); % flag 'T'
                        indZ = strfind(dataS,'Z'); % flag 'Z'
                        
                        % extract date/time
                        year = str2double(dataS(1:4));
                        month = str2double(dataS(6:7));
                        day = str2double(dataS(9:10));
                        hh = str2double(dataS(12:13));
                        mm = str2double(dataS(15:16));
                        ss = str2double(dataS(18:indZ-1));
                        clear indT indZ
                        
                        % log time data
                        com(k,4) = num2cell(year);
                        com(k,5) = num2cell(month);
                        com(k,6) = num2cell(day);
                        com(k,7) = num2cell(hh);
                        com(k,8) = num2cell(mm);
                        com(k,9) = num2cell(ss);
                        com(k,10)= num2cell(datenum(year,month,day,hh,mm,ss));
                    end; clear dataS year month day hh mm ss k;
                    
                    % log data
                    comp(in:ind,:) = com;
                    clear com in ind;
                end;
            end; clear j;
        end
        
        comp(1,:)=[];
        % kickout 'SBIT'
        comp(strcmp(comp(:,1),'SBIT'),:)=[];
        
        % sort chronologically
        [~,si] = sort(cell2mat(comp(:,10)));
        syslog.(yfield).Fault.data.comp = comp(si,:);
        display([datestr(clock) ': processed CRITICAL messeges for ' vhc ': ' yfield])
    end
    
    % save
    %
    save([workd 'syslog_' vhc '_comp.mat'],...
        'filePath','logName','syslog','compHeader')
    %}
    
end