function [actual_phase,fullCycle] = ETP_AutoCorrect_edge(data)
% This function adjusts for the bias in the algorithm and returns the best
% fullCycle. Bias is a constant variable that is added to the typical cycle
% length.
bias = 0;
bestBias = 0;
minError = 100; % A large number to begin with
while 1
    [actual_phase,~] = ETP_Bias(data,bias);
    % Check whether the new bias value yields better results 
    if abs(mean(actual_phase)) < minError
        % If yes, set as best case and continue search
        minError = abs(mean(actual_phase));
        bestBias = bias;
    else
        % If not, already found the optimum, stop the search
        break
    end
    if mean(actual_phase) < 0
        % If generally early
        bias = bias + 1;
    elseif mean(actual_phase) > 0
        % If generally late
        bias = bias - 1;
    end
end
% Run with the best bias found and return
[actual_phase,fullCycle] = ETP_Bias(data,bestBias);
end

function [actual_phase,fullCycle] = ETP_Bias(data,bias)
% Train and validate based on the resting data and given bias adjustment
%% Parameters
targetFreq = [8 13]; % Band of interest in Hz
srate = 1000; % Sampling rate in Hz
elec_interest = [47 13 14 16 17 44 45 46 48]; % ['Electrode of interest' 'Surrounding electrodes'];
data_length_in_sec = 180;
training_length_in_sec = 90;
%% Train
edge = round(srate./(targetFreq(1)*3)); % Ignore this many samples from the end

mydata = ft_preproc_bandpassfilter(data, srate, targetFreq, [], 'fir','twopass');

if length(elec_interest) == 1
    myseq = mydata(elec_interest, 1:srate*data_length_in_sec)-mydata(64, 1:srate*data_length_in_sec);
else
    ref = mean(mydata(elec_interest(2:end), 1:srate*data_length_in_sec));
    myseq = mydata(elec_interest(1), 1:srate*data_length_in_sec)-ref;
end

alpha_phase = angle(hilbert(myseq));

locs_hi = mypeakseek(myseq(1:srate*training_length_in_sec),srate/(targetFreq(2)+3));
ipi = diff(locs_hi);

pks2 = ipi;
pks2(pks2>round(srate/6.7)) = nan; % Threshold (Not important, bias adjustes it anaway)
fullCycle = round(exp(nanmean(log(pks2))))+bias; % Typical cycle length in samples

trl_num = 255;
nexttarget = nan(1,trl_num);
delay = nan(1,trl_num);
actual_phase = nan(1,trl_num);

for i = 1:trl_num
    if length(elec_interest) == 1
        ref = data(64, srate*training_length_in_sec+i*350:srate*training_length_in_sec+i*350+(srate/2-1));
        myseq2 = data(elec_interest, srate*training_length_in_sec+i*350:srate*training_length_in_sec+i*350+(srate/2-1))-ref;
    else
        ref = mean(data(elec_interest(2:end), srate*training_length_in_sec+i*350:srate*training_length_in_sec+i*350+(srate/2-1)));
        myseq2 = data(elec_interest(1), srate*training_length_in_sec+i*350:srate*training_length_in_sec+i*350+(srate/2-1))-ref;
    end
    
    myseq2 = ft_preproc_bandpassfilter(myseq2, srate, targetFreq, [], 'brickwall','onepass');
    
    locs_hi = mypeakseek(myseq2(1:end-edge),srate/(targetFreq(2)+1));
    
    nexttarget(i) = srate*training_length_in_sec+i*350 + locs_hi(end) + fullCycle;
    actual_phase(i) = alpha_phase(nexttarget(i));
end
end