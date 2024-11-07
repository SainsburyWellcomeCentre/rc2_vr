nidaq_dev               = 'Dev1';
di_chan_toggle          = 'port0/line0';
di_chan_gain            = 'port0/line1';

di = daq.createSession('ni');
di.addDigitalChannel(nidaq_dev, di_chan_toggle, 'InputOnly');
di.addDigitalChannel(nidaq_dev, di_chan_gain, 'InputOnly');

try
    while 1
        di_state = inputSingleScan(di);
        disp(di_state(2));
    end
catch ME
    rethrow(ME)
end