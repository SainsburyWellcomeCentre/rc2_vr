% load corridor details, and use the luminance values in dot_masks to apply
% full screen for luminance measurments
screen_numbers          = [1, 3];

% file with corridor details
corridor_location       = '..\saved\virtual_corridor_mp_300_960x540_20210826.mat';

% apply gamma correction and file containing gamma information
apply_gamma_correction  = true;
gamma_correction_file   = 'gamma_table_mp_300.mat';

% luminance level to apply
level                   = 'white';  % black, grey, white
datatype                = 'float';

% load corridor
load(corridor_location, 'dot_mask', 'corridor_mask', ...
    'position', 'screenXpixels', 'screenYpixels');

load(gamma_correction_file, 'gamma_table');

% apply same value across dot mask
switch level
    case 'black'
        if strcmp(datatype, 'int')
            dot_mask(:, :, :) = min(unique(dot_mask(:)));
        else
            fill_value = 0.0161;
        end
    case 'grey'
        if strcmp(datatype, 'int')
            dot_mask(:, :, :) = median(unique(dot_mask(:)));
        else
            fill_value = 0.023;
        end
    case 'white'
        if strcmp(datatype, 'int')
            dot_mask(:, :, :) = max(unique(dot_mask(:)));
        else
            fill_value = 0.0335;
        end
end

% initialize
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);

try
    
    [window1, ~] = PsychImaging('OpenWindow', screen_numbers(1), 0);
    [window2, ~] = PsychImaging('OpenWindow', screen_numbers(2), 0);
    
    Screen('BlendFunction', window1, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('BlendFunction', window2, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    original_gamma1 = Screen('LoadNormalizedGammaTable', window1, gamma_table, 0);
    original_gamma2 = Screen('LoadNormalizedGammaTable', window2, gamma_table, 0);
    
    if strcmp(datatype, 'int')
        
        dot_texture1 = Screen('MakeTexture', window1, dot_mask(:, :, 1));
        dot_texture2 = Screen('MakeTexture', window2, dot_mask(:, :, 1));

        Screen('DrawTexture', window1, dot_texture1);
        Screen('DrawTexture', window2, dot_texture2);
        
    elseif strcmp(datatype, 'float')
        
        Screen('FillRect', window1, fill_value);
        Screen('FillRect', window2, fill_value);
        
    end
    
    Screen('Flip', window1);
    Screen('Flip', window2);
    
    while 1
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('escape'))
            error('escape');
        end
    end
catch ME
    
    sca;
    rethrow(ME);
    Screen('LoadNormalizedGammaTable', window, original_gamma, 0);
end