function collectClickerData
    global clicker_ID
    global clicker_num
    global baseDays
    global isLeapYear
    global urlProfNames
    global problems
    global debug
    clc
    tic
    debug = fopen('debug.log','w');
    fprintf(debug,'Diagnostic trace\n\n');
    problems = {'B88B05', 'tthachil3'
                'B69278', 'slashley7'
                'B7C88C', 'mrjv3'
                'B039B1', 'avashi3'
                'B68A9C', 'abarnhill3'
                'B81DC9', 'rclark66'
                'B88CC7', 'mmohagaonkar3'
                }
    %
    %  AT THE BEGINNING OF THE SEMESTER
    %   1. Download from T-Square spreadsheet template for Excel
    %          store it as gradebook.xls
    %
    %   2. Get the clicker registrations:
    %       - Go to the T-Square page, the Clicker menu
    %       - download the clicker data as clicker_list.tplx
    %       - run unzip_clickers.m
    %       - the IDs will be in clicker_IDs.txt
    %       
    %  3. set the lecture times (edit the setLectureTimes helper fn)
    setLectureTimes
    %
    %  4. get the locations where instructors store the sessions:
    urlProfNames = {'ProfSmith','ProfHB'};
    sectionURLs = {'http://www.prism.gatech.edu/~ds182/TurningPoint%205/Sessions/', ...
        'http://www.prism.gatech.edu/~mhb6/PRSresultsFall2015/'};
    %
    %  5. set the leapYear flag
    isLeapYear = false;
    %
    %  6. set the date of the first day of class
    %                mo  day    of first day of class
    baseDays = daysTo(8) + 17 - 7;
    %  7. Make an empty folder "Sessions" in your current folder
    %
    %  THAT'S ALL - now, you just run the thing,
    %       and upload Gradebook_TSquare.xls to the grade book
    %       it always replaces all the PRS grades.  This is good because
    %       the Turning Point stuff records the entry even if the clicker
    %       isn't registered, so adding the clicker to the list (see below)
    %       actually recoveres 'lost' entries.
    %
    %   Well, not quite.  If students add their clickers later, the best
    %       thing to do is edit clicker_IDs.txt, adding them at the
    %       top of the file
    %
    decode_clickers('clicker_IDs.txt')
    gradebook = pullGradebook; 
    master_Semester = num2cell(zeros(length(gradebook)-1,17));
    firstRow = {'PRS Week 01 [5]','PRS Week 02 [5]','PRS Week 03 [5]','PRS Week 04 [5]',...
        'PRS Week 05 [5]','PRS Week 06 [5]','PRS Week 07 [5]','PRS Week 08 [5]','PRS Week 09 [5]',...
        'PRS Week 10 [5]','PRS Week 11 [5]','PRS Week 12 [5]','PRS Week 13 [5]','PRS Week 14 [5]',...
        'PRS Week 15 [5]','PRS Week 16 [5]','PRS Week 17 [5]'};
    master_Semester = [firstRow;master_Semester];
    master_weeks = [];
    zeroOut = []; 
    allIDs = {}; 
    for url = 1:length(sectionURLs)
        fprintf(['\n\nGrading ' urlProfNames{url}])
        fprintf(debug, ['\n\nGrading ' urlProfNames{url} '\n\n']);
        updatedDir = pullFiles(url,sectionURLs{url});
        total_Section = cell(1,17);
        total_Section = cellfun(@(X)(cell(1,3)),total_Section,'UniformOutput',false);
        weekCellLoc = ones(1,17);
        %Unzip all files and parse contents
        %fprintf('.');
        for i = 1:length(updatedDir)
            perccount(i,length(updatedDir) + (3*length(total_Section))); 
            %Unzip .zip file and delete the old .zip file
            try
                unzip([cd '\' updatedDir(i).name(1:end-5) '.zip'],updatedDir(i).name(1:end-5));
                delete([cd '\' updatedDir(i).name(1:end-5) '.zip']);
                cd(updatedDir(i).name(1:end-5));
                %Pull all data from the file in the following form: 
                %  2XN Cell array
                %     1st row is device IDs
                %     2nd row is number of correct responses from that ID
                %  Last column first row = total number of questions from session
                classCell = parseXML;
                cd('..');
                [weekNum, lecture]  = explore(updatedDir(i).name);
                if isnan(weekNum) || weekNum < 1 || weekNum > length(total_Section)
                    continue;
                end
                listClassCell(weekNum, lecture, classCell)
                total_Section{weekNum}{weekCellLoc(weekNum)} = classCell;
                weekCellLoc(weekNum) = weekCellLoc(weekNum) + 1;
                allIDs = [allIDs classCell(1,1:end-1)]; 
            catch er
                fprintf('bad unzip: %s\n', er.identifier);
            end
        end
        %fprintf('.');
        cd('..');
        cd('..');
        cd('..');
        %Start out writing all weeks
        weeksToWrite = 1:length(total_Section);
        %Total number of questions for each weeks
        totalNumofQuestions = zeros(1,length(total_Section));
        for i = 1:length(total_Section)
            perccount(i+length(updatedDir),length(updatedDir) + (3*length(total_Section)));
            %Check to see if any data exists for that weeks
            if ~isempty([total_Section{i}{:}])
                weekTotal = 0;
                for j = 1:length(total_Section{i})
                    %If data exists for that day of the week
                    if ~isempty([total_Section{i}{j}])
                        %Add to week total number of questions
                        weekTotal = weekTotal + total_Section{i}{j}{1,end};
                    end
                end
                totalNumofQuestions(i) = weekTotal;
            %If no data for that week, exclude it from the final grade file
            else
                weeksToWrite(weeksToWrite==i) = [];
            end
        end
        %Take out unnecessary weeks
        total_Section = total_Section(weeksToWrite);
        %Remove location trackers for unnecessary weeks
        weekCellLoc = weekCellLoc(weeksToWrite);
        %Remove unnecessary from total questions for each week
        totalNumofQuestions = totalNumofQuestions(weeksToWrite);
        %Student correct answers
        stud_NumCorrectAns = num2cell(zeros(length(gradebook)-1,length(total_Section)));
        %Collect students to write to gradebook later
        students_To_Write = []; 
        for i = 1:length(total_Section) 
            perccount(i+length(updatedDir)+length(total_Section),length(updatedDir) + (3*length(total_Section)));
            for j = 1:length(total_Section{i})
                if ~isempty([total_Section{i}{j}])
                    for k = 1:length(total_Section{i}{j})
                        %Get clicker ID !!!!!!!!!!!!!
                        currentID = total_Section{i}{j}{1,k}; 
                        try
                            n = hex2dec(currentID);
                        catch
                            n = -1;
                        end
                        %See if clicker # matches a student
                        studLoc = find(clicker_num == n);
                        if ~isempty(studLoc)
                            %Remove that ID from list
                            allIDs(strcmpi(allIDs,currentID)) = [];
                            %Get corresponding GT username
                            username = clicker_ID{studLoc};
                            check_problems(username, n)
%                            fprintf(debug,'%s with ID %s ', username, currentID); 
                            %Find student location in gradebook
                            gradebookLoc = find(strcmpi(gradebook(:,1),username));
                            if ~isempty(gradebookLoc)
                                %1 point for each day of attendance 
                                master_Semester{gradebookLoc,weeksToWrite(i)} = master_Semester{gradebookLoc,weeksToWrite(i)} + 1;
                                %Collect student correct answers HERE
                                numtoadd = total_Section{i}{j}{2,k};
                                stud_NumCorrectAns{gradebookLoc-1,i} = stud_NumCorrectAns{gradebookLoc-1,i} + numtoadd;
%                                fprintf(debug, ' present with %d', numtoadd);
                                %Only check students who answered for
                                %increased effeciency
                                students_To_Write(1,end+1) = gradebookLoc;
                                students_To_Write(2,end) = weeksToWrite(i); 
                            end
%                            fprintf(debug,'\n')
                        end
                    end
                end
            end
        end
        for i = 1:length(total_Section)
            perccount(i+length(updatedDir)+(2*length(total_Section)),length(updatedDir) + (3*length(total_Section)));
            for j = 1:length(gradebook)-1
                if any(j+1==students_To_Write(1,:))
                    student = students_To_Write(2,j+1==students_To_Write(1,:)); 
                    if any(student==weeksToWrite(i))
                        %Tells the next section which students have already
                        %attended
    %                     check_repeat(j,weeksToWrite(i)) = true;
                        if stud_NumCorrectAns{j,i} >= round(totalNumofQuestions(i)./2)
                            %Two points if they answer more than half of the
                            %questions correct
                            master_Semester{j+1,weeksToWrite(i)} = master_Semester{j+1,weeksToWrite(i)} + 2;%round(master_Semester{j+1,weeksToWrite(i)}/2);%+ 2;
                        end
                    end
                end
            end
        end
        %fprintf('.');
        %Collect weeks throughout sections
        master_weeks = [master_weeks weeksToWrite];
    end
%
%   cap scores at 5
    [rows, cols] = size(master_Semester);
    for r = 2:rows
        for c = 1:cols
            n = master_Semester{r,c};
            if n > 5
                master_Semester{r,c} = 5;
            end
        end
    end
    fprintf(' Processing...'); 
    %master_Semester = checkRepeats(master_Semester);
    %Delete duplicate weeks
    weeksToWrite = unique(master_weeks);
    %Grab necessary weeks from grades
    master_Semester = master_Semester(:,weeksToWrite);
    %Concatenate
    master_Semester = [gradebook(:,1:2) master_Semester];
    %Write final file
    delete('Gradebook_TSquare.xls');
    xlswrite('Gradebook_TSquare.xls',master_Semester);
    %Print unused clicker IDs
    allIDs = unique(allIDs); 
    fprintf(debug,'\n\nThe following IDs answered questions but were not assigned to any student\n'); 
    cellfun(@(X) fprintf(debug,'%s\n',X),allIDs);
    time = toc;
    %Display results
    fprintf(['\n' repmat('=',1,78) '\n']);
    fprintf([repmat(' ',1,30) 'Total Time: ' num2str(time) repmat(' ',1,30) '\n']);
    fprintf(debug, '%d clicker IDs were found with no assigned student\n',length(allIDs)); 
    fprintf('%d clicker IDs were found with no assigned student\n',length(allIDs)); 
%    fprintf('\t-Consult Unused.txt for more details\n'); 
    fprintf([repmat('=',1,78) '\n']); 
end

function classCell = parseXML
    fh = fopen('TTSession.xml');
    rawText = textscan(fh,'%s');
    rawText = rawText{1};
    line = 1;
    NumQuestions = 0;
    classCell = [];
    firstRunThrough = true;
    while true
        while line <= length(rawText) && isempty(strfind(rawText{line},'<multichoice>'))
            line = line + 1;
        end
        if line > length(rawText)
            break;
        end
        NumQuestions = NumQuestions + 1;
        while isempty(strfind(rawText{line},'<answers>'))
            line = line + 1;
        end
        answerNum = 1;
        while true
            while isempty(strfind(rawText{line},'<valuetype>'))
                line = line + 1;
            end
            if str2double(rawText{line}(strfind(rawText{line},'<valuetype>')+11:strfind(rawText{line},'</valuetype>')-1))==1
                correctAnswer = answerNum;
                break;
            end
            answerNum = answerNum + 1;
            line = line + 1;
            if strcmpi(rawText{line+1},'</answers>')
                break;
            end
        end
        if ~exist('correctAnswer','var')
            correctAnswer = -1; 
            NumQuestions = NumQuestions - 1; 
        end
        while isempty(strfind(rawText{line},'<responses>'))
            line = line + 1;
        end
        while ~strcmpi(rawText{line},'</responses>')
            if ~isempty(strfind(rawText{line},'<deviceid>'))
                deviceID = rawText{line}(strfind(rawText{line},'<deviceid>')+10:strfind(rawText{line},'</deviceid>')-1);
                if firstRunThrough
                    classCell{1,end+1} = deviceID;
                else
                    if ~any(strcmpi(classCell(1,:),deviceID))
                        classCell{1,end+1} = deviceID;
                    end
                end
                while isempty(strfind(rawText{line},'<responsestring>'))
                    line = line + 1;
                end
                studResponse = str2double(rawText{line}(strfind(rawText{line},'<responsestring>')+16:strfind(rawText{line},'</responsestring>')-1));
                if studResponse == correctAnswer
                    if firstRunThrough
                        classCell{2,end} = 1;
                    else
                        classCell{2,strcmpi(classCell(1,:),deviceID)} = classCell{2,strcmpi(classCell(1,:),deviceID)} + 1;
                    end
                elseif firstRunThrough
                    classCell{2,end} = 0;
                end
            end
            line = line + 1;
        end
        firstRunThrough = false;
    end
    fclose(fh);
    classCell{1,end+1} = NumQuestions;
end

function gradebook = pullGradebook
    filesinDir = dir;
    filesinDir = filesinDir(cellfun(@length,{filesinDir.name})>=9);
    fileNames = cellfun(@(X)X(1:9),{filesinDir.name},'UniformOutput',false);
    gradeBookfile = {filesinDir.name};
    gradeBookfile = gradeBookfile(strcmpi(fileNames,'gradebook'));
    lengths = cellfun(@length,gradeBookfile);
    [~,loc] = min(lengths);
    gradeBookfile = gradeBookfile{loc};
    [~,~,oldGradebook] = xlsread(gradeBookfile);
    gradebook = oldGradebook(:,1:2);
end

function updatedDir = pullFiles(url,urlToRead)
    global urlProfNames
    %Get all files available
    data_Section = urlread(urlToRead);
    %Exclude all files that don't contain clicker data
    files_Section = strfind(data_Section,'.tpzx');
    %Delete empty references
    files_Section = files_Section(2:2:end);
    brackets = strfind(data_Section,'>');
    files = cell(1,length(files_Section));
    %Collect all file names
    for i = 1:length(files)
        startLoc_All = (files_Section(i)-brackets);
        startLoc = min(startLoc_All(startLoc_All>0));
        startLoc = brackets((startLoc_All==startLoc)) + 1;
        files{i} = data_Section(startLoc:files_Section(i)+4);
    end
    %Make directory if it doesn't exist
    if ~exist('Sessions','dir')
        mkdir('Sessions');
        cd('Sessions');
        for ndx = 1:length(urlProfNames)
            nm = ['Sessions_' urlProfNames{ndx}];
            if ~exist(nm, 'dir')
                mkdir(nm);
            end
        end
        cd('..');
    end
    cd('Sessions');
    nm = ['Sessions_' urlProfNames{url}];
    cd(nm);
    %Get files already in directory
    currentSessions = dir();
    currentSessions = currentSessions(~[currentSessions.isdir]);
    %Check for overlap
    intersectFiles = intersect({currentSessions.name},files);
    %If there is overlap, ignore it
    for i = 1:length(intersectFiles)
        files = files(~strcmpi(files,intersectFiles{i}));
    end
    %Fix formatting and save files to folder
    for i = 1:length(files)
        linkName = files{i};
        linkName = strrep(linkName,' ','%20');
        linkName = strrep(linkName,'amp;','');
        urlwrite([urlToRead linkName],files{i});
    end
    %Create a folder for the zipped files
    if ~exist('Sessions_Zipped','dir')
        mkdir('Sessions_Zipped');
    end
    %Copy all files to new folder
    updatedDir = dir();
    updatedDir = updatedDir(~[updatedDir.isdir]);
    for i = 1:length(updatedDir)
        copyfile(fullfile(cd,updatedDir(i).name),[fullfile(cd,'Sessions_Zipped\') updatedDir(i).name(1:end-5) '.zip']);
    end
    %Navigate
    cd('Sessions_Zipped');
end

function  perccount(currI,totalLoop)
    persistent lastCall;
    if currI==1
        lastCall = []; 
    end
    if(currI==1 || lastCall  ~=  floor(((currI)/totalLoop) * 100))
        if(currI  ~=  1)
            fprintf(1,'\b\b\b\b');
        else
            fprintf(1,' ');
        end
        pc_done  =  num2str(floor(((currI)/totalLoop) * 100));
        if(length(pc_done)  ==  1)
            pc_done(2)  =  pc_done(1);
            pc_done(1)  =  '0';
        end
        fprintf(1,'%s%% ',pc_done);
    end
    lastCall  =  floor(((currI)/totalLoop) * 100);
end

function [week lect] = explore(filename)
global baseDays
global debug

    clc
    str = filename;
    fprintf('%s', str);
    fprintf(debug, '%s\n', str);
    [~, str] = strtok(str, ' ');
    [t, str] = strtok(str, ' -');
    if t(1) == '('
        [t, str] = strtok(str, ' -');
    end
    month = str2num(t);
    [t, str] = strtok(str, ' -');
    day = str2num(t);
    [t, str] = strtok(str, ' -');
    year = str2num(t);
    [t, str] = strtok(str, ' -');
    hour = str2num(t);
    [t, str] = strtok(str, ' -');
    min = str2num(t);
    ampm = strtok(str, ' .');
    %    fprintf(' data taken on %d/%d/%d at %d:%d %s\n', ...
    %    month, day, year, hour, min, ampm)
    days = daysTo(month)+day;
    week = floor((days - baseDays) / 7);
    if week < 1
        'ouch'
    end
    lect = getLecture(hour, min, ampm);
    fprintf(' -- week %2d lecture %s\n', week, lect);
end

function dtg = daysTo(mo)
    global isLeapYear
    dtg = 0;
    for m = 1:mo
        switch m
            case {9, 4, 6, 11}
                dim = 30;
            case 2
                if isLeapYear
                    dim = 29;
                else
                    dim = 28;
                end
            otherwise
                dim = 31;
        end
        dtg = dtg + dim;
    end
end

function lect = getLecture(hr, min, ampm)
    global lectureTime
    if hr < 12 && (ampm(1) == 'p' || ampm(1) == 'P')
        hr = hr + 12;
    end
    best = 0;
    dmin = 99999;
    for ln = 1:length(lectureTime)
        lt = 60*lectureTime(ln).hour+lectureTime(ln).min;
        now = 60*hr + min;
        tryit = abs(lt-now);
        if tryit < dmin
            dmin = tryit;
            best = ln;
        end
    end
    if best == 0
        disp('gotcha')
    end
    lect = lectureTime(best).letter;
    fprintf('Lecture %s\n', lect)
end

function setLectureTimes
    global lectureTime
    %   use 24 hour clock !!!!
    %   set the time for the middle of the lecture 
    lectureTime(1).letter = 'A';
    lectureTime(1).hour = 10;
    lectureTime(1).min = 30;
    lectureTime(2).letter = 'B';
    lectureTime(2).hour = 12;
    lectureTime(2).min = 30;
    lectureTime(3).letter = 'C';
    lectureTime(3).hour = 14;
    lectureTime(3).min = 30;
    lectureTime(4).letter = 'D';
    lectureTime(4).hour = 15;
    lectureTime(4).min = 30;
end

function listClassCell(wk, lect, ca)
    global debug
    [r, N] = size(ca);
    %  2XN Cell array
    %     1st row is device IDs
    %     2nd row is number of correct responses from that ID
    %  Last column first row = total number of questions from session
    for ndx = 1:N-1
       fprintf(debug,'wk %d; lect %s\t%s - %d\n', wk, lect, ca{1,ndx}, ca{2,ndx}); 
    end
end

function decode_clickers(name)
    global clicker_ID
    global clicker_num
    global debug
    
    clicker_ID = {};
    clicker_num = [];
    if nargin == 0
        name = 'clicker_IDs.txt';
    end
    fh = fopen(name,'r');
    line = '';
    delim = [char(9) ' '];
    while ischar(line) 
        line = fgetl(fh);
        if ischar(line)
            [GTID line] = strtok(line,delim);
            if length(line) > 0
                ID = strtok(line, delim);
                try
                    n = hex2dec(ID);
                catch
                    n = -1;
                    ID = '-------';
                end
            else
                    n = -1;
                    ID = '-------';
            end
            % !!!!!!!!!!!!!!!!!!
            check_problems(GTID, n)
            clicker_ID = [clicker_ID {GTID}];
            clicker_num = [clicker_num n];
            fprintf(debug,'%4d\t%s\t%s\t%d\n', length(clicker_ID), GTID, ID, n);
        end
    end
    fclose(fh);
end

function check_problems(GTID, n)
    global problems
    global debug
    
    found = false;
    for ndx = 1:length(problems)
        ID = problems{ndx,2};
        if strcmp(ID, GTID)
            found = true;
            at = ndx;
            break;
        end
    end
    if found
        np = hex2dec(problems{ndx,1});
        if np ~= n
            ns = myn2h(n);
            nps = myn2h(np)
            fprintf(debug,'\n>>>%s n was %s, not %s\n', GTID, ns, nps);
        end
    end        
end

function str = myn2h(n)
    str = '';
    while n > 0
        dig = mod(n,16);
        if dig < 10
            ch = char('0' + dig);
        else
            ch = char('A' + dig - 10);
        end
        str = [ch str];
        n = floor(n/16);
    end
end
