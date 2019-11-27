function timing = test_nidaq_loops()
% tests duration to read analog input and digital input

%% parameters
n_loops                 = 1000;
nidaq_dev               = 'Dev1';
ai_chan                 = 'ai0';
di_chan                 = 'port0/line0';


%% DAQ
ai = daq.createSession('ni');
ai.addAnalogInputChannel(nidaq_dev, ai_chan, 'Voltage');

di = daq.createSession('ni');
di.addDigitalChannel(nidaq_dev, di_chan, 'InputOnly');


%% init
timing = nan(n_loops, 1);
tic;


%% start the loop
for i = 1 : n_loops
    
    % poll ai and di
    di_state = inputSingleScan(di);
    ai_volts = inputSingleScan(ai);
    
    % store timing
    timing(i) = toc;
end
