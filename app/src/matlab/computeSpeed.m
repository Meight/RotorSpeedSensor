function speed = computeSpeed(numbersofChangedPixels, fps)
    numTime = length(numbersofChangedPixels);
    ROIIndexInterpolation = 1:0.01:(numTime*fps);
    differenceInterpolation = interp1(ROIIndex,numbersofChangedPixels,ROIIndexInterpolation,'spline');

    % Process in results
    diffMax = zeros(2,1);
    n = 1;
    for k = 2:length(ROIIndexInterpolation)-1
        if ((differenceInterpolation(1,k)>=differenceInterpolation(1,k-1))&&(differenceInterpolation(1,k)>differenceInterpolation(1,k+1)))
            diffMax(:,n) = [differenceInterpolation(k); ROIIndexInterpolation(k)];
        end
        n = n+1;
    end

    diffMaxReal = diffMax(:,diffMax(1,:)>mean(numRed));

    diffMaxRealModified = diffMaxReal(:,2:length(diffMaxReal));

    timeLength = (max(diffMaxRealModified(2,:)) - min(diffMaxRealModified(2,:)))*1/fps;
    numMax = length(diffMaxRealModified(1,:))-1;
    speed = 60*numMax/timeLength;
end