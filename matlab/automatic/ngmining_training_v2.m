%% clear and close everything
clear all; close all; clc;
tic
SETUP=textread('../ngmining_setup.txt','%s');
%% cd to correct dir
%ROOT_DIR = '/home/shah/asd2015dev/autotrain/';           % Put data folder path HERE !!!!!
ROOT_DIR=SETUP{2,1};
cd([ROOT_DIR,'matlab/automatic']);
addpath '../tools'                                      % Add paths for the tools folder  !!!!
addpath '../samples/negative/'
%% options
data_dir = [ROOT_DIR,'/data'];
data_set = '';
%% get label directory
cam = 2; % 2 = left color camera
nglabel_dir = fullfile(data_dir,[data_set strcat('/','not_',SETUP{4,1},'_label_') num2str(cam)]);  % read Notcar labels
nnglabels   = length(dir(fullfile(nglabel_dir, '*.txt')));
%% get NG label directory
label_dir = fullfile(data_dir,[data_set '/label_' num2str(cam)]);      % read positive labels
nlabels   = length(dir(fullfile(label_dir, '*.txt')));
%% image input
image_dir = fullfile(data_dir,[data_set '/image_' num2str(cam)]);       % image directory
nimages   = length(dir(fullfile(image_dir, '*.png')));
%% HOG block input
hog_dir = fullfile(data_dir,[data_set '/hog_' num2str(cam)]);          % HOG directory
nymls   = length(dir(fullfile(hog_dir, '*.yml')));


%% Original negative matrix input for SVM training
exbigmat  = importdata(fullfile(data_dir,strcat('/negative_features_',SETUP{4,1},'.mat')));             % Oringinal negative matrix path




%% main loop for car ng mining


bigmat= [];                   % matrix used to store false positives for each group
ngbigmat = [] ;               % matrix used to store false positives for each image

npg=20;                       % set image number per group

total= min([nnglabels nimages nlabels])-1;         %total image number
groupn=ceil(total/npg);                    %calculate group number (with 20 images per group)



switch SETUP{4,1}

    case {'car_back','car_front','car_all'}

        for grp=1:1:(groupn+1)

            count = 0;

            ngbigmat = [] ;
            for lab_idx = (0+(grp-1)*npg):1:min((grp*npg-1),total)

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

                %% parse the NotCar label files
                ngobjects   = readncLabels(nglabel_dir,lab_idx);        %read labels from NotCar labels
                total_ngobj = length(ngobjects);                        % No. of all NotCar

                %% get all NotCar rectrangles
                ngt      = 1;
                ngcar_pt = [];
                for a = 1:total_ngobj

                    % get the object label type
                    type = ngobjects(a).type;

                    % get left, top, right, bottom pixel coordinates for all cars in image
                    if strcmp( type, 'NotCar' )
                        %% save the NotCar roi
                        ngcar_pt.(['c',num2str(ngt)]) = [ngobjects(a).x1,ngobjects(a).y1,ngobjects(a).x2-ngobjects(a).x1+1,ngobjects(a).y2-ngobjects(a).y1+1]; % get x1, y1, width, height
                        ngt = ngt + 1;
                    end
                end

            %%  Generate negetive mining examples
                ngstructSize = length(fieldnames(ngcar_pt));       % get total No. of NotCar in a label
                for j=1:ngstructSize                               % iterate through every NotCar label
                  if (t>1)                                          % if there is a 'Car' in label and we have read the labels
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

                            switch SETUP{6,1}
                                case 'overlap'
                                   test(b) = rectangle_collision(x1,y1,x2,y2,x,y,w,h); % check for overlaps between NotCar and Dontcare, add the result to a cell to test

                                 case 'area'
                                    test(b) = collision_area_based(x1,y1,x2,y2,x,y,w,h);
                            end
                        end

                        if (dct>1)                                            % if there is a DontCare label
                            dcstructSize = length(fieldnames(dccar_pt));       % get total No. of 'DontCare'in a label
                            dctest = logical(ones(1,dcstructSize));
                             for b = 1:dcstructSize                         % get ROI from DontCare labels
                                 x1 = dccar_pt.(['dc',num2str(b)])((1));       % get x1
                                 y1 = dccar_pt.(['dc',num2str(b)])((2));       % get y1
                                 x2 = dccar_pt.(['dc',num2str(b)])((3));       % get width
                                 y2 = dccar_pt.(['dc',num2str(b)])((4));       % get height

                                 switch SETUP{6,1}
                                     case 'overlap'
                                        dctest(b) = rectangle_collision(x1,y1,x2,y2,x,y,w,h); % check for overlaps between NotCar and Dontcare, add the result to a cell to test

                                     case 'area'
                                         dctest(b) = collision_area_based(x1,y1,x2,y2,x,y,w,h);

                                 end
                             end

                            collision = (any(test == 1)||any(dctest==1));             %check if there is collision between NotCar and Car and DontCare

                        else

                            collision = (any(test == 1));                             %if no DontCare, check if there is collision between NotCar and Car

                        end

                        if(collision)                                                % if there is overlap, ignore this NotCar label

                        else                                                         % if there is no overlap, record this NotCar label
                           count = count + 1;
                           %% construct a negative feature for this NotCar label
                            [out,window]   = constructHOGFeature( YamlStruct, x, y, w, h, 0 );
                            ngbigmat(count,:)= out(1,:);
                        end

                  else                                          % if there is no car in this image, then all NotCar should be recorded.
                    x = ngcar_pt.(['c',num2str(j)])((1));       % get x1
                    y = ngcar_pt.(['c',num2str(j)])((2));       % get y1
                    w = ngcar_pt.(['c',num2str(j)])((3));       % get width
                    h = ngcar_pt.(['c',num2str(j)])((4));       % get height
                    count = count + 1;
                    %% construct a negative feature
                    [out,window]   = constructHOGFeature( YamlStruct, x, y, w, h, 0 );
                    ngbigmat(count,:)= out(1,:);

                  end
                end
            end
            %%
            bigmat=[bigmat;ngbigmat];
            fclose('all');
        end

%% main loop for pedestrain ng mining
case 'pedestrian'

        for grp=1:1:(groupn+1)

            count = 0;

            ngbigmat = [] ;
            for lab_idx = (0+(grp-1)*npg):1:min((grp*npg-1),total)

                %% parse the label files
                objects   = readLabels(label_dir,lab_idx);                   %read car labels
                total_obj = length(objects);                                 % No. of all the cars
                disp('Processing Image NO. :')
                lab_idx
                %% get all car rectrangles
                t      = 1;
                ped_pt = [];                                                 % an object to store all cars in one image

                for a = 1:total_obj

                    % get the object label type
                    type = objects(a).type;

                    % get left, top, right, bottom pixel coordinates for all cars in image
                    if strcmp( type, 'Pedestrian' )
                        %% save the roi of cars
                        ped_pt.(['c',num2str(t)]) = [objects(a).x1,objects(a).y1,objects(a).x2-objects(a).x1+1,objects(a).y2-objects(a).y1+1]; % get x1, y1, width, height
                        t = t + 1;
                    end

                end

                %% read and display the image
                img        = imread(sprintf('%s/%06d.png',image_dir,lab_idx));
                YamlStruct = parseHOGFile( sprintf('%s/%06d.yml', hog_dir, lab_idx) );

                %% parse the NotCar label files
                ngobjects   = readncLabels(nglabel_dir,lab_idx);        %read labels from NotCar labels
                total_ncobj = length(ngobjects);                        % No. of all NotCar

                %% get all NotCar rectrangles
                ngt      = 1;
                ngped_pt = [];
                for a = 1:total_ncobj

                    % get the object label type
                    type = ngobjects(a).type;

                    % get left, top, right, bottom pixel coordinates for all cars in image
                    if strcmp( type, 'NotCar' ) %% Need to change back to NotPed in the furture!!!!!
                        %% save the NotCar roi
                        ngped_pt.(['c',num2str(ngt)]) = [ngobjects(a).x1,ngobjects(a).y1,ngobjects(a).x2-ngobjects(a).x1+1,ngobjects(a).y2-ngobjects(a).y1+1]; % get x1, y1, width, height
                        ngt = ngt + 1;
                    end
                end

            %%  Generate negetive mining examples

            if(~(isempty(ngped_pt)))
                    ngstructSize = length(fieldnames(ngped_pt));       % get total No. of NotCar in a label
                    for j=1:ngstructSize                               % iterate through every NotCar label
                      if (t>1)                                          % if there is a 'Car' in label and we have read the labels
                           structSize = length(fieldnames(ped_pt));       % get total No. of 'Cars'in a label
                            x = ngped_pt.(['c',num2str(j)])((1));       % get ROI from NotCar items
                            y = ngped_pt.(['c',num2str(j)])((2));       % get y1 ....
                            w = ngped_pt.(['c',num2str(j)])((3));       % get width ....
                            h = ngped_pt.(['c',num2str(j)])((4));       % get height ....
                            test = logical(ones(1,structSize));            % construct array to store test results
                            for b = 1:structSize                         % get ROI from real cars labels
                                x1 = ped_pt.(['c',num2str(b)])((1));       % get x1
                                y1 = ped_pt.(['c',num2str(b)])((2));       % get y1
                                x2 = ped_pt.(['c',num2str(b)])((3));       % get width
                                y2 = ped_pt.(['c',num2str(b)])((4));       % get height

                                switch SETUP{6,1}
                                    case 'overlap'
                                       test(b) = rectangle_collision(x1,y1,x2,y2,x,y,w,h); % check for overlaps between NotCar and Dontcare, add the result to a cell to test

                                     case 'area'
                                        test(b) = collision_area_based(x1,y1,x2,y2,x,y,w,h);
                                end
                            end


                            collision = (any(test == 1));                             %if no DontCare, check if there is collision between NotCar and Car



                            if(collision)                                                % if there is overlap, ignore this NotCar label

                            else                                                         % if there is no overlap, record this NotCar label
                               count = count + 1;
                               %% construct a negative feature for this NotCar label
                                [out,window]   = constructHOGFeature_64x128( YamlStruct, x, y, w, h, 0 );
                                if(isempty(out))
                                    count=count-1;
                                else
                                    ngbigmat(count,:)= out(1,:);
                                end
                            end

                      else                                          % if there is no car in this image, then all NotCar should be recorded.
                        x = ngped_pt.(['c',num2str(j)])((1));       % get x1
                        y = ngped_pt.(['c',num2str(j)])((2));       % get y1
                        w = ngped_pt.(['c',num2str(j)])((3));       % get width
                        h = ngped_pt.(['c',num2str(j)])((4));       % get height
                        count = count + 1;
                        %% construct a negative feature
                        [out,window]   = constructHOGFeature_64x128( YamlStruct, x, y, w, h, 0 );
                                if(isempty(out))
                                    count=count-1;
                                else
                                    ngbigmat(count,:)= out(1,:);
                                end
                      end
                    end
            end

          end
            %%
            bigmat=[bigmat;ngbigmat];
            fclose('all');
     end





end



%%
exbigmat=[exbigmat;bigmat];                % Combine NG matrix with original matrix

save(strcat('../../data/','/negative_features_',SETUP{4,1},'.mat'), 'exbigmat','-v7.3');
toc
%% %%%%%%%%%%%%
% SVM %%%%%%%%%
%%%%%%%%%%%%%%%%%%
clear all;
%%
tic
SETUP=textread('../ngmining_setup.txt','%s');

pos_samples_file = matfile(strcat('../../data/','/positive_features_',SETUP{4,1},'.mat'));  % Path of original positive matrix
pos_samples      = pos_samples_file.bigmat;

neg_samples_file = matfile(strcat('../../data/','/negative_features_',SETUP{4,1},'.mat'));  % Path of original positive matrix
neg_samples      = neg_samples_file.exbigmat;


switch SETUP{4,1}
    case {'car_back','car_front','car_all'}
        window           = [56 48];
    case 'pedestrian'
        window           = [64 128];
end


npos             = size(pos_samples,1);
nneg             = size(neg_samples,1);
ndim             = size(neg_samples,2);

%% construct class labels
labels = [ones(size(pos_samples,1),1); -1*ones(size(neg_samples,1),1)];

%% SVM training
SVMModel = fitcsvm( [pos_samples;neg_samples], labels );

%% write yml the classifiers file

%% Path to put the new classifier
fid = fopen(strcat('../../data/Detector_',SETUP{4,1},'.yml'),'w');                 % creat the new SVM classifier set output path HERE !!!!!
fid
fprintf(fid,'%%YAML:1.0\n');
fprintf(fid,'width: %i\n',window(1));
fprintf(fid,'height: %i\n',window(2));
fprintf(fid,'detector: [ ');
for i = 1:1:size(SVMModel.Beta,1)
    fprintf(fid,'%.10d, ',SVMModel.Beta(i));
end
fprintf(fid,'%.10d ]',SVMModel.Bias);
fclose(fid);

toc
quit force
