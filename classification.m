%% recheck the classification algorthim
% there are references on extraction the plant from the backgroud and do
% some work on the comparision of several methods

%%
function out = classification(wheat)

% %image enhancement
% wheat = imadjust(wheat);

%transform color space
Trans = makecform('srgb2lab');
wheatLab = applycform(wheat,Trans);                                                            

%convert To Binary image
level=graythresh(wheatLab(:,:,2));
w = im2bw(mat2gray(wheatLab(:,:,2)),level);

%remove small objects
w=~w;
out = bwareaopen(w,300);
out = bwmorph(out,'majority');
% st = strel('disk',5);
% out = imdilate(out,st);
% out = imerode(out,st);
end






    
    













