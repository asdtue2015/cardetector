function answer = rectangle_collision(x_1, y_1, width_1, height_1, x_2, y_2, width_2,height_2)
area1 = width_1* height_1;
sq1= [x_1,y_1,width_1,height_1];
sq2= [x_2,y_2,width_2,height_2];
int_area = rectint(sq1, sq2);
area2 = width_2* height_2;
center1x = x_1 + (width_1)/2;
center1y = y_1 + (height_1)/2;
center2x = x_2 + (width_2)/2;
center2y = y_2 + (height_2)/2;
center1 = [center1x center1y];
center2 = [center2x center2y];
dist_between_centers = pdist([center1x,center1y;center2x,center2y],'euclidean');
D1=sqrt((width_1*width_1)+(height_1*height_1));
D2=sqrt((width_2*width_2)+(height_2*height_2));
r1=(D1)/2;
r2=(D2)/2;
answer= false;
if r1<r2
   min_r=r1;
   max_r=r2;
   minsq=1;
%     if (center1(1)>x_2&&center1(1)<x_2+width_2)&&(center1(2)>y_2&&center1(2)<y_2+height_2)
%        % answer=true;
%     end
if int_area/area1>0.5
    answer =true;
end
else 
   min_r=r2;
   max_r=r1;
   minsq=2;
%     if (center2(1)>x_1&&center2(1)<x_1+width_1)&&(center2(2)>y_1&&center2(2)<y_1+height_1)
%        % answer=true;
%     end
if int_area/area2>0.9
    answer= true;
end
end
% if (dist_between_centers<= min_r)&&((center1(1)>x_2&&center1(1)<x_2+width_2)&&(center1(2)>y_2&&center1(2)<y_2+height_2)||(center2(1)>x_1&&center2(1)<x_1+width_1)&&(center2(2)>y_1&&center2(2)<y_1+height_1))
%    answer = true;
% end
if max_r/min_r >1.5
    answer=false;
end
 %boolean =  ~(x_1 > x_2+width_2 || x_1+width_1 < x_2 || y_1 > y_2+height_2 || y_1+height_1 < y_2);
end