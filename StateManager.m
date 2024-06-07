classdef StateManager < handle
    properties
        isRunning = false;
    end
    methods
        function start(obj)
            obj.isRunning = true;
            disp('Start button pressed'); % Debug message
        end
        function stop(obj)
            obj.isRunning = false;
            disp('Stop button pressed'); % Debug message
        end
    end
end
