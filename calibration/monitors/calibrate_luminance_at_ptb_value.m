screen_number = 3;
intensity_val = 0.04;
apply_gamma_correction = true;
gamma_correction_file = 'temp_gamma_table_mp_300_left_monitor.mat';

load(gamma_correction_file, 'gamma_table');
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
try
    
    [window, ~] = PsychImaging('OpenWindow', screen_number, 0);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    original_gamma = Screen('LoadNormalizedGammaTable', window, gamma_table, 0);
    Screen('FillRect', window, intensity_val);
    Screen('Flip', window);
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