function Iout = extractwebs_hp(I)

I = im2double(I);

% High pass filter by subtracting result of morphological close
% then performing another close to combine near areas
Ic = imclose(I, strel('square', 12));
%Id = imclose(Ic - I, strel('disk', 5));
Ibw = (Ic - I) > 0;

% remove noise
Iout = bwareaopen(Ibw, 20);
%Iout = bwareafilt(Ibw, 4);