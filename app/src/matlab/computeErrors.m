%% Automatically runs tests for the given frequencies and sample rates series.
%% Usage:
%% e.g. frenquencySeries = [5, 30] and sampleRates = [30, 118] wil run tests for
%% 5Hz_30fps, 5Hz_118fps, 30Hz_30fps, 30Hz_118fps, in that order.
%%
%% Note: figures used for comparisons are excerpted from actual measures given
%%       in the article.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% Rotor frequencies to be tested:
frenquencySeries = [5, 10, 20, 30, 40, 50];
% using the following samples rates for each:
sampleRates = [30, 60];
% Sampling duration (seconds):
samplingDuration = 5;

for rotorFrequency = frenquencySeries
    for sampleRate = sampleRates
        % Deduce filename
        fileName = sprintf('%dHz_%dfps.jpg', rotorFrequency, sampleRate);

    end
end
