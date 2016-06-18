folder = 'eval/subject2a';
saveasf = 'eval2.csv';

load trainedClassifiers6.mat

gestureIntMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
gestureIntMap('rockon') = 0;
gestureIntMap('peace') = 1;
gestureIntMap('five') = 2;
gestureIntMap('fist') = 3;

gestureMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
gestureMap('rockon') =  im2double(imread('icons/rockon.png'));
gestureMap('peace') = im2double(imread('icons/peace.png'));
gestureMap('five') = im2double(imread('icons/five.png'));
gestureMap('fist') = im2double(imread('icons/fist.png'));

files = dir([folder '/*.png']);
data = [];
imn = 0;
for file = files'
    I = im2double(rgb2gray(imread([folder '/' file.name])));
    tic
    Iseg = handsegment_gmm(I);
    Iseg = im2double(largestcc(Iseg));
    tseg = toc;
    %Iseg = I > 0;
    
    tic
    cc = bwconncomp(Iseg);
    stats = regionprops(cc, 'Centroid', 'Orientation');
    handcenter = stats.Centroid;
    handangle = stats.Orientation;
    if handangle < 0
        handangle = handangle + 180;
    end
    handpt = [(handcenter(1) + 50*cosd(handangle)) ...
        (handcenter(2) - 50*sind(handangle))];
    
    Itip = extractfingertips(Iseg);
    tipcc = bwconncomp(Itip);
    tipstats = regionprops(tipcc, 'Centroid');
    tipcenters = cat(1, tipstats.Centroid);
    [tiptheta, tiprho] = cart2pol(tipcenters(:, 1) - handcenter(1),...
        tipcenters(:, 2) - handcenter(2));
    tiptheta = rad2deg(tiptheta) + handangle;
    tiptheta(tiptheta > 180) = 360 - tiptheta(tiptheta > 180);
    tiptheta(tiptheta < -180) = 360 + tiptheta(tiptheta < -180);
    tips = [tiptheta tiprho];
    
    tipsmask = tips(:, 1) > -120 & tips(:, 1) < 120;
    tipsmask = repmat(tipsmask, 1, 2);
    tips = tips .* tipsmask;
    
    tipangulardistances = zeros(1, 4);
    for i = 2:size(tips, 1)
        tipangulardistances(i-1) = mod(tips(1, 1) - tips(i, 1), 360);
        if i == 5
            break
        end
    end
    
    tipradii = zeros(1, 5);
    for i = 1:size(tips, 1)
        tipradii(i) = tips(i, 1);
        if i == 5
            break
        end
    end
    
    Iweb = extractwebs_hp(Iseg);
    webcc = bwconncomp(Iweb);
    webstats = regionprops(webcc, 'Centroid');
    webcenters = cat(1, webstats.Centroid);
    
    if size(webcenters, 1) > 0
        [webtheta, webrho] = cart2pol(webcenters(:, 1) - handcenter(1), ...
            webcenters(:, 2) - handcenter(2));
        webtheta = rad2deg(webtheta) + handangle;
        webtheta(webtheta > 180) = 360 - webtheta(webtheta > 180);
        webtheta(webtheta < -180) = 360 + webtheta(webtheta < -180);
        webs = [webtheta webrho];

        websmask = webs(:, 1) > -120 & webs(:, 1) < 120;
        websmask = repmat(websmask, 1, 2);
        websf = webs .* websmask;

        webavgr = mean(websf(:, 2));
        tipavgr = mean(tips(:, 2));
        avgdistdiff = tipavgr / webavgr;
    else
        avgdistdiff = 1;
    end
    
    if avgdistdiff == Inf
        avgdistdiff = 1;
    end
    
    newrow = [tipangulardistances tipradii avgdistdiff];
    tfeat = toc;
    
    tic
    gesture1 = predict(trainedKNN.ClassificationKNN, newrow);
    gesture2 = predict(trainedLinDisc.ClassificationDiscriminant, newrow);
    gesture3 = predict(trainedSVM.ClassificationSVM, newrow);
    gesture = majorityvote({gesture1 gesture2 gesture3});
    tclass = toc;
    
    newdata = [tseg tfeat tclass ...
        gestureIntMap(cell2mat(gesture1)) gestureIntMap(cell2mat(gesture2)) gestureIntMap(cell2mat(gesture3))...
        gestureIntMap(gesture)];
    data = [data; newdata];
    
    imgfig = figure;
    
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
    if ~isempty(tipcenters)
        plot(tipcenters(:, 1), tipcenters(:, 2), 'g+');
    end

    % Plot estimated web locations
    if ~isempty(webcenters)
        plot(webcenters(:, 1), webcenters(:, 2), 'yx');
    end

    hold off
    drawnow
    saveas(imgfig, [folder '/results/' sprintf('r%i.png', imn)]);
    close all
    imn = imn + 1;
end

csvwrite([folder '/' saveasf], data);