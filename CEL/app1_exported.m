classdef app1_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        InputPanel                     matlab.ui.container.Panel
        UIAxes                         matlab.ui.control.UIAxes
        SelectAudioButton              matlab.ui.control.Button
        SampleLengthEditFieldLabel     matlab.ui.control.Label
        SampleLengthEditField          matlab.ui.control.EditField
        AudioTimeEditFieldLabel        matlab.ui.control.Label
        AudioTimeEditField             matlab.ui.control.EditField
        FileSizeEditFieldLabel         matlab.ui.control.Label
        FileSizeEditField              matlab.ui.control.EditField
        RecordAudioButton              matlab.ui.control.Button
        DisplayInputDetailsButton      matlab.ui.control.Button
        OutputPanel                    matlab.ui.container.Panel
        UIAxes2                        matlab.ui.control.UIAxes
        SNRLabel                       matlab.ui.control.Label
        SNREditField                   matlab.ui.control.EditField
        PowerLabel                     matlab.ui.control.Label
        PowerEditField                 matlab.ui.control.EditField
        CompressAudioButton            matlab.ui.control.Button
        FileSizeEditField_2Label       matlab.ui.control.Label
        FileSizeEditField_2            matlab.ui.control.EditField
        CompressionRateEditFieldLabel  matlab.ui.control.Label
        CompressionRateEditField       matlab.ui.control.EditField
        DispalyOutputDetailsButton     matlab.ui.control.Button
        AudioCompressorLabel           matlab.ui.control.Label
        TextArea                       matlab.ui.control.TextArea
        MessageLabel                   matlab.ui.control.Label
    end



    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: SelectAudioButton
        function SelectAudioButtonPushed(app, event)
            [file,path] = uigetfile('*.wav');
            if isequal(file,0)
               app.TextArea.Value = 'User selected Cancel';
            else
               fileinfo = dir(file);
               SIZE = fileinfo.bytes;
               SizeIn = SIZE/1024;
               
               clear x fs 
               
               [x, fs] = audioread(file);
               N = length(x);
               t=0:1/fs:(N-1)/fs;
               
               app.TextArea.Value = 'Playing Original Signal.';
               sound(x,fs)
            
               msg = append(int2str(N/fs),' seconds');
               app.UIAxes.Visible = 'on';
               plot(app.UIAxes,t,x,'r')
                 
               app.SampleLengthEditField.Value = int2str(N);
               app.AudioTimeEditField.Value = msg;
               app.FileSizeEditField.Value = num2str(SizeIn);
               
               currString = app.TextArea.Value;
               currString{end+1} = 'Audio ready for compression.';
               app.TextArea.Value = currString;
            
               app.CompressAudioButton.Enable = 'on';
               app.DisplayInputDetailsButton.Enable = 'on';
               
               setappdata(app.SelectAudioButton,'AudioSignal',x);
               setappdata(app.SelectAudioButton,'FrequencySample',fs);
               setappdata(app.SelectAudioButton,'SampleLength',N);
               setappdata(app.SelectAudioButton,'InputFileSize',SizeIn);
               setappdata(app.SelectAudioButton,'File',file);
            end
        end


        % Button pushed function: CompressAudioButton
        function CompressAudioButtonPushed(app, event)
            app.UIAxes2.Visible = 'on';
            
            currString = app.TextArea.Value;
            currString{end+1} = 'Compressing audio...';
            app.TextArea.Value = currString;
            
            app.DispalyOutputDetailsButton.Enable = 'on';
            
            x = getappdata(app.SelectAudioButton,'AudioSignal');
            fs = getappdata(app.SelectAudioButton,'FrequencySample');
            N = getappdata(app.SelectAudioButton,'SampleLength');
            SizeIn = getappdata(app.SelectAudioButton,'InputFileSize');
            
            
            %y = dct(x) returns the unitary discrete cosine transform of input array x. The output y has the same size as x
            %x = idct(y,n) truncates the relevant dimension of y to length n before transforming
            
            blockSize = 8192;
            
            samplesHalf = blockSize/2;
            
            DataCompressed = [];
            
            for i=1:blockSize:N-blockSize
                windowDCT = dct(x(i:i+blockSize-1));
                DataCompressed(i:i+blockSize-1) = idct(windowDCT(1:samplesHalf), blockSize);
            end
            
            file = 'output.wav';
            audiowrite(file ,DataCompressed,fs)
            [y,fs] = audioread(file);
            fileinfo = dir(file);
            SIZE = fileinfo.bytes;
            SizeOut = SIZE/1024; 
            
            t=0:1/fs:(length(y)-1)/fs;
            plot(app.UIAxes2,t,y,'g')
            
            currString = app.TextArea.Value;
            currString{end+1} = 'Playing Compressed Signal.';
            app.TextArea.Value = currString;
            sound(y,fs)
            
            [SNR, noisePow] = snr(y,fs);
            compressionRate = SizeIn/SizeOut;
            
            currString = app.TextArea.Value;
            currString{end+1} = 'Audio Compressed Sucessfully!';
            app.TextArea.Value = currString;
            
            app.FileSizeEditField_2.Value = num2str(SizeOut);
            app.SNREditField.Value = num2str(SNR);
            app.PowerEditField.Value = num2str(noisePow);
            app.CompressionRateEditField.Value = num2str(compressionRate);
            
            setappdata(app.CompressAudioButton,'File',file);
            
        end

        % Button pushed function: RecordAudioButton
        function RecordAudioButtonPushed(app, event)
            app.UIAxes.Visible = 'on';
            
            fs = 44100;
            nBits= 8;
            NumChannels = 1;
            
            recObj = audiorecorder(fs,nBits,NumChannels);
            currString = app.TextArea.Value;
            currString{end+1} = 'Start Recording';
            app.TextArea.Value = currString;
            recordblocking(recObj,5);
            currString = app.TextArea.Value;
            currString{end+1} = 'Stop Recording';
            app.TextArea.Value = currString;
            
            play(recObj);
            myRec = getaudiodata(recObj);
            
            file = 'MyRec.wav';
            
            audiowrite(file,myRec,fs)
            [x, fs] = audioread(file);
            
            fileinfo = dir('MyRec.wav');
            SIZE = fileinfo.bytes;
            SizeIn = SIZE/1024;
                       
            N = length(x);
            t=0:1/fs:(N-1)/fs;
               
            msg = append(int2str(N/fs),' seconds');
            app.UIAxes.Visible = 'on';
            plot(app.UIAxes,t,x,'r')
            
            currString = app.TextArea.Value;
            currString{end+1} = 'Playing Recorded Signal.';
            app.TextArea.Value = currString;
            sound(x,fs)
            
            app.SampleLengthEditField.Value = int2str(N);
            app.AudioTimeEditField.Value = msg;
            app.FileSizeEditField.Value = num2str(SizeIn);
            
            app.CompressAudioButton.Enable = 'on';
            app.DisplayInputDetailsButton.Enable = 'on';
            
            currString = app.TextArea.Value;
            currString{end+1} = 'Audio ready for compression.';
            app.TextArea.Value = currString;
            
            setappdata(app.SelectAudioButton,'AudioSignal',x);
            setappdata(app.SelectAudioButton,'FrequencySample',fs);
            setappdata(app.SelectAudioButton,'SampleLength',N);
            setappdata(app.SelectAudioButton,'InputFileSize',SizeIn);
            setappdata(app.SelectAudioButton,'File',file);
            
        end

        % Button pushed function: DisplayInputDetailsButton
        function DisplayInputDetailsButtonPushed(app, event)
            file = getappdata(app.SelectAudioButton,'File');
            
            info = audioinfo(file);
            
            Field = fieldnames(info);
            Data = struct2cell(info);
            CStr = cell(1, numel(Field));
            
            for k = 1:numel(Field)
                if ischar(Data{k})
                    CStr{k}= sprintf('%s: %s', Field{k}, Data{k});
                elseif isnumeric(Data{k})
                    if isempty(Data{k})
                        CStr{k} = sprintf('%s: []',Field{k});
                    else 
                        CStr{k} = sprintf('%s: %s',Field{k}, num2str(Data{k}));
                    end
                else
                    CStr{k} = sprintf('%s: [%s]', Field{k}, class(Data{k}));
                end
            end
            
            app.TextArea.Value = CStr;
            
        end

        % Button pushed function: DispalyOutputDetailsButton
        function DispalyOutputDetailsButtonPushed(app, event)
            file = getappdata(app.CompressAudioButton,'File');
            
            info = audioinfo(file);
            
            Field = fieldnames(info);
            Data = struct2cell(info);
            CStr = cell(1, numel(Field));
            
            for k = 1:numel(Field)
                if ischar(Data{k})
                    CStr{k}= sprintf('%s: %s', Field{k}, Data{k});
                elseif isnumeric(Data{k})
                    if isempty(Data{k})
                        CStr{k} = sprintf('%s: []',Field{k});
                    else 
                        CStr{k} = sprintf('%s: %s',Field{k}, num2str(Data{k}));
                    end
                else
                    CStr{k} = sprintf('%s: [%s]', Field{k}, class(Data{k}));
                end
            end
            
            app.TextArea.Value = CStr;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.8706 0.9529 0.9922];
            app.UIFigure.Position = [100 100 640 708];
            app.UIFigure.Name = 'UI Figure';

            % Create InputPanel
            app.InputPanel = uipanel(app.UIFigure);
            app.InputPanel.BorderType = 'none';
            app.InputPanel.TitlePosition = 'centertop';
            app.InputPanel.Title = 'Input';
            app.InputPanel.BackgroundColor = [0.8706 0.9922 0.8784];
            app.InputPanel.FontWeight = 'bold';
            app.InputPanel.FontSize = 14;
            app.InputPanel.Position = [24 178 275 456];

            % Create UIAxes
            app.UIAxes = uiaxes(app.InputPanel);
            title(app.UIAxes, 'Original Signal')
            xlabel(app.UIAxes, 'Time')
            ylabel(app.UIAxes, 'Amplitude')
            app.UIAxes.PlotBoxAspectRatio = [1.50537634408602 1 1];
            app.UIAxes.Visible = 'off';
            app.UIAxes.Position = [11 249 253 175];

            % Create SelectAudioButton
            app.SelectAudioButton = uibutton(app.InputPanel, 'push');
            app.SelectAudioButton.ButtonPushedFcn = createCallbackFcn(app, @SelectAudioButtonPushed, true);
            app.SelectAudioButton.BackgroundColor = [0.5647 0.9333 0.5647];
            app.SelectAudioButton.FontWeight = 'bold';
            app.SelectAudioButton.Position = [11 207 254 22];
            app.SelectAudioButton.Text = 'Select Audio';

            % Create SampleLengthEditFieldLabel
            app.SampleLengthEditFieldLabel = uilabel(app.InputPanel);
            app.SampleLengthEditFieldLabel.HorizontalAlignment = 'right';
            app.SampleLengthEditFieldLabel.Position = [46 122 90 22];
            app.SampleLengthEditFieldLabel.Text = 'Sample Length:';

            % Create SampleLengthEditField
            app.SampleLengthEditField = uieditfield(app.InputPanel, 'text');
            app.SampleLengthEditField.Editable = 'off';
            app.SampleLengthEditField.Position = [151 122 100 22];

            % Create AudioTimeEditFieldLabel
            app.AudioTimeEditFieldLabel = uilabel(app.InputPanel);
            app.AudioTimeEditFieldLabel.HorizontalAlignment = 'right';
            app.AudioTimeEditFieldLabel.Position = [67 80 69 22];
            app.AudioTimeEditFieldLabel.Text = 'Audio Time:';

            % Create AudioTimeEditField
            app.AudioTimeEditField = uieditfield(app.InputPanel, 'text');
            app.AudioTimeEditField.Editable = 'off';
            app.AudioTimeEditField.Position = [151 80 100 22];

            % Create FileSizeEditFieldLabel
            app.FileSizeEditFieldLabel = uilabel(app.InputPanel);
            app.FileSizeEditFieldLabel.HorizontalAlignment = 'right';
            app.FileSizeEditFieldLabel.Position = [81 39 55 22];
            app.FileSizeEditFieldLabel.Text = 'File Size:';

            % Create FileSizeEditField
            app.FileSizeEditField = uieditfield(app.InputPanel, 'text');
            app.FileSizeEditField.Editable = 'off';
            app.FileSizeEditField.Position = [151 39 100 22];

            % Create RecordAudioButton
            app.RecordAudioButton = uibutton(app.InputPanel, 'push');
            app.RecordAudioButton.ButtonPushedFcn = createCallbackFcn(app, @RecordAudioButtonPushed, true);
            app.RecordAudioButton.BackgroundColor = [0.5647 0.9333 0.5647];
            app.RecordAudioButton.FontWeight = 'bold';
            app.RecordAudioButton.Position = [11 175 254 22];
            app.RecordAudioButton.Text = 'Record Audio';

            % Create DisplayInputDetailsButton
            app.DisplayInputDetailsButton = uibutton(app.InputPanel, 'push');
            app.DisplayInputDetailsButton.ButtonPushedFcn = createCallbackFcn(app, @DisplayInputDetailsButtonPushed, true);
            app.DisplayInputDetailsButton.BackgroundColor = [1 0.5608 0.5608];
            app.DisplayInputDetailsButton.FontWeight = 'bold';
            app.DisplayInputDetailsButton.Enable = 'off';
            app.DisplayInputDetailsButton.Position = [71 10 134 22];
            app.DisplayInputDetailsButton.Text = 'Display Input Details';

            % Create OutputPanel
            app.OutputPanel = uipanel(app.UIFigure);
            app.OutputPanel.BorderType = 'none';
            app.OutputPanel.TitlePosition = 'centertop';
            app.OutputPanel.Title = 'Output';
            app.OutputPanel.BackgroundColor = [0.8706 0.9922 0.8784];
            app.OutputPanel.FontWeight = 'bold';
            app.OutputPanel.FontSize = 14;
            app.OutputPanel.Position = [341 178 275 456];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.OutputPanel);
            title(app.UIAxes2, 'Compressed Signal')
            xlabel(app.UIAxes2, 'Time')
            ylabel(app.UIAxes2, 'Amplitude')
            app.UIAxes2.PlotBoxAspectRatio = [1.53763440860215 1 1];
            app.UIAxes2.Visible = 'off';
            app.UIAxes2.Position = [8 249 258 175];

            % Create SNRLabel
            app.SNRLabel = uilabel(app.OutputPanel);
            app.SNRLabel.HorizontalAlignment = 'right';
            app.SNRLabel.Position = [82 164 34 22];
            app.SNRLabel.Text = 'SNR:';

            % Create SNREditField
            app.SNREditField = uieditfield(app.OutputPanel, 'text');
            app.SNREditField.Editable = 'off';
            app.SNREditField.Position = [131 164 100 22];

            % Create PowerLabel
            app.PowerLabel = uilabel(app.OutputPanel);
            app.PowerLabel.HorizontalAlignment = 'right';
            app.PowerLabel.Position = [73 122 43 22];
            app.PowerLabel.Text = 'Power:';

            % Create PowerEditField
            app.PowerEditField = uieditfield(app.OutputPanel, 'text');
            app.PowerEditField.Editable = 'off';
            app.PowerEditField.Position = [131 122 100 22];

            % Create CompressAudioButton
            app.CompressAudioButton = uibutton(app.OutputPanel, 'push');
            app.CompressAudioButton.ButtonPushedFcn = createCallbackFcn(app, @CompressAudioButtonPushed, true);
            app.CompressAudioButton.BackgroundColor = [0.5647 0.9333 0.5647];
            app.CompressAudioButton.FontWeight = 'bold';
            app.CompressAudioButton.Enable = 'off';
            app.CompressAudioButton.Position = [8 206 258 22];
            app.CompressAudioButton.Text = 'Compress Audio';

            % Create FileSizeEditField_2Label
            app.FileSizeEditField_2Label = uilabel(app.OutputPanel);
            app.FileSizeEditField_2Label.HorizontalAlignment = 'right';
            app.FileSizeEditField_2Label.Position = [61 81 55 22];
            app.FileSizeEditField_2Label.Text = 'File Size:';

            % Create FileSizeEditField_2
            app.FileSizeEditField_2 = uieditfield(app.OutputPanel, 'text');
            app.FileSizeEditField_2.Editable = 'off';
            app.FileSizeEditField_2.Position = [131 81 100 22];

            % Create CompressionRateEditFieldLabel
            app.CompressionRateEditFieldLabel = uilabel(app.OutputPanel);
            app.CompressionRateEditFieldLabel.HorizontalAlignment = 'right';
            app.CompressionRateEditFieldLabel.Position = [8 39 108 22];
            app.CompressionRateEditFieldLabel.Text = 'Compression Rate:';

            % Create CompressionRateEditField
            app.CompressionRateEditField = uieditfield(app.OutputPanel, 'text');
            app.CompressionRateEditField.Editable = 'off';
            app.CompressionRateEditField.Position = [131 39 100 22];

            % Create DispalyOutputDetailsButton
            app.DispalyOutputDetailsButton = uibutton(app.OutputPanel, 'push');
            app.DispalyOutputDetailsButton.ButtonPushedFcn = createCallbackFcn(app, @DispalyOutputDetailsButtonPushed, true);
            app.DispalyOutputDetailsButton.BackgroundColor = [1 0.5608 0.5608];
            app.DispalyOutputDetailsButton.FontWeight = 'bold';
            app.DispalyOutputDetailsButton.Enable = 'off';
            app.DispalyOutputDetailsButton.Position = [67 10 144 22];
            app.DispalyOutputDetailsButton.Text = 'Dispaly Output Details';

            % Create AudioCompressorLabel
            app.AudioCompressorLabel = uilabel(app.UIFigure);
            app.AudioCompressorLabel.FontName = 'Times New Roman';
            app.AudioCompressorLabel.FontSize = 32;
            app.AudioCompressorLabel.FontWeight = 'bold';
            app.AudioCompressorLabel.Position = [187 651 266 41];
            app.AudioCompressorLabel.Text = 'Audio Compressor';

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.Editable = 'off';
            app.TextArea.Position = [24 27 592 116];

            % Create MessageLabel
            app.MessageLabel = uilabel(app.UIFigure);
            app.MessageLabel.FontWeight = 'bold';
            app.MessageLabel.Position = [24 148 63 22];
            app.MessageLabel.Text = 'Message: ';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end