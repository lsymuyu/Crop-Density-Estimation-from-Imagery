%% the function for the estimation of the picture with chessbord to estimate the 
% transformation matrix and scalling ratio
function [tform,Ratio] = Transformation_ratio(IM,Dimension_chessboard,dimension_square)
%% automatic detect the points
Num_Crosspoints = (Dimension_chessboard(1)-1)*(Dimension_chessboard(2)-1);
detect_points = detectCheckerboardPoints(IM);

Num = [1,min(Dimension_chessboard)-1,...
    Num_Crosspoints-min(Dimension_chessboard)+2,...
    Num_Crosspoints];
Border_points = detect_points(Num,:);
CIR_pt = [Border_points,repmat(30,size(Border_points,1),1)];

IM_points = insertShape(IM,'FilledCircle',CIR_pt,'color','r');
IM_points_text = insertText(IM_points,Border_points,1:size(Border_points,1),...
                            'FontSize',90,'BoxOpacity',0.4);
imshow(IM_points_text)
%% Image transformation
M = Border_points;
[dum,indsorty]=sort(M(:,2));
Upper = M(indsorty(3:4),:);
Lower = M(indsorty(1:2),:);

if Upper(2,1)<Upper(1,1)
    toto = Upper(1,:);
    Upper(1,:) = Upper(2,:);
    Upper(2,:) = toto;
end

if Lower(2,1)>Lower(1,1)
    toto = Lower(1,:);
    Lower(1,:) = Lower(2,:);
    Lower(2,:) = toto;
end
% the four corners of the rectangle 
M1 = cat(1,Upper,Lower);
N=M1(1:4,:);
N(2,2)=N(1,2);
N(3,1)=N(2,1);
N(4,2)=N(3,2);
N(4,1)=N(1,1);

tform = cp2tform(M1(1:4,:),N,'projective');
IM_trans = imtransform(IM,tform,'XData',[1 size(IM,2)],'YData',...
    [1 size(IM,1)],'fillvalues',0);

%% modification: points transformation (Algorithm from Marie)
% I don't need to detect the point again!! The result is the same.
M_trans = tformfwd(tform,Border_points(:,1),Border_points(:,2));
figure()
% IM_trans_points = insertMarker(IM_trans,M_trans,'o','color','r','size',30);
%                             
% IM_trans_points_text = insertText(IM_trans_points,M_trans,1:size(M_trans, 1),...
%                                   'FontSize',100,'BoxOpacity',0.4);

CIR_pt = [M_trans,repmat(30,size(M_trans,1),1)];                              
IM_points = insertShape(IM_trans,'FilledCircle',CIR_pt,'color','r');
IM_trans_points_text = insertText(IM_points,M_trans,1:size(M_trans,1),...
                            'FontSize',90,'BoxOpacity',0.4);                              
                                                                                          
Width_Pix = mean(abs([M_trans(1,1)-M_trans(3,1),M_trans(4,1)-M_trans(2,1)]));
Height_Pix = mean(abs([M_trans(1,2)-M_trans(2,2),M_trans(4,2)-M_trans(3,2)]));
% Width (X) and Height (Y): long and short
Width = (max(Dimension_chessboard)-2)*dimension_square;
Height = (min(Dimension_chessboard)-2)*dimension_square;
Ratio.X = Width/Width_Pix;
Ratio.Y = Height/Height_Pix;
string_Ratio = sprintf('Ratio X = %0.3f; Ratio Y = %0.3f',Ratio.X ,Ratio.Y);
imshow(IM_trans_points_text)
xlim = get(gca,'xlim');
ylim = get(gca,'ylim');
% text(xlim(2)*0.7,ylim(2)*0.85,string_Ratio,'color','green');
end
