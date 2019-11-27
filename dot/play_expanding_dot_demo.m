
% filename of corridor
dot_location       = 'saved\virtual_dot_full_res.mat';

% screen information
screen_number           = 1;


%% load parameters for the dot
load(dot_location, 'dot_mask', 'corridor_mask', ...
    'position', 'screenXpixels', 'screenYpixels');
corridor_length         = max(position);


%% startup psychotoolbox
PsychDefaultSetup(2);

% make sure screen is available
screens = Screen('Screens');

% open a window on chosen screen
[window, ~] = PsychImaging('OpenWindow', screen_number, 0);


%% pre-define the textures
dot_texture = [];
for i = 1 : size(dot_mask, 3)
    dot_texture(i) = Screen('MakeTexture', window, dot_mask(:, :, i));
end


%% initialization

n_iter = 3600;
vbl = Screen('Flip', window);

% start at the beginning
pos = 0;

% some timing information
tic;
last_t = toc;


%% start the loop
for i = 1 : n_iter
    
    % velocity is a sine wave
    vel = 25;
    
    % compute the position based on velocity
    this_t = toc;
    pos = pos + (vel*(this_t-last_t));
    last_t = this_t;
    
    
    % just keep looping
    if pos >= 120
        pos = 0;
        idx = 1;
    elseif pos <= 0
        pos = 0;
        idx = 1;
    else
        [~, idx] = min(abs(position - pos));
    end
    
    % draw the textures to screen
    Screen('DrawTexture', window, dot_texture(idx), [], [0, 0, screenXpixels, screenYpixels]);
    
    % display updated image
    Screen('Flip', window);
    
    % check for key-press from the user.
    [~, ~, keyCode] = KbCheck;
    if keyCode(KbName('escape'))
        sca;
        error('escape');
    end
end

% display average frame rate
avgfps = n_iter / (GetSecs - vbl)

% clear the screen
Screen('CloseAll')
sca;
