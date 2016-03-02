%% draw a approximate 64 x 128 rectangle based on random value
function [x, y, w ,h] = generate_rectangle_64x128( imsize, maxscale )

    while 1 == 1
        
        %% generate a random roi
        x = floor((imsize(2)-imsize(2)/10).*rand(1) + imsize(2)/10);
        y = floor((imsize(1)-imsize(1)/10).*rand(1) + imsize(1)/10);
        h = floor( 128 * (1+rand(1)*(maxscale-1)) );
        w = floor( 0.5 * h );

        %% must fit in image
        if (x+w < imsize(2)) & (y+h < imsize(1))
            break;
        end
        
    end
    
end