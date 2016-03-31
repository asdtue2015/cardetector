function boolean = rectangle_collision(x_1, y_1, width_1, height_1, x_2, y_2, width_2,height_2)
  boolean =  ~(x_1 > x_2+width_2 || x_1+width_1 < x_2 || y_1 > y_2+height_2 || y_1+height_1 < y_2);
end