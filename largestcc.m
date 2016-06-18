function Iout = largestcc(Iseg)

[rows, cols] = size(Iseg);
cc = bwconncomp(Iseg);
Iout = zeros(rows, cols);
if cc.NumObjects > 0
    numPixels = cellfun(@numel, cc.PixelIdxList);
    [~,idx] = max(numPixels);
    Iout(cc.PixelIdxList{idx}) = 1;
end