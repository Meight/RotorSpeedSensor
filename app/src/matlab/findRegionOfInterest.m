function [horizontalMin, horizontalMax, verticalMin, verticalMax] = findRegionOfInterest(images, height, width, amountOfImagesForROIDetection)
    %% Function findRegionOfInterest
    %% Uses the first frame of a given scenario to find a region of interest (ROI)
    %% on which the rest of the procedure should focus. The way the ROI is
    %% computed is described in details in the article.
    %%
    %% @author Matthieu Le Boucher <matt.leboucher@gmail.com>
    %%
    %% Inputs:
    %%      - TODO
    %%      - amountOfImagesForROIDetection: allows to change the number of
    %%          frames that should be used to determine the ROI. A higher
    %%          value is likely to give more precise results at the price of
    %%          additional computational cost.
    %%          Default (recommended) value: 30.
    %% Outputs:
    %%      - verticalMin, verticalMax, horizontalMin, horizontalMax are the
    %%          extreme indices of the bounding box of the ROI.
    %%      - BW: an actual binary image which equals 1 for every pixel in the
    %%          ROI, and 0 otherwise.

% Reshape data
images = permute(reshape(images, [width, height, amountOfImagesForROIDetection]), [2, 1, 3]);

% Load first frame

imagesStandardDeviation = std(images,0,3);
amountOfPixelsPerFrame = size(imagesStandardDeviation,1)*size(imagesStandardDeviation,2);
maxValueOfImagesStd = max(max(imagesStandardDeviation));

cumulativeDistribution = zeros(100,2);
for index = 1:100
    valuePixel = index*maxValueOfImagesStd/100;
    cumulativeDistribution(index,1) = valuePixel;
    cumulativeDistribution(index,2) = sum(sum(imagesStandardDeviation<=valuePixel))/amountOfPixelsPerFrame;
end
threshold = cumulativeDistribution(sum(cumulativeDistribution(:,2)<=0.9),1);

BW2 = imagesStandardDeviation >= threshold;
CC = bwlabel(BW2,4);
ind = mode(CC(CC>0));

BW = zeros(height,width);
BW(CC==ind) = 1;

%% Find bounding box.
horizontalMin = width;
horizontalMax = 0;
for index3 = 1:size(BW,1)
    tempHorizontal = find(BW(index3,:)==1);
    if (min(tempHorizontal)<horizontalMin)
        horizontalMin = min(tempHorizontal);
    end
    if (max(tempHorizontal)>horizontalMax)
        horizontalMax = max(tempHorizontal);
    end
end

verticalMin = height;
verticalMax = 0;
for index4 = 1:size(BW,2)
    tempVertical = find(BW(:,index4)==1);
    if (min(tempVertical)<verticalMin)
        verticalMin = min(tempVertical);
    end
    if (max(tempVertical)>verticalMax)
        verticalMax = max(tempVertical);
    end
end

