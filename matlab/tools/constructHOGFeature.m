%%
%% Create the HOG feature for the ROI
%%
function [ out, window ] = constructHOGFeature( YamlStruct, x, y, label_width, label_height, scale_offset )

    %% resolution of the training image
    lab_res = [label_width label_height];

    %% win size 
    win_size = [56 48];

    %% number of HOG blocks in window
    Ax = win_size(1)/8 - 1; % in x direction
    Ay = win_size(2)/8 - 1; % in y direction

    %% read yaml file with the raw HOG blocks
    nlevels         = YamlStruct.level;
    nlevels         = str2double(nlevels);
    block_hist_size = YamlStruct.blockhistsize;
    block_hist_size = str2double(block_hist_size);
    scale_level     = YamlStruct.scaleList;

    %% calculate window width for each level in the image pyramid
    for a  = 1:nlevels
        value              = win_size(1) * scale_level{a};
        cell_res_width(a)  = floor(value);
        value              = win_size(2) * scale_level{a};
        cell_res_height(a) = floor(value);
    end

    %% choose the first level in which the window fully encloses the ROI
    index = find( 0 <= (cell_res_width  - lab_res(1)) & 0 <= (cell_res_height - lab_res(2)) );
    if isempty(index)
        index = size(scale_level,2);
    else
        index = index(1)+scale_offset;
        if size(scale_level,2) < index
           index = size(scale_level,2); 
        end
    end

    %% compute the upper left corner of the ROI in the selected level
    %% taking into consideration an 8 pixel stride
    label_x = x + lab_res(1)/2;             % to center of roi
    label_y = y + lab_res(2)/2;             % to center of roi
    label_x = label_x / scale_level{index}; % coordinates in correct scale level
    label_y = label_y / scale_level{index}; % coordinates in correct scale level
    label_x = label_x - win_size(1)/2;      % to upper-left corner of roi
    label_y = label_y - win_size(2)/2;      % to upper-left corner of roi
    if label_x<8
        label_x = 8;
    end
    if label_y<8
        label_y = 8;
    end            

    %% create the features for effective windows aligned to 8 pixel stride (floor,floor)
    window = [];
    out    = [];
    wnd    = [ 8*floor(label_x/8) 8*floor(label_y/8) win_size(1) win_size(2) scale_level{index} ];
    dsc    = joinHogBlocks( YamlStruct, floor(label_x/8), floor(label_y/8), block_hist_size, index, Ax, Ay );
    if ~isempty(dsc)
        window = [window; wnd];
        out    = [out; dsc];
    end

    %% create the features for effective windows aligned to 8 pixel stride (floor,ceil)
    wnd = [ 8*floor(label_x/8) 8*ceil(label_y/8)  win_size(1) win_size(2) scale_level{index} ];
    dsc = joinHogBlocks( YamlStruct, floor(label_x/8), ceil(label_y/8),  block_hist_size, index, Ax, Ay );
    if ~isempty(dsc)
        window = [window; wnd];
        out    = [out; dsc];
    end

    %% create the features for effective windows aligned to 8 pixel stride (ceil,floor)
    wnd = [ 8*ceil(label_x/8)  8*floor(label_y/8) win_size(1) win_size(2) scale_level{index} ];
    dsc = joinHogBlocks( YamlStruct, ceil(label_x/8),  floor(label_y/8), block_hist_size, index, Ax, Ay );
    if ~isempty(dsc)
        window = [window; wnd];
        out    = [out; dsc];
    end

    %% create the features for effective windows aligned to 8 pixel stride (ceil,ceil)
    wnd = [ 8*ceil(label_x/8)  8*ceil(label_y/8)  win_size(1) win_size(2) scale_level{index} ];
    dsc = joinHogBlocks( YamlStruct, ceil(label_x/8),  ceil(label_y/8),  block_hist_size, index, Ax, Ay );
    if ~isempty(dsc)
        window = [window; wnd];
        out    = [out; dsc];
    end

end


%% put the HOG blocks together
%% use column major over blocks as it is the default of opencv
function [out] = joinHogBlocks( YamlStruct, Ix, Iy, block_hist_size, index, Ax, Ay )
 
%% setup the HOG blocks
feature_level       = (YamlStruct.featList{index})'; %% why the minus ? (probably for compatability with OpenCV)
total_element_level = YamlStruct.elementList{index};
blocks_per_img      = YamlStruct.blocksperimgList{index};
Blocks              = reshape( feature_level, block_hist_size, total_element_level/block_hist_size );

%% create the HOG descriptor (column major)
Ib = (Iy-1) * blocks_per_img(1) + Ix; % start
a  = 0;

%% for each column
for i = 1:Ax
        
    %% for each row
    for j = 0 : blocks_per_img(1) : blocks_per_img(1) * (Ay-1) 
        
        %% get the block HOG data
        a           = a + 1;        
        block_index = Ib + j + i;
%         [block_index Ib j i]
        if (block_index <= blocks_per_img(1) * blocks_per_img(2))
            
            %% inside image
            s1(:,a) = Blocks(:,block_index);
        else
            
            %% outside do not use
            out = [];
            return
        end
        
    end
end

%% return the HOG descriptor
out = s1(:)';

end


    
    
