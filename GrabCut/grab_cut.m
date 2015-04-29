%% Read image and take input; initialize
% for color images
clc;clear; close all; addpath('gco-v3.0/matlab')
im_clr = imread('parrot_small.jpg');
im = im_clr;
rect = rectInput(im_clr); % Take input
sz = size(im);
sz = sz(1:2);

N = sz(1)*sz(2);
Z = double(reshape(im,N,3));

alpha = ones(sz(1),sz(2));
alpha(rect(1):rect(1)+rect(3),rect(2):rect(2)+rect(4)) = 2;
alpha = alpha(:);

im_crop_clr = im_clr(rect(1):rect(1)+rect(3),rect(2):rect(2)+rect(4),:);
N_crop = size(im_crop_clr,1)*size(im_crop_clr,2);


%% Pairwise
gamma = 20; %for smoothening
beta = 0.5/mean2((Z - circshift(Z,1)).^2); %for edge contrast; more beta - less contrast considered as edges 
k = 3; %number of components in gmm

pairwise = assmeblePairwise(im,gamma,beta);

maxIter = 3;
%% Iterations
for i = 1:maxIter 
    %% Unary
    tic
    gmm_back = gmdistribution.fit(Z(alpha == 1,:),k);
    gmm_fore = gmdistribution.fit(Z(alpha == 2,:),k);
    
    
    pdf_back = -log(pdf(gmm_back,Z));
    pdf_fore = -log(pdf(gmm_fore,Z));
    unary = [pdf_back, pdf_fore]';
    toc
    %% GCO
    gc_obj = GCO_Create(N,2);
    GCO_SetDataCost(gc_obj,int32(unary))
    %GCO_SetSmoothCost(gc_obj,ones(2)-eye(2))
    GCO_SetNeighbors(gc_obj,pairwise)
    GCO_Expansion(gc_obj);
    labels = GCO_GetLabeling(gc_obj);
    GCO_Delete(gc_obj)
    alpha = labels;
    
end
%% Results
figure
imshow(cutImage(im_clr,labels,2))
title(num2str(beta))

figure
subplot(1,2,1)
imshow(cutImage(im_clr,labels,2))
subplot(1,2,2)
imshow(reshape(double(labels-1),sz))