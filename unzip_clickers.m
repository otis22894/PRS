function unzip_clickers
clc
global fh

    name = 'clicker_list.tplx';
    fh = fopen(name, 'r');
    out = fopen('clicker_IDs.txt','w');
    % <?xml version="1.0" encoding="UTF-8"?>
    if ~strcmp(get_tag(), '?xml'), error('bad tag: ?xml'), end
    % <participantlist>
    if ~strcmp(get_tag(), 'participantlist'), error('bad tag: participantlist'), end
    %     <ttxmlversion>2012</ttxmlversion>
    if ~strcmp(get_tag(), 'ttxmlversion'), error('bad tag: ttxmlversion'), end
    %     <guid>CD52D5F2408A42A086D3D4B11A0241B8</guid>
    if ~strcmp(get_tag(), 'guid'), error('bad tag: guid'), end
    %     <lmssource>gtc-9c5c-30ea-50e6-9ea7-eb8f3cd66b2e</lmssource>
    if ~strcmp(get_tag(), 'lmssource'), error('bad tag: lmssource'), end
    %     <name>CS1371_CS1171</name>
    [tag rest] = get_tag();
    if ~strcmp(tag, 'name'), error('bad tag: name'), end
    name = strtok(rest,'<> ');
    %     <created>03/02/2015 20:53:45 PM</created>
    [tag rest] = get_tag();
    if ~strcmp(tag, 'created'), error('bad tag: created'), end
    created = strtok(rest,'<> ');
    %     <modified>03/02/2015 20:53:45 PM</modified>
    [tag rest] = get_tag();
    if ~strcmp(tag, 'modified'), error('bad tag: modified'), end
    modified = strtok(rest,'<> ');
    fprintf('%s created %s; modified %s\n', name, created, modified);
    %     <headers>
    tag = get_tag;
    if ~strcmp(tag, 'headers'), error('bad tag: headers'), end
    while ~strcmp(tag, '/headers')
        tag = get_tag;
    end
    %         <deviceid/>
    %         <firstname/>
    %         <lastname/>
    %         <userid/>
    %     </headers>
    %     <participants>
    if ~strcmp(get_tag(), 'participants'), error('bad tag: participants'), end
        %         <participant>
    if ~strcmp(get_tag(), 'participant'), error('bad tag: participant'), end
    while ~strcmp(tag, '/participants')
        %             <participantid>D2C649D83EEA4540A7920C6461DF25DB</participantid>
        if ~strcmp(get_tag(), 'participantid'), error('bad tag: participantid'), end
        %             <devices>
        if ~strcmp(get_tag(), 'devices'), error('bad tag: devices'), end
        %                 <device>b264ba</device>
        [tag rest] = get_tag;
        devices = [];
        while ~strcmp(tag, '/devices')
            devices = [devices ' ' strtok(rest, '<> ')];
            [tag rest] = get_tag;
        end
        %             </devices>
        while ~strcmp(tag, 'userid')
            [tag rest] = get_tag;
        end
        %             <firstname>Aakarsh</firstname>
        %             <lastname>Palnitkar</lastname>
        %             <userid>apalnitkar6</userid>
        userid = strtok(rest, '<> ');
        %         </participant>
        tag = get_tag;
        tag = get_tag;
        fprintf(out,'%s %s\n', userid, devices);
        %         <participant>
    end
        %         <participant>
        %             <participantid>C60B9007E75A45D99A679EC4A6094456</participantid>
        %             <devices>
        %                 <device>B88B98</device>
        %             </devices>
        %             <firstname>Aaron</firstname>
        %             <lastname>Young</lastname>
        %             <userid>ayoung61</userid>
        %         </participant>
    %     </participants>
    fclose(out);
    fclose(fh);
    % </participantlist>
end

function [tag rest] = get_tag
    global fh
    
    line = fgetl(fh);
    [tag rest] = strtok(line, '<> ');
end
