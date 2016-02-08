function yaml = parseHOGFile(file)

    % open the file for (binary) reading
    fid = fopen(file);
    str = fread(fid);
    str = char(str');    
    
    %% get the histogram size and number of image pyramid levels
    blockhistsize = regexpi(str,'block hist size: *([0-9.]*)','tokens','once');
    level         = regexpi(str,'Levels: *([0-9]*)','tokens','once');
    yaml.blockhistsize = blockhistsize;
    yaml.level         = level;
    
    %% parse scales
    scale = regexpi(str,'Scale[0-9]*: *([0-9.]*)','match');
    scaleList = cell(1,1);
    for i = 1:numel(scale)
        scaleNum  = str2double(regexp(scale{i},'Scale([0-9]*)','tokens','once'));
        parts     = regexpi(scale{i},':','split');
        scaleVals = eval(['[',regexprep(strtrim(parts{2}),'\r\n',','),']']);
        scaleList{scaleNum} = scaleVals;
    end
    yaml.scaleList = scaleList;
    
    %% parse the blocks per pyramid level
    blocksperimg = regexpi(str,'blocksperimg[0-9]*: \[([ 0-9.,]*)\]','match');
    blocksperimgList = cell(1,1);
    for i = 1:numel(blocksperimg)
        blocksperimgNum  = str2double(regexp(blocksperimg{i},'blocksperimg([0-9]*)','tokens','once'));
        parts            = regexpi(blocksperimg{i},':','split');
        blocksperimgVals = eval(['[',regexprep(strtrim(parts{2}),'\r\n',','),']']);
        blocksperimgList{blocksperimgNum} = blocksperimgVals;
    end
    yaml.blocksperimgList = blocksperimgList;

    %% parse the number of elements per pyramid level 
    elements = regexpi(str,'Elements[0-9]*:[\r\n \-0-9.e]*','match');
    elementsList = cell(1,1);
    for i = 1:numel(elements)
        elementNum = str2double(regexp(elements{i},'Elements([0-9]*)','tokens','once'));
        parts = regexpi(elements{i},':','split');
        eleVals = eval(['[',regexprep(strtrim(parts{2}),'\r\n',','),']']);
        elementList{elementNum} = eleVals;
    end
    yaml.elementList = elementList;
    
    %% parse the feature elements per pyramid level
    features = regexpi(str,'Features[0-9]*: \[STARTBINARY(.*?)ENDBINARY\]','match');
    featList = cell(1,1);
    for i = 1:numel(features)
        featNum = str2double(regexp(features{i},'Features([0-9]*)','tokens','once'));
        parts   = regexpi(features{i},'[STARTBINARY','split');
        raw     = parts{2};
        raw     = raw(1:end-10); % remove "ENDBINARY]"
        raw     = uint8(raw);
        raw     = double(typecast(raw,'single'));
        featList{featNum} = raw;
    end
    yaml.featList = featList;
  
end