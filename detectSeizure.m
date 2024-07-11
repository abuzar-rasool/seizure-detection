function detectSeizure(accelBuffer, sampleRate, updateGUI, timeBuffer, ...
                       SECONDS_FOR_DETECTION, ROI_THRESHOLD, POWER_RATIO_THRESHOLD, ...
                       MIN_SEIZURE_COUNT, MAX_DETECTION_COUNT)
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
    if nargin < 8, MIN_SEIZURE_COUNT = 2; end
    if nargin < 9, MAX_DETECTION_COUNT = 3; end

    % Check if buffer is empty
    if isempty(accelBuffer)
        disp('Buffer is empty, skipping detection');
        return;
    end

    % Calculate the number of samples for the given duration
    numSamples = sampleRate * SECONDS_FOR_DETECTION;
    if size(accelBuffer, 1) < numSamples
        disp('Not enough data for 5 seconds, skipping detection');
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

        % Check for seizure with hysteresis
        seizureDetected = (roiPower > ROI_THRESHOLD) && (powerRatio > POWER_RATIO_THRESHOLD);
        
        if seizureDetected
            seizureCount = seizureCount + 1;
        else
            seizureCount = 0; % reset if seizure condition is not met
        end

        % Update detection count based on seizure count
        if seizureCount >= MIN_SEIZURE_COUNT
            detectionCount = min(detectionCount + 1, MAX_DETECTION_COUNT); % Cap detectionCount to avoid overflow
        else
            detectionCount = max(0, detectionCount - 1);  % Decrease count, but not below 0
        end

        % Determine status based on detection count
        if detectionCount >= MIN_SEIZURE_COUNT  % Seizure detected for a sustained period
            status = 'Alarm: Seizure detected!';
        elseif detectionCount >= 1  % Possible seizure
            status = 'Warning: Possible seizure!';
        else
            status = 'No Seizure';
        end

        lastStatus = status;
        lastUpdateTime = recentTimeBuffer(end);
    else
        status = lastStatus;
    end

    % Update GUI with current data
    n = length(recentAccelBuffer);
    timeData = linspace(0, n/sampleRate, n);
    accelMagnitude = sqrt(sum(recentAccelBuffer.^2, 2)); % Combine 3-axis data
    updateGUI(timeData, accelMagnitude, status);
end

