function syslog_getMissionName_LRAUV(vh, workd)
% Lats modified Dec 31, 2014
% Ben Raanan

% This script scans .dlist file associated with each mission

% workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
% yr=2010:2015;
% vh={'Tethys','Daphne','Makai'};
% global vh workd

for v=1:numel(vh)
    
    vhc = vh{v};
    % clearvars -except workd yr vh q v vhc syslog filePath logName compHeader
    load([workd 'syslog_' vhc '_comp.mat']);
    
    fname = fieldnames(syslog);
    fname(strcmp(fname,'nosyslog'))=[];
    for q=1:numel(fname)
        
        
        yfield = fname{q};
        year = yfield(2:end);
        
        fpath = ['/Volumes/LRAUV/' vhc '/missionlogs/' year '/'];
        [mlist,~,mInd] = unique(logName.(yfield)(:,2));
        formatSpec = '%s';
        
        for c=1:numel(mlist)
            
            % readin .dlist
            fileID = fopen([fpath mlist{c} '.dlist']);
            
            if fileID~=-1
                txt = textscan(fileID,formatSpec,'Delimiter', '\n');
                dlist = txt{1,1};
                
                if ~isempty(dlist)
                    
                    syslog.(yfield).(['M' mlist{c}]).dlist = dlist;
                    
                    ci = (not(cellfun('isempty', strfind(dlist,'Deployment Name:'))));
                    mname = char(dlist(ci,1));
                    mname = mname(20:end);
                    
                    logName.(yfield)(mInd==c,3) = {mname};
                end
                fclose(fileID);
            end
        end
    end
    
    % save
    %
    save([workd 'syslog_' vhc '_comp.mat'],...
        'filePath','logName','syslog','compHeader')
    %}
end