function imaq

close all
clear

cam = webcam;
window = figure;

load imgind.mat
step = 0;

while 1
    % Acquire and preprocess image from camera
    I = im2double(fliplr(snapshot(cam)));
    I = imcrop(I, [160 120 480 360]);
    Igr = rgb2gray(I);
    
    % Segment camera image
    if exist('params', 'var')
        [Iseg, params] = handsegment_gmm(Igr, params);
    else
        [Iseg, params] = handsegment_gmm(Igr);
    end
    
    % Extract the largest connected component
    Iseg = largestcc(Iseg);
    Ireal = repmat(Iseg, [1 1 3]) .* I;
    
    if ~ishandle(window)
        break
    end
    
    try
        step = step + 1;
        imshow(Ireal);
        
        if mod(step, 10) == 0
            hold on
            text(20, 20, 'SAVED', 'Color', 'red');
            hold off
            
            imgind = imgind + 1;
            imwrite(I, sprintf('eval/subject1/im%i.png', imgind));
        end
    catch
        break
    end
end

save('imgind.mat', 'imgind');
clear cam