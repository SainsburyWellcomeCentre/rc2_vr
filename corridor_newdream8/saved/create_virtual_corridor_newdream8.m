% parameters of the setup and virtual corridor
%   dot colours and mid-grey wall is set to match the corridor as it
%   appeared on the Sony projector

fname                       = 'virtual_corridor_newdream8_960x540_20210705.mat';

corridor_half_width         = 5;            % cm, virtual corridor half-width (mouse is in centre of corridor)
distance_from_screen        = 5;            % cm, distance of mouse from screen

% screen information
screen_width                = 34.4;                      
screen_height               = 19.3;

screenXpixels               = 960;
screenYpixels               = 540;

mouse_height                = 0;            % cm, height of mouse relative to bottom of screen
corridor_above_mouse        = 5;            % cm, height of corridor relative to mouse
corridor_below_mouse        = -0.5;           % cm, bottom of corridor relative to mouse

distance_to_simulate        = 125;          % cm, amount of corridor to simulate
distance_to_simulate_back   = 5;
resolution_to_simulate      = 0.1;          % cm, the resolution to simulate

rng(1);

% parameters for the dots
n_dots                      = 130;
min_backward                = -3.9 - distance_to_simulate_back;         % cm, furthest dot centre behind mouse (in corridor coordinates)
max_forward                 = 300;          % cm, furthest dot centre in front of mouse (corridor coordinates)
min_down                    = -0.5;         
max_up                      = corridor_above_mouse - 0.5;
min_radius                  = 0.3;          % cm, smallest dot radius
max_radius                  = 2;            % cm, largest dot radius

current_x                   = min_backward;
dot_radius                  = nan(n_dots, 1);
dot_centres.x               = nan(n_dots, 1);
for i = 1 : n_dots
    dot_radius(i)           = min_radius + (max_radius - min_radius)*rand;           % vector of dot radii
    dot_centres.x(i)        = current_x + rand*dot_radius(i);
    current_x               = current_x + 2*dot_radius(i);
end

scale                       = 1;

dot_centres.y               = min_down + (max_up - min_down)*rand(n_dots, 1);                   % vector of dot centres along y axis
%dot_colours                 = randi(2, n_dots, 1) - 1;                                          % vector of dot colours (white/black)
dot_colours                 = 0.4 + 0.2*(randi(2, n_dots, 1) - 1);

% convert colours for newdream8
dark_spots                  = dot_colours == 0.4;
light_spots                 = dot_colours == 0.6;

% calibration on 2021-07-05 (see gamma_tests_sony_projector.txt)
dot_colours(dark_spots)     = 2*0.1285;
dot_colours(light_spots)    = 2*0.20625;
grey_fraction               = 2*0.16;

%% x-y screen coordinates
[X, Y] = meshgrid(linspace(0, screen_width, screenXpixels/scale), linspace(0, screen_height, screenYpixels/scale));
Y = flipud(Y);


%% create masks of dots a all points along the corridor

whiteVal = 127;
greyVal = grey_fraction * whiteVal;



% position at which to simulate the corridor
n_points = floor((distance_to_simulate+distance_to_simulate_back)/resolution_to_simulate)+1;
position = linspace(-distance_to_simulate_back, distance_to_simulate, n_points);%(0:n_points-1)*resolution_to_simulate;

% preallocate mask array
dot_mask = greyVal*ones(size(X, 1), size(X, 2), n_points, 'uint8');

% auxiliary parameters, to speed up the processing
A = (corridor_half_width^2)*(2*(Y-mouse_height).^2 + X.^2 - 4*distance_from_screen*(X - distance_from_screen))./(X.^2);
B = -2*sqrt(2)*corridor_half_width*(Y-mouse_height)./X;
C = 2*corridor_half_width*(2*distance_from_screen./X - 1);
D = nan(size(X, 1), size(X, 2), length(dot_centres.x));
for j = 1 : length(dot_centres.x)
    D(:, :, j) = A + B*dot_centres.y(j) + (dot_centres.y(j)^2 - dot_radius(j)^2);
end

% start timing
tic;

% create a dot mask at 1mm resolution
for i = 1 : n_points
    
    % mask
    temp_mask = greyVal * ones(size(X), 'uint8');
    
    % move dot centres along corridor
    T = dot_centres.x - (i-1)*resolution_to_simulate;
    
    % simplified
    for j = 1 : length(dot_centres.x)
        temp_mask(D(:, :, j) < T(j)*C - T(j)^2) = whiteVal*dot_colours(j);
    end
    
    % store this mask
    dot_mask(:, :, i) = temp_mask;
    
    % display iteration
    fprintf('done iteration %i/%i,  ~%i s remaining\n', i, n_points, (n_points-i)*(toc/i));
end



%% infinite corridor shape on the screen
corridor_mask = (Y < mouse_height + (corridor_above_mouse*X/(sqrt(2)*corridor_half_width))) & ...
    (Y > mouse_height + (corridor_below_mouse*X/(sqrt(2)*corridor_half_width)));
corridor_mask = cat(3, ones(size(corridor_mask))*0, ~corridor_mask);


%% save the corridor
% use -v7.3 flag because matrix is large
clear A B C D E i j T temp_mask X Y current_x
% save all other information
save(fname, '-v7.3');  % , 'dot_mask', 'corridor_mask', 'position', 'screenXpixels', 'screenYpixels', 'scale'