% parameters of the setup and expanding dot

fname                       = 'virtual_dot_full_res.mat';

% screen information
screen_width                = 30;                      
screen_height               = 18;

screenXpixels               = 1920;
screenYpixels               = 1080;

% mouse position
mouse_height                = 1;            % cm, height of mouse relative to bottom of screen
distance_from_screen        = 5;

% dot parameters
dot_above_mouse             = 0;
dot_radius                  = 10;

distance_to_simulate        = 120;
resolution_to_simulate      = 0.1;

minimum_distance_from_dot   = sqrt(2)*distance_from_screen;
distance_from_dot           = minimum_distance_from_dot + distance_to_simulate - position;

% position at which to simulate the corridor
n_points                    = floor(distance_to_simulate/resolution_to_simulate);
position                    = (0:n_points-1)*resolution_to_simulate;

scale                       = 1;

%% x-y screen coordinates
[X, Y] = meshgrid(linspace(0, screen_width, screenXpixels/scale), linspace(0, screen_height, screenYpixels/scale));
Y = flipud(Y);


%% loop

% preallocate mask array
dot_mask = zeros(size(X, 1), size(X, 2), length(distance_from_dot), 'uint8');

% create a dot at 1mm resolution
for i = 1 : length(distance_from_dot)
    
    % auxiliary parameters
    Xt = (distance_from_dot(i)/dot_radius)*(X./(2*distance_from_screen - X));
    A = (dot_radius*Xt + distance_from_dot(i));
    B = Y - mouse_height;
    C = sqrt(2)*distance_from_screen*dot_above_mouse;
    D = sqrt(2)*distance_from_screen*dot_radius;
    E = 1 - Xt.^2;
    
    idx = ((A.*B - C)/D).^2 < E;
    
    % we need this condition because we have a hyperbola
    max_x = 2*distance_from_screen*dot_radius/(dot_radius+distance_from_dot(i));
    idx = idx & X < max_x;
    
    % create the current 'dot'
    temp = zeros(size(X), 'uint8');
    temp(idx) = 255;
    
    % store it
    dot_mask(:, :, i) = temp;
end


%% save the dot
save(fname, '-v7.3', 'dot_mask', 'position', 'screenXpixels', 'screenYpixels', 'scale');