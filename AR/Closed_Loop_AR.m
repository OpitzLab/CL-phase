function [allVec,allTs,allTs_marker,allTs_trigger] = Closed_Loop_AR()
% Closed-loop algorithm using autoregressive forward prediction and hilbert
% transform to detect the peak.
% allVec: Raw EEG (channel*sample)
% allTs: Timestamp of each sample
% allTs_marker: Timestamp of event markers
% allTs_trigger: Timestamp of the sample at which triggere was delivered
%% Parameters
TrigInt = 2; % Minimum interval between trials
fnative = 10000; % Native sampling rate
fs = 500; % Processing sampling rate
win_length = fs/2; % Window length for online processing
targetFreq = [8 13]; % Band of interest in Hz
elec_interest = [47 13 14 16 17 44 45 46 48]; % ['Electrode of interest' 'Surrounding electrodes'];
desired_phase = 0; % Targeted phase
technical_delay = 8; % Technical delay in ms
phase_tolereance = 0.1; % Phase tolerance in radians
p = 30; % AR order
edge = 32; % Number of samples to remove
ForwardSamples = 64; % Number of samples to predict
%% Initialization
trig_timer = tic; % Used for timing between triggers
adjusted_desired_phase = desired_phase-(2*pi*mean(targetFreq)*technical_delay)/1000;
downsample = floor(fnative/fs);
allVec = nan(64, 1000000);
allTs = nan(1,1000000);
chunk = zeros(fs,1);
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
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG'); 
end

result_marker = {};
while isempty(result_marker)
    result_marker = lsl_resolve_byprop(lib,'type','Markers');
end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});
inlet_marker = lsl_inlet(result_marker{1});
%%
disp('Now receiving data...');
sample = 0; % Number of samples recieved
downsample_idx = downsample; % Index used for downsampling
allTs_trigger = [];
allTs_marker = [];

while 1
    % Get data from the inlet
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
        if sample >= win_length && toc(trig_timer) > TrigInt
            if length(elec_interest) == 1
                chunk = allVec(elec_interest,sample-win_length+1:sample)-allVec(64,sample-win_length+1:sample);
            else
                ref = mean(allVec(elec_interest(2:end),sample-win_length+1:sample));
                chunk = allVec(elec_interest(1),sample-win_length+1:sample)-ref;
            end
            chunk_filt = ft_preproc_bandpassfilter(chunk, fs, targetFreq, 128, 'fir','twopass');
            coeffs = aryule(chunk_filt(edge+1:end-edge), p); % AR model (edges removed)
            coeffs = -coeffs(end:-1:2);
            nextValues = zeros(1,p+ForwardSamples);
            nextValues(1:p) = chunk_filt(end-p-edge+1:end-edge);
            for jj = 1:ForwardSamples
                nextValues(p+jj) = coeffs*nextValues(jj:p+jj-1)';
            end
            phase = angle(hilbert(nextValues(p+1:end)));
            phase_now = phase(edge);
            
            if abs(phase_now-adjusted_desired_phase) <= phase_tolereance
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