% Parameters
sampleRate = 13; % Sample rate in Hz
bufferSize = 2; % Buffer size for 5 seconds of data

% Buffers
timeBuffer = zeros(bufferSize, 1);
accelBuffer = zeros(bufferSize, 3);

% Load dataset
[data, labels, metadata] = parseEpilepsyDataset('Epilepsy_TRAIN.ts');

% Create a StateManager instance
stateManager = StateManager();

% Create GUI and get the updateGUI function handle and state manager
guiHandles = createGUI(stateManager);
updateGUI = guiHandles.updateGUI;

% Debug message to indicate the main script is running
disp('Main script started. Waiting for start button...');

% Start the acquisition loop
currentIndex = 1;
while true
    if stateManager.isRunning
        % Debug message to confirm isRunning state
        disp('Data acquisition running...');
        
        % Simulate real-time data acquisition from the dataset
        if currentIndex <= length(data)
            % Get the next chunk of data
            accelData = data{currentIndex};
            % Ensure accelData has 3 columns
            if size(accelData, 2) ~= 3
                accelData = reshape(accelData, [], 3);
            end
            timeData = (0:size(accelData, 1)-1)' / sampleRate;
            
            % Debug print to verify data collection
            disp('Data collected:');
            disp(accelData);

            % Append data to buffers
            accelBuffer = [accelBuffer(size(accelData, 1)+1:end, :); accelData];
            timeBuffer = [timeBuffer(length(timeData)+1:end); timeData];

            % Call the FFT and detection function
            detectSeizure(accelBuffer, sampleRate, updateGUI);

            % Move to the next data segment
            currentIndex = currentIndex + 1;
        else
            % No more data to process
            disp('End of dataset reached');
            break;
        end
    else
        % Debug message to confirm loop is idle
        disp('Data acquisition paused');
    end
    
    pause(0.05); % Adjust the pause duration as needed
end

function [data, labels, metadata] = parseEpilepsyDataset(filename)
    % Open the file
    fid = fopen(filename, 'r');
    
    % Read and parse the metadata
    metadata = struct();
    while true
        line = fgetl(fid);
        if startsWith(line, '@')
            if contains(line, 'problemName')
                metadata.problemName = extractAfter(line, ' ');
            elseif contains(line, 'timeStamps')
                metadata.timeStamps = contains(line, 'true');
            elseif contains(line, 'missing')
                metadata.missing = contains(line, 'true');
            elseif contains(line, 'univariate')
                metadata.univariate = contains(line, 'true');
            elseif contains(line, 'dimensions')
                metadata.dimensions = str2double(extractAfter(line, ' '));
            elseif contains(line, 'equalLength')
                metadata.equalLength = contains(line, 'true');
            elseif contains(line, 'seriesLength')
                metadata.seriesLength = str2double(extractAfter(line, ' '));
            elseif contains(line, 'classLabel')
                metadata.classLabel = split(extractAfter(line, ' '));
            elseif contains(line, '@data')
                break;
            end
        end
    end
    
    % Read and parse the data
    data = {};
    labels = {};
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line)
            parts = split(line, ':');
            series = cellfun(@(x) str2double(split(x, ',')), parts(1:end-1), 'UniformOutput', false);
            label = parts{end};
            data{end+1} = cell2mat(series);
            labels{end+1} = label;
        end
    end
    
    % Close the file
    fclose(fid);
end