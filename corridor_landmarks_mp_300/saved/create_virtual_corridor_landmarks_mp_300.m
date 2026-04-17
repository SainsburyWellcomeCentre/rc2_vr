% parameters of the setup and virtual corridor
%   dot colours and mid-grey wall is set to match the corridor as it
%   appeared on the Sony projector

% fname                       = 'virtual_corridor_mp_300_960x540_20210827.mat';
fname                       = 'C:\Users\mateo\Documents\rc2\vr\corridor_landmarks_mp_300\saved\virtual_corridor_landmarks_mp_300_960x540_20260330.mat';

corridor_half_width         = 5;            % cm, virtual corridor half-width (mouse is in centre of corridor)
distance_from_screen        = 8;            % cm, distance of mouse from screen

% screen information
screen_width                = 34.7;                      
screen_height               = 19.5;

screenXpixels               = 960;
screenYpixels               = 540;

mouse_height                = 2;            % cm, height of mouse relative to bottom of screen
corridor_above_mouse        = 5;            % cm, height of corridor relative to mouse
corridor_below_mouse        = -0.5;           % cm, bottom of corridor relative to mouse

distance_to_simulate        = 125;          % cm, amount of corridor to simulate (125)
distance_to_simulate_back   = 5;             % (5)
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

% parameters for landmarks (white circles on corridor walls)
landmark1_pos               = 10;           % cm, beginning - white circle
landmark2_pos               = 62.5;         % cm, middle - white circle
landmark3_pos               = 115;          % cm, end - white circle
landmark_radius             = 3;            % cm, radius of landmark circles
landmark_height             = 2;            % cm, height on wall where landmarks appear
landmark_color              = 1.0;          % white for all landmarks

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
dark_spots                  = single(dot_colours) == single(0.4);
light_spots                 = single(dot_colours) == single(0.6);

% calibration on 2021-07-05 (see gamma_tests_mp_300.txt and luminance_tests_mp_300.txt)
dot_colours(dark_spots)     = 2*0.035;
dot_colours(light_spots)    = 2*0.096;
grey_fraction               = 2*0.056;

%% x-y screen coordinates
[X, Y] = meshgrid(linspace(0, screen_width, screenXpixels/scale), linspace(0, screen_height, screenYpixels/scale));
Y = flipud(Y);


%% create masks of dots at all points along the corridor

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
    
    % add landmarks (white circles on walls)
    % Landmark 1
    T_landmark1 = landmark1_pos - (i-1)*resolution_to_simulate;
    E1 = A + B*landmark_height + (landmark_height^2 - landmark_radius^2);
    temp_mask(E1 < T_landmark1*C - T_landmark1^2) = whiteVal*landmark_color;
    
   % Landmark 2 - Triangle (projected as triangle on wall)
    T_landmark2 = landmark2_pos - (i-1)*resolution_to_simulate;

    % Calculate wall coordinates (where screen rays hit the corridor wall)
    wall_y = sqrt(2)*corridor_half_width*(Y - mouse_height)./X;
    wall_x = corridor_half_width*(2*distance_from_screen./X - 1);

    % Calculate position relative to landmark center
    wall_x_rel = wall_x - T_landmark2;
    wall_y_rel = wall_y - landmark_height;

    % Triangle mask: upward-pointing triangle, tapers from base to apex
    % Base at wall_y_rel = -landmark_radius (bottom), apex at +landmark_radius (top)
    triangle_mask = (wall_y_rel >= -landmark_radius) & (wall_y_rel <= landmark_radius) & ...
                    (abs(wall_x_rel) < (landmark_radius - wall_y_rel)/2) & (X > 0);
    temp_mask(triangle_mask) = whiteVal*landmark_color;
    % Landmark 3 - Square/Box (projected as square on wall)
    T_landmark3 = landmark3_pos - (i-1)*resolution_to_simulate;

    % Calculate wall coordinates (where screen rays hit the corridor wall)
    wall_y = sqrt(2)*corridor_half_width*(Y - mouse_height)./X;
    wall_x = corridor_half_width*(2*distance_from_screen./X - 1);

    % Calculate position relative to landmark center
    wall_x_rel = wall_x - T_landmark3;
    wall_y_rel = wall_y - landmark_height;

    % Square mask: both dimensions within box size
    square_mask = (abs(wall_x_rel) < landmark_radius) & (abs(wall_y_rel) < landmark_radius) & (X > 0);
    temp_mask(square_mask) = whiteVal*landmark_color;
    
    % store this mask
    dot_mask(:, :, i) = temp_mask;
    
    % display iteration progress
    fprintf('done iteration %i/%i,  ~%i s remaining\n', i, n_points, (n_points-i)*(toc/i));
end



%% infinite corridor shape on the screen
corridor_mask = (Y < mouse_height + (corridor_above_mouse*X/(sqrt(2)*corridor_half_width))) & ...
    (Y > mouse_height + (corridor_below_mouse*X/(sqrt(2)*corridor_half_width)));
corridor_mask = cat(3, ones(size(corridor_mask))*0, ~corridor_mask);


%% Save the corridor BEFORE debug visualization
% This ensures the file is saved even if the debug window is closed incorrectly
fprintf('\n=== SAVING CORRIDOR ===\n');
fprintf('Saving to: %s\n', fname);
save(fname, '-v7.3');
fprintf('Save completed successfully!\n');


%% Debug mode - simple frame viewer
debug_mode = true;  % Set to false to skip visualization

if debug_mode
    fprintf('\n=== DEBUG MODE ===\n');
    fprintf('NOTE: File has already been saved. You can safely close this viewer.\n');
    fprintf('Total frames: %d (%.1f cm of corridor)\n', n_points, distance_to_simulate + distance_to_simulate_back);
    fprintf('Frame resolution: %.1f mm per frame\n', resolution_to_simulate*10);
    fprintf('Landmarks: circle (%.1f cm radius) at %.1f cm, triangle (%.1f cm base) at %.1f cm, square (%.1f cm side) at %.1f cm\n', ...
     landmark_radius, landmark1_pos, 2*landmark_radius, landmark2_pos, 2*landmark_radius, landmark3_pos);
    
    % Simple frame-by-frame viewer
    fig = figure('Name', 'Corridor Frame Viewer (File Already Saved)', 'KeyPressFcn', @(~,~)[]);
    frame_idx = 1;
    step_size = 1;  % change to 10 for faster browsing
    
    while true
        imshow(dot_mask(:, :, frame_idx));
        title(sprintf('Frame %d/%d | Position: %.2f cm | FILE SAVED ✓ | [←/→: ±1, ↑/↓: ±10, Q: quit]', ...
              frame_idx, n_points, position(frame_idx)));
        
        key = waitforbuttonpress;
        if key == 1  % keyboard press
            ch = get(gcf, 'CurrentCharacter');
            if ch == 'q' || ch == 'Q'
                break;
            elseif ch == 28  % left arrow
                frame_idx = max(1, frame_idx - step_size);
            elseif ch == 29  % right arrow
                frame_idx = min(n_points, frame_idx + step_size);
            elseif ch == 30  % up arrow (faster forward)
                frame_idx = min(n_points, frame_idx + 10);
            elseif ch == 31  % down arrow (faster backward)
                frame_idx = max(1, frame_idx - 10);
            end
        end
        
        % Check if figure was closed
        if ~ishandle(fig)
            break;
        end
    end
    
    if ishandle(fig)
        close(fig);
    end
    fprintf('Debug mode completed.\n\n');
end


%% End of script
fprintf('=== SCRIPT COMPLETE ===\n');
fprintf('Corridor file ready: %s\n', fname);