%% parameters

% filename of corridor
corridor_location       = 'saved\virtual_corridor_full_res.mat';

% screen information
screen_number           = 1;


%% load parameters for the corridor
load(corridor_location, 'dot_mask', 'corridor_mask', ...
    'position', 'screenXpixels', 'screenYpixels');
corridor_length         = max(position);


%% startup psychotoolbox
PsychDefaultSetup(2);

% make sure screen is available
screens = Screen('Screens');

% open a window on chosen screen
[window, ~] = PsychImaging('OpenWindow', screen_number, 0);

% for alpha blending (the corridor is an alpha mask)
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');


%% pre-define the textures
% pre-define the textures
corridor_texture = Screen('MakeTexture', window, corridor_mask);

dot_texture = [];
for i = 1 : size(dot_mask, 3)
    dot_texture(i) = Screen('MakeTexture', window, dot_mask(:, :, i));
end


%% initialization

n_iter = 3600;
vbl = Screen('Flip', window);

% start half-way down the corridor
pos = 50;

% some timing information
tic;
last_t = toc;


%% start the loop
for i = 1 : n_iter
    
    % velocity is a sine wave
    vel = 25*sin(2*pi*0.5*i/60);
    
    % compute the position based on velocity
    this_t = toc;
    pos = pos + (vel*(this_t-last_t));
    last_t = this_t;
    
    % don't go beyond limits
    if pos >= 120
        pos = 120;
        idx = length(position);
    elseif pos <= 0
        pos = 0;
        idx = 1;
    else
        [~, idx] = min(abs(position - pos));
    end
    
    % draw the textures to screen
    Screen('DrawTexture', window, dot_texture(idx), [], [0, 0, screenXpixels, screenYpixels]);
    Screen('DrawTexture', window, corridor_texture, [], [0, 0, screenXpixels, screenYpixels]);
    
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
