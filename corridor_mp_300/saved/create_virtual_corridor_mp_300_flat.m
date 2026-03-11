% Parameters of the setup and virtual corridor
fname                       = 'virtual_corridor_mp_300_960x540_flat.mat';

corridor_half_width         = 5;            % cm, virtual corridor half-width (mouse is in centre of corridor)
distance_from_screen        = 8;            % cm, distance of mouse from screen

% Screen information
screen_width                = 34.7;                      
screen_height               = 19.5;

screenXpixels               = 960;
screenYpixels               = 540;

mouse_height                = 2;            % cm, height of mouse relative to bottom of screen
corridor_above_mouse        = 5;            % cm, height of corridor relative to mouse
corridor_below_mouse        = -0.5;         % cm, bottom of corridor relative to mouse

distance_to_simulate        = 125;          % cm, amount of corridor to simulate
distance_to_simulate_back   = 5;
resolution_to_simulate      = 0.1;          % cm, the resolution to simulate

rng(1);

% Parameters for the dots
n_dots                      = 130;
min_backward                = -3.9 - distance_to_simulate_back; % cm, furthest dot centre behind mouse (in corridor coordinates)
max_forward                 = 300;          % cm, furthest dot centre in front of mouse (corridor coordinates)
min_down                    = corridor_below_mouse; % Corridor bottom
max_up                      = corridor_above_mouse; % Corridor top
min_radius                  = 0.3;          % cm, smallest dot radius
max_radius                  = 2;            % cm, largest dot radius

% Pre-allocate and generate dot positions and radii
dot_radius                  = min_radius + (max_radius - min_radius) * rand(n_dots, 1); % Random radii
dot_centres.x               = min_backward + (max_forward - min_backward) * rand(n_dots, 1); % Random x positions
dot_centres.y               = min_down + (max_up - min_down) * rand(n_dots, 1); % Random y positions

% Ensure dots are well-distributed (no clustering):
% Adjust horizontal spacing between dots to avoid overlaps
dot_centres.x = sort(dot_centres.x); % Ensure forward progression along x-axis
for i = 2:n_dots
    min_spacing = dot_radius(i-1) + dot_radius(i); % Minimum spacing to avoid overlaps
    if dot_centres.x(i) - dot_centres.x(i-1) < min_spacing
        dot_centres.x(i) = dot_centres.x(i-1) + min_spacing + rand; % Adjust spacing
    end
end

% Convert normalized colors to 8-bit grayscale intensities
greyVal = 127;  % Mid-grey background
blackVal = round(greyVal * 0.6); % Scaled black dots
whiteVal = round(greyVal * 1.5); % Scaled white dots

% Assign dot colors: randomly choose black or white
dot_colours = randi(2, n_dots, 1); % 1 = black, 2 = white
dot_colours(dot_colours == 1) = blackVal; % Black dots
dot_colours(dot_colours == 2) = whiteVal; % White dots

%% x-y screen coordinates
[X, Y] = meshgrid(linspace(0, screen_width, screenXpixels), linspace(0, screen_height, screenYpixels));
Y = flipud(Y);

%% Create masks of dots at all points along the corridor
% Position at which to simulate the corridor
n_points = floor((distance_to_simulate + distance_to_simulate_back) / resolution_to_simulate) + 1;
position = linspace(-distance_to_simulate_back, distance_to_simulate, n_points);

% Preallocate mask array
dot_mask = greyVal * ones(size(X, 1), size(X, 2), n_points, 'uint8');

% Auxiliary parameters to speed up the processing
tic;
for i = 1:n_points
    % Mask
    temp_mask = greyVal * ones(size(X), 'uint8');
    
    % Move dot centres along corridor
    T = dot_centres.x - (i-1)*resolution_to_simulate;
    
    % Process only visible dots
    visible = T > 0 & T < screen_width;
    visible_indices = find(visible); % Indices of visible dots
    
    for j = visible_indices'
        % Calculate dot positions
        mask_x = (X - T(j)).^2 + (Y - (mouse_height + dot_centres.y(j))).^2;
        mask_r = dot_radius(j)^2;

        % Apply the dot positions
        temp_mask(mask_x < mask_r) = dot_colours(j);
    end
    
    % Store this mask
    dot_mask(:, :, i) = temp_mask;
    
    % Display iteration progress
    fprintf('done iteration %i/%i,  ~%i s remaining\n', i, n_points, round((n_points - i) * toc / i));
end

%% Save the corridor
save(fname, 'dot_mask', 'dot_centres', 'position', 'screenXpixels', 'screenYpixels', '-v7.3');
