function [allVec,allTs,allTs_marker,allTs_trigger] = Closed_Loop_FFT()
% Closed-loop algorithm using fft method to detect peak
% allVec: Raw EEG (channel*sample)
% allTs: Timestamp of each sample
% allTs_marker: Timestamp of event markers
% allTs_trigger: Timestamp of the sample at which triggere was delivered
%% Parameters
elec_interest = [47 13 14 16 17 44 45 46 48]; % ['Electrode of interest' 'Surrounding electrodes'];
fnative = 10000; % Native sampling rate
fs = 1000; % Processing sampling rate
TrigInt = 2; % Minimum interval between trials
win_length = fs/2; % Window length for online processing
targetFreq = [8 13]; % Band of interest in Hz
desired_phase = 0; % Targeted phase
technical_delay = 8; % Technical delay in ms
delay_tolerance = 5; % Delay tolerance in ms
%% Initialization
trig_timer = tic; % Used for timing between triggers
downsample = floor(fnative/fs);
allVec = nan(64, 100000);
allTs = nan(1,100000);
ft_defaults;
%% Initialize LPT Port
% initialize access to the inpoutx64 low-level I/O driver
config_io;
% optional step: verify that the inpoutx64 driver was successfully initialized
global cogent;
if( cogent.io.status ~= 0 )
    error('inp/outp installation failed');
end
% write a value to the LPT output port
address = hex2dec('C020');
outp(address, 0);
%% Close prieviously opened inlet streams in case it was not closed properly
try
    inlet.close_stream();
    inlet_marker.close_stream();
catch
end
%% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result_eeg = {};
while isempty(result_eeg)
    result_eeg = lsl_resolve_byprop(lib,'type','EEG');
end

result_marker = {};
while isempty(result_marker)
    result_marker = lsl_resolve_byprop(lib,'type','Markers');
end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result_eeg{1});
inlet_marker = lsl_inlet(result_marker{1});
%%
disp('Now receiving data...');
sample = 0; % Number of samples recieved
downsample_idx = 10; % Index used for downsampling
allTs_trigger = [];
allTs_marker = [];

while 1
    [vec,ts] = inlet.pull_sample(1);
    [~,ts_marker] = inlet_marker.pull_chunk();
    allTs_marker = [allTs_marker ts_marker];
    if isempty(vec)
        break; % End cycle if didn't receive data within certain time
    end
    if downsample_idx == downsample
        sample = sample+1;
        allVec(:,sample) = vec';
        allTs(:,sample) = ts;
        downsample_idx = 1;
        if sample >= win_length && toc(trig_timer) > TrigInt % Enough samples & enough time between triggers
            if length(elec_interest) == 1
                chunk = allVec(elec_interest,sample-win_length+1:sample)-allVec(64,sample-win_length+1:sample);
            else
                ref = mean(allVec(elec_interest(2:end),sample-win_length+1:sample));
                chunk = allVec(elec_interest(1),sample-win_length+1:sample)-ref;
            end
            chunk_filt = ft_preproc_bandpassfilter(chunk, fs, targetFreq, [], 'fir','twopass');
            
            Xf = fft(chunk_filt,4096);
            [~,idx] = max(abs(Xf));
            f_est = (idx-1)*fs/length(Xf); % Estimated frequecy
            phase_est = angle(Xf(idx)); % Estimated phase at the beggining of winddow
            phase = mod(2*pi*f_est*(win_length-1)/fs+phase_est,2*pi); % Current sample phase
            phase = wrapToPi(phase);
            
            if abs((desired_phase-phase)*fs/f_est/2/pi-technical_delay) <= delay_tolerance
                outp(address, 32);
                trig_timer = tic; % Reset timer after each trigger
                pause(0.015);
                outp(address, 0);
                allTs_trigger = [allTs_trigger ts];
                disp('Stim');
            end
        end
    else
        downsample_idx = downsample_idx + 1;
    end
end

inlet.close_stream();
inlet_marker.close_stream();
disp('Finished receiving');
clear cogent
disp('Closed LPT Port');
end