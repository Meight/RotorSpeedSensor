function result = grayLevel(previousImage, image, height, width, roi)
    previousImage = reshape(previousImage, [width, height])';
    image = reshape(image, [width, height])';
    ROIData = image(roi(3):roi(4),roi(1):roi(2));
    ROIPreviousData = previousImage(roi(3):roi(4),roi(1):roi(2));

    result = sum(sum((ROIData - ROIPreviousData)>50));
end