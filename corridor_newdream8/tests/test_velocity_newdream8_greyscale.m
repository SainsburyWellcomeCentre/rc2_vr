function test_velocity_newdream8_greyscale()

Screen('Preference', 'SkipSyncTests', 1);

%% parameters
calibration_file        = 'calibration.mat';
screen_number           = 2;

% load calibration
load(calibration_file, 'calibration');

nidaq_dev               = 'Dev1';
ai_offset               = calibration.offset;
cm_per_s_per_volts      = calibration.scale;
ai_deadband             = 0.01;  % V
max_speed               = 100;  % cm/s

ai_chan                 = 'ai0';
ao_chan                 = 'ao0';
ao_volt_white           = 5;


%% NIDAQ
% create analog input channel
ai = daq.createSession('ni');
ai.addAnalogInputChannel(nidaq_dev, ai_chan, 'Voltage');

ao = daq.createSession('ni');
ao.addAnalogOutputChannel(nidaq_dev, ao_chan, 'Voltage');


%% startup psychotoolbox
PsychDefaultSetup(2);

% open a window on chosen screen
[window, ~] = PsychImaging('OpenWindow', screen_number(1), 0);
% [window2, ~] = PsychImaging('OpenWindow', screen_number(2), 0);

ifi = Screen('GetFlipInterval', window);
% ifi2 = Screen('GetFlipInterval', window2);

% correct for gamma - just use same table for both
load('temp_gamma_table_newdream8_right_monitor.mat', 'gamma_table');
original_gamma = Screen('LoadNormalizedGammaTable', window, gamma_table, 0);
% original_gamma2 = Screen('LoadNormalizedGammaTable', window2, gamma_table, 0);

% for alpha blending (the corridor is an alpha mask)
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
% Screen('BlendFunction', window2, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

vbl = Screen('Flip', window);
% vbl2 = Screen('Flip', window2);

try
    
    %% loop
    % read analog input and display the current position
    %   compare this with the original RC.
    while true
        
        % get velocity here
        ai_volts = inputSingleScan(ai);
        
        % poll analog input == velocity
        ai_volts = (ai_volts - ai_offset);
        
        speed = 0;
        if abs(ai_volts) > ai_deadband
            speed =  cm_per_s_per_volts * ai_volts;
        end
        
        % output input on minidaq
        outputSingleScan(ao, ao_volt_white*speed/max_speed);
        
        % we want conditions to be similar to corridor so present something
        % and wait for screen to refresh
        Screen('FillRect', window, speed/max_speed);
%         Screen('FillRect', window2, speed/max_speed);
        
        % flip the screen
        vbl = Screen('Flip', window, vbl + 0.5*ifi);
%         vbl2 = Screen('Flip', window2, vbl2 + 0.5*ifi2);
        
        % check for key-press from the user
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            sca;
            error('escape');
        end
    end
    
catch ME
    
    Screen('LoadNormalizedGammaTable', window, original_gamma, 0);
%     Screen('LoadNormalizedGammaTable', window2, original_gamma2, 0);
    
    % close upon error
    sca;
    rethrow(ME);
end
