Educated Temporal Prediction (ETP) is a robust algorithm that learns statistical features of the individual EEG and predicts the ongoing EEG phase to deliver TMS pulse in real-time.

The approach conceptualized by Ivan Alekseichuk, implemented by Sina Shirinpour.

To use:
1) Run Closed_Loop_ETP_train.m on approx. 3 min of EEG recorded before the TMS-EEG session.
2) Run Closed_Loop_ETP.m during the TMS-EEG session.

The following parameters need to be specified in the scripts:
In Closed_Loop_ETP_train.m:
1)
