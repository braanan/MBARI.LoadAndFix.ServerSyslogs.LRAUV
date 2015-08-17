% compCountPlot.m
% comp count plot (per year per vehicle)
clear
close all

workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
% yr=2014:2015;
figd ='~/Desktop/FigTemp/MTBCF/comp/';
vh={'Tethys','Daphne', 'Makai'};
% vh={'Daphne'};

setAxesDefaults
co = linspecer(12,'qualitative');

load('syslog_AllVehicles_comp.mat')
% d = load([workd 'syslog_Daphne_comp.mat']);
% t = load([workd 'syslog_Tethys_comp.mat']);
% m = load([workd 'syslog_Makai_comp.mat']);

for v=1:length(vh);
    
    fname = fieldnames(syslogs.(vh{v}));
    fname(strcmp(fname,'nosyslog'))=[];
    
    for q=1:length(fname)
        
        yr = fname{q}; yr = str2double(yr(2:end));
        if yr>2013
            
            mname = syslogs.(vh{v}).(fname{q}).Fault.data.logCount(1:end-1,1:2);
            umname = unique(mname(:,1));
            umcount = zeros(size(umname));
            comp = syslogs.(vh{v}).(fname{q}).Fault.data.compFilt(:,[1,3]);
            cflist = syslogs.(vh{v}).(fname{q}).Fault.data.compCount;
            cflist(cell2mat(cflist(:,2))<3,:)=[];
            
            figure; hold on;
            set(groot,'defaultAxesColorOrder',co);
            set(gcf,'Units','normalized','Position',[0 0.2 1 0.7],...
                'PaperPositionMode','auto')
            
            for k = 1:length(cflist)
                
                f = find(strcmp(comp(:,1),cflist{k,1}));
                
                logsf = comp(f,2);
                umcount = zeros(size(umname));
                for c=1:numel(logsf)
                    logtmp = logsf{c};
                    
                    
                    mistmp = mname(strcmp(logtmp(2:end),mname(:,2)),1);
                    mistmpi = find(strcmp(umname,mistmp));
                    umcount(mistmpi) = umcount(mistmpi)+1;
                end
                
                
                p(k) = plot(1:numel(umcount),cumsum(umcount),'linewidth',3);
                lgnd{k} = [cflist{k,1} ' ('...
                    num2str(cflist{k,2}) ')'];
            end
            
            for k=1:length(umname)
                l = umname{k};
                if any(strfind(l,'201'))
                    l=l(12:end);
                end
                l(strfind(l,'_'))=' ';
                l(strfind(l,'-'))=' ';
                l(strfind(l,vh{v}):strfind(l,vh{v})+length(vh{v})-1)=[];
                if length(l)>25; l = horzcat(l(1:24),'...'); end
                xlab{k,1} = strtrim(l);
            end
            
            set(gca,'xtick',1:length(umname),'XtickLabel',xlab)
            set(gca,'XTickLabelRotation',45)
            % rotateticklabel(gca,45);
            lg = legend(p,lgnd,'location','nw');
            
            
            title([vh{v} ' - Cumulative Component Failure ' num2str(yr) ],'fontweight','bold','fontsize',24)
            ylabel('Failure Count');
            set(lg, 'fontsize',18,'Interpreter', 'none');
            grid on; box on;
            pb = get(gca, 'position');
            set(gca,'Position',[pb(1) pb(2)+0.1 pb(3) pb(4)-0.1])
            
            clear xlab lgnd p lgnd
            
            set(gca,'layer','top','fontWeight','bold','fontsize',20);
            
            print2pdf(gcf,[figd 'FailCount_DT' vh{v} '_' fname{q} ]);
            close
        end
    end
end

set(groot,'defaultAxesColorOrder','remove')
