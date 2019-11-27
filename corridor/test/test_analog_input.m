function ai_volts = test_analog_input()
% tests analog input

%% parameters
n_loops             = 1000;
nidaq_dev           = 'Dev1';
chan                = 'ai0';


%% DAQ
ai = daq.createSession('ni');
ai.addAnalogInputChannel(nidaq_dev, chan, 'Voltage');


%% initialize
ai_volts = nan(n_loops, 1);


%% loop
for i = 1 : n_loops
    
    % get poll analog input and print value
    ai_volts(i) = inputSingleScan(ai);
    fprintf(' %.8fV\n', ai_volts(i));
end
