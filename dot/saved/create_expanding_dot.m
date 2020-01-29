% parameters of the setup and expanding dot

fname                       = 'virtual_dot_sony_mpc1a_1280x720_20200129_grey.mat';

% screen information
screen_width                = 30;                      
screen_height               = 18;

screenXpixels               = 1280;
screenYpixels               = 720;

% mouse position
mouse_height                = 0;            % cm, height of mouse relative to bottom of screen
distance_from_screen        = 5;

% dot parameters
dot_colour                  = floor(127/2); % this is to match the corridor luminance 
dot_above_mouse             = 9;
dot_radius                  = 9;

distance_to_simulate        = 120;
distance_to_simulate_back   = 5;
resolution_to_simulate      = 0.1;

% position at which to simulate the corridor
n_points = floor((distance_to_simulate+distance_to_simulate_back)/resolution_to_simulate)+1;
position = linspace(-distance_to_simulate_back, distance_to_simulate, n_points);%(0:n_points-1)*resolution_to_simulate;

minimum_distance_from_dot   = sqrt(2)*distance_from_screen;
distance_from_dot           = minimum_distance_from_dot + distance_to_simulate - position;

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
    temp(idx) = dot_colour;
    
    % store it
    dot_mask(:, :, i) = temp;
end


%% save the dot
clear A B C D E distance_from_dot i idx max_x minimum_distance_from_dot n_points temp X Xt Y
save(fname, '-v7.3');