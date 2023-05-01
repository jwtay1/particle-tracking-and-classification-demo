clearvars
clc

load('20230501_positions.mat');

%% Generate an output structure

for iP = 1:tracks.NumTracks

    ct = getTrack(tracks, iP);

    if numel(ct.Frames) < 10
        continue
    else
        %Add track to output structure
        if ~exist('filteredTracks', 'var')
            filteredTracks = ct;
        else
            filteredTracks = [filteredTracks; ct];
        end
    end
end

for iP = 1:numel(filteredTracks)

    %Compute the displacement at each frame
    filteredTracks(iP).DisplacementStep = [0; sqrt(sum((diff(filteredTracks(iP).Centroid, 1)).^2, 2))];

    %Classify if particle is moving or not
    filteredTracks(iP).IsMoving = filteredTracks(iP).DisplacementStep > 1.5;

    if nnz(filteredTracks(iP).IsMoving) >= (0.8 * numel(ct.Frames))
        filteredTracks(iP).Classification = 'moving';
    else
        filteredTracks(iP).Classification = 'immobile';
    end
    
end

%% Remake the video

filepath = 'D:\Projects\ALMC Tickets\Ian Wyllie\data\flowStoppage\001_AAB_20230427_PVDF650_40nmusphere_0.002flow_001.nd2';

reader = BioformatsImage(filepath);

vid = VideoWriter('finalTracks.avi');
vid.FrameRate = 7.5;
open(vid)

for iT = 1:100
    
    I = getPlane(reader, 1, 1, iT);

    %Normalize output image
    I = double(I);
    I = (I - min(I, [], 'all'))/(13000 - min(I, [], 'all')); %Note: Hard coded maximum value
    I(I > 1) = 1;

    for iP = 1:numel(filteredTracks)
        
        frameIdx = find(ismember(filteredTracks(iP).Frames, iT), 1, 'first');

        if ~isempty(frameIdx)
            I = insertText(I, filteredTracks(iP).Centroid(frameIdx, :), int2str(iP), ...
                'BoxOpacity', 0, 'TextColor', 'y', 'AnchorPoint', 'CenterTop');

            if strcmpi(filteredTracks(iP).Classification, 'immobile')
                I = insertShape(I, 'circle', [filteredTracks(iP).Centroid(frameIdx, :), 5], ...
                    'Color', 'red');

            end

        end

    end

    writeVideo(vid, I);

end

close(vid)