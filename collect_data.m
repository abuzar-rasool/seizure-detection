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
roiThreshold = 0.0020;
powerRationThreshold = 0.005;
timeInterval = 5;
sampleRate = 16;             % Sample rate in Hz
bufferSize = sampleRate * timeInterval; % Buffer size for timeInterval seconds of data
readInterval = 1/sampleRate; % Time interval between data reads
historyFile = 'history_train.csv'; % Path to the history file

% List of files to process
fileList = dir('./raw_processed_data_train/*.ts'); % List all .ts files in the directory
numFiles = length(fileList);

% Loop through each file
for fileIdx = 1:numFiles
    filename = fullfile(fileList(fileIdx).folder, fileList(fileIdx).name);
    
    % Buffers
    timeBuffer = zeros(bufferSize, 1);
    accelBuffer = zeros(bufferSize, 3);

    % Clear any persistent variables in detectSeizure function
    clear detectSeizure;

    % Create a StateManager instance
    stateManager = StateManager();

    % Create GUI and get the updateGUI function handle and state manager
    guiHandles = createGUI(stateManager);
    updateGUI = guiHandles.updateGUI;

    % Load the data from the file
    data = loadDataFromFile(filename);

    % Initialize storage for results
    roiResults = [];
    powerResults = [];
    detectionResults = [];

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
            [roiPower, powerRatio, seizureDetected] = detectSeizure(accelBuffer, sampleRate, updateGUI, timeBuffer, timeInterval, roiThreshold, powerRationThreshold, 1, 2, 1, 2);

            % Store results if valid
            if ~isnan(roiPower) && ~isnan(powerRatio)
                roiResults = [roiResults, roiPower];
                powerResults = [powerResults, powerRatio];
                detectionResults = [detectionResults, seizureDetected];
            end

            % Increment the data index
            dataIndex = dataIndex + 1;
        else
            % Debug message to confirm loop is idle
            disp('Loop is idle');

            % Small pause to prevent tight loop when not running
            pause(0.05);
        end
    end

    % Save results to history file
    saveResultsToHistoryFile(historyFile, filename, roiResults, powerResults, detectionResults);
    
    % Close the GUI for the current file
    close(guiHandles.hFigure);
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

% Function to save results to the history file
function saveResultsToHistoryFile(historyFile, filename, roiResults, powerResults, detectionResults)
    % Prepare the results in the required format
    numResults = length(roiResults);
    results = [{filename}];
    for i = 1:numResults
        results = [results, {roiResults(i)}, {powerResults(i)}, {detectionResults(i)}];
    end

    if isfile(historyFile)
        % Read existing history file
        historyData = readcell(historyFile);

        % Find the maximum number of columns in existing data and current results
        maxColumns = max(size(historyData, 2), length(results));

        % Update the existing entry or append new entry
        fileIndex = find(strcmp(historyData(:, 1), filename), 1);
        if ~isempty(fileIndex)
            % Update the existing entry
            historyData(fileIndex, 1:length(results)) = results;
        else
            % Append a new entry
            historyData = [historyData; [results, cell(1, maxColumns - length(results))]];
        end
    else
        % Create headers dynamically based on the number of results
        headers = {'File'};
        for i = 1:numResults
            headers = [headers, {['ROI_' num2str(i)]}, {['POWER_' num2str(i)]}, {['DETECTED_' num2str(i)]}];
        end
        % Create a new history file with headers
        historyData = [headers; [results, cell(1, length(headers) - length(results))]];
    end

    % Ensure all rows have the same number of columns
    numCols = size(historyData, 2);
    for i = 1:size(historyData, 1)
        historyData(i, end+1:numCols) = {NaN};
    end

    % Write updated history data to the CSV file
    writecell(historyData, historyFile);
end