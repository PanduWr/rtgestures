function [Iseg, params] = handsegment_gmm(I, params)

% increase tolerance to improve speed
options = struct('TolFun', 1e-4);

I = im2double(I);
[rows, cols, depth] = size(I);

if depth > 1
    I = rgb2gray(I);
end

lpf = fspecial('gaussian', 15);
If = imfilter(I, lpf);

% Compute GMM using prior information if available
Iv = If(:);
try 
    if nargin < 2 || ~isstruct(params)
        gmfit = fitgmdist(Iv, 2, 'Options', options);
    else
        gmfit = fitgmdist(Iv, 2, 'Start', params, 'Options', options);
    end
catch % model didn't converge, so we're probably not looking at a hand.
    params = 0;
    Iseg = zeros(rows, cols);
    return
end

% Compute posterior probabilities and determine most likely class
post = posterior(gmfit, Iv);
Isegv = post(:, 1) > post(:, 2);

% Flip colors if necessary
if sum(Isegv) > (rows * cols)/2
    Isegv = ~Isegv;
end

% cache starting parameters for use next time
params = struct('mu', gmfit.mu, 'Sigma', gmfit.Sigma, ...
    'ComponentProportion', gmfit.ComponentProportion);

% convert output vector to image
Iseg = reshape(Isegv, rows, cols);

% postprocess to repair rough edges
%Iseg = imdilate(Iseg, strel('disk', 4));
Iseg = imfill(Iseg, 'holes');