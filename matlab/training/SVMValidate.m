%% clear and close everything
clear all; close all; clc;

%% cd to correct dir
ROOT_DIR = 'C:\Users\zli1\Desktop\Car detect\';
% ROOT_DIR = '/home/shah/Projects/'
cd( [ROOT_DIR,'/matlab/training'] );

%% load the feature files
pos_samples_file = matfile('../../data/positive_features.mat');
pos_samples      = pos_samples_file.bigmat; 
npos             = size(pos_samples,1)
neg_samples_file = matfile('../../data/negative_features.mat'); 
neg_samples      = neg_samples_file.bigmat;  
nneg             = size(neg_samples,1)
ndim             = size(neg_samples,2)

%% parse the SVM model
fid = fopen('../../data/carDetector56x48.yml','r');
str = fscanf(fid,'%s');
SVMModel = eval(['[',str(37:end-1),']']);
SVMModel = SVMModel';

%% test samples
pos_score = pos_samples*SVMModel(1:end-1)+SVMModel(end);
neg_score = neg_samples*SVMModel(1:end-1)+SVMModel(end);

%% scores
pos_score = sum(0 < pos_score,1)/size(pos_score,1)
neg_score = sum(0 > neg_score,1)/size(neg_score,1)
