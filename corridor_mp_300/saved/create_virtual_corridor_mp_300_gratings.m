% parameters of the setup and virtual corridor
%   gratings are set to match the corridor as it
%   appeared on the 300Hz MG monitors

fname                       = 'virtual_corridor_mp_300_gratings_960x540_20241022.mat';

%% Initialize Psychtoolbox
Screen('Preference', 'SkipSyncTests', 1);
screenNumber = max(Screen('Screens'));
[window, windowRect] = Screen('OpenWindow', screenNumber, [0 0 0]);

%% Parameters for grating
gratingSize = 256; % Size of the grating texture
gratingFrequency = 8; % Frequency of the grating
gratingAngle = 0; % Angle in degrees
driftSpeed = 0.1; % Speed of the drift

%% Create a grating texture
[x, y] = meshgrid(linspace(-1, 1, gratingSize));
grating = sin(2 * pi * gratingFrequency * (x + y)); % Create grating
gratingTexture = Screen('MakeTexture', window, grating);

%% Corridor parameters
corridorWidth = 800; % Width of the corridor
corridorHeight = 600; % Height of the corridor
numFrames = 200; % Number of frames to display

for frame = 1:numFrames
    % Calculate the position of the grating
    offset = mod(frame * driftSpeed * 100, gratingSize);
    
    % Draw the grating texture
    Screen('DrawTexture', window, gratingTexture, [], [0 -corridorHeight/2 corridorWidth corridorHeight/2], gratingAngle, [], [], [], [], kPsychDontDoRotation);
    
    % Flip to the screen
    Screen('Flip', window);
end

%% save all other information
save(fname, '-v7.3');  