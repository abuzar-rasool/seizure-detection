function [roiPower, powerRatio, seizureDetected] = detectSeizure(accelBuffer, sampleRate, updateGUI, timeBuffer, ...
                       SECONDS_FOR_DETECTION, ROI_THRESHOLD, POWER_RATIO_THRESHOLD, ...
                       WARNING_THRESHOLD, ALARM_THRESHOLD, MIN_SEIZURE_COUNT, MAX_DETECTION_COUNT)
    % Persistent variables to retain values across function calls
    persistent detectionCount lastStatus lastUpdateTime seizureCount

    % Initialize persistent variables if empty
    if isempty(detectionCount), detectionCount = 0; end
    if isempty(lastStatus), lastStatus = 'No Seizure'; end
    if isempty(lastUpdateTime), lastUpdateTime = 0; end
    if isempty(seizureCount), seizureCount = 0; end

    % Set default values for constants if not provided
    if nargin < 5, SECONDS_FOR_DETECTION = 5; end
    if nargin < 6, ROI_THRESHOLD = 3; end
    if nargin < 7, POWER_RATIO_THRESHOLD = 0.01; end
    if nargin < 8, WARNING_THRESHOLD = 2; end
    if nargin < 9, ALARM_THRESHOLD = 3; end
    if nargin < 10, MIN_SEIZURE_COUNT = 2; end
    if nargin < 11, MAX_DETECTION_COUNT = 3; end

    % Check if buffer is empty
    if isempty(accelBuffer)
        disp('Buffer is empty, skipping detection');
        roiPower = NaN;
        powerRatio = NaN;
        seizureDetected = false;
        return;
    end

    % Calculate the number of samples for the given duration
    numSamples = sampleRate * SECONDS_FOR_DETECTION;
    if size(accelBuffer, 1) < numSamples
        disp('Not enough data for 5 seconds, skipping detection');
        roiPower = NaN;
        powerRatio = NaN;
        seizureDetected = false;
        return;
    end

    % Use the most recent data for GUI update
    recentAccelBuffer = accelBuffer(end-numSamples+1:end, :);
    recentTimeBuffer = timeBuffer(end-numSamples+1:end);

    % Perform FFT and power calculations every detection interval
    if recentTimeBuffer(end) - lastUpdateTime >= SECONDS_FOR_DETECTION
        [roiPower, powerRatio, totalPower] = processFFTAndPower(recentAccelBuffer, sampleRate);
        
        % Debugging information
        disp(['ROI Power: ', num2str(roiPower)]);
        disp(['Power Ratio: ', num2str(powerRatio)]);
        
        if isnan(roiPower) || isnan(powerRatio)
            disp('FFT processing returned NaN values.');
        end
        
        roiThresholdReached = roiPower > ROI_THRESHOLD;
        powerRatioThresholdReached = powerRatio > POWER_RATIO_THRESHOLD;

        disp(['ROI Threshold Reached: ', num2str(roiThresholdReached)]);
        disp(['Power Ratio Threshold Reached: ', num2str(powerRatioThresholdReached)]);

        % Check for seizure with hysteresis
        seizureDetected = roiThresholdReached && powerRatioThresholdReached;

        if seizureDetected
            seizureCount = seizureCount + 1;
        else
            seizureCount = 0; % reset if seizure condition is not met
        end

        % Update detection count based on seizure count
        if seizureCount >= MIN_SEIZURE_COUNT
            detectionCount = detectionCount + 1;
            detectionCount = min(detectionCount, MAX_DETECTION_COUNT); % Cap detectionCount to avoid overflow
        else
            detectionCount = detectionCount - 1;
            detectionCount = max(0, detectionCount);  % Decrease count, but not below 0
        end

        % Determine status based on detection count
        if detectionCount >= ALARM_THRESHOLD  % Seizure detected for a sustained period
            status = 'Alarm: Seizure detected!';
        elseif detectionCount >= WARNING_THRESHOLD  % Possible seizure
            status = 'Warning: Possible seizure!';
        else
            status = 'No Seizure';
        end

        lastStatus = status;
        lastUpdateTime = recentTimeBuffer(end);
    else
        status = lastStatus;
        roiPower = NaN; % If not enough time has passed, return NaN for outputs
        powerRatio = NaN;
        seizureDetected = false;
    end

    % Update GUI with current data, if updateGUI function handle is provided
    if ~isempty(updateGUI)
        n = length(recentAccelBuffer);
        timeData = linspace(0, n/sampleRate, n);
        accelMagnitude = sqrt(sum(recentAccelBuffer.^2, 2)); % Combine 3-axis data
        updateGUI(timeData, accelMagnitude, status);
    end
end