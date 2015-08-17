function get_syslog_CRITICAL_LRAUV(vh,yr,workd,varargin)
% Last modified April 24, 2014
% Ben Raanan

% This script retreives and logs CRITICAL messeges from syslog files

% workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
% yr=2010:2015;
% vh={'Tethys','Daphne','Makai'};
% global yr vh workd

if ischar(vh)
    vh = {vh};
end

formatSpec = '%s';

for v=1:numel(vh)
    
    vhc = vh{v};

    h = waitbar(0,['Retreving ' vhc ' syslogs...']);
    
    % check connection with server
    if ~checkServerConnection('/Volumes/LRAUV/')
        close(h)
        error('find_syslog_LRAUV: Could not establish connection with server smb://atlas.shore.mbari.org/LRAUV/')
    end;
 
    load([workd 'syslog_' vhc '.mat'])
    
    try
        oldscan = load([workd 'syslog_' vhc '_comp.mat']);
        syslog = oldscan.syslog;
    catch
        oldscan = [];
        warning(['[get_syslog_CRITICAL_LRAUV]: Couldnt find syslog_' vhc '_comp.mat: Performing full scan'])
    end
    
    % Force fresh scan
    if strcmpi(varargin,'fresh')
        oldscan = [];
    end
    
    syslog.nosyslog =cell(1);
    for q=1:length(yr)
        
        year = num2str(yr(q));
        yfield = ['y' year];
        
        if ~isempty(oldscan)
            updatepath = setdiff(filePath.(yfield),oldscan.filePath.(yfield));
        else
            updatepath = filePath.(yfield);
        end
        
        waitbar(0.01,h,['Scaning ' year ' syslogs for ' (vh{v}) '...']);
        
        if ~isempty(updatepath)
            
            for j=1:numel(updatepath)
                
                ltmp = ['D' logName.(yfield){j,1}];
                mtmp = ['M' logName.(yfield){j,2}];
                ftmp = filePath.(yfield){j,1};
                
                syslog.(yfield).(mtmp).(ltmp).path = ftmp;
                
                % readin syslog to struct
                fileID = fopen([ftmp 'syslog']);
                
                if fileID~=-1
                    txt = textscan(fileID,formatSpec,'Delimiter', '\n');
                    txt = txt{1,1};
                    if ~isempty(txt)
                        
                        % index CRITICAL messages and extract them to struct
                        ci = ~(cellfun('isempty', strfind(txt,'CRITICAL')));
                        syslog.(yfield).(mtmp).(ltmp).CRITICAL = txt(ci,1);
                        
                        % get first and last lines in syslogs for runtime calc
                        rtInd = find(not(cellfun(@isempty,txt)));
                        
                        % ensure time stamp is complete
                        rtin=1; rtend=length(rtInd);
                        while cellfun('isempty', strfind(txt(rtInd(rtin)),'Z'))
                            rtin =rtin+1;
                        end
                        
                        while cellfun('isempty', strfind(txt(rtInd(rtend)),'Z'))
                            rtend =rtend-1;
                        end
                        
                        syslog.(yfield).(mtmp).(ltmp).runTime = txt([rtInd(rtin),rtInd(rtend)],1);
                        
                        
                        fclose(fileID);
                    end
                    
                else
                    
                    warning([ftmp ': Invalid file identifier'])
                    syslog.nosyslog{length(syslog.nosyslog)+1,:} = ftmp;
                    syslog.(yfield).(mtmp) = rmfield(syslog.(yfield).(mtmp),(ltmp));
                    
                end
                clear txt ci fileID
                
                %     copyfile(['/Volumes' fileName{j,1}],[outf mission{j,1} '_' fields{j,1} '.syslog']);
                waitbar(j./length(filePath.(yfield)),h,['Scaning ' year ' syslogs for ' vh{v} ' ['...
                    num2str(100*(j./length(filePath.(yfield))),2) '%]'] );
                
            end; clear j tmp;
        
            display([datestr(clock) ' [get_syslog_CRITICAL_LRAUV]: Updated CRITICAL messeges from ' vhc ' ' year ' syslog records'])
        else
            display([datestr(clock) ' [get_syslog_CRITICAL_LRAUV]: Skipped ' vhc ' ' year ' syslog records: CRITICAL messege record is up to date!'])
        end
    end
    
    % save
    %
    save([workd 'syslog_' vhc '.mat'],...
        'filePath','logName','syslog')
    %}
    close(h)
    clearvars -except workd yr vh q v formatSpec varargin
end