%% Read image and take input; initialize
% This file will only do segmentation inside the cropped rectangle, but
% learns the model from all the matrix.

clc;clear; close all; addpath('gco-v3.0/matlab')
im_clr = imread('rose_small.jpg');
im = rgb2gray(im_clr);
rect = rectInput(im_clr); % Take input
sz = size(im);
sz = sz(1:2);
Z = double(im(:));
N = numel(Z);

im_crop_clr = im_clr(rect(1):rect(1)+rect(3),rect(2):rect(2)+rect(4),:);
im_crop =im(rect(1):rect(1)+rect(3),rect(2):rect(2)+rect(4));
sz_crop = size(im_crop);
Z_crop = double(im_crop(:));
N_crop = numel(Z_crop);

alpha = ones(size(im));
alpha(rect(1):rect(1)+rect(3),rect(2):rect(2)+rect(4)) = 2;
alpha = alpha(:);
%% Parameters
gamma = 50%10*100;
beta = 0.5/mean((Z_crop - circshift(Z_crop,1)).^2);

%% UNARY
gc_obj = GCO_Create(N_crop,2);

h = [imhist(uint8(Z(alpha == 1))) imhist(uint8(Z(alpha == 2)))];
h = h./repmat(sum(h),256,1);
h = h';

eps = exp(-50);
unary = -10*log(h(:,Z_crop+1)+eps);

GCO_SetDataCost(gc_obj,int32(unary))

%% PAIRWISE
tada = 1; %(m ~= i) 6699,6632

r = zeros(N_crop*8,1);
c = zeros(N_crop*8,1);
s = zeros(N_crop*8,1);
disp('Assembling pairwise matrix')
j = 1;
for i = 1:N_crop
    [x,y] = ind2sub_fast(sz_crop,i);
    
    %8 connectivty
    
    m = sub2ind_fast(sz_crop,min(x+1,sz_crop(1)),y);
    s(j) = 1*(m ~= i)*exp(-beta*(Z_crop(m)-Z_crop(i))^2);
    c(j) = m; r(j) = i;j=j+1;
    
    m = sub2ind_fast(sz_crop,max(x-1,1),y);
    s(j) = 1*(m ~= i)*exp(-beta*(Z_crop(m)-Z_crop(i))^2);
    c(j) = m; r(j) = i;j=j+1;
    
    m = sub2ind_fast(sz_crop,x,min(y+1,sz_crop(2)));
    s(j) = 1*(m ~= i)*exp(-beta*(Z_crop(m)-Z_crop(i))^2);
    c(j) = m; r(j) = i;j=j+1;
    
    m = sub2ind_fast(sz_crop,x,max(y-1,1));
    s(j) = 1*(m ~= i)*exp(-beta*(Z_crop(m)-Z_crop(i))^2);
    c(j) = m; r(j) = i;j=j+1;
    
    
    
    m = sub2ind_fast(sz_crop,min(x+1,sz_crop(1)),min(y+1,sz_crop(2)));
    s(j) = 1/sqrt(2)*(m ~= i)*exp(-beta*(Z_crop(m)-Z_crop(i))^2);
    c(j) = m; r(j) = i;j=j+1;
    
    m = sub2ind_fast(sz_crop,max(x-1,1),max(y-1,1));
    s(j) = 1/sqrt(2)*(m ~= i)*exp(-beta*(Z_crop(m)-Z_crop(i))^2);
    c(j) = m; r(j) = i;j=j+1;
    
    m = sub2ind_fast(sz_crop,max(x-1,1),min(y+1,sz_crop(2)));
    s(j) = 1/sqrt(2)*(m ~= i)*exp(-beta*(Z_crop(m)-Z_crop(i))^2);
    c(j) = m; r(j) = i;j=j+1;
    
    m = sub2ind_fast(sz_crop,min(x+1,sz_crop(1)),max(y-1,1));
    s(j) = 1/sqrt(2)*(m ~= i)*exp(-beta*(Z_crop(m)-Z_crop(i))^2);
    c(j) = m; r(j) = i;j=j+1;
    
end
pairwise = gamma*sparse(r,c,s,N_crop,N_crop);
disp('done')

%GCO_SetSmoothCost(gc_obj,ones(2)-eye(2))
GCO_SetNeighbors(gc_obj,pairwise)
GCO_Expansion(gc_obj);
labels = GCO_GetLabeling(gc_obj);
GCO_Delete(gc_obj)

%% Results
figure
imshow(cutImage(im_crop_clr,labels,2))
title(num2str(beta))

figure
subplot(1,2,1)
imshow(cutImage(im_crop_clr,labels,2))
subplot(1,2,2)
imshow(reshape(double(labels-1),sz_crop))