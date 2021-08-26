function test_ttl_trigger_to_screen_update_delay()
%%test_ttl_trigger_to_screen_update_delay()
% Updates screen from black to white when digital input goes high.


%% parameters
Screen('Preference', 'SkipSyncTests', 1);

% screen information
screen_number           = 1;

% NI-DAQ info
nidaq_dev               = 'Dev1';
di_chan                 = 'port0/line0';
ao_chan                 = 'ao0';

%% setup DAQ
di = daq.createSession('ni');
di.addDigitalChannel(nidaq_dev, di_chan, 'InputOnly');
ao = daq.createSession('ni');
ao.addAnalogOutputChannel(nidaq_dev, ao_chan, 'Voltage');


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

old_di_state = 0;
brightness_value = 0;

%% start the loop
try
    while 1
        
        % poll the digital input
        current_di_state = inputSingleScan(di);
       
        delta_di_state = current_di_state - old_di_state;
        old_di_state = current_di_state;
        
        % if trigger hasn't gone high, don't update
        if delta_di_state ~= 1
            % check for key-press from the user
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('escape'))
                sca;
                error('escape');
            end
            continue
        end
        
        % copy analog input to analog output
        outputSingleScan(ao, brightness_value);
        
        % calculate brightness value
        brightness_value = mod(brightness_value+1, 2);
        
        % update screen brightness
        Screen('FillRect', window, brightness_value);
        
        % display updated image
        Screen('Flip', window, [], [], 2);
        
        % check for key-press from the user
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            sca;
            error('escape');
        end
    end
    
catch ME
    
    % close upon error
    sca;
    rethrow(ME);
end
