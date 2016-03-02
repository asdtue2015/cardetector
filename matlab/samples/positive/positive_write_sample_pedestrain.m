%% clear and close everything
clear all; close all; clc;

%% cd to correct dir
ROOT_DIR = 'C:\Users\zli1\Desktop\Car detect\';
% ROOT_DIR = '/home/shah/Projects/'
cd([ROOT_DIR,'matlab/samples/positive']);
addpath '../../tools'

%% options
data_dir = 'F:\Car detect\data';
data_set = '';

%% get label directory
cam = 2; % 2 = left color camera
label_dir = 'F:\Car detect\data\label_2';      % read positive labels
nlabels   = length(dir(fullfile(label_dir, '*.txt')));

%% image input
image_dir = 'F:\Car detect\data\image_2';
nimages   = length(dir(fullfile(image_dir, '*.png')));

%% HOG block input
hog_dir = 'F:\Car detect\data\hog_2';
nymls   = length(dir(fullfile(hog_dir, '*.yml')));

%% main loop
img_idx = 0;
count   = 1;
bigmat  = [];
for lab_idx = 1:1:min([nlabels nimages])-1
    
    %% parse the label files
    objects = readLabels(label_dir,lab_idx);
    
    %% for each object in the image
    j = 0;
    for a = 1 :1:length(objects)
        
        %% get type of object
        s1 = objects(a).type;
        ostring = 'Pedestrian';
        xbegin  = objects(a).x1;
        ybegin  = objects(a).y1;
        width   = objects(a).x2-objects(a).x1;
        height  = objects(a).y2-objects(a).y1;
        %ratio   = width/height;
       % angle   = objects(a).alpha;
        
        %% is this an oject of interest
        state = not(strcmp(objects(a).type,ostring)) | (objects(a).truncation>0.15) | (objects(a).occlusion==2) | (objects(a).occlusion==3) | (height<48) ;
        
        %% found another object of interest
        if (state == 0)
            
            %% only for first object load data
            if j == 0
                img        = imread( sprintf('%s/%06d.png', image_dir, lab_idx) );
                YamlStruct = parseHOGFile( sprintf('%s/%06d.yml', hog_dir, lab_idx) );                
            end
            
            %% increase output counter
            j = j + 1;
                                     
            %% position of label
            pos = [objects(a).x1, objects(a).y1, objects(a).x2-objects(a).x1+1, objects(a).y2-objects(a).y1+1];  
            
            %% show image and label
            figure(1)
            imshow(img);
            rectangle('Position',pos,'EdgeColor','red')
            
            %% get the HOG descriptor                      
            [out,window] = constructHOGFeature( YamlStruct, pos(1), pos(2), pos(3), pos(4), 0 );
            
            %% valid feature locations
            if~isempty(out)
                
                %% write the roi of the object to an image
                sprintf('%06d_pos_%1da.png', lab_idx, j )
                img_rsz  = imresize( img, 1/window(1,5) );
                img_crop = imcrop( img_rsz, [window(1,1) window(1,2) window(1,3)-1 window(1,4)-1] );
                figure(2)
                imshow(img_crop)

                %% save all HOG features
                for nf = 1:size(out,1)               
                    img_idx           = img_idx + 1;
                    bigmat(img_idx,:) = out(nf,:);
                end

            end
            
            %% get the HOG descriptor with scale offset          
            [out,window] = constructHOGFeature( YamlStruct, pos(1), pos(2), pos(3), pos(4), 1 );
            
            %% valid feature locations
            if~isempty(out)
                
                %% save all HOG features
                for nf = 1:size(out,1)               
                    img_idx           = img_idx + 1;
                    bigmat(img_idx,:) = out(nf,:);
                end

            end
            
        end
    end
    
    fclose('all');
end

%% save for training
save('../../../data/positive_features_pedestrain.mat', 'bigmat');

