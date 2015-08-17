function syslog_dropweight_LRAUV(vh, workd)
% Lats modified Dec 31, 2014
% Ben Raanan

% This script locates and logs "dropping drop weight" critical messages

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
        
        clear comp
        comp = syslog.(yfield).Fault.data.comp;
        
        % index "dropping drop weight" messages
        dwi = find(not(cellfun(@isempty,strfind(comp(:,11),'drop weight'))));
        
        % eliminate redundency
        [~,ui] = unique(comp(dwi,2),'stable');
        
        % log
        syslog.(yfield).Fault.data.drop_weight = comp(dwi(ui),:);
        syslog.(yfield).Fault.drop_weightTable = array2table(comp(dwi(ui),:),...
        'VariableNames', compHeader);
    
    end; clear q comp dwi ui 
    % save 
    %
    save([workd 'syslog_' vhc '_comp.mat'],...
        'filePath','logName','syslog','compHeader','logCi')
    %}
end; clear v

