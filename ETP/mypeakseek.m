function locs = mypeakseek(x,minpeakdist)
% Alternative to the findpeaks function.  This thing runs much much faster.
% It really leaves findpeaks in the dust.  It also can handle ties between
% peaks.  Findpeaks just erases both in a tie.  Shame on findpeaks.
%
% x is a row vector input (generally a timecourse)
% minpeakdist is the minimum desired distance between peaks (optional, defaults to 1)
% minpeakh is the minimum height of a peak (optional)
%
% (c) 2010
% Peter O'Connor
% peter<dot>ed<dot>oconnor .AT. gmail<dot>com
%
% Modified by Sina Shirinpour (2019, shiri008<at>umn<dot>edu) for
% Shirinpour et al., Experimental Evaluation of Methods for Real-Time EEG 
% Phase-Specific Transcranial Magnetic Stimulation, 2019, bioRxiv


% Find all maxima and ties
locs=find(x(2:end-1)>=x(1:end-2) & x(2:end-1)>=x(3:end))+1;

while 1
    del = diff(locs)<minpeakdist;
    if ~any(del), break; end
    pks=x(locs);
    [garb mins] = min([pks(del) ; pks([false del])]); %#ok<ASGLU>
    deln=find(del);
    deln=[deln(mins == 1) deln(mins == 2)+1];
    locs(deln) = [];
end

end