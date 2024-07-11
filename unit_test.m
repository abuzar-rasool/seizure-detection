classdef unit_test < matlab.unittest.TestCase
    
    methods(TestClassSetup)
        % Shared setup for the entire test class
    end
    
    methods(TestMethodSetup)
        % Setup for each test
    end
    
    methods(Test)
        % Test methods
        
        function testDetectSeizureFunction(testCase)
            % Constants for the test
            sampleRate = 100; % Hz
            SECONDS_FOR_DETECTION = 5;
            ROI_THRESHOLD = 3;
            POWER_RATIO_THRESHOLD = 0.01;
            MIN_SEIZURE_COUNT = 2;
            MAX_DETECTION_COUNT = 3;

            % Generate synthetic accelerometer data for testing
            t = linspace(0, 20, sampleRate * 20); % 20 seconds of data
            seizureSignal = [sin(2*pi*7*t(1:sampleRate*10))'; sin(2*pi*7*t(1:sampleRate*10))'; sin(2*pi*7*t(1:sampleRate*10))'];
            normalSignal = [sin(2*pi*1*t(sampleRate*10+1:end))'; sin(2*pi*1*t(sampleRate*10+1:end))'; sin(2*pi*1*t(sampleRate*10+1:end))'];
            accelBuffer = [seizureSignal; normalSignal];
            timeBuffer = t';

            % Dummy updateGUI function to capture status
            statuses = {};
            function updateGUI(~, ~, status)
                statuses{end+1} = status; %#ok<AGROW>
            end

            % Call the detectSeizure function multiple times to simulate real-time data processing
            numUpdates = length(t) - sampleRate * SECONDS_FOR_DETECTION + 1;
            for i = 1:numUpdates
                currentAccelBuffer = accelBuffer(1:i + sampleRate * SECONDS_FOR_DETECTION - 1, :);
                currentTimeBuffer = timeBuffer(1:i + sampleRate * SECONDS_FOR_DETECTION - 1);
                detectSeizure(currentAccelBuffer, sampleRate, @updateGUI, currentTimeBuffer, ...
                              SECONDS_FOR_DETECTION, ROI_THRESHOLD, POWER_RATIO_THRESHOLD, ...
                              MIN_SEIZURE_COUNT, MAX_DETECTION_COUNT);
            end

            % Verify that the function was called the expected number of times
            expectedNumUpdates = numUpdates;
            actualNumUpdates = length(statuses);
            
            testCase.verifyEqual(actualNumUpdates, expectedNumUpdates, ...
                sprintf('Expected %d status updates, but got %d', expectedNumUpdates, actualNumUpdates));
            
            % Verify that each status update is not empty
            for i = 1:actualNumUpdates
                testCase.verifyNotEmpty(statuses{i}, ...
                    sprintf('Status at index %d is empty.', i));
            end
        end

        function testProcessFFTAndPower(testCase)
            % Constants for the test
            sampleRate = 100; % Hz
            ROI_FREQ_RANGE = [5 10];
            
            % Generate synthetic accelerometer data for testing
            t = linspace(0, 5, sampleRate * 5); % 5 seconds of data
            accelSignal = [sin(2*pi*7*t)'; sin(2*pi*7*t)'; sin(2*pi*7*t)'];
            recentAccelBuffer = accelSignal;

            % Calculate expected values
            n = length(recentAccelBuffer);
            f = (0:n-1)*(sampleRate/n);
            f = f(1:floor(n/2)+1);
            accelMagnitude = sqrt(sum(recentAccelBuffer.^2, 2));
            accelFFT = fft(accelMagnitude);
            accelPower = abs(accelFFT/n).^2;
            accelPower = accelPower(1:floor(n/2)+1);
            roiIndices = (f >= ROI_FREQ_RANGE(1)) & (f <= ROI_FREQ_RANGE(2));
            expectedRoiPower = sum(accelPower(roiIndices));
            expectedTotalPower = sum(accelPower);
            expectedPowerRatio = expectedRoiPower / expectedTotalPower;

            % Call the processFFTAndPower function
            [roiPower, powerRatio, totalPower] = processFFTAndPower(recentAccelBuffer, sampleRate);

            % Verify the results
            testCase.verifyEqual(roiPower, expectedRoiPower, 'AbsTol', 0.01, 'ROI Power does not match expected value.');
            testCase.verifyEqual(powerRatio, expectedPowerRatio, 'AbsTol', 0.01, 'Power Ratio does not match expected value.');
            testCase.verifyEqual(totalPower, expectedTotalPower, 'AbsTol', 0.01, 'Total Power does not match expected value.');
        end
        function testCreateGUI(testCase)
            % Create a mock state manager
            stateManager = createMockStateManager();
            
            % Create the GUI
            guiHandles = createGUI(stateManager);
            
            % Verify that the GUI figure was created
            hFig = findall(0, 'Type', 'figure', 'Name', 'Seizure Detection');
            testCase.verifyNotEmpty(hFig, 'The GUI figure was not created.');
            
            % Verify that the updateGUI function handle is returned
            testCase.verifyTrue(isfield(guiHandles, 'updateGUI'), 'The updateGUI function handle is not returned.');
            testCase.verifyTrue(isa(guiHandles.updateGUI, 'function_handle'), 'The updateGUI is not a function handle.');
            
            % Verify initial status
            hTextDetectionStatus = findall(hFig, 'Style', 'text', 'String', 'No Seizure');
            testCase.verifyNotEmpty(hTextDetectionStatus, 'Initial detection status "No Seizure" not found.');
            testCase.verifyEqual(hTextDetectionStatus.BackgroundColor, [0 1 0], 'Initial detection status background color is not green.');
            
            % Simulate GUI updates and verify the changes
            updateGUI = guiHandles.updateGUI;
            timeData = 0:0.01:10; % 10 seconds of time data
            accelData = sin(2*pi*1*timeData); % Synthetic accelerometer data

            % Test for 'No Seizure' status
            updateGUI(timeData, accelData, 'No Seizure');
            testCase.verifyEqual(hTextDetectionStatus.String, 'No Seizure', 'Detection status "No Seizure" not updated correctly.');
            testCase.verifyEqual(hTextDetectionStatus.BackgroundColor, [0 1 0], 'Detection status background color is not green.');
            
            % Test for 'Warning: Possible seizure!' status
            updateGUI(timeData, accelData, 'Warning: Possible seizure!');
            testCase.verifyEqual(hTextDetectionStatus.String, 'Warning: Possible seizure!', 'Detection status "Warning: Possible seizure!" not updated correctly.');
            testCase.verifyEqual(hTextDetectionStatus.BackgroundColor, [1 1 0], 'Detection status background color is not yellow.');
            
            % Test for 'Alarm: Seizure detected!' status
            updateGUI(timeData, accelData, 'Alarm: Seizure detected!');
            testCase.verifyEqual(hTextDetectionStatus.String, 'Alarm: Seizure detected!', 'Detection status "Alarm: Seizure detected!" not updated correctly.');
            testCase.verifyEqual(hTextDetectionStatus.BackgroundColor, [1 0 0], 'Detection status background color is not red.');
        end
    end
    
end


function stateManager = createMockStateManager()
    % Create a mock state manager with start and stop methods
    stateManager = struct();
    stateManager.start = @startMock;
    stateManager.stop = @stopMock;
    
    function startMock()
        disp('State manager started.');
    end

    function stopMock()
        disp('State manager stopped.');
    end
end
