classdef Calibration < handle
    
    properties
        ni
        offset
        scale
        max_velocity = 1000
    end
    
    
    methods
        
        function obj = Calibration()
        %%obj = CALIBRATION()
        %   Runs calibration routines for the VR
        %
            
            obj.ni = daq.createSession('ni');
            obj.ni.addAnalogInputChannel('Dev1', 'ai0', 'Voltage');
        end
        
        
        
        function ai_offset(obj)
            
            ai_voltage = nan(100000, 1);
            count = 0;
            
            tic;
            while toc < 10
                count = count + 1;
                ai_voltage(count) = obj.ni.inputSingleScan();
            end
            ai_voltage(count+1:end) = [];
            
            
            h_fig = figure;
            plot(ai_voltage)
            xlabel('Sample point')
            ylabel('Volts')
            title('trace to average')
            
            % prompt user whether they are happy
            uans = input('Averaging this trace, press enter if happy, otherwise press N and rerun calibration:');
            
            % close the figure
            close(h_fig);
            
            % if user pressed N exit
            if strcmp(uans, 'N')
                return
            end
            
            % main teensy offset on PC... step 1 done.
            obj.offset = mean(ai_voltage);
        end
        
        
        
        function ai_scale(obj)
            
            
            % print message to user
            fprintf('Calibrating the voltage scale. Make sure the "forward_only" script is loaded on the teensy.\nAnd treadmill is unblocked.')
            input('Then move the treadmill as fast as possible within the next 10s. Press enter to start.\n');
            
            ai_voltage = nan(100000, 1);
            count = 0;
            
            tic;
            while toc < 10
                count = count + 1;
                ai_voltage(count) = obj.ni.inputSingleScan();
            end
            ai_voltage(count+1:end) = [];
            
            
            % print message to user
            fprintf('Place box over part of trace to average:\n');
            
            h_fig = figure;
            plot(ai_voltage)
            xlabel('Sample point')
            ylabel('Volts')
            
            rect = drawrectangle();
            
            uans = input('Press enter key when happy with position (press N to exit):');
            
            
            
            if strcmp(uans, 'N')
                return
            end
            
            coords = round(rect.Position);
            idx1 = round(coords(1));
            idx2 = round(idx1+coords(3));
            
            
            close(h_fig);
            
            ai_max = mean(ai_voltage(idx1:idx2));
            
            % compute the scale, in cm
            obj.scale = obj.max_velocity/(ai_max - obj.offset)/10;
            
            fprintf('Filtered teensy scale:  %.6f cm/s', obj.scale);
        end
        
        
        
        function save(obj, fname)
            
            % check that all the parameters have been filled
            valid = ~isempty(obj.offset) && ~isempty(obj.scale);
        
            % if not true then problem
            if ~valid
                error('one or more parameters have not been calibrated');
            end
            
            calibration.offset = obj.offset;
            calibration.scale = obj.scale;
            
            save(fname, 'calibration');
        end
    end
end