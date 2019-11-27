% test the geometry of the expanding dot with lines and circles

%% parameters
distance_from_screen    = 5;

distance_from_dot       = 125:-1:7;
dot_radius              = 9;

screen_width            = 30;
screen_height           = 18;

screen_width_px         = 1920;
screen_height_px        = 1080;

mouse_height            = 9;
circle_above_mouse      = 0;


% pixelate the screen
[X_screen, Y_screen] = meshgrid(linspace(0, screen_width, screen_width_px), ...
    linspace(0, screen_height, screen_height_px));

% preallocate a mask
mask = false(size(X_screen, 1), size(X_screen, 2), length(distance_from_dot));

% for each distance simulate the dot
for i = 1 : length(distance_from_dot)
    
    % auxiliary equations
    Xt = (distance_from_dot(i)/dot_radius)*(X_screen./(2*distance_from_screen - X_screen));
    A = (dot_radius*Xt + distance_from_dot(i));
    B = Y_screen - mouse_height;
    C = sqrt(2)*distance_from_screen*circle_above_mouse;
    D = sqrt(2)*distance_from_screen*dot_radius;
    E = 1 - Xt.^2;
    
    % which pixels are in the circle
    idx = ((A.*B - C)/D).^2 < E;
    
    % we need this condition because we have a hyperbola
    max_x = 2*distance_from_screen*dot_radius/(dot_radius+distance_from_dot(i));
    idx = idx & X_screen < max_x;
    
    % temp array and store in mask
    temp = false(size(X_screen));
    temp(idx) = true;
    mask(:, :, i) = temp;
end


%% play a movie of the expanding dot
figure
for i = 1 : length(distance_from_dot)
    imagesc(flipud(mask(:, :, i)))
    pause(1/20)
end


%% parametric equations for dot
% parametrize circle
t = 0:0.01:2*pi;

% index of 'distance_from_dot' at which to plot dot
pos_idx = 100;

% set of x and y coordinates for circle at this location
x = 2*distance_from_screen*dot_radius*cos(t)./(dot_radius*cos(t)+distance_from_dot(pos_idx));
y = mouse_height + sqrt(2)*distance_from_screen*(dot_radius*sin(t)+circle_above_mouse)./(dot_radius*cos(t)+distance_from_dot(pos_idx));


% do the plotting
figure
hold on

% move around the circle and colour it according to parameter t, above.
for j = 1 : length(x)-1
    plot(x([j, j+1]), y([j, j+1]), 'color', [j/length(x), 0, 1-j/length(x)])
end

% update axes
xlim([0, 30])
ylim([0, 18])
set(gca, 'plotBoxAspectRatio', [30, 18, 1])

