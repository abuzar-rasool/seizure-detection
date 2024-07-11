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

% Constants
filename = 'data_seizure2_detect_false.ts';  % Path to the data file
sampleRate = 16;             % Sample rate in Hz
bufferSize = sampleRate * 5; % Buffer size for 5 seconds of data
readInterval = 1/sampleRate; % Time interval between data reads

% Buffers
timeBuffer = zeros(bufferSize, 1);
accelBuffer = zeros(bufferSize, 3);

% Create a StateManager instance
stateManager = StateManager();

% Create GUI and get the updateGUI function handle and state manager
guiHandles = createGUI(stateManager);
updateGUI = guiHandles.updateGUI;

% Load the data from the file
data = loadDataFromFile(filename);


% Start the acquisition loop
dataIndex = 1;
numSamples = length(data.time);

while dataIndex <= numSamples
    if stateManager.isRunning

        % Simulate real-time delay for each data point
        pause(readInterval);

        % Get the current data point
        timeData = data.time(dataIndex);
        accelData = data.accel(dataIndex, :);

        % Append new data to buffers
        accelBuffer = [accelBuffer(2:end, :); accelData];
        timeBuffer = [timeBuffer(2:end); timeData];

        % Call the FFT and detection function
        detectSeizure(accelBuffer, sampleRate, updateGUI,timeBuffer);

        % Increment the data index
        dataIndex = dataIndex + 1;
    else
        % Debug message to confirm loop is idle
        
        % Small pause to prevent tight loop when not running
        pause(0.05);
    end
end

% Function to load data from a file
function data = loadDataFromFile(filename)
    fileID = fopen(filename, 'r');
    header = fgetl(fileID); % Skip the first line (SampleRate)
    header = fgetl(fileID); % Skip the second line (column headers)

    dataArray = textscan(fileID, '%f %f %f %f', 'Delimiter', '\t');
    fclose(fileID);

    data.time = dataArray{1};
    data.accel = [dataArray{2}, dataArray{3}, dataArray{4}];
end
