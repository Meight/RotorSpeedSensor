close all
clear
home
nameDir = input('Dir: ');
nameKey = input('Image key: ');
extension = input('Image extension: ');
fps = input('fps = ');
numTime = input('Time length: ');
cumulativeDistribution = zeros(100,2);

%% Find ROI
state = 'Reading...'
for index = 1:50
    imageName = strcat(nameDir,'/',nameKey,num2str(index),extension)
    imageData = imread(imageName);
    imageData = im2double(imageData)*255;
    if (index==1)
        imageDataRed = imageData(:,:,1);
        imageDataGreen = imageData(:,:,2);
        imageDataBlue = imageData(:,:,3);
    else
        imageDataRed(:,:,index) = imageData(:,:,1);
        imageDataGreen(:,:,index) = imageData(:,:,2);
        imageDataBlue(:,:,index) = imageData(:,:,3);
    end
end

imageStdRed = std(imageDataRed,0,3);
imageStdGreen = std(imageDataGreen,0,3);
imageStdBlue = std(imageDataBlue,0,3);
numberPixelPerFrame = size(imageStdRed,1)*size(imageStdRed,2);
maxValueOfImageStd = max([max(max(imageStdRed)) max(max(imageStdGreen)) max(max(imageStdBlue))]);
for index2 = 1:100
    valuePixel = index2*maxValueOfImageStd/100;
    cumulativeDistribution(index2,1) = valuePixel;
    cumulativeDistribution(index2,2) = sum(sum(imageStdRed<=valuePixel)+sum(imageStdGreen<=valuePixel)+sum(imageStdBlue<=valuePixel))/3/numberPixelPerFrame;
end

home
threshold = cumulativeDistribution(sum(cumulativeDistribution(:,2)<=0.9),1)
state = 'Finding threshold Completed'

fig = figure();
subplot(2,2,1);
subimage((imageStdRed>=threshold)*255); grid on; axis on;
title('red');
subplot(2,2,2);
subimage((imageStdGreen>=threshold)*255); grid on; axis on;
title('green');
subplot(2,2,3);
subimage((imageStdBlue>=threshold)*255); grid on; axis on;
title('blue');
subplot(2,2,4);
subimage(((imageStdRed>=threshold)|(imageStdGreen>=threshold)|(imageStdBlue>=threshold))*255); grid on; axis on;
title('total');

BW = (imageStdRed>=threshold)|(imageStdGreen>=threshold)|(imageStdBlue>=threshold);
CC = bwconncomp(BW);
numPixels = cellfun(@numel,CC.PixelIdxList);
[numPixelsMax,idx] = max(numPixels);
BW(:,:) = 0;
BW(CC.PixelIdxList{idx}) = 1;
figure, imshow(BW);

minHorizontal = inf;
maxHorizontal = 0;
for index3 = 1:size(BW,1)
    tempHorizontal = find(BW(index3,:)==1);
    if (min(tempHorizontal)<minHorizontal)
        minHorizontal = min(tempHorizontal);
    end
    if (max(tempHorizontal)>maxHorizontal)
        maxHorizontal = max(tempHorizontal);
    end
end

minVertical = inf;
maxVertical = 0;
for index4 = 1:size(BW,2)
    tempVertical = find(BW(:,index4)==1);
    if (min(tempVertical)<minVertical)
        minVertical = min(tempVertical);
    end
    if (max(tempVertical)>maxVertical)
        maxVertical = max(tempVertical);
    end
end

BW(minVertical:maxVertical,minHorizontal:minHorizontal+2) = 1;
BW(minVertical:maxVertical,maxHorizontal-2:maxHorizontal) = 1;
BW(minVertical:minVertical+2,minHorizontal:maxHorizontal) = 1;
BW(maxVertical-2:maxVertical,minHorizontal:maxHorizontal) = 1;
figure, imshow(BW);

pause(1);

%% Process in ROI
state = 'Processing in ROI'
numRed = zeros(1,numTime*fps);
numGreen = zeros(1,numTime*fps);
numBlue = zeros(1,numTime*fps);
ROIIndex = 1:(numTime*fps);
for index5 = 1:(numTime*fps)
    imageName = strcat(nameDir,'/',nameKey,num2str(index5),extension)
    imageData = imread(imageName);
    imageDataRed = imageData(:,:,1);
    imageDataGreen = imageData(:,:,2);
    imageDataBlue = imageData(:,:,3);
    ROIDataRed = imageDataRed(minVertical:maxVertical,minHorizontal:maxHorizontal);
    ROIDataGreen = imageDataGreen(minVertical:maxVertical,minHorizontal:maxHorizontal);
    ROIDataBlue = imageDataBlue(minVertical:maxVertical,minHorizontal:maxHorizontal);
    if (index5>1)
        ROIDifferrentRed = (ROIDataRed - ROIDataRedPrevious)>50;
        ROIDifferrentGreen = (ROIDataGreen - ROIDataGreenPrevious)>50;
        ROIDifferrentBlue = (ROIDataBlue - ROIDataBluePrevious)>50;
        numRed(index5) = sum(sum(ROIDifferrentRed));
        numGreen(index5) = sum(sum(ROIDifferrentGreen));
        numBlue(index5) = sum(sum(ROIDifferrentBlue));
    end
    ROIDataRedPrevious = ROIDataRed;
    ROIDataGreenPrevious = ROIDataGreen;
    ROIDataBluePrevious = ROIDataBlue;
end

ROIIndexInterpolation = 1:0.01:(numTime*fps);
numRedInterpolation = interp1(ROIIndex,numRed,ROIIndexInterpolation,'spline');
numGreenInterpolation = interp1(ROIIndex,numGreen,ROIIndexInterpolation,'spline');
numBlueInterpolation = interp1(ROIIndex,numBlue,ROIIndexInterpolation,'spline');

figure();
subplot(3,1,1);
plot(ROIIndexInterpolation,numRedInterpolation,'Color','red'); grid on; axis on; hold on;
plot(ROIIndex,numRed,'Color','black','LineStyle','--'); grid on; axis on; hold on;
plot(ROIIndex,ones(numTime*fps)*mean(numRed),'Color','black','LineWidth',2); grid on; axis on;
% figure();
subplot(3,1,2);
plot(ROIIndexInterpolation,numGreenInterpolation,'Color','green'); grid on; axis on; hold on;
plot(ROIIndex,numGreen,'Color','black','LineStyle','--'); grid on; axis on; hold on;
plot(ROIIndex,ones(numTime*fps)*mean(numGreen),'Color','black','LineWidth',2); grid on; axis on;
% figure();
subplot(3,1,3);
plot(ROIIndexInterpolation,numBlueInterpolation,'Color','blue'); grid on; axis on; hold on;
plot(ROIIndex,numBlue,'Color','black','LineStyle','--'); grid on; axis on; hold on;
plot(ROIIndex,ones(numTime*fps)*mean(numBlue),'Color','black','LineWidth',2); grid on; axis on;

% Process in results
numRedMax = zeros(2,1);
n = 1;
for k = 2:length(ROIIndexInterpolation)-1
    if ((numRedInterpolation(1,k)>=numRedInterpolation(1,k-1))&&(numRedInterpolation(1,k)>numRedInterpolation(1,k+1)))
        numRedMax(:,n) = [numRedInterpolation(k); ROIIndexInterpolation(k)];
    end
    n = n+1;
end

numGreenMax = zeros(2,1);
n = 1;
for k = 2:length(ROIIndexInterpolation)-1
    if ((numGreenInterpolation(1,k)>=numGreenInterpolation(1,k-1))&&(numGreenInterpolation(1,k)>numGreenInterpolation(1,k+1)))
        numGreenMax(:,n) = [numGreenInterpolation(k); ROIIndexInterpolation(k)];
    end
    n = n+1;
end

numBlueMax = zeros(2,1);
n = 1;
for k = 2:length(ROIIndexInterpolation)-1
    if ((numBlueInterpolation(1,k)>=numBlueInterpolation(1,k-1))&&(numBlueInterpolation(1,k)>numBlueInterpolation(1,k+1)))
        numBlueMax(:,n) = [numBlueInterpolation(k); ROIIndexInterpolation(k)];
    end
    n = n+1;
end

numRedMaxReal = numRedMax(:,numRedMax(1,:)>mean(numRed));
numGreenMaxReal = numGreenMax(:,numGreenMax(1,:)>mean(numGreen));
numBlueMaxReal = numBlueMax(:,numBlueMax(1,:)>mean(numBlue));

numRedMaxRealModified = numRedMaxReal(:,2:length(numRedMaxReal));
numGreenMaxRealModified = numGreenMaxReal(:,2:length(numGreenMaxReal));
numBlueMaxRealModified = numBlueMaxReal(:,2:length(numBlueMaxReal));

timeLength = (max(numRedMaxRealModified(2,:)) - min(numRedMaxRealModified(2,:)))*1/fps
numMax = length(numRedMaxRealModified(1,:))-1
speed = 60*numMax/timeLength
