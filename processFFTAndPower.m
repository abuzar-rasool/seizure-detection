function [roiPower, powerRatio, totalPower] = processFFTAndPower(recentAccelBuffer, sampleRate)
    % Define constants
    ROI_FREQ_RANGE = [5 10];

    % Convert time domain to frequency domain using FFT
    n = length(recentAccelBuffer);
    f = (0:n-1)*(sampleRate/n);
    f = f(1:floor(n/2)+1); % Frequency range for positive frequencies

    % Calculate FFT for each axis and sum
    accelMagnitude = sqrt(sum(recentAccelBuffer.^2, 2)); % Combine 3-axis data
    accelFFT = fft(accelMagnitude);
    accelPower = abs(accelFFT/n).^2;
    accelPower = accelPower(1:floor(n/2)+1);

    % Calculate power in ROI frequency range
    roiIndices = (f >= ROI_FREQ_RANGE(1)) & (f <= ROI_FREQ_RANGE(2));
    roiPower = sum(accelPower(roiIndices));

    % Calculate total power in the spectrum
    totalPower = sum(accelPower);

    % Calculate power ratio
    powerRatio = roiPower / totalPower;
end