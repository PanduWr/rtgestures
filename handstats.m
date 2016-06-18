function [cc, center, angle] = handstats(Iseg)

cc = bwconncomp(Iseg);
stats = regionprops(cc, 'Centroid', 'Orientation');

if cc.NumObjects == 0
    center = [0 0];
    angle = 0;
    return
end

angle = stats.Orientation;
center = stats.Centroid;

if angle < 0
    angle = angle + 180;
end