% MTBCF_BARPLOTS.m
clear
close all

workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
% yr=2012:2014;
figd ='~/Desktop/FigTemp/MTBCF/';
vh={'Tethys','Daphne', 'Makai'};

load('syslog_AllVehicles_comp.mat')
% d = load([workd 'syslog_Daphne_comp.mat']);
% t = load([workd 'syslog_Tethys_comp.mat']);
% m = load([workd 'syslog_Makai_comp.mat']);



for v=1:length(vh);
    
    total = []; multiY=[]; yrtmp = [];
    fname = fieldnames(syslogs.(vh{v}));
    fname(strcmp(fname,'nosyslog'))=[];
    
    for q=1:length(fname)
        
        yr = fname{q}; yr = str2double(yr(2:end));
        if yr>2011 && yr<=2015
            tmp = syslogs.(vh{v}).(fname{q}).Fault.data.logCount(:,1:4);
            total  = vertcat(total,tmp(end,:));
            multiY = vertcat(multiY,tmp(1:end-1,:));
            yrtmp  = vertcat(yrtmp,ones(size(tmp(1:end-1,1)))*yr);
            yr=[];
        end
    end
    
    
    
    
    [u, ui] = unique(multiY(:,1),'stable');
    depName = u; depYr = yrtmp(ui);
    multiY_c = cell2mat(multiY(:,3));
    multiY_rt = cell2mat(multiY(:,4));
    
    for k = 1:length(u)
        f = find(strcmp(multiY(:,1),u(k)));
        depM(k,:) = sum(multiY_rt(f))/sum(multiY_c(f));
        if isinf(depM(k,:))
            depM(k,:) = sum(multiY_rt(f));
        end
    end
    depM(depM==inf)=NaN;
    
    u = unique(yrtmp,'stable');
    for k = 1:length(u)
        f = find(yrtmp==u(k));
        yrM(k,:) = sum(multiY_rt(f))/sum(multiY_c(f));
    end
    depM(depM==inf)=NaN;
    
    globM = sum(multiY_rt)/sum(multiY_c);
    
    syslogs.(vh{v}).Fault.logCount = multiY;            multiY  = [];
    syslogs.(vh{v}).Fault.logCountYr = yrtmp;           yrtmp   = [];
    syslogs.(vh{v}).Fault.depName = depName;            depName = [];
    syslogs.(vh{v}).Fault.depYr = depYr;                depYr   = [];
    syslogs.(vh{v}).Fault.depMTBCF = depM;              depM    = [];
    syslogs.(vh{v}).Fault.yrMTBCF = yrM;                yrM     = [];
    syslogs.(vh{v}).Fault.yr = u;                       u       = [];
    syslogs.(vh{v}).Fault.globalMTBCF = globM;          globM   = [];
    
    
    
    u=unique(syslogs.(vh{v}).Fault.logCount(:,1),'stable');
    
    for k=1:length(u)
        
        l = u{k};
        
        if any(strfind(l,'201'))
            l=l(12:end);
        end
        
        l(strfind(l,'_')) = ' ';
        l(strfind(l,'-')) = ' ';
        l(strfind(l,vh{v}):strfind(l,vh{v})+length(vh{v})-1)=[];
        
        xlab{k,1} = strtrim(l);
    end
    
    figure;
    set(gcf,'Units','normalized','Position',[0 0.2 1 0.7],...
        'PaperPositionMode','auto') %,'visible','off');
    b = bar(syslogs.(vh{v}).Fault.depMTBCF);
    hold on;
    
    uyr = unique(syslogs.(vh{v}).Fault.depYr);
    for k=1:length(uyr)
        f = find(syslogs.(vh{v}).Fault.depYr==uyr(k));
        
        annual    = nanmean(syslogs.(vh{v}).Fault.depMTBCF(f));
        criticals = total{k,find(strcmp(total(k,:),'Total:'))+1};
        runtime   = total{k,find(strcmp(total(k,:),'Total:'))+2};
        
        p(k) = plot(f,ones(size(f))*annual,...
            'linewidth',4);
        
        lgnd{k} = [' ' num2str(uyr(k)) ' - Runtime: ' sprintf('%.1f',runtime) ' hr  |  # of Critcal errors: ' sprintf('%.0f',criticals) '  |  MTBCF: '...
            sprintf('%.1f',annual) ' hr'];
    end
    lg = legend(p,lgnd,'location','nw');
    
    set(gca,'xtick',1:length(syslogs.(vh{v}).Fault.depMTBCF))
    set(gca,'XtickLabel',xlab,'XTickLabelRotation',45);
    title([vh{v} ' - Deployment Mean Time Between Critical Failures (MTBCF)'],'fontweight','bold','fontsize',24)
    ylabel('MTBCF (hour)','fontweight','bold','fontsize',20);
    % xlabel('Deployment','fontweight','bold','fontsize',16);
    set(gca,'layer','top','fontWeight','bold','fontsize',16);
    set(lg, 'fontsize',18)
    grid on; box on; axis tight; ylim([0 120]);
    pb = get(gca, 'position');
    set(gca,'Position',[pb(1) pb(2)+0.1 pb(3) pb(4)-0.1])
    
    %     print(gcf,[figd 'MTBCF_' vh{v}],'-r600','-dpng');
    %     close
    clear xlab lgnd p lgnd lg
end


%% VP vs ALL

setAxesDefaults
vhc = vh(1:2);
x = 2012:2015;
for v=1:length(vh);
    
    fname = fieldnames(syslogs.(vh{v}));
    fname(strcmp(fname,'nosyslog'))=[];
    fname(strcmp(fname,'Fault'))=[];
    runTime(v) = sum(cell2mat(syslogs.(vh{v}).Fault.logCount(:,4)));
    for q=1:length(fname)
        
        yr = fname{q}; yr = str2double(yr(2:end));
        idx = find(x==yr);
        if idx
            stmp(v,idx) = length(syslogs.(vh{v}).(fname{q}).Fault.data.compFilt(:,1));
            sVPtmp(v,idx) = length(syslogs.(vh{v}).(fname{q}).Fault.data.compVp(:,1));
            sDWtmp(v,idx) = length(syslogs.(vh{v}).(fname{q}).Fault.data.drop_weight(:,1));
        end
    end
    
    %stmp(stmp==0)=[];   sVPtmp(sVPtmp==0)=[];
    %sDWtmp(sDWtmp==0)=[]; x(x==0)=[];
    
end

stmp = sum(stmp); sVPtmp = sum(sVPtmp); sDWtmp = sum(sDWtmp);

figure;
bar(x,stmp,0.5,'FaceColor',[0.2,0.2,0.5]); hold on;
bar(x,sVPtmp,0.5,'FaceColor',[  0    0.4470    0.7410],...
    'EdgeColor',[  0    0.4470    0.7410]);
title(['Tethys, Daphne & Makai (' num2str(sum(runTime),4) ' hours of operation)'],...
    'fontweight','bold','fontsize',24);
ylabel('Critical Failure Count','fontweight','bold','fontsize',22);
lg = legend(['Total ' num2str(sum(stmp))],['Vertical plane ' num2str(sum(sVPtmp)) ' ('...
    num2str(100*sum(sVPtmp)/sum(stmp),3) '%)'],'location','northeast');
ylim([0 290])
for j=1:length(x)
    text(x(j),stmp(j),[num2str(100*sVPtmp(j)/stmp(j),3) '%'],...
        'HorizontalAlignment','center',...
        'VerticalAlignment','bottom',...
        'fontweight','bold','fontsize',18)
end
grid on; box on;
set(gca,'layer','top','fontWeight','bold','fontsize',20);

% print2pdf(gcf,[figd 'FailCount_DT']);
% close

% clear *tmp x runTime


%%

% f = '~/Desktop/Tethys_MTBCF_2012-2014';
% print2pdf(gcf,f)
% close

