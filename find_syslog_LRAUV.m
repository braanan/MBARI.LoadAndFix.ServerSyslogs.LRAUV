function find_syslog_LRAUV(vh,yr,workd)
% Last modified Jan. 18, 2014
% Ben Raanan

% This script locates syslog files from server folders and logs thier paths

% workd = '~/Documents/MATLAB/MBARI/LoadAndFix/ServerSyslogs/mat/';
% yr=2010:2014;
% vh={'Tethys','Daphne','Makai'};
% global yr vh workd

if ischar(vh)
    vh = {vh};
end

for v=1:numel(vh)

    vhc = vh{v};
    clear filePath mission logName nameFolds logs fName

    for q=1:length(yr)

        year = num2str(yr(q));

        h = waitbar(0,['Retrieving ' year ' syslogs...']);


        pathFolder = ['/Volumes/LRAUV/' vhc '/missionlogs/' year '/'];

        % find folder subdirectories
        d = dir('/Volumes/LRAUV/'); % check connection
        if isempty(d)
            close(h)
            error('[find_syslog_LRAUV]: Could not establish connection with server smb://atlas.shore.mbari.org/LRAUV/')
        end; clear d
        d = dir(pathFolder);
        isub = [d(:).isdir]; % returns logical vector
        nameFolds = {d(isub).name}';

        % eliminate nonrelevent directories
        ignore  = {' ','.','..'};
        for c=1:length(ignore)
            ci = (cellfun('isempty', strfind(nameFolds,ignore{c})));
            nameFolds = nameFolds(ci);
        end; clear c ci


        % eliminate nonrelevent missions
        ignore  = {'latest','Lab','lab','Tank','Tow','Battery','cal','None'};
        mout = true(size(nameFolds));
        logs2ignore = cell(1); lind = 0;
        for c=1:numel(nameFolds)

            % readin .dlist
            fileID = fopen([pathFolder nameFolds{c} '.dlist']);

            if fileID~=-1
                txt = textscan(fileID,'%s','Delimiter', '\n');
                dlist = txt{1,1};

                if ~isempty(dlist)

                    % flag mission names to ignore
                    ci = ~(cellfun('isempty', strfind(dlist,'Deployment Name:')));
                    mname = char(dlist(ci,1));
                    mname = mname(20:end);

                    for k = ignore
                        if any(strfind(mname,k{:}))
                            mout(c) = false;
                            break
                        end
                    end

                    % flag logs to ignore (#log in mission .dlist file)
                    li = ~(cellfun('isempty', strfind(dlist,['#' year])));

                    if any(li)
                        tmp = dlist(li);
                        for k=1:numel(tmp)
                            lind = lind+1;
                            tmpl = tmp{k};
                            logs2ignore{lind,:} = tmpl(2:end);
                        end
                    end; clear li tmp tmpl k

                end;
                fclose(fileID); clear ci mname dlist txt
            end
        end
        nameFolds = nameFolds(mout); clear mout

        % log mission names for each vehicle
        %{
        b = ~(cellfun('isempty', regexpi(nameFolds,'daphne')));
        c = ~(cellfun('isempty', regexpi(nameFolds,'makai')));
        a = ~(b | c);   % not(cellfun('isempty', regexpi(nameFolds,'tethys')));

        mission.all     = nameFolds;
        mission.Tethys  = nameFolds(a,:);
        mission.Daphne  = nameFolds(b,:);
        mission.Makai   = nameFolds(c,:);


        % add 'M' to begining of mission name (struct can't start w/ num)
        for k=1:length(nameFolds)
            nf{k,:} = ['M' nameFolds{k}];
        end; clear k
        %}

        fName = cell(1);
        logs  = cell(1,2);
        for j=1:length(nameFolds)

            % folder path
            tmp = [pathFolder nameFolds{j} '/'];

            % find folder subdirectories
            d = dir(tmp);
            isub = [d(:).isdir];       % returns logical vector
            X = {d(isub).name}';

            % eliminate nonrelevent directories
            ci = not(cellfun('isempty', strfind(X,year)));
            X = X(ci);
            if ~cellfun('isempty',logs2ignore)
                X(ismember(X,logs2ignore))=[];
            end

            % log names
            in = size(fName,1)+1;
            ind = in:length(X)+in-1;
            logs(ind,1) = X;

            % concatenate to form syslog file paths
            for k=1:length(ind)
                logs{ind(k),2} = nameFolds{j};
                fName{ind(k),:} = strcat(tmp,X{k},'/');
            end; clear k;

            waitbar( j./length(nameFolds),h,['Retrieving ' vhc ' ' year ' syslogs... ['...
                num2str(100*(j./length(nameFolds)),2) '%]'] );

        end; clear j in ind isub d ci X;
        fName(1)=[];
        logs(1,:) =[];



        % log syslog file paths and log names for each vehicle
        filePath.(['y' year]) = fName;
        logName.(['y' year])  = logs;
        display([datestr(clock) '[find_syslog_LRAUV]: Compleated syslog scan for ' vhc ' ' year])
        close(h)
    end

    % save
    %
    save([workd 'syslog_' vhc '.mat'],'filePath','logName')
    %}
end
