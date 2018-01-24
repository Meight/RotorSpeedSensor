close all
clear

% images = [];
% fps = 30;
% for index = 1:50
%     imageName = strcat('5Hz30fps/5Hz30fps',num2str(index),'.jpg');
%     imageData = imread(imageName);
%     imageData = im2double(imageData);
%     images(:,:,index) = 255*rgb2gray(imageData);
% end
% 
% save images;
% return;

load images;

[height,width,~] = size(images);

imagesROI = permute(images(:,:,1:30), [2,1,3] );
imagesROI = imagesROI(:);

[horizontalMin, horizontalMax, verticalMin, verticalMax] = findRegionOfInterest(imagesROI, height, width, 30);
    