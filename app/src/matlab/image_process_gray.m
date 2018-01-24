close all
clear
home

%% Parameters
amountOfImagesForROIDetection = 50;
percentageThreshold = 0.9;
showBlueAndGreenComponents = false;

colors = ['f1faee'; 'a8dadc'; '457b9d'; '1d3557'; 'e63946'];
colors = hex2rgb(colors)/255;

nameDir = '20Hz_30fps'; %input('Dir: ');
nameKey = nameDir; %input('Image key: ');
extension = 'jpg'; %input('Image extension: ');
fps = input('fps = ');
numTime = input('Time length: ');
cumulativeDistribution = zeros(100,2);

%% Find ROI
disp('Determining ROI...');

firstImage = imread(strcat(nameDir,'/','1.',extension));
[nbRows, nbColumns, ~] = size(firstImage);
images = zeros(nbRows, nbColumns, amountOfImagesForROIDetection);
images(:,:,1) = double(rgb2gray(firstImage));
for index = 2:amountOfImagesForROIDetection
    images(:,:,index) = double(rgb2gray(imread(strcat(nameDir,'/',num2str(index),'.',extension))));
end

imagesStandardDeviation = std(images,0,3);
amountOfPixelsPerFrame = size(imagesStandardDeviation,1)*size(imagesStandardDeviation,2);
maxValueOfImagesStd = max(max(imagesStandardDeviation));
for index = 1:100
    valuePixel = index*maxValueOfImagesStd/100;
    cumulativeDistribution(index,1) = valuePixel;
    cumulativeDistribution(index,2) = sum(sum(imagesStandardDeviation<=valuePixel))/amountOfPixelsPerFrame;
end

home
threshold = cumulativeDistribution(sum(cumulativeDistribution(:,2)<=percentageThreshold),1);
disp('Finding threshold completed.');

% fig = figure();
% subplot(2,2,1);
% subimage((imageStdRed>=threshold)*255); grid on; axis on;
% title('red');
% subplot(2,2,2);
% subimage((imageStdGreen>=threshold)*255); grid on; axis on;
% title('green');
% subplot(2,2,3);
% subimage((imageStdBlue>=threshold)*255); grid on; axis on;
% title('blue');
% subplot(2,2,4);
% subimage(((imageStdRed>=threshold)|(imageStdGreen>=threshold)|(imageStdBlue>=threshold))*255); grid on; axis on;
% title('total');

BW = imagesStandardDeviation >= threshold;
CC = bwconncomp(BW);
numPixels = cellfun(@numel,CC.PixelIdxList);
[numPixelsMax,idx] = max(numPixels);
BW(:,:) = 0;
BW(CC.PixelIdxList{idx}) = 1;
% figure, imshow(BW);

%% Find bounding box.
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

%% Process in ROI
disp('Processing in ROI...');
figure();
numberOfChangedPixels = zeros(1,numTime*fps);
numGreen = zeros(1,numTime*fps);
numBlue = zeros(1,numTime*fps);
ROIIndex = 1:(numTime*fps);

transparencyMask = double(BW);
transparencyMask(BW == 0) = 0.2;

for index = 1:(numTime*fps)
    imageData = double(rgb2gray(imread(strcat(nameDir,'/',num2str(index),'.',extension))));
%      subplot(1,2,1);
%      h = imshow(imageData);
%      title(sprintf('Frame %d/%d', index, (numTime*fps)));
%      axis off;
%      hold on;
%      set(h,'alphadata',transparencyMask);
    
    ROIData = imageData(minVertical:maxVertical,minHorizontal:maxHorizontal);
    if (index>1)
        numberOfChangedPixels(index) = sum(sum((ROIData - ROIPreviousData)>50));
    end
    ROIPreviousData = ROIData;
    
    % Plot diffs
%      subplot(1,2,2);
%      plot(ROIIndex,numberOfChangedPixels,'Color',colors(5,:)); grid on; axis on; hold on;
%      title('Red difference over time');
%      pause(0.1);
end


interpolationSamplesPerFrame = 100;
f_e = fps*interpolationSamplesPerFrame;
ROIIndexInterpolation = 1:(1/interpolationSamplesPerFrame):(numTime*fps);
differenceInterpolation = interp1(ROIIndex,numberOfChangedPixels,ROIIndexInterpolation,'spline');

figure(8);
plot(ROIIndex,numberOfChangedPixels,'Color',colors(4,:),'LineStyle','--'); grid on; axis on; hold on;
title('Amount of changed pixels within ROI (unprocessed)');

% Process in results
numRedMax = zeros(2,1);
n = 1;
for k = 2:length(ROIIndexInterpolation)-1
    if ((differenceInterpolation(1,k)>=differenceInterpolation(1,k-1))&&(differenceInterpolation(1,k)>differenceInterpolation(1,k+1)))
        numRedMax(:,n) = [differenceInterpolation(k); ROIIndexInterpolation(k)];
    end
    n = n+1;
end

numRedMaxReal = numRedMax(:,numRedMax(1,:)>mean(numberOfChangedPixels));

% Interpolate maxima
numRedMaxRealInterpolationIndices = 0:1/interpolationSamplesPerFrame:(numTime*fps);
numRedMaxRealInterpolation = spline(numRedMaxReal(2,:), numRedMaxReal(1,:), numRedMaxRealInterpolationIndices);



% Find new interpolation peaks
[yPeaks,xPeaks] = findpeaks(numRedMaxRealInterpolation);
 % Readjust coordinates
if xPeaks(end)-xPeaks(1) > f_e/2
    numRedMaxRealInterpolationIndices = numRedMaxRealInterpolationIndices(xPeaks(1):xPeaks(end));
    numRedMaxRealInterpolation = numRedMaxRealInterpolation(xPeaks(1):xPeaks(end));
    differenceInterpolation = differenceInterpolation(xPeaks(1):xPeaks(end));
    ROIIndexInterpolation = ROIIndexInterpolation(xPeaks(1):xPeaks(end));
else
    disp('CAUTION! Not enough samples to compute precize peaks. Fourier''s transform will be computed on the whole sample.');
end

figure(9);
plot(numRedMaxRealInterpolationIndices,numRedMaxRealInterpolation,'Color',colors(4,:),'LineWidth',2); 
hold on;
plot(xPeaks*(1/interpolationSamplesPerFrame),yPeaks,'*','MarkerSize',8,'Color',colors(5,:));
title('Interpolated maxima with detected peaks');

%% Compute TF of interpolated data
w = hamming(length(differenceInterpolation))';
% Apply hamming window

weightedDifferenceInterpolation = differenceInterpolation.*w;
TF = abs(fft(weightedDifferenceInterpolation));
[baseAmplitude,firstPeakFrequencyIndex] = max(TF(2:f_e/2)); % Ignore continous component
firstPeakFrequency = firstPeakFrequencyIndex*f_e/length(TF);
disp(sprintf('Base frequency is: %.2f Hz', 2*firstPeakFrequency));

figure();
plot([1:f_e/2]*f_e/length(TF), TF(1:f_e/2),'Color','Blue');
title('Spectral decomposition of interpolated data');

%% Plot number of changed pixels.
figure(10);
plot(ROIIndexInterpolation,differenceInterpolation,'Color',colors(3,:)); 
title('Interpolated data (processed)');
grid on; axis on; hold on;
plot(ROIIndex,numberOfChangedPixels,'Color',colors(1,:),'LineStyle','--'); grid on; axis on; hold on;
plot(ROIIndex,ones(numTime*fps)*mean(numberOfChangedPixels),'Color',colors(1,:),'LineWidth',2); grid on; axis on;
plot(numRedMaxRealInterpolationIndices,numRedMaxRealInterpolation,'Color',colors(4,:),'LineWidth',2);
% plot(x,y,'*','Color',colors(5,:));

% TF of interpolated peaks
TF = abs(fft(numRedMaxRealInterpolation));
[delayAmplitude,firstDelayPeakFrequencyIndex] = max(TF(2:end)); % Ignore continous component
firstDelayPeakFrequency = firstDelayPeakFrequencyIndex*f_e/length(TF);
disp(sprintf('First peak frequency is: %.2f Hz', firstDelayPeakFrequency));

figure;
plot([1:50]*f_e/length(TF),abs(TF(1:50)),'r-');
title('Spectral decomposition of the delayed front');

% Only keep the interpolation between first and last max to avoid beginning
% and ending noise.
% numRedMaxRealInterpolationIndices = numRedMaxRealInterpolationIndices(x(1):1/interpolationSamplesPerFrame:x(end));
% numRedMaxRealInterpolation = numRedMaxRealInterpolation(x(1):1/interpolationSamplesPerFrame:x(end));

% numRedMaxRealModified = numRedMaxReal(:,2:length(numRedMaxReal));

speed = 30 * (2*firstPeakFrequency - 2*firstDelayPeakFrequency);
disp(sprintf('Speed: %f r.p.m.', speed));

% timeLength = (max(numRedMaxRealModified(2,:)) - min(numRedMaxRealModified(2,:)))*1/fps
% numMax = length(numRedMaxRealModified(1,:))-1
% speed = 60*numMax/timeLength
