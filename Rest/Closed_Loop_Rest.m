function [allVec_rest,allTs_rest] = Closed_Loop_Rest()
% Record resting state EEG 
% allVec_rest: Resting EEG (channel*sample)
% allTs_rest: Timestamp of each sample
%% Parameters
fnative = 10000; % Native sampling rate
fs = 1000; % Processing sampling rate
%% Initialization
downsample = floor(fnative/fs);
allVec_rest = nan(64, 100000);
allTs_rest = nan(1,100000);
%% Close prieviously opened inlet streams in case it was not closed properly
try
    inlet.close_stream();
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
        downsample_idx = 1;
    else
        downsample_idx = downsample_idx + 1;
    end
end

inlet.close_stream();
disp('Finished receiving');
end