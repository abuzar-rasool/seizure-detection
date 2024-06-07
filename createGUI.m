function guiHandles = createGUI(stateManager)
    % Create a figure for the GUI
    hFig = figure('Name', 'Seizure Detection', 'NumberTitle', 'off', ...
                  'Position', [100, 100, 1000, 700]);
              
    % Axes for time-domain data
    hAxesTime = subplot(3, 1, 1, 'Parent', hFig);
    hLineTime = plot(hAxesTime, NaN, NaN, 'Color', 'b');
    title(hAxesTime, 'Time-Domain Data');
    xlabel(hAxesTime, 'Time (s)');
    ylabel(hAxesTime, 'Acceleration (m/s^2)');
    
    % Axes for frequency-domain data
    hAxesFreq = subplot(3, 1, 2, 'Parent', hFig);
    hLineFreq = plot(hAxesFreq, NaN, NaN, 'Color', 'b');
    title(hAxesFreq, 'Frequency-Domain Data');
    xlabel(hAxesFreq, 'Frequency (Hz)');
    ylabel(hAxesFreq, 'Power');
    ylim(hAxesFreq, [0 10]); % Initial limit
    
    % Text for warnings and alarms
    hTextStatus = uicontrol('Style', 'text', 'Parent', hFig, ...
                            'String', 'Status: Monitoring...', ...
                            'Position', [450, 20, 200, 30], ...
                            'FontSize', 12, 'BackgroundColor', 'white');

    % Start button
    hButtonStart = uicontrol('Style', 'pushbutton', 'String', 'Start', ...
                             'Position', [100, 20, 100, 30], ...
                             'Callback', @startCallback);

    % Stop button
    hButtonStop = uicontrol('Style', 'pushbutton', 'String', 'Stop', ...
                            'Position', [250, 20, 100, 30], ...
                            'Callback', @stopCallback);
    
    % Update function for GUI
    function updateGUI(timeData, accelData, f, powerData, status)
        % Debug print to verify GUI updates
        disp('Updating GUI');
        disp(['Status: ', status]);

        set(hLineTime, 'XData', timeData, 'YData', accelData);
        set(hLineFreq, 'XData', f, 'YData', powerData);
        
        % Adjust y-axis limit based on max power
        maxPower = max(powerData);
        ylim(hAxesFreq, [0 max(maxPower * 1.1, 10)]);
        
        set(hTextStatus, 'String', ['Status: ', status]);
        
        % Change color based on status
        if contains(status, 'Seizure detected')
            set(hLineTime, 'Color', 'r');
            set(hLineFreq, 'Color', 'r');
            set(hTextStatus, 'BackgroundColor', 'red');
        elseif contains(status, 'Warning')
            set(hLineTime, 'Color', 'y');
            set(hLineFreq, 'Color', 'y');
            set(hTextStatus, 'BackgroundColor', 'yellow');
        else
            set(hLineTime, 'Color', 'b');
            set(hLineFreq, 'Color', 'b');
            set(hTextStatus, 'BackgroundColor', 'white');
        end
        drawnow;
    end

    % Callback function for Start button
    function startCallback(~, ~)
        stateManager.start();
        set(hTextStatus, 'String', 'Status: Monitoring...');
        set(hTextStatus, 'BackgroundColor', 'white');
    end

    % Callback function for Stop button
    function stopCallback(~, ~)
        stateManager.stop();
        set(hTextStatus, 'String', 'Status: Stopped');
        set(hTextStatus, 'BackgroundColor', 'white');
    end
    
    % Return the updateGUI function handle and state manager
    guiHandles.updateGUI = @updateGUI;
end
