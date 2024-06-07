function detectSeizure(accelBuffer, sampleRate, updateGUI)
    % Check if buffers are empty (initial call for GUI setup)
    if isempty(accelBuffer)
        disp('Buffer is empty, skipping detection');
        return;
    end

    % Debug print to verify buffer
    disp('Buffer data:');
    disp(accelBuffer);
    
    % Convert time domain to frequency domain using FFT
    n = length(accelBuffer);
    f = (0:n-1)*(sampleRate/n);
    f = f(1:n/2+1); % Frequency range for positive frequencies
    
    % Calculate FFT for each axis and sum
    accelMagnitude = sqrt(sum(accelBuffer.^2, 2)); % Combine 3-axis data
    accelFFT = fft(accelMagnitude);
    accelPower = abs(accelFFT/n).^2;
    accelPower = accelPower(1:n/2+1);
    
    % Debug print to verify FFT and power calculation
    disp('FFT Power:');
    disp(accelPower);
    
    % Define ROI frequency range
    roiFreqRange = [5 10];
    
    % Calculate power in ROI frequency range
    roiIndices = (f >= roiFreqRange(1)) & (f <= roiFreqRange(2));
    roiPower = sum(accelPower(roiIndices));
    
    % Calculate total power in the spectrum
    totalPower = sum(accelPower);
    
    % Calculate ratio
    powerRatio = roiPower / totalPower;
    
    % Adjusted thresholds for seizure detection
    roiThreshold = 0.1;  % Lowered threshold
    powerRatioThreshold = 0.05;  % Lowered threshold
    
    % Check for seizure
    status = 'Monitoring...';
    if roiPower > roiThreshold && powerRatio > powerRatioThreshold
        status = 'Seizure detected!';
        % Debug message for seizure detection
        disp('Seizure detected!');
    elseif roiPower > roiThreshold * 0.8 && powerRatio > powerRatioThreshold * 0.8
        status = 'Warning: Possible seizure!';
        % Debug message for seizure warning
        disp('Warning: Possible seizure!');
    end
    
    % Update GUI with current data
    timeData = linspace(0, n/sampleRate, n);
    updateGUI(timeData, accelMagnitude, f, accelPower, status);
end
