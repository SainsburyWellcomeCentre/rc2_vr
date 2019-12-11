function run_virtual_corridor()
%%RUN_VIRTUAL_CORRIDOR()
%   Runs an inifinite loop in a corridor.
%   Start at position 0, listens to an analog input and computes a "position"
%   value (integration of the analog input which it expects to be a )
%   If digital input is high, screen is black and position resets to 0.
%   Relevant parameters are inside this script... will be a good idea to take them
%   out.
%   Must pre-create the corridor (using 'create_virtual_corridor.m') and
%   load it here.

%% parameters
% whether to save some debugging variables
debug_on                = 0;

% file with corridor
corridor_location       = 'saved\virtual_corridor_sony_mpcl1a_1280x720_20191210.mat';
calibration_file        = 'calibration.mat';

% screen information
screen_number           = 2;

% load calibration
load(calibration_file, 'calibration');

% NI-DAQ info
nidaq_dev               = 'Dev1';
ai_chan                 = 'ai0';
ai_offset               = calibration.offset;
cm_per_s_per_volts      = calibration.scale;
ai_deadband             = 0.01;
di_chan                 = 'port0/line0';



%% load parameters for the corridor
load(corridor_location, 'dot_mask', 'corridor_mask', ...
    'position', 'screenXpixels', 'screenYpixels');
forward_limit         = max(position);
back_limit         = min(position);

%% setup DAQ
ai = daq.createSession('ni');
ai.addAnalogInputChannel(nidaq_dev, ai_chan, 'Voltage');

di = daq.createSession('ni');
di.addDigitalChannel(nidaq_dev, di_chan, 'InputOnly');


%% startup psychotoolbox
PsychDefaultSetup(2);

% make sure screen is available
screens = Screen('Screens');
if ~ismember(screen_number, screens)
    error('screen %i is not available', screen_number);
end

% open a window on chosen screen
[window, ~] = PsychImaging('OpenWindow', screen_number, 0);

% make sure that the corridor was generated for this screen
[xpix, ypix] = Screen('WindowSize', window);
% if xpix ~= screenXpixels || ypix ~= screenYPixels
%    error('loaded corridor is not for this screen: %s', corridor_location);
% end

% for alpha blending (the corridor is an alpha mask)
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');


%% pre-define the textures
% corridor mask
corridor_texture = Screen('MakeTexture', window, corridor_mask);

% dot textures
dot_texture = [];
for i = 1 : size(dot_mask, 3)
    dot_texture(i) = Screen('MakeTexture', window, dot_mask(:, :, i));
end


%% initialization
pos = 0;
last_tic = tic;

% if debugging store some extra information
if debug_on
    iters = 10000;
    store_time = nan(iters, 1);
    count = 0;
    initial_tic = tic;
end


%% start the loop
try
    while 1
        
        % poll the digital input
        di_state = inputSingleScan(di);
        
        if di_state == 1
            Screen('FillRect', window, 0);
            Screen('Flip', window);
            pos = 0;
            continue
        end
        
        % poll analog input == velocity
        ai_volts = inputSingleScan(ai);
        
        % compute the updated position
        ai_volts = (ai_volts - ai_offset);
        if abs(ai_volts) > ai_deadband
            speed =  cm_per_s_per_volts * ai_volts;
            pos = pos + speed * (toc(last_tic));
        end
        last_tic = tic;
        
        
        % set limits here
        if pos >= forward_limit
            pos = forward_limit;
            idx = length(position);
        elseif pos <= back_limit
            pos = back_limit;
            idx = 1;
        else
            [~, idx] = min(abs(position - pos));
        end
        
        % print out position if in debug
        if debug_on
            fprintf('%.2f cm\n', pos);
        end
        
        % draw the textures to screen
        Screen('DrawTexture', window, dot_texture(idx));
        Screen('DrawTexture', window, corridor_texture);
        
        % display updated image
        Screen('Flip', window);
        
        % if debugging 
        if debug_on
            if count < iters
                count = count + 1;
                store_time(count) = toc(initial_tic);
            end
        end
        
        % check for key-press from the user
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            if debug_on
                assignin('base', 'store_time', store_time)
            end
            Screen('CloseAll');
            sca;
            error('escape');
        end
    end
    
catch ME
    
    % close upon error
    Screen('CloseAll');
    sca;
    rethrow(ME);
end
