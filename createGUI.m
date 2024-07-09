function guiHandles = createGUI(stateManager)
    % Create a figure for the GUI
    hFig = figure('Name', 'Seizure Detection', 'NumberTitle', 'off', ...
                  'Position', [100, 100, 1000, 700]);
              
    % Axes for time-domain data
    hAxesTime = subplot(2, 1, 1, 'Parent', hFig);
    hLineTime = plot(hAxesTime, NaN, NaN, 'Color', 'b');
    title(hAxesTime, 'Time-Domain Data');
    xlabel(hAxesTime, 'Time (s)');
    ylabel(hAxesTime, 'Acceleration (m/s^2)');



    % Detection Status - Heading and Text
    hTextDetectionHeading = uicontrol('Style', 'text', 'Parent', hFig, ...
                            'String', 'Detection Status:', ...
                            'Position', [525, 270, 200, 60], ...
                            'FontSize', 18, 'FontWeight', 'bold', ...
                            'HorizontalAlignment', 'left');

    hTextDetectionStatus = uicontrol('Style', 'text', 'Parent', hFig, ...
                            'String', 'No Seizure', ...
                            'Position', [525, 200, 250, 80], ...
                            'FontSize', 20, 'BackgroundColor', 'green', ...
                            'FontWeight', 'bold');

    % Connectivity Status - Heading and Text
    hTextConnectivityHeading = uicontrol('Style', 'text', 'Parent', hFig, ...
                            'String', 'Connectivity:', ...
                            'Position', [175, 270, 150, 60], ...
                            'FontSize', 18, ...
                            'FontWeight', 'bold', 'HorizontalAlignment', 'left');

    hTextConnectivityStatus = uicontrol('Style', 'pushbutton', 'Parent', hFig, ...
                            'String', 'Not Connected', ...
                            'Position', [175, 260, 225, 30], ...
                            'FontSize', 12, 'BackgroundColor', 'white');

    % Start button
    hButtonStart = uicontrol('Style', 'togglebutton', 'String', 'Start', ...
                             'Position', [175, 200, 100, 50], ...
                             'Callback', @startCallback);

    % Stop button
    hButtonStop = uicontrol('Style', 'togglebutton', 'String', 'Stop', ...
                            'Position', [300, 200, 100, 50], ...
                            'Callback', @stopCallback);
    
    % Update function for GUI
    function updateGUI(timeData, accelData, status)
        % Debug print to verify GUI updates
        disp('Updating GUI');
        disp(['Status: ', status]);

        set(hLineTime, 'XData', timeData, 'YData', accelData);
        
        set(hTextDetectionStatus, 'String', [status]);
        
        % Change color based on status
        if contains(status, 'Seizure detected')
            set(hLineTime, 'Color', 'r');
            set(hTextDetectionStatus, 'BackgroundColor', 'red');
        elseif contains(status, 'Warning')
            set(hLineTime, 'Color', 'y');
            set(hTextDetectionStatus, 'BackgroundColor', 'yellow');
        else
            set(hLineTime, 'Color', 'b');
            set(hTextDetectionStatus, 'BackgroundColor', 'green');
        end
        drawnow;
    end

    % Callback function for Start button
    function startCallback(~, ~)
        stateManager.start();
        set(hTextConnectivityStatus, 'String', 'Connected');
        set(hTextConnectivityStatus, 'BackgroundColor', 'green');
    end

    % Callback function for Stop button
    function stopCallback(~, ~)
        stateManager.stop();
        set(hTextConnectivityStatus, 'String', 'Not Connected');
        set(hTextConnectivityStatus, 'BackgroundColor', 'white');
    end
    
    % Return the updateGUI function handle and state manager
    guiHandles.updateGUI = @updateGUI;
end
