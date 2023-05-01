clearvars
clc

filepath = 'D:\Projects\ALMC Tickets\Ian Wyllie\data\flowStoppage\001_AAB_20230427_PVDF650_40nmusphere_0.002flow_001.nd2';

reader = BioformatsImage(filepath);

Tracker = LAPLinker;
Tracker.LinkScoreRange = [0 30];

vid = VideoWriter('test.avi');
vid.FrameRate = 7.5;
open(vid)
%%
for iT = 1:100

    I = getPlane(reader, 1, 1, iT);

    %Estimate background
    bg = imopen(I, strel('disk', 100));

    Isub = I - bg;
    %imshow(imadjust(I - bg), [])

    Isub = imgaussfilt(Isub, 1);
    % imshow(Isub, [0 0.5e4])

    Isub = double(Isub);

    %Find spots
    g1 = imgaussfilt(Isub, 2);
    g2 = imgaussfilt(Isub, 7);

    Idiff = g1 - g2;
    % imshow(Idiff, [])
    
    mask = Idiff > 500;

    % figure(1)
    % showoverlay(Isub, mask);

    data = regionprops(mask, 'Centroid');

    Tracker = assignToTrack(Tracker, iT, data);

    I = double(I);
    I = (I - min(I, [], 'all'))/(max(I, [], 'all') - min(I, [], 'all'));

    Iout = showoverlay(I, mask);

    for iAT = Tracker.activeTrackIDs

        ct = getTrack(Tracker, iAT);
        Iout = insertText(Iout, ct.Centroid(end, :), int2str(iAT));

    end

    writeVideo(vid, Iout);

end

close(vid)

tracks = Tracker.tracks;
save('20230501_positions.mat', 'tracks')