% % Parameters
% amountOfTrackedPixels = 1;
% frequency = 20;
% sampleRate = 118;
% filename = sprintf('639-tours-slow', frequency, sampleRate);
% 
% video = VideoReader(sprintf('%s.mp4', filename));
% info = get(video);
% fps = sampleRate;
% actualFPS = 118; % info.FrameRate;
% sampleTime = 10; % in seconds

%% Find ROI.

if exist(sprintf('%s_%ds_ROI.mat', filename, sampleTime)) == 0
    if verbose
    disp(sprintf('ROI not found for "%s", computing it...', filename));
    end
    [horizontalMin, horizontalMax, verticalMin, verticalMax, BW] = findRegionOfInterest(filename, 30);
    save(sprintf('%s_%ds_ROI.mat', filename, sampleTime));
else
    if verbose
    disp(sprintf('ROI found for "%s", loading...', filename));
    end
    load(sprintf('%s_%ds_ROI.mat', filename, sampleTime));
end

% [horizontalMin] = 0;
% horizontalMax = 100;
% verticalMin = 0;
% verticalMax = 100;

%% Compute grid within the ROI.
if verbose
    disp('Computing grid within the ROI...');
end
ROIWidth = horizontalMax - horizontalMin;
ROIHeight = verticalMax - verticalMin;
areaPerPixel = floor(sqrt(ROIWidth * ROIHeight / amountOfTrackedPixels));
rate = ROIWidth / ROIHeight;
amountOfHorizontalTrackedPixels = max(1, floor(sqrt(amountOfTrackedPixels / rate)));
amountOfVerticalTrackedPixels = max(1, floor(amountOfTrackedPixels / amountOfHorizontalTrackedPixels));

trackedPixels = zeros(2, amountOfHorizontalTrackedPixels * amountOfVerticalTrackedPixels);

horizontalStep = (ROIWidth / (amountOfHorizontalTrackedPixels));
verticalStep = (ROIHeight / (amountOfVerticalTrackedPixels));

close all;
figure(1);
subplot(2,2,1);
axis off;
imagesc(BW);
title('ROI with tracked pixels');
hold on;

pixelIndex = 1;
for i = 1:amountOfHorizontalTrackedPixels
    for j = 1:amountOfVerticalTrackedPixels
        trackedPixels(1, pixelIndex) = round(horizontalMin + horizontalStep * (i - 0.5));
        trackedPixels(2, pixelIndex) = round(verticalMin + verticalStep * (j - 0.5));
        
        if ~BW(trackedPixels(1, pixelIndex), trackedPixels(2, pixelIndex))
            trackedPixels(:, pixelIndex) = [];
        else
            subplot(2,2,1);
            plot(trackedPixels(2, pixelIndex), trackedPixels(1, pixelIndex), '*r');
            hold on;
            pixelIndex = pixelIndex + 1;
        end
    end
end

%% Sample frames values over time at tracked pixels.
if verbose
disp('Sampling frames values over time at tracked pixels...');
end

if exist(sprintf('%s_%ds_pixels.mat', filename, sampleTime)) == 0
    if verbose
    disp(sprintf('Tracked pixels values not found for "%s" (%d seconds), computing...', filename, sampleTime));
    end
    
    amountOfTrackedPixels = size(trackedPixels, 2);
    trackedPixelsValuesOverTime = zeros(sampleTime * fps, amountOfTrackedPixels);

    subplot(2,2,2);
    for frameIndex = 1:(sampleTime * fps)
        frame = double(rgb2gray(imread(sprintf('%s/%d.jpg', filename, frameIndex))));
        
        % Equalize histogram
        % frame = histeq(frame);

        for trackedPixelIndex = 1:amountOfTrackedPixels
            trackedPixelsValuesOverTime(frameIndex, trackedPixelIndex) = ...
                frame(trackedPixels(1, trackedPixelIndex), trackedPixels(2, trackedPixelIndex));
        end

        if mod(frameIndex, round(actualFPS)) == 0
            line([frameIndex frameIndex], [0 250], 'Color', 'black', 'LineWidth', 2);
            hold on;
        end
    end
    
    save(sprintf('%s_%ds_pixels.mat', filename, sampleTime));
else
    if verbose
    disp(sprintf('Tracked pixels values found for "%s" (%d seconds), loading...', filename, sampleTime));
    end
    load(sprintf('%s_%ds_pixels.mat', filename, sampleTime));
end

subplot(2,2,2);

% Find peaks.
if verbose
disp('Finding peaks...');
end
[yPeaks,xPeaks] = findpeaks(trackedPixelsValuesOverTime(:, 1), 'MINPEAKHEIGHT', mean(trackedPixelsValuesOverTime(:,1)), 'MINPEAKDISTANCE', 3);

% Keep peaks that are lesser than their surrounding neighbors.
keptPeaks = zeros((sampleTime * fps),1);
keptPeaksX = [];
peaksStandardDeviation = std(yPeaks, 1); % Normalized by factor n
peaksThreshold = (max(yPeaks) - peaksStandardDeviation);
for i = 2:(length(yPeaks)-1)
    if yPeaks(i - 1) > yPeaks(i) && yPeaks(i + 1) > yPeaks(i) && yPeaks(i) < peaksThreshold
        keptPeaks(xPeaks(i)) = yPeaks(i);
        keptPeaksX = [keptPeaksX, xPeaks(i)];
    else
        keptPeaks(xPeaks(i)) = 0;
    end
end

plot(xPeaks, yPeaks, 'r*');
hold on;
plot(1:(sampleTime * fps), peaksThreshold, 'k-.', 'LineWidth', 3);
hold on;

yPeaks = keptPeaks;
plot(keptPeaksX, yPeaks(keptPeaksX), 'k*');
hold on;

amountOfKeptPeaks = sum(find(yPeaks ~= 0));

w = hamming(size(trackedPixelsValuesOverTime, 1));
color = 200/amountOfTrackedPixels;
for i = 1:amountOfTrackedPixels
    plot(1:(sampleTime * fps), trackedPixelsValuesOverTime(:, i), 'Color', [color * i, 0, 0]/255);
    hold on;
    
    trackedPixelsValuesOverTime(:, i) = trackedPixelsValuesOverTime(:, i) .* w;
end
title(sprintf('Values of tracked pixels over time\nActual sample rate: %0.2f', actualFPS));



%% Perform Fourier's transform on tracked pixels' values.
if verbose
disp('Performing FT on tracked pixels'' values...');
end

% Apply zero-padding.
amountOfZeros = 400;
trackedPixelsValuesOverTime(sampleTime * fps + 1:sampleTime * fps + amountOfZeros, :) = 0;

TFs = zeros(sampleTime * fps + amountOfZeros, amountOfTrackedPixels);
for i = 1:amountOfTrackedPixels
    TFs(:, i) = abs(fft(trackedPixelsValuesOverTime(:, i)));
end

% Apply Hamming window & zero-padding to peaks.
w = hamming(length(yPeaks));
yPeaks = yPeaks.*w;

yPeaks = [yPeaks ; zeros(amountOfZeros, 1)];
peaksTF = abs(fft(yPeaks));

[yFrontPeaks, xFrontPeaks] = findpeaks(peaksTF);
if length(xFrontPeaks) ~= 0
    frontFrequency = xFrontPeaks(1) * actualFPS /  size(peaksTF, 1);
else
    frontFrequency = 0;
end

% frontFrequency = 0;

fundamentals = zeros(1, size(TFs, 2));
for i = 1:size(TFs, 2)
    [yPeaks, xPeaks] = findpeaks(TFs(1:end/2, i));
    
    % Sort peaks
    [yPeaks, indices] = sort(yPeaks, 'descend');
    xPeaks = xPeaks(indices);
    yPeaks = yPeaks(yPeaks > yPeaks(1) * 0.8);
    xPeaks = xPeaks(1:length(yPeaks));
    
    fundamentals(i) = min(xPeaks) * actualFPS / size(TFs, 1);
end

mainFrequency = median(fundamentals);

subplot(2,2,3);
for i = 1:amountOfTrackedPixels
    plot(actualFPS * (1:size(TFs, 1))/size(TFs, 1), TFs(:, i), 'Color', [color * i, 0, 0]/255);
    hold on;
end
title(sprintf('Spectral decompositions of pixel values over time\nFundamental: %0.2f Hz\nRotor speed: %0.2f r.p.m', mainFrequency, 60 * (mainFrequency - frontFrequency)));

subplot(2,2,4);
plot(actualFPS * (1:size(peaksTF, 1))/size(peaksTF, 1), peaksTF, 'b', 'LineWidth', 2);
hold on;
title(sprintf('Spectral decomposition of the mark''s front\nFront''s frequency: %0.2f', frontFrequency));


% figure(1);
% subplot(2,2,2);
% plot(1:(sampleTime * fps), 10 * sin(mainFrequency * [1:(sampleTime * fps)]), 'b', 'LineWidth', 2);
% hold on;
% plot(1:(sampleTime * fps), 10 * sin(frontFrequency * [1:(sampleTime * fps)]), 'r', 'LineWidth', 2);