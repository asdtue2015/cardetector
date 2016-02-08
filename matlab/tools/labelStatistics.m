%% clear and close everything
clear all; close all; clc;

%% options
ROOT_DIR = '/home/gijs/projects/vslam/Programming/c/';
% ROOT_DIR = '/home/shah/Projects/'
data_dir = [ROOT_DIR,'/TUE_Multiclass_Detector/data'];
data_set = '';

%% get label directory
cam = 2; % 2 = left color camera
label_dir = fullfile(data_dir,[data_set '/label_' num2str(cam)]);
nlabels   = length(dir(fullfile(label_dir, '*.txt')));

%% main loop
img_idx   = 0;
count     = 1;
roiWidht  = [];
roiHeight = [];
roiRatio  = [];
for lab_idx = 0:1:nlabels-1

    %% parse the label files
    objects = readLabels(label_dir,lab_idx);
    
    %% for each object in the image
    j = 0;
    for a = 1 :1:length(objects)
        
        %% get type of object
        s1 = objects(a).type;
        ostring = 'Car';
        xbegin  = objects(a).x1;
        ybegin  = objects(a).y1;
        width   = objects(a).x2-objects(a).x1;
        height  = objects(a).y2-objects(a).y1;
        ratio   = width/height;
        angle   = objects(a).alpha;
        
        %% is this an oject of interest
        state = not((strcmp(objects(a).type,ostring))) | (objects(a).truncation>0.15) | (not(objects(a).occlusion==0)) | ((height)<40 ) | (objects(a).alpha >=-pi/2+0.07) | ((objects(a).alpha <=-pi/2-0.07));% | (objects(a).alpha <=-pi/2-0.07));
        
        %% found another object of interest
        if (state ==0)
            roiWidht  = [roiWidht width];
            roiHeight = [roiHeight height]; 
            roiRatio  = [roiRatio width/height];
        end
    end
end

%% statistics
size(roiWidht,2)
widht  = mean(roiWidht,2)
height = mean(roiHeight,2)
ratio  = mean(roiRatio,2)

figure(1)
hist(roiWidht,[0:5:600])
grid on;
title('Width');

figure(2)
hist(roiHeight,[0:5:600])
grid on;
title('Height');

figure(3)
hist(roiRatio,[0:0.1:2])
grid on;
title('Ratio');

