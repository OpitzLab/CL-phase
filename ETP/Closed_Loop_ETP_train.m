function [allVec_rest,allTs_rest,fullCycle] = Closed_Loop_ETP_train()
% Closed-loop algorithm using ETP to train the prediction algorithm based 
% on a resting state recording to use in real time.
% allVec_rest: Resting EEG (channel*sample)
% allTs_rest: Timestamp of each sample
% fullCycle: Adjusted period based on education
%% Parameters
fnative = 10000; % Native sampling rate
fs = 1000; % Processing sampling rate
rest_length_in_sec = 180; % Resting state length in s
%% Initialization
downsample = floor(fnative/fs);
allVec_rest = nan(64, rest_length_in_sec*fs);
allTs_rest = nan(1,rest_length_in_sec*fs);
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

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result_eeg{1});
%%
disp('Now receiving data...');
sample = 0; % Number of samples recieved
downsample_idx = 10; % Index used for downsampling

while 1
    [vec,ts] = inlet.pull_sample(1);
    if isempty(vec)
        break; % End cycle if didn't receive data within certain time
    end
    if downsample_idx == downsample
        sample = sample+1;
        allVec_rest(:,sample) = vec';
        allTs_rest(:,sample) = ts;
        if mod(sample/fs,30) == 0
            disp(['time: ' num2str(sample/fs) 's']);
        end
        if sample == rest_length_in_sec*fs
            break
        end
        downsample_idx = 1;
    else
        downsample_idx = downsample_idx + 1;
    end
end

inlet.close_stream();
disp('Finished receiving');

% Calculate fullCycle
% Change desired electrode and frequency band in the next function
ft_defaults;
[estimated_phase,fullCycle] = ETP_AutoCorrect_edge(allVec_rest);
figure;
polarhistogram(estimated_phase,36);
end