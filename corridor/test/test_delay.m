function test_delay()
%%TEST_DELAY()
%   Measures analog input and converts into a full screen grey value.
%   The grey value represents the speed at which the virtual corridor would be
%   moving.
%   Uses similar code to 'run_virtual_corridor'.
%   Measure with photodiode at output of projector.

%% parameters
% whether to save some debugging variables
debug_on                = 0;

%Screen('Preference', 'SkipSyncTests', 1);

% velocity in cm/s at which brightness = 1
max_speed               = 100;

% offsets
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
ai_deadband             = 0.005;
di_chan                 = 'port0/line0';


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

% for alpha blending (the corridor is an alpha mask)
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

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
            continue
        end
        
        % poll analog input == velocity
        ai_volts = inputSingleScan(ai);
        
        % compute the updated position
        ai_volts = (ai_volts - ai_offset);
        if abs(ai_volts) > ai_deadband
            speed =  cm_per_s_per_volts * ai_volts;
        end
        
        % calculate brightness value
        brightness_value = max(0, min(speed/max_speed, 1));
        
        % update screen brightness
        Screen('FillRect', window, brightness_value);
        
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
