function [cc, centers] = featurestats(Ibw)

cc = bwconncomp(Ibw);
stats = regionprops(cc, 'Centroid');
centers = cat(1, stats.Centroid);
