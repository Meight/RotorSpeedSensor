clear
home
videoName = input('Video name: ');
numFrame = input('Number frames: ');
state = 'Reading...'
v = VideoReader(videoName);
imageKey = videoName(1:length(videoName)-4);
mkdir(imageKey);
imageExtension = 'jpg';

state = 'Processing...'
for index = 1:numFrame
    video = read(v,index);
    imageName = strcat(imageKey,'/',num2str(index),'.',imageExtension);
    imwrite(video(:,:,:),imageName);
end
state = 'Completed.'