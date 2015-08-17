% function syslog_eliminateRedundant_LRAUV(vh, workd)
% Lats modified Dec 31, 2014
% Ben Raanan

% This script eliminates redundent critical faults and counts critical
% errors by log, mission and component

workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
yr=2010:2015;
vh={ 'Tethys', 'Daphne', 'Makai' };
% global vh workd

if ischar(vh)
    vh = {vh};
end

for v=1:numel(vh)
    
    vhc = vh{v};
    clearvars -except workd yr vh q v vhc syslog filePath logName compHeader
    load([workd 'syslog_' vhc '_comp.mat']);
    fname = fieldnames(syslog);
    fname(strcmp(fname,'nosyslog'))=[];
    
    
    for q=1:numel(fname)
        
        yfield = fname{q};
        
        clear comp
        comp = syslog.(yfield).Fault.data.comp;
        
        if ~isempty(comp)
            % reduce missions and logs to unique
            clear logCount missionCount
            [logCount,logCounti,~]     = unique(logName.(yfield)(:,1));
            
            % re-order: some missions don't have a dlist file, hence the if
            if size(logName.(yfield),2)>2
                logCount(:,2) = logCount;
                logCount(:,1) = logName.(yfield)(logCounti,3);
                logCi(q)=2;
            else
                logCi(q)=1;
            end
            missionCount = unique(logName.(yfield)(:,2));
            
            % eliminate redundant critical messages per log
            tbc = 17; % minmum time interval between compnant critical (minuts)
            neo=1; clear compFilt
            for c=1:size(logCount,1)
                
                % index log entries
                ind = find(ismember(comp(:,3),['D' logCount{c,logCi(q)}]));
                
                if ~isempty(ind)
                    
                    % index unique componant faults [stable: keep order of origin (chrono)]
                    [u, ui, uii]   = unique(comp(ind,1),'stable');
                    compui = unique(uii);
                    
                    for k=1:numel(compui)
                        
                        f=find(uii==compui(k));
                        
                        % find out how much time between messages (same
                        % componant in same log)
                        timebc = zeros(size(f));
                        timebc(2:end) = diff(cell2mat(comp(ind(f),10)));
                        f=f(timebc>=tbc/(24*60));
                        
                        % log/concatenate
                        if ~isempty(f)
                            compFilt(neo:neo+size(f,1)-1,:) = comp(ind(f),:); % [u comp(ind(ui),2:end)];
                            neo = neo+size(f,1);
                        else
                            compFilt(neo,:) = comp(ind(ui(k)),:);% [u comp(ind(ui),2:end)];
                            neo = neo+1;
                        end; clear f
                    end
                end
            end; clear c neo ind u ui;
            
            
            % eliminate redundant critical messages per mission
            perMiss = {'DropWeight','Default:Iridium:Read_Iridium:A_Timeout:B',...
                'Default:Iridium:A_Timeout:B','Environmental'};
            
            for c=1:numel(missionCount)
                
                % index unique componant faults [stable: keep order of origin (chrono)]
                for j=1:numel(perMiss)
                    
                    % index mission entries
                    ind = find(ismember(compFilt(:,2),['M' missionCount{c}]));
                    
                    % index redundant compnant critical messages
                    f = find(strcmp(perMiss(j),compFilt(ind,1)));
                    
                    if ~isempty(f)
                        compFilt(ind(f(2:end)),:)=[]; % keep only the first entry
                    end
                end; clear j ind f;
            end; clear c
            
            
            
            % count critical fault per mission
            for c=1:numel(missionCount)
                missionCount{c,2} = sum(strcmp(['M' missionCount{c,1}],compFilt(:,2)));
            end; clear c
            % missionCount{length(missionCount)+1,1} = 'Total';
            % missionCount{length(missionCount),2} = num2str(sum(cell2mat(missionCount(:,2))));
            
            % count critical fault per log
            for c=1:numel(logCount(:,1))
                logCount{c,logCi(q)+1} = sum(strcmp(['D' logCount{c,logCi(q)}],compFilt(:,3)));
            end; clear c
            
            
            % count critical fault per componant
            compCount = unique(compFilt(:,1));
            for c=1:numel(compCount)
                compCount{c,2} = sum(strcmp(compCount(c,1),compFilt(:,1)));
            end;
            
            [~,si] = sort(cell2mat(compCount(:,2)),'descend');
            compCount = compCount(si,:);
            clear c si;
            
            
            % flag critical faults asociated w/ vertical plane flight
            vpc = {'MassServo','ElevatorServo','BuoyancyServo','VerticalControl','ThrusterServo','DropWeight'};
            j=1; compVp = cell(j,12);
            for c=1:size(compFilt,1)
                
                if any(strcmp(compFilt{c,1},vpc))
                    compVp(j,:) = compFilt(c,:);
                    j=j+1;
                end
            end; clear c j;
            
            syslog.(yfield).Fault.data.compFilt = compFilt;
            syslog.(yfield).Fault.compFiltTable = array2table(compFilt,...
                'VariableNames', compHeader);
            
            syslog.(yfield).Fault.data.compVp = compVp;
            syslog.(yfield).Fault.compVpTable = array2table(compVp,...
                'VariableNames', compHeader);
            
            syslog.(yfield).Fault.data.compCount = compCount;
            syslog.(yfield).Fault.compCount = array2table(compCount,...
                'VariableNames', {'Componant','Fault_count'});
            
            syslog.(yfield).Fault.data.missionCount = missionCount;
            syslog.(yfield).Fault.data.logCount = logCount;
        end
    end
    
    
    % save
    %
    save([workd 'syslog_' vhc '_comp.mat'],...
        'filePath','logName','syslog','compHeader','logCi')
    %}
end
