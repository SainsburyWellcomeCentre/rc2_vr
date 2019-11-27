function run_expanding_dot()
%%RUN_EXPANDING_DOT()
%   Runs an inifinite loop of approaching a large white dot.
%   Start at position 0, listens to an analog input and computes a "position"
%   value (integration of the analog input which it expects to be a )
%   If digital input is high, screen is black and position resets to 0.
%   Relevant parameters are inside this script... will be a good idea to take them
%   out.
%   Must pre-create the dot (using 'create_expanding_dot.m') and
%   load it here.

%% parameters

% file with dot
dot_location       = 'saved\virtual_dot_full_res.mat';

% screen information
screen_number           = 1;

% NI-DAQ info
nidaq_dev               = 'Dev1';
ai_chan                 = 'ai0';
ai_offset               = 0.511115639488569;
ai_deadband             = 0.015;
di_chan                 = 'port0/line0';
cm_per_s_per_volts      = 100/2.5;


%% load parameters for the dot
load(dot_location, 'dot_mask', ...
    'position', 'screenXpixels', 'screenYpixels');
corridor_length         = max(position);


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
if xpix ~= screenXpixels || ypix ~= screenYPixels
    error('loaded corridor is not for this screen: %s', corridor_location);
end


%% pre-define the textures
% dot textures
dot_texture = [];
for i = 1 : size(dot_mask, 3)
    dot_texture(i) = Screen('MakeTexture', window, dot_mask(:, :, i));
end


%% initialization
pos = 0;
last_tic = tic;


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
        if pos >= corridor_length
            pos = corridor_length;
            idx = length(position);
        elseif pos <= 0
            pos = 0;
            idx = 1;
        else
            [~, idx] = min(abs(position - pos));
        end
        
        % draw the textures to screen
        Screen('DrawTexture', window, dot_texture(idx));
        
        % display updated image
        Screen('Flip', window);
        
        % check for key-press from the user.
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
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