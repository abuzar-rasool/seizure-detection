% Clear all variables from the workspace
clear;

% Clear all functions and scripts from memory
clear functions;

% Close all figure windows
close all;

% Clear the command window
clc;

% Clear the persistent variables in all functions
clear all;

% Clear existing connections to the mobile device
clear m;

% Initialize mobile device connection
m = mobiledev;
m.AccelerationSensorEnabled = 1;
m.Logging = 1;

% Parameters
sampleRate = 16; % Sample rate in Hz
bufferSize = sampleRate * 5; % Buffer size for 5 seconds of data

% Buffers
timeBuffer = zeros(bufferSize, 1);
accelBuffer = zeros(bufferSize, 3);

% Create a StateManager instance
stateManager = StateManager();

% Create GUI and get the updateGUI function handle and state manager
guiHandles = createGUI(stateManager);
updateGUI = guiHandles.updateGUI;

% Debug message to indicate the main script is running
disp('Main script started. Waiting for start button...');

% Data storage variables
collectedTimeData = [];
collectedAccelData = [];

% Start the acquisition loop
while true
    if stateManager.isRunning
        
        % Get the latest accelerometer data
        [accelData, timeData] = accellog(m);

        if ~isempty(accelData)

            % Remove duplicate or old data
            if ~isempty(collectedTimeData)
                newIdx = find(timeData > collectedTimeData(end), 1, 'first');
                if isempty(newIdx)
                    continue;
                end
                accelData = accelData(newIdx:end, :);
                timeData = timeData(newIdx:end);
            end

            % Append new data to collected data
            collectedAccelData = [collectedAccelData; accelData];
            collectedTimeData = [collectedTimeData; timeData];

            % Append data to buffers
            accelBuffer = [accelBuffer(size(accelData, 1)+1:end, :); accelData];
            timeBuffer = [timeBuffer(length(timeData)+1:end); timeData];

            % Call the FFT and detection function
            
            detectSeizure(accelBuffer, sampleRate, updateGUI, timeBuffer);
        else
            % Debug message if no data is collected
            disp('No data collected...');
        end
    else
        
        % If acquisition has stopped, save the collected data to a file
        if ~isempty(collectedTimeData) && ~isempty(collectedAccelData)
            filename = 'accel_data.ts';
            saveDataToFile(filename, collectedTimeData, collectedAccelData, sampleRate);
            collectedTimeData = [];
            collectedAccelData = [];
        end
    end
    
    pause(0.05); % Adjust the pause duration as needed
end

% Function to save data to a file
function saveDataToFile(filename, timeData, accelData, sampleRate)
    fileID = fopen(filename, 'w');
    fprintf(fileID, 'SampleRate: %d\n', sampleRate);
    fprintf(fileID, 'Time(s)\tAccelX(m/s^2)\tAccelY(m/s^2)\tAccelZ(m/s^2)\n');
    for i = 1:length(timeData)
        fprintf(fileID, '%.6f\t%.6f\t%.6f\t%.6f\n', timeData(i), accelData(i, 1), accelData(i, 2), accelData(i, 3));
    end
    fclose(fileID);
    disp(['Data saved to ' filename]);
end
