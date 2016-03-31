function answer = collision_area_based(x_1, y_1, width_1, height_1, x_2, y_2, width_2,height_2)
area1 = width_1* height_1;
sq1= [x_1,y_1,width_1,height_1];
sq2= [x_2,y_2,width_2,height_2];
int_area = rectint(sq1, sq2);
area2 = width_2* height_2;

answer= false;

if (int_area/area2>=0.7 && int_area/area1>=0.7 )
    answer= true;
end



end