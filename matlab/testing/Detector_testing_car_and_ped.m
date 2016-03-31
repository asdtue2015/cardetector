%% clear and close everything
clear all; close all; clc;

SETUP=textread('../testing_setup.txt','%s');
%% cd to correct dir
%ROOT_DIR = '/home/shah/asd2015dev/autotrain/';           % Put data folder path HERE !!!!!
ROOT_DIR=SETUP{2,1};
cd([ROOT_DIR,'matlab/testing']);
addpath '../tools'                                      % Add paths for the tools folder  !!!!
addpath '../samples/negative/'
%% options
data_dir = [ROOT_DIR,'/data'];
data_set = '';
%% get detection label directory
cam = 2; % 2 = left color camera
nglabel_dir = fullfile(data_dir,[data_set strcat('/','not_',SETUP{4,1},'_label_') num2str(cam)]);  % read testing labels
%nglabel_dir = fullfile(data_dir,[data_set strcat('/nclabelgr1_') num2str(cam)]);  % read testing labels
nnglabels   = length(dir(fullfile(nglabel_dir, '*.txt')));
%% get testing label directory
label_dir = fullfile(data_dir,[data_set '/testing_label_' num2str(cam)]);      % read positive labels
%label_dir = fullfile(data_dir,[data_set '/label_' num2str(cam)]);      % read positive labels
nlabels   = length(dir(fullfile(label_dir, '*.txt')));
%% image input
image_dir = fullfile(data_dir,[data_set '/testing_image_' num2str(cam)]);       % image directory
%image_dir = fullfile(data_dir,[data_set '/image_' num2str(cam)]);       % image directory
nimages   = length(dir(fullfile(image_dir, '*.png')));
%% Testing loop
npg=20;                       % set image number per group

total= min([nnglabels nimages nlabels])-1;         %total image number
groupn=ceil(total/npg);                    %calculate group number (with 20 images per group)


testingresult=zeros(total,9);
        
        for grp=1:1:(groupn+1)

            

           
            for lab_idx = (0+(grp-1)*npg):1:min((grp*npg-1),total)
             
             testingresult(lab_idx+1,1)=lab_idx;
                true_count = 0;
                false_count = 0;
                %% parse the label files
                objects   = readLabels(label_dir,lab_idx);                   %read car labels
                total_obj = length(objects);                                 % No. of all the cars
                fprintf('Processing Image NO.: %s \n',num2str(lab_idx))
                
                %% get all car rectrangles
                t      = 1;
                car_pt = [];                                                 % an object to store all cars in one image

                dct      = 1;
                dccar_pt = [];

                
                if (strcmp( SETUP{4,1}, 'pedestrian') )
                        for a = 1:total_obj                                          % count car labels and DontCare labels

                            % get the object label type
                            type = objects(a).type;

                            % get left, top, right, bottom pixel coordinates for all cars in image
                            if strcmp( type, 'Pedestrian' )
                                %% save the roi of cars                  
                                t = t + 1;
                            end                           
                        end
                else                 
                    
                    for a = 1:total_obj                                          % count car labels and DontCare labels

                        % get the object label type
                        type = objects(a).type;

                        % get left, top, right, bottom pixel coordinates for all cars in image
                        if strcmp( type, 'Car' )
                            %% save the roi of cars                  
                            t = t + 1;
                        end
                        if strcmp( type, 'DontCare' )
                            %% save the roi of cars
                            dct = dct + 1;
                        end
                    end
                   
                end
                
                
                %% read and display the image
%                 img        = imread(sprintf('%s/%06d.png',image_dir,lab_idx));
%                 figure(1)
%                 imshow(img)
                
                testingresult(lab_idx+1,8)=t-1;
                testingresult(lab_idx+1,9)=dct-1;
 
                qt=1;
                dqt=1;
                
                if (strcmp( SETUP{4,1}, 'pedestrian') )                                     
                            for a = 1:total_obj

                                % get the object label type
                                type = objects(a).type;

                                % get left, top, right, bottom pixel coordinates for all cars in image
                                if (strcmp( type, 'Pedestrian' )&&((objects(a).x2-objects(a).x1+1)*(objects(a).y2-objects(a).y1+1)>=(64*128*0.7)))
                                    %% save the roi of cars
                                    car_pt.(['c',num2str(qt)]) = [objects(a).x1,objects(a).y1,objects(a).x2-objects(a).x1+1,objects(a).y2-objects(a).y1+1]; % get x1, y1, width, height
                                    qt = qt + 1;                               

                                end
                    
                            end  
              else   
                        for a = 1:total_obj

                            % get the object label type
                            type = objects(a).type;

                            % get left, top, right, bottom pixel coordinates for all cars in image
                            if ((strcmp( type, 'Car' )||strcmp( type, 'DontCare' ))&&((objects(a).x2-objects(a).x1+1)*(objects(a).y2-objects(a).y1+1)>=(56*48*0.7)))
                                %% save the roi of cars
                                car_pt.(['c',num2str(qt)]) = [objects(a).x1,objects(a).y1,objects(a).x2-objects(a).x1+1,objects(a).y2-objects(a).y1+1]; % get x1, y1, width, height
                                qt = qt + 1;

                            elseif ((strcmp( type, 'Car' )||strcmp( type, 'DontCare' ))&&((objects(a).x2-objects(a).x1+1)*(objects(a).y2-objects(a).y1+1)<(56*48*0.7)))
                                dqcar_pt.(['c',num2str(dqt)]) = [objects(a).x1,objects(a).y1,objects(a).x2-objects(a).x1+1,objects(a).y2-objects(a).y1+1]; % get x1, y1, width, height
                                dqt = dqt + 1;
                            end

                        end
               end
                
                
                testingresult(lab_idx+1,3)=qt-1;    
                    
                if(~isempty(car_pt))
                    structSize = length(fieldnames(car_pt));
                    detectedcar=zeros(structSize,1);
                end
                %% parse the testing label files
                ngobjects   = readncLabels(nglabel_dir,lab_idx);        %read labels from testing labels
                total_ngobj = length(ngobjects);                        % No. of all testing detections

                %% get all testing rectrangles
                ngt      = 1;
                ngcar_pt = [];
                
                
                if (strcmp( SETUP{4,1}, 'pedestrian') )                     
                        for a = 1:total_ngobj

                            % get the object label type
                            type = ngobjects(a).type;

                            % get left, top, right, bottom pixel coordinates for all cars in image
                            if strcmp( type, './Detector_car_all.yml.backup8;255;0;0;NotCar' )
                                %% save the NotCar roi
                                ngcar_pt.(['c',num2str(ngt)]) = [ngobjects(a).x1,ngobjects(a).y1,ngobjects(a).x2-ngobjects(a).x1+1,ngobjects(a).y2-ngobjects(a).y1+1]; % get x1, y1, width, height
                                ngt = ngt + 1;
                            end
                        end                 
                else    
                        for a = 1:total_ngobj

                            % get the object label type
                            type = ngobjects(a).type;

                            % get left, top, right, bottom pixel coordinates for all cars in image
                            if strcmp( type, './Detector_car_all.yml.backup8;255;0;0;NotCar' )
                                %% save the NotCar roi
                                ngcar_pt.(['c',num2str(ngt)]) = [ngobjects(a).x1,ngobjects(a).y1,ngobjects(a).x2-ngobjects(a).x1+1,ngobjects(a).y2-ngobjects(a).y1+1]; % get x1, y1, width, height
                                ngt = ngt + 1;
                            end
                        end                      
                end    

            %%  Generate negetive mining examples
              if (~isempty(ngcar_pt))
                ngstructSize = length(fieldnames(ngcar_pt));       % get total No. of NotCar in a label
                for j=1:ngstructSize                               % iterate through every NotCar label
                  if (qt>1)                                          % if there is a 'Car' in label and we have read the labels
                       structSize = length(fieldnames(car_pt));       % get total No. of 'Cars'in a label
                        x = ngcar_pt.(['c',num2str(j)])((1));       % get ROI from NotCar items
                        y = ngcar_pt.(['c',num2str(j)])((2));       % get y1 ....
                        w = ngcar_pt.(['c',num2str(j)])((3));       % get width ....
                        h = ngcar_pt.(['c',num2str(j)])((4));       % get height ....
                        
                     
                        test = logical(ones(1,structSize));            % construct array to store test results
                        for b = 1:structSize                         % get ROI from real cars labels
                            x1 = car_pt.(['c',num2str(b)])((1));       % get x1
                            y1 = car_pt.(['c',num2str(b)])((2));       % get y1
                            x2 = car_pt.(['c',num2str(b)])((3));       % get width
                            y2 = car_pt.(['c',num2str(b)])((4));       % get height

%                             cpos=[x1 y1 x2 y2];                           %Display rectangles for Cars
%                              figure(1)
%                             rectangle('Position',cpos,'EdgeColor','blue')
                           
                            switch SETUP{6,1}
                                case 'overlap'
                                   test(b) = rectangle_collision(x1,y1,x2,y2,x,y,w,h); % check for overlaps between NotCar and Dontcare, add the result to a cell to test

                                 case 'area'                               
                                    test(b) = collision_area_based(x1,y1,x2,y2,x,y,w,h);
                                          
                            end           
                        end

                       

                        collision = (any(test == 1));                             %if no DontCare, check if there is collision between NotCar and Car


                        if(collision)                                                % if there is overlap, record this testing label as TRUE
                            %% Record and draw the TRUE detection
                            true_count = true_count + 1;
                            
                            for ii=1:1:length(test)
                                if test(ii)==1
                                    detectedcar(ii)=1;
                                end
                            end
                      
%                             pos=[x y w h];                            % record NotCar ROI
%                             figure(1)
%                             rectangle('Position',pos,'EdgeColor','green') % display Not Car ROI on original image

                            
                        else                                                         % if there is no overlap, record this testing label as FALSE
                           
                           %% Record and draw the FALSE detection
                           false_count = false_count + 1; 
%                            npos=[x y w h];
%                             figure(1)
%                              rectangle('Position',npos,'EdgeColor','red')
                            
                        end

                  else                                          % if there is no car in this image, then all testing labels should be recorded as FALSE.
                    x = ngcar_pt.(['c',num2str(j)])((1));       % get x1
                    y = ngcar_pt.(['c',num2str(j)])((2));       % get y1
                    w = ngcar_pt.(['c',num2str(j)])((3));       % get width
                    h = ngcar_pt.(['c',num2str(j)])((4));       % get height
                    false_count = false_count + 1;
%                     npos=[x y w h];
%                     figure(1)
%                     rectangle('Position',npos,'EdgeColor','red')
                    %% Record the FALSE detection
                    

                  end
                end
              end
                
                
         testingresult(lab_idx+1,5)=true_count;  
         testingresult(lab_idx+1,6)=false_count;
                 
         precision=true_count/(true_count+false_count);
         testingresult(lab_idx+1,7)=precision;
         
         if(~isempty(car_pt))
             testingresult(lab_idx+1,2)=sum(detectedcar);
             recall=sum(detectedcar)/(qt-1);
         else 
             testingresult(lab_idx+1,2)=0;
             recall=NaN;
         end  
         
         
             
         testingresult(lab_idx+1,4)=recall;
       

         

            
                
                
                
                
                
          fclose('all');      
            end
            %%
     
            
            
            
            
            
        end
      
        total_detected=sum(testingresult(:,2));
        total_qualified=sum(testingresult(:,3));
        total_recall=total_detected/total_qualified;
        total_true=sum(testingresult(:,5));
        total_false=sum(testingresult(:,6));
        total_precision=total_true/(total_true+total_false);
        
 fid = fopen(strcat('test_result_',SETUP{4,1},'.txt'),'w');
        fprintf(fid,'%s  %s  %s  %s  %s  %s  %s  %s  %s \n','File_num','Detected','Qualified','Recall','Positives','Falses','Precision','Total Car','Total Dontcare');
        fprintf(fid,'%6.0f    %6.0f    %6.0f    %6.3f    %6.0f    %6.0f    %6.3f    %6.0f    %6.0f \n',testingresult');
        fprintf(fid,' %s    %6.0f    %6.0f    %6.3f    %6.0f    %6.0f    %6.3f   \n','total',total_detected,total_qualified,total_recall,total_true,total_false,total_precision);
        
        fclose(fid);         
