function Iout = extractfingertips(I)

% Set up kernels and convert input image to double
load kernel-fingertip3.mat
I = im2double(I);

% Extract fingertip regions at each scale and normalize result
Ic = imfilter(I, h, 'conv');
Ic = Ic / max(Ic(:));

Ic2 = imfilter(I, h2, 'conv');
Ic2 = Ic2 / max(Ic2(:));

Ic3 = imfilter(I, h3, 'conv');
Ic3 = Ic3 / max(Ic3(:));

% Blur result to combine duplicate regions
lpf = fspecial('gaussian');
Icf =  imfilter(Ic, lpf);
Icf2 = imfilter(Ic2, lpf);
Icf3 = imfilter(Ic3, lpf);

% Threshold each scale mask
Ibw = Icf > 0.25;
Ibw2 = Icf2 > 0.25;
Ibw3 = Icf3 > 0.25;

% Combine scale masks
Ibwc = Ibw & Ibw2 & Ibw3;

% Remove noise
Iout = bwareaopen(Ibwc, 10);
Iout = imclose(Iout, strel('disk', 16));
%Iout = bwareaopen(Ibwc, 10);
%Iout = bwareafilt(Ibwc, 5);