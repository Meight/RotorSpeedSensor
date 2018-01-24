% Parameters
amountOfTrackedPixels = 10;
frequency = 20;
sampleRate = 30;
filename = sprintf('581-tours', frequency, sampleRate);

video = VideoReader(sprintf('%s.mp4', filename));
info = get(video);
fps = sampleRate;
actualFPS = info.FrameRate;

verbose = false;
actualRPM = 1550;

for sampleTime = 1:10
    spatialAnalysis;
    computedRPM = mainFrequency * 60;
    
    error = (computedRPM - actualRPM) / actualRPM * 100;
    
    disp(sprintf('%d %0.2f %0.3f', sampleTime, computedRPM, error));
end
