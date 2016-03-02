%% clear and close everything
clear all; close all; clc;

%% cd to correct dir
ROOT_DIR = '/home/hazem/Desktop/cardetectz/';
% ROOT_DIR = '/home/shah/Projects/'
cd( [ROOT_DIR,'/matlab/training'] );

%% load the feature files
window           = [56 48];
pos_samples_file = matfile('../../data/positive_features_front.mat');
pos_samples      = pos_samples_file.bigmat; 
npos             = size(pos_samples,1)
neg_samples_file = matfile('../../data/front_ov_100h.mat'); 
neg_samples      = neg_samples_file.exbigmat;  
nneg             = size(neg_samples,1)
ndim             = size(neg_samples,2)

%% construct class labels
labels = [ones(size(pos_samples,1),1); -1*ones(size(neg_samples,1),1)];

%% SVM training
SVMModel = fitcsvm( [pos_samples;neg_samples], labels );

%% write yml the classifiers file
fid = fopen('../../data/carDetector56x48_front_ov_100h_centroids.yml','w');
fprintf(fid,'%%YAML:1.0\n');  
fprintf(fid,'width: %i\n',window(1));
fprintf(fid,'height: %i\n',window(2));
fprintf(fid,'detector: [ ');   
for i = 1:1:size(SVMModel.Beta,1)
    fprintf(fid,'%.10d, ',SVMModel.Beta(i));
end
fprintf(fid,'%.10d ]',SVMModel.Bias);
fclose(fid);
       
%% analysis
%CVSVMModel = crossval(SVMModel);
%classLoss  = kfoldLoss(CVSVMModel)