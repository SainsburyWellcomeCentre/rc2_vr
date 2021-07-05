screen_number = 1;
intensity_val = 0.1285;
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);
try
    
    [window, ~] = PsychImaging('OpenWindow', screen_number, 0);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
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
end