%% clear and close everything
clear all; close all; clc;

%% cd to correct dir
ROOT_DIR = 'C:\Users\zli1\Desktop\Car detect\';
% ROOT_DIR = '/home/shah/Projects/'
cd([ROOT_DIR,'matlab/samples/negative']);
addpath '../../tools'

%% options
data_dir = ['F:\Car detect\data'];
data_set = '';

%% get label directory
cam = 2; % 2 = left color camera
label_dir = fullfile(data_dir,[data_set '/label_' num2str(cam)]);
nlabels   = length(dir(fullfile(label_dir, '*.txt')));

%% image input
image_dir = fullfile(data_dir,[data_set '/image_' num2str(cam)]);
nimages   = length(dir(fullfile(image_dir, '*.png')));

%% HOG block input
hog_dir = fullfile(data_dir,[data_set '/hog_' num2str(cam)]);
nymls   = length(dir(fullfile(hog_dir, '*.yml')));


%% main loop
count = 0;
bigmat  = [];
for lab_idx = 0:1:min([nlabels nimages])-1
    
    
    %% parse the label files
    objects   = readLabels(label_dir,lab_idx);
    total_obj = length(objects);
    
    %% get all car rectrangles
    t      = 1;
    ped_pt = [];
    for a = 1:total_obj
        
        % get the object label type
        type = objects(a).type;        

        % get left, top, right, bottom pixel coordinates for all cars in image
        if strcmp( type, 'Pedestrian' )
%             img_idx =  img_idx + 1; % total of 'Car' 

            %% save the roi
            ped_pt.(['c',num2str(t)]) = [objects(a).x1,objects(a).y1,objects(a).x2-objects(a).x1+1,objects(a).y2-objects(a).y1+1]; % get x1, y1, width, height
            t = t + 1;  
        end
    end
    
    %% read the image
    img        = imread(sprintf('%s/%06d.png',image_dir,lab_idx));
    YamlStruct = parseHOGFile( sprintf('%s/%06d.yml', hog_dir, lab_idx) );
     figure(1)
     imshow(img)
        
    %% generate X negatives per image
    for j = 1:10
        
        %% Iterate through all 'Car' label and check for collision
        if (t>1)                                          % if there is a 'Car' in label and we have read the labels 
            collision = true;                             % initalize collision to 'true'
            structSize = length(fieldnames(ped_pt));      % get total No. of 'Cars'in a label  
            while (collision == true)                     % iterate through all 'Car' label
                [x, y, w ,h] = generate_rectangle_56x48( size(img), 4 ); % generate a roi
                test = logical(ones(1,structSize));
                for b = 1:1:structSize                         % 
                    x1 = ped_pt.(['c',num2str(b)])((1));       % get x1
                    y1 = ped_pt.(['c',num2str(b)])((2));       % get y1
                    x2 = ped_pt.(['c',num2str(b)])((3));       % get width 
                    y2 = ped_pt.(['c',num2str(b)])((4));       % get height 
                    test(b) = rectangle_collision(x1,y1,x2,y2,x,y,w,h); % check for collision, add the result to a cell to test 
                end
                collision = any(test == 1);
            end
            count = count + 1;
        else                                                         % if the label does not have any 'Car' object
            [x, y, w ,h] = generate_rectangle_56x48( size(img), 4 ); % generate a roi but no checks needed
            count = count + 1;
        end
                
        %% construct a negative feature
        [out,window]   = constructHOGFeature( YamlStruct, x, y, w, h, 0 );
        bigmat(count,:)= out(1,:);
        
        %% write the roi of the object to an image
       sprintf('%06d_neg_%1d.png', lab_idx, j )
         img_rsz  = imresize( img, 1/window(5) );
         img_crop = imcrop( img, [window(1,1) window(1,2) window(1,3)-1 window(1,4)-1] );
         figure(2)
         imshow(img_crop)
        %imwrite( img_crop, sprintf('%06d_neg_%1d.png', lab_idx, j ) );
        
    end
    
    fclose('all');
end

%% save for training
save('../../../data/negative_features_pedestrain.mat', 'bigmat');



