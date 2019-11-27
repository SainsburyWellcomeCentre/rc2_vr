function test_velocity()

%% parameters
nidaq_dev               = 'Dev1';
ai_offset               = 0.511115639488569;
ai_deadband             = 0.015;
cm_per_s_per_volts      = 100/2.5;
max_pos                 = 120;


%% NIDAQ
% create analog input channel
ai = daq.createSession('ni');
ai.addAnalogInputChannel(nidaq_dev, 'ai0', 'Voltage');


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


%% initialization
pos = 0;
last_tic = tic;


%% loop
% read analog input and display the current position
%   compare this with the original RC.
while pos < max_pos
    
    % get velocity here
    ai_volts = inputSingleScan(ai);
    
    % poll analog input == velocity
    ai_volts = (ai_volts - ai_offset);
    if abs(ai_volts) > ai_deadband
        speed =  cm_per_s_per_volts * ai_volts;
        pos = pos + speed * (toc(last_tic));
    end
    last_tic = tic;
    
    % we want conditions to be similar to corridor so present something
    % and wait for screen to refresh
    Screen('FillRect', window, 0);
    Screen('Flip', window);
    
    % display
    fprintf('position: %.2f cm\n', pos);
end

fprintf('reached final position, %.2f cm\n', max_pos);
