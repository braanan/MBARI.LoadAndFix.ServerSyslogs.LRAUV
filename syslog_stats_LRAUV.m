function syslog_stats_LRAUV(vh,workd)
% Lats modified Dec 30, 2014
% Ben Raanan

% This script calculates annual TBCF and MTBCF in logs and also computes
% stats for vertical plain critical errors

% workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
% yr=2010:2014;
% vh={'Tethys','Daphne','Makai'};
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
        
        if isfield(syslog.(yfield).Fault.data,'logCount')
            % snip totals if already existent
            if strcmp(syslog.(yfield).Fault.data.logCount(end,logCi(q)),'Total:')
                syslog.(yfield).Fault.data.logCount(end,:)=[];
            end
            
            % replace empty cells w/ 0
            in = cellfun(@isempty,syslog.(yfield).Fault.data.logCount);
            syslog.(yfield).Fault.data.logCount(in) = {0};
            clear in
            
            
            % get log record length
            fl = length(syslog.(yfield).Fault.data.logCount(:,logCi(q)));
            % convert cell to mat
            lMat = cell2mat(syslog.(yfield).Fault.data.logCount(:,logCi(q)+1:logCi(q)+2));
            
            
            % calc TBCF and MTBCF in logs
            %------------------------------------------------------------------
            tbcf    = NaN(length(lMat),1);
            tbcf(1) = lMat(1,2);
            
            % calc TBCF
            for c=2:length(lMat)
                if lMat(c-1,1)==0
                    tbcf(c) = tbcf(c-1)+lMat(c,2);
                else
                    tbcf(c) = lMat(c,2);
                end;
            end; clear c;
            lMat(:,3)=tbcf;
            
            % calc MTBCF
            mtbcf = zeros(length(lMat),1);
            mtbcf(lMat(:,1)~=0,:) = tbcf(lMat(:,1)~=0)./lMat(lMat(:,1)~=0,1);
            mtbcf(mtbcf==0) = NaN;
            lMat(:,4)=mtbcf;
            
            % calc anual stats
            anlogCritical = nansum(lMat(:,1));
            anlogRunTime  = nansum(lMat(:,2));
            anlogMTBCF    = nanmean(lMat(:,4));
            
            % concat
            clMat(:,1:logCi(q)) = syslog.(yfield).Fault.data.logCount(:,1:logCi(q));
            clMat(:,logCi(q)+1:logCi(q)+4) = num2cell(lMat);
            clMat(fl+1,logCi(q):end) = {'Total:',anlogCritical, anlogRunTime,'' ,anlogMTBCF};
            
            if logCi(q)==2
                heads = {'Mission_name','Log_name','Critical_error_count','Log_runtime', 'TBCF','MTBCF'};
            elseif logCi(q)==1
                heads = {'Log_name','Critical_error_count','Log_runtime', 'TBCF','MTBCF'};
            end
            % log in struct
            syslog.(yfield).Fault.data.logCount = clMat;
            syslog.(yfield).Fault.data.logCountHeader   = heads;
            syslog.(yfield).Fault.logCountTable = array2table(syslog.(yfield).Fault.data.logCount,...
                'VariableNames',syslog.(yfield).Fault.data.logCountHeader);
            clear fl lMat tbcf mtbcf anlogCritical anlogRunTime anlogMTBCF clMat
            %------------------------------------------------------------------
            
            
            % Vertical Plane
            %------------------------------------------------------------------
            if strcmp(syslog.(yfield).Fault.data.logCount(end,logCi(q)),'Total:')
                in = size(syslog.(yfield).Fault.data.logCount,1)-1;
            end
            
            logs = syslog.(yfield).Fault.data.logCount(1:in,logCi(q));
            
            vpl = unique(syslog.(yfield).Fault.data.compVp(:,3));
            for c=1:length(logs)
                vpli(c,1) = ismember(['D' logs{c}],vpl);
            end; clear c
            
            logs(:,2) = num2cell(zeros(size(logs)));
            logs(:,2) = num2cell(double(vpli));
            logs(:,3) = syslog.(yfield).Fault.data.logCount(1:end-1,logCi(q)+2);
            
            lg = cell2mat(logs(:,2:3));
            
            % calc TBCF and MTBCF in logs
            %------------------------------------------------------------------
            tbcf    = NaN(length(lg),1);
            tbcf(1) = lg(1,2);
            
            % calc TBCF
            for c=2:length(lg)
                if lg(c-1,1)==0
                    tbcf(c) = tbcf(c-1)+lg(c,2);
                else
                    tbcf(c) = lg(c,2);
                end;
            end; clear c;
            lg(:,3)=tbcf;
            
            % calc MTBCF
            mtbcf = zeros(length(lg),1);
            mtbcf(lg(:,1)~=0,:) = tbcf(lg(:,1)~=0)./lg(lg(:,1)~=0,1);
            mtbcf(mtbcf==0) = NaN;
            lg(:,4)=mtbcf;
            
            % calc anual stats
            anlogCritical = nansum(lg(:,1));
            anlogRunTime  = nansum(lg(:,2));
            anlogMTBCF    = nanmean(lg(:,4));
            
            % concat
            clg = logs;
            clg(:,4:5) = num2cell(lg(:,3:4));
            heads = {'Log_name','Critical_error_count','Log_runtime', 'TBCF','MTBCF'};
            % log in struct
            syslog.(yfield).Fault.data.logCountVerticalPlane = clg;
            syslog.(yfield).Fault.data.logCountVerticalPlane(end+1,:) = {'Total:',anlogCritical, anlogRunTime,'' ,anlogMTBCF};
            syslog.(yfield).Fault.logCountVerticalPlaneTable = array2table(syslog.(yfield).Fault.data.logCountVerticalPlane,...
                'VariableNames',heads);
            clear logs vpl vpli lg clg tbcf mtbcf anlogCritical anlogRunTime anlogMTBCF heads
            
            % gather anual stats per mission
            %{
        %------------------------------------------------------------------
        fm = length(syslog.(yfeild).Fault.missionCount(:,1));
        
        mMat = cell2mat(syslog.(yfeild).Fault.missionCount(:,2:3));
        
        
        anualCritical = nansum(mMat(:,1));
        anualRunTime  = nansum(mMat(:,2));
        anualMTBCF    = nanmean(mMat(:,2));
        
        syslog.(yfeild).Fault.missionCount(fm+1,:) = {'Total:',anualCritical, anualRunTime, anualMTBCF};
        clear fm mMat ind anualCritical anualRunTime anualMTBCF
        %------------------------------------------------------------------
        
        %         anualVp(v,:) = sum(cell2mat(syslog.(yfeild).Fault.compVp(:,2)));
            %}
        end
    end
    
    % save
    %
    save([workd 'syslog_' vhc '_comp.mat'],...
        'filePath','logName','syslog','compHeader','logCi')
    %}
end

