function detectSeizure(accelBuffer, sampleRate, updateGUI)
    persistent detectionCount lastStatus lastUpdateTime
    if isempty(detectionCount), detectionCount = 0; end
    if isempty(lastStatus), lastStatus = 'No Seizure'; end
    if isempty(lastUpdateTime), lastUpdateTime = 0; end

    % Check if buffer is empty
    if isempty(accelBuffer)
        disp('Buffer is empty, skipping detection');
        return;
    end

    % Get the number of samples corresponding to the last 5 seconds
    numSamples = sampleRate * 5;
    if size(accelBuffer, 1) < numSamples
        disp('Not enough data for 5 seconds, skipping detection');
        return;
    end

    % Use the most recent 5 seconds of data for GUI update
    recentAccelBuffer = accelBuffer(end-numSamples+1:end, :);

    % Perform FFT and power calculations every 5 seconds
    currentTime = toc;
    if currentTime - lastUpdateTime >= 5
        [roiPower, powerRatio, totalPower] = processFFTAndPower(recentAccelBuffer, sampleRate);

        % Print debugging information
        disp(['ROI Power: ', num2str(roiPower)]);
        disp(['Power Ratio: ', num2str(powerRatio)]);

        % Thresholds (adjust these based on testing)
        roiThreshold = 15;
        powerRatioThreshold = 0.01;

        % Check for seizure with hysteresis
        seizureDetected = (roiPower > roiThreshold) && (powerRatio > powerRatioThreshold);
        persistent seizureCount
        if isempty(seizureCount), seizureCount = 0; end
        
        if seizureDetected
            seizureCount = seizureCount + 1;
        else
            seizureCount = 0; % reset if seizure condition is not met
        end

        % Update detection count based on seizure count
        if seizureCount >= 2
            detectionCount = min(detectionCount + 1, 3); % Cap detectionCount to avoid overflow
        else
            detectionCount = max(0, detectionCount - 1);  % Decrease count, but not below 0
        end

        % Determine status based on detection count
        if detectionCount >= 2  % Seizure detected for a sustained period
            status = 'Alarm: Seizure detected!';
        elseif detectionCount >= 1  % Possible seizure
            status = 'Warning: Possible seizure!';
        else
            status = 'No Seizure';
        end

        lastStatus = status;
        lastUpdateTime = currentTime;
    else
        status = lastStatus;
    end

    % Update GUI with current data
    n = length(recentAccelBuffer);
    timeData = linspace(0, n/sampleRate, n);
    accelMagnitude = sqrt(sum(recentAccelBuffer.^2, 2)); % Combine 3-axis data
    updateGUI(timeData, accelMagnitude, status);
end

function [roiPower, powerRatio, totalPower] = processFFTAndPower(recentAccelBuffer, sampleRate)
    % Convert time domain to frequency domain using FFT
    n = length(recentAccelBuffer);
    f = (0:n-1)*(sampleRate/n);
    f = f(1:floor(n/2)+1); % Frequency range for positive frequencies

    % Calculate FFT for each axis and sum
    accelMagnitude = sqrt(sum(recentAccelBuffer.^2, 2)); % Combine 3-axis data
    accelFFT = fft(accelMagnitude);
    accelPower = abs(accelFFT/n).^2;
    accelPower = accelPower(1:floor(n/2)+1);

    % Define ROI frequency range
    roiFreqRange = [5 10];

    % Calculate power in ROI frequency range
    roiIndices = (f >= roiFreqRange(1)) & (f <= roiFreqRange(2));
    roiPower = sum(accelPower(roiIndices));

    % Calculate total power in the spectrum
    totalPower = sum(accelPower);

    % Calculate ratio
    powerRatio = roiPower / totalPower;
end