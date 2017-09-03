%% Data acquisition
% Date: 10/02/2014
% Edit: 06/03/2014
% Eidt: 25/04/2014

% Note: training data acquisation and distritbuion estimation

clear; clc; close all
%% Start parallel computation
% set the maximum of cores or workers
%parpool
%% Image directory
image_filename = 'D:\Papers\Density_estimation\Github_code\Data\Sample_IM';
Calibration_filename = 'D:\Papers\Density_estimation\Github_code\Data\Calibration\170cm_40Degree_Toulouse.JPG';

%% Set the folder for output
image_names = dir([image_filename,'\*.JPG']);
N = length(image_names);
if N == 0
    W_object=warndlg('There is no image in this folder. Please recheck the image filename.',...
        'Warning!');
    return
end
mkdir(image_filename,'output')
output_default_path = fullfile(image_filename,'output');
message = 'Select the output folder';
uiwait(msgbox(message));
output_folder = uigetdir(output_default_path);
%% calibration process
IM = imread(Calibration_filename);
[tform,Ratio] = Transformation_ratio(IM,[10,7],3.5); % unit: cm
close all
%% Processing
Positions_write = table();
Properties_write = table();

for n = 1:N
    %% image read and classification
    image_dir = fullfile(image_filename,image_names(n).name);
    wheat = imread(image_dir);
    wheat_binary = classification(wheat);
    
    %% image transformation
    IM_trans = imtransform(wheat,tform,'XData',[1 size(wheat,2)],'YData',...
        [1 size(wheat,1)],'fillvalues',0);
    IM_trans_binary = imtransform(wheat_binary,tform,'XData',[1 size(wheat,2)],'YData',...
        [1 size(wheat,1)],'fillvalues',0);
    
    %% clear the samll object and remove incomplete border rows
    % clear the border and the isolated cases
    % IM_trans_binary = imclearborder(IM_trans_binary);
    sum_row = sum(IM_trans_binary');
    sum_row = smooth(sum_row,200,'rloess');
    Y_peaks_min = peakfinder(sum_row,0.1,[],-1);
        rows = length(Y_peaks_min);

    %% input the number of rows
        IM_trans_binary = bwareaopen(IM_trans_binary,300);
    imshow(IM_trans_binary)
    Objects = regionprops(IM_trans_binary,'Centroid','ConvexArea','Eccentricity',...
        'EquivDiameter','Extent','FilledArea','Area','MajorAxisLength',...
        'MinorAxisLength','Orientation','Solidity','Image','ConvexHull');

    for k = 1:length(Objects)
        Object_center(k,:) = Objects(k).Centroid;
    end
    [idx,c] = kmeans(Object_center(:,2),rows,'replicates',5);
    Row_index = idx;
    %% display the image (corrected without binarization) full screen
    % inspired by the following work
    % http://stackoverflow.com/questions/19989565/how-can-i-keep-matlab-figure-window-maximized-when-showing-a-new-image
    close all
    screenSize = get(0,'screensize');
    screenWidth = screenSize(3);
    screenHeight = screenSize(4);
    hFig = figure('Name',image_names(n).name,...
        'Position', [0 0 screenWidth screenHeight],...
        'WindowStyle','modal',...
        'Color',[0.5 0.5 0.5],...
        'Toolbar','none');
    imshow(IM_trans,'InitialMagnification','fit')
    hold on
    %% Object properties
    for k = 1:length(Objects)
        skeleton_objects = skeleton_lsy(Objects(k).Image);
        Endpoints = bwmorph(skeleton_objects,'endpoints');
        Branpoints = bwmorph(skeleton_objects,'branchpoints');
        Length = regionprops(skeleton_objects,'Area');
        Length_skele(k,:) = cell2mat({Length.Area}); % skeletoon length
        Num_end(k,:) = sum(sum(Endpoints)); % number of endpoints
        Num_bran(k,:) = sum(sum(Branpoints)); % number of branch points
        Moment(k,:) = feature_vec(Objects(k).Image);
        Num_row(k,:) = Row_index(k);
        Area(k,:) = Objects(k).Area;
        ConvexArea(k,:) = Objects(k).ConvexArea;
        Eccentricity(k,:) = Objects(k).Eccentricity;
        EquivDiameter(k,:) = Objects(k).EquivDiameter;
        Extent(k,:) = Objects(k).Extent;
        FilledArea(k,:) = Objects(k).FilledArea;
        MajorAxisLength(k,:) = Objects(k).MajorAxisLength;
        MinorAxisLength(k,:) = Objects(k).MinorAxisLength;
        Orientation(k,:) = Objects(k).Orientation;
        Solidity(k,:) = Objects(k).Solidity;
    end
    cc = hsv(rows);
    for k = 1:length(Objects)
        points = Objects(k).ConvexHull;
        convex = convhull(points);
        plot(points(convex,1),points(convex,2),'color',cc(Row_index(k),:))
        objectCentroid = Objects(k).Centroid;
        text(objectCentroid(1),objectCentroid(2),num2str(k),'color','green','FontSize',15);
    end
    
    %% Visually identify plants
    wheat_label = bwlabel(IM_trans_binary);
    button = 1;
    M = [];
    new_M=[];
    plants = [];
    
    zoom out
    hold on
    button = 0;
    
    % the nearest non nan pixel to represent the object lable and retrive
    % the row number
    [~,ID] = bwdist(IM_trans_binary);
    
    while ismember(button,[0,1,2,3])
        [X,Y,button] = ginput2(1,'KeepZoom');
        if button == 3
            if wheat_label(ceil(Y),ceil(X)) ~= 0
                object_label = wheat_label(ceil(Y),ceil(X));
            else
                Ind = sub2ind(size(wheat_label),ceil(Y),ceil(X));
                near_ind = ID(Ind);
                object_label = wheat_label(near_ind);
            end
            M = [M;X,Y,object_label,Row_index(object_label)];
            plot(M(:,1),M(:,2),'x','MarkerSize',10,'MarkerEdgeColor',cc(Row_index(k),:),...
                'MarkerFaceColor',cc(Row_index(k),:));
        else
            hold off
            close all
            break
        end
    end
    
    for m = 1:length(Objects)
        plants(m,:) = sum(M(:,3) == m);
    end
    
    Positions_New = table(repmat(image_names(n).name,size(M,1),1),...
        M(:,4),M(:,3),M(:,1)*Ratio.X,M(:,2)*Ratio.Y,...
        'VariableNames',{'image_name','Row','Object_number','X','Y'});
    
    image_name = repmat(image_names(n).name,length(Objects),1);
    Properties_New = table(image_name,Area,ConvexArea,Eccentricity,EquivDiameter,Extent,...
        FilledArea,MajorAxisLength,MinorAxisLength,Orientation,Solidity,...
        Length_skele,Num_end,Num_bran,Moment(:,1),Moment(:,2),Moment(:,3),Moment(:,4),...
        Moment(:,5),Moment(:,6),Moment(:,7),Num_row,plants,...
        'VariableNames',{'image_name','Area','ConvexArea','Eccentricity',...
        'EquivDiameter','Extent','FilledArea','MajorAxisLength','MinorAxisLength',...
        'Orientation','Solidity','Length_skele','Num_end','Num_bran',...
        'Moment_1','Moment_2','Moment_3','Moment_4','Moment_5','Moment_6','Moment_7',...
        'Num_row','plants'});
    
    %% save the properties and positions of points into csv file
    output_file_positions = fullfile(output_folder,'Positions.csv');
    output_file_properties = fullfile(output_folder,'properties.csv');
    
    if exist(output_file_positions,'file')
        Positions = readtable(output_file_positions);
        Positions.image_name = cell2mat(Positions.image_name);
        Positions_write = [Positions;Positions_New];
    else
        Positions_write = Positions_New;
    end
    writetable(Positions_write,output_file_positions)
    
    if exist(output_file_properties,'file')
        Properties = readtable(output_file_properties);
        Properties.image_name = cell2mat(Properties.image_name);
        Properties_write = [Properties;Properties_New];
    else
        Properties_write = Properties_New;
    end
    writetable(Properties_write,output_file_properties)
    %% empty the variables
    Length_skele = []; % skeletoon length
    Num_end = []; % number of endpoints
    Num_bran = []; % number of branch points
    Moment = [];
    Num_row = [];
    Area = [];
    ConvexArea = [];
    Eccentricity = [];
    EquivDiameter = [];
    Extent = [];
    FilledArea = [];
    MajorAxisLength = [];
    MinorAxisLength = [];
    Orientation = [];
    Solidity = [];
end




