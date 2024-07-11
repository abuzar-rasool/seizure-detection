% Clear existing connections to the mobile device
clear m;

% Initialize mobile device connection
m = mobiledev;
m.AccelerationSensorEnabled = 1;
m.Logging = 1;

% Parameters
sampleRate = 16; % Sample rate in Hz
bufferSize = sampleRate*5; % Buffer size for 5 seconds of data

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

% Start the acquisition loop
while true
    if stateManager.isRunning
        % Debug message to confirm isRunning state
        
        % Get the latest accelerometer data
        [accelData, timeData] = accellog(m);

        if ~isempty(accelData)
            % Debug print to verify data collection
           

            % Append data to buffers
            accelBuffer = [accelBuffer(size(accelData, 1)+1:end, :); accelData];
            timeBuffer = [timeBuffer(length(timeData)+1:end); timeData];

           
            % Call the FFT and detection function
            detectSeizure(accelBuffer, sampleRate, updateGUI);
        else
            % Debug message if no data is collected
        end
    else
        % Debug message to confirm loop is idle
    end
    
    pause(0.05); % Adjust the pause duration as needed
end