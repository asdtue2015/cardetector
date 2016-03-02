%% clear and close everything
clear all; close all; clc;
tic
%% cd to correct dir
ROOT_DIR = '/home/hazem/Desktop/cardetectz/';
% ROOT_DIR = '/home/shah/Projects/'
cd([ROOT_DIR,'matlab/ngmining']);
addpath '../tools'
addpath '../samples/negative/'
%% options
data_dir = [ROOT_DIR,'/data'];
data_set = '';
%% get label directory
cam = 2; % 2 = left color camera
nclabel_dir = fullfile(data_dir,[data_set '/nclabelfront_' num2str(cam)]);  % read Notcar labels
nnclabels   = length(dir(fullfile(nclabel_dir, '*.txt')));

label_dir = 'F:\Car detect\data\label_2';      % read positive labels
nlabels   = length(dir(fullfile(label_dir, '*.txt')));
%% image input
image_dir = 'F:\Car detect\data\image_2';
nimages   = length(dir(fullfile(image_dir, '*.png')));
%% HOG block input
hog_dir = 'F:\Car detect\data\hog_2';
nymls   = length(dir(fullfile(hog_dir, '*.yml')));

%% main loop
count = 0;
bigmat  = importdata('../../data/negative_features.mat');
ncbigmat = [] ;
%%
%for lab_idx = 0:1:min([nnclabels nimages])-1   
    lab_idx = 13;
    %% parse the label files
    objects   = readLabels(label_dir,lab_idx);                   %read car labels
    total_obj = length(objects);                                 % No. of all the cars
    disp('Processing Image NO. :')
    lab_idx
    %% get all car rectrangles
    t      = 1;
    car_pt = [];                                                 % an object to store all cars in one image 
    
    dct      = 1;
    dccar_pt = [];  
    
    for a = 1:total_obj
        
        % get the object label type
        type = objects(a).type;        

        % get left, top, right, bottom pixel coordinates for all cars in image
        if strcmp( type, 'Car' )
            %% save the roi of cars
            car_pt.(['c',num2str(t)]) = [objects(a).x1,objects(a).y1,objects(a).x2-objects(a).x1+1,objects(a).y2-objects(a).y1+1]; % get x1, y1, width, height
            t = t + 1;  
        end
        
        if strcmp( type, 'DontCare' )
            %% save the roi of cars
            dccar_pt.(['dc',num2str(dct)]) = [objects(a).x1,objects(a).y1,objects(a).x2-objects(a).x1+1,objects(a).y2-objects(a).y1+1]; % get x1, y1, width, height
            dct = dct + 1;  
        end
        
    end
    
    %% read and display the image
    img        = imread(sprintf('%s/%06d.png',image_dir,lab_idx));
    YamlStruct = parseHOGFile( sprintf('%s/%06d.yml', hog_dir, lab_idx) );
     figure(1)
     imshow(img)

   
    %% parse the NotCar label files
    ncobjects   = readncLabels(nclabel_dir,lab_idx);        %read labels from NotCar labels
    total_ncobj = length(ncobjects);                        % No. of all NotCar 
    
    %% get all NotCar rectrangles
    nct      = 1;
    nccar_pt = [];
    for a = 1:total_ncobj
        
        % get the object label type
        type = ncobjects(a).type;        

        % get left, top, right, bottom pixel coordinates for all cars in image
        if strcmp( type, 'NotCar' )
            %% save the NotCar roi
            nccar_pt.(['c',num2str(nct)]) = [ncobjects(a).x1,ncobjects(a).y1,ncobjects(a).x2-ncobjects(a).x1+1,ncobjects(a).y2-ncobjects(a).y1+1]; % get x1, y1, width, height
            nct = nct + 1;  
        end
    end 
     
%%  Generate negetive mining examples
    ncstructSize = length(fieldnames(nccar_pt));       % get total No. of NotCar in a label
    for j=1:ncstructSize                               % iterate through every NotCar label
      if (t>1)                                          % if there is a 'Car' in label and we have read the labels  
          
                                                        
           structSize = length(fieldnames(car_pt));       % get total No. of 'Cars'in a label
           
                                                        
             
            x = nccar_pt.(['c',num2str(j)])((1));       % get ROI from NotCar items
            y = nccar_pt.(['c',num2str(j)])((2));       % get y1 ....
            w = nccar_pt.(['c',num2str(j)])((3));       % get width ....
            h = nccar_pt.(['c',num2str(j)])((4));       % get height ....
            
            
            

                pos=[x y w h];                            % record NotCar ROI
%                 img_crop = imcrop( img, [x y w h] );    % display NotCar ROI
%                 figure
%                 imshow(img_crop)
                figure(1)
                rectangle('Position',pos,'EdgeColor','green') % display Not Car ROI on original image
            
            
            
            
            
            
            test = logical(ones(1,structSize));            % construct array to store test results
            for b = 1:structSize                         % get ROI from real cars labels
                x1 = car_pt.(['c',num2str(b)])((1));       % get x1
                y1 = car_pt.(['c',num2str(b)])((2));       % get y1
                x2 = car_pt.(['c',num2str(b)])((3));       % get width 
                y2 = car_pt.(['c',num2str(b)])((4));       % get height 
                
                cpos=[x1 y1 x2 y2];                           %Display rectangles for Cars
                figure(1)
                rectangle('Position',cpos,'EdgeColor','blue')
                
                
                test(b) = rectangle_collision(x1,y1,x2,y2,x,y,w,h); % check for overlaps between NotCar and Car, add the result to a cell to test
               % test(b) = collision_centroids_based(x1,y1,x2,y2,x,y,w,h);
                
%                 if(test(b))                     
%                     figure(1)
%                     rectangle('Position',[x y w h],'EdgeColor','cyan')
%                 end
            end
            
            if (dct>1)                                            % if there is a DontCare label
                dcstructSize = length(fieldnames(dccar_pt));       % get total No. of 'DontCare'in a label
                dctest = logical(ones(1,dcstructSize));               
                 for b = 1:dcstructSize                         % get ROI from DontCare labels
                     x1 = dccar_pt.(['dc',num2str(b)])((1));       % get x1
                     y1 = dccar_pt.(['dc',num2str(b)])((2));       % get y1
                     x2 = dccar_pt.(['dc',num2str(b)])((3));       % get width 
                     y2 = dccar_pt.(['dc',num2str(b)])((4));       % get height 
                
                     dcpos=[x1 y1 x2 y2];                              %Display rectangles for DontCare
                     figure(1)
                     rectangle('Position',dcpos,'EdgeColor','magenta')
                
                     
                      dctest(b) = rectangle_collision(x1,y1,x2,y2,x,y,w,h); % check for overlaps between NotCar and Dontcare, add the result to a cell to test 
                   % dctest(b) = collision_centroids_based(x1,y1,x2,y2,x,y,w,h);
                    
%                     if(dctest(b))
%                        
%                         figure(1)
%                         rectangle('Position',[x y w h],'EdgeColor','cyan')
%                     end
                    
                    
                 end
     
                collision = (any(test == 1)||any(dctest==1));             %check if there is collision between NotCar and Car and DontCare
            
            else
            
                collision = (any(test == 1));                             %if no DontCare, check if there is collision between NotCar and Car
            
            end
            
            
            
            
            if(collision)                                                % if there is overlap, ignore this NotCar label
            
                                                          
            else                                                         % if there is no overlap, record this NotCar label
               count = count + 1;
%                img_crop = imcrop( img, [x y w h] );                    % display this NotCar ROI in a new figure            
%                figure(88)              
%                imshow(img_crop)
               npos=[x y w h];
               figure(1)
               rectangle('Position',npos,'EdgeColor','red')
               %% construct a negative feature for this NotCar label
                [out,window]   = constructHOGFeature( YamlStruct, x, y, w, h, 0 );
                ncbigmat(count,:)= out(1,:);
               %% Display the Hog ROI of the NotCar                   
%                 sprintf('N%05d_neg_%1d.png', lab_idx, j ) 
%                 img_rsz  = imresize( img, 1/window(1,5) ); 
%                 img_crop = imcrop( img_rsz, [window(1,1) window(1,2) window(1,3)-1 window(1,4)-1] );
%                 figure(99)
%                 imshow(img_crop)
            end
            
         
      else                                          % if there is no car in this image, then all NotCar should be recorded.
        x = nccar_pt.(['c',num2str(j)])((1));       % get x1
        y = nccar_pt.(['c',num2str(j)])((2));       % get y1
        w = nccar_pt.(['c',num2str(j)])((3));       % get width 
        h = nccar_pt.(['c',num2str(j)])((4));       % get height   
        count = count + 1; 
%         img_crop = imcrop( img, [x y w h] );    display this NotCar ROI
%         figure(88)              
%         imshow(img_crop)
         npos=[x y w h];
        figure(1)
        rectangle('Position',npos,'EdgeColor','red')
        %% construct a negative feature
        [out,window]   = constructHOGFeature( YamlStruct, x, y, w, h, 0 );
        ncbigmat(count,:)= out(1,:);
        %% write the roi of the object to an image
%         sprintf('N%05d_neg_%1d.png', lab_idx, j )
%         img_rsz  = imresize( img, 1/window(1,5) );
%         img_crop = imcrop( img_rsz, [window(1,1) window(1,2) window(1,3)-1 window(1,4)-1] );
%         figure(99)
%         imshow(img_crop)
        
      end
        
    
      
    end 


%end
%%
bigmat=[bigmat;ncbigmat];
toc
%% save for training
%save('../../../data/negative_features.mat', 'bigmat');
%save('../../data/notcar_features.mat', 'ncbigmat');
