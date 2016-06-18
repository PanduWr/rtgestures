close all
clear

% set up camera stream
cam = webcam;

% load the trained classifiers
load trainedClassifiers6.mat

gestureMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
gestureMap('rockon') =  im2double(imread('icons/rockon.png'));
gestureMap('peace') = im2double(imread('icons/peace.png'));
gestureMap('five') = im2double(imread('icons/five.png'));
gestureMap('fist') = im2double(imread('icons/fist.png'));

window = figure;
while 1
    % Acquire and preprocess image from camera
    I = fliplr(snapshot(cam));
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
    
    % Extract basic properties from hand
    [handcc, handcenter, handangle] = handstats(Iseg);
    handpt = [(handcenter(1) + 50*cosd(handangle)) ...
            (handcenter(2) - 50*sind(handangle))];
    %Iseg = imrotate(Iseg, 90-handangle);
    
    % Find fingertip and web regions
    Itips = extractfingertips(Iseg);
    Iwebs = extractwebs_hp(Iseg);
    [tipcc, tips] = featurestats(Itips);
    [webcc, webs] = featurestats(Iwebs);
    
    % Convert tips and webs to polar coordinates relative to hand
    % orientation and center
    if numel(tips) > 0
        [tiptheta, tiprho] = cart2pol(tips(:, 1) - handcenter(1),...
            tips(:, 2) - handcenter(2));
        tiptheta = rad2deg(tiptheta) + handangle;
        tiptheta(tiptheta > 180) = 360 - tiptheta(tiptheta > 180);
        tiptheta(tiptheta < -180) = 360 + tiptheta(tiptheta < -180);
        tipspol = [tiptheta tiprho];
    else
        tipspol = [];
    end
    
    if numel(webs) > 0
        [webtheta, webrho] = cart2pol(webs(:, 1) - handcenter(1), ...
            webs(:, 2) - handcenter(2));

        webtheta = rad2deg(webtheta) + handangle;
        webtheta(webtheta > 180) = 360 - webtheta(webtheta > 180);
        webtheta(webtheta < -180) = 360 + webtheta(webtheta < -180);
        webspol = [webtheta webrho];
    else
        webspol = [];
    end
    
    if numel(tipspol) > 0
        tipsmask = tipspol(:, 1) > -120 & tipspol(:, 1) < 120;
        tipsmask = repmat(tipsmask, 1, 2);
        tipspol = tipsmask .* tipspol;
    end
    
    if numel(webspol) > 0 && numel(tipspol) > 0
        websmask = webspol(:, 1) > -120 & webspol(:, 1) < 120;
        websmask = repmat(websmask, 1, 2);
        webspol = websmask .* webspol;

        webavgr = mean(webspol(:, 2));
        tipavgr = mean(tipspol(:, 2));
        avgdistdiff = tipavgr / webavgr;
    else
        avgdistdiff = 1;
    end
    
    tipangulardistances = zeros(1, 4);
    for i = 2:size(tipspol, 1)
        tipangulardistances(i-1) = mod(tipspol(1, 1) - tipspol(i, 1), 360);
        if i == 5
            break
        end
    end
    
    tipradii = zeros(1, 5);
    for i = 1:size(tipspol, 1)
        tipradii(i) = tipspol(i, 1);
        if i == 5
            break
        end
    end
    
    % Run classifiers
    newrow = [tipangulardistances tipradii avgdistdiff];
    gesture1 = predict(trainedKNN.ClassificationKNN, newrow);
    gesture2 = predict(trainedLinDisc.ClassificationDiscriminant, newrow);
    gesture3 = predict(trainedSVM.ClassificationSVM, newrow);
    gesture = majorityvote({gesture1 gesture2 gesture3});
    
    try
        if ~ishandle(window)
            break
        end
        
        % copy the icon for the predicted gesture
        icon = gestureMap(gesture);
        [r,c,d] = size(icon);
        Isegicon = repmat(Iseg, [1 1 3]);
        Isegicon(1:r, 1:c, 1:d) = icon;
        
        imshow(Isegicon);
        hold on
        
        % Plot hand centroid and direction
        if ~isempty(handcenter)
            plot(handcenter(1), handcenter(2), 'ro');
            plot([handcenter(1) handpt(1)], [handcenter(2) handpt(2)], 'r-');
        end
        
        % Plot fingertip centroids
        if ~isempty(tips)
            plot(tips(:, 1), tips(:, 2), 'g+');
        end
        
        % Plot estimated web locations
        if ~isempty(webs)
            plot(webs(:, 1), webs(:, 2), 'yx');
        end
        

    catch
        % figure was closed
       break
    end
    
    drawnow
end

clear cam