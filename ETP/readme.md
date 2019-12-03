# Educated Temporal Prediction (ETP)
Educated Temporal Prediction (ETP) is a robust algorithm that learns statistical features of the individual EEG and predicts the ongoing EEG phase to deliver TMS pulse in real-time.

The code conceptualized by Ivan Alekseichuk, implemented by Sina Shirinpour.

## Use
1) Run "[allVec_rest,allTs_rest,fullCycle] = Closed_Loop_ETP_train();" to record three minutes of resting EEG and train the algorithm. The fullCycle constant is the tranined parameter. 
2) Run "[allVec,allTs,allTs_marker,allTs_trigger] = Closed_Loop_ETP(fullCycle);" to use fullCycle to deliver TMS pulse in real-time based on EEG phase.

## Parameters
The following parameters need to be specified in the scripts, depending on the hardware, desired brain region, and the band of interest:

#### In ETP_AutoCorrect_edge.m
- targetFreq = [Bounds of the band of interest in Hz];
- srate = Sampling rate in Hz;
- elec_interest = ['Electrode of interest' 'Surrounding electrodes'];

#### In Closed_Loop_ETP.m
- targetFreq = [Bounds of the band of interest in Hz];
- elec_interest = ['Electrode of interest' 'Surrounding electrodes'];
- fnative = Acquisition sampling rate;
- fs = processing sampling rate;
- TrigInt = minimum interval between trials in seconds;
- technical_delay = technical delay in ms;

**Note: Make sure the corresponding parameters in the Closed_Loop_ETP.m are the same as in ETP_AutoCorrect_edge.m.**
