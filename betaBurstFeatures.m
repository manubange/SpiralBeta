function output = betaBurstFeatures(cfg, input)
%if ~isfield(cfg,'channel'); cfg.channel = input.label(1) ; end
if isfield(cfg,'iTrial'); 
    trials = cfg.iTrial;
else trials = 1: size(input.trial,2);
end

fs = input.fsample;
idxChan=find(strcmp(input.label, 'LFP_cl'));
thresh = cfg.thresh;


for iTrial=trials
    data = [];
    transitions = [];
    vector = [];
    SbjBetaBursts=[];
    data = input.trial{1,iTrial} (idxChan,:);
    nSamples = size(data,2);
    
    
    samples_overThresh=find(data>thresh);
    
    betabursts_binarised{1,iTrial} (idxChan,1:nSamples) = 0;
    betabursts_binarised{1,iTrial} (idxChan,samples_overThresh) = 1;
    
    vector =  betabursts_binarised{1,iTrial}(idxChan,:);
    transitions(2:nSamples)=vector(2:end)-vector(1:end-1);
    
    
    % get indices of burst onsets
    if vector(1,1)==1
        SbjBetaBursts.start(1,1)=1;
        SbjBetaBursts.start = [SbjBetaBursts.start find(transitions==1)];
    else
        SbjBetaBursts.start = [find(transitions==1)];
    end
    
    
    % get indices of end of bursts
    SbjBetaBursts.end(1,:)=find(transitions==-1);
    if vector(1,end)==1
        SbjBetaBursts.end= [SbjBetaBursts.end find(vector == 1,1, 'last')];
    else end
    
    % duration
    SbjBetaBursts.duration_samples(1,:) = SbjBetaBursts.end-SbjBetaBursts.start;
    SbjBetaBursts.duration_time(1,:) = SbjBetaBursts.duration_samples/fs;
    
    % remove bursts shorter 100ms
    idx_tooShortBursts=find (SbjBetaBursts.duration_time <0.1);   % in s
    
    SbjBetaBursts.start(idx_tooShortBursts) = [];
    SbjBetaBursts.end(idx_tooShortBursts) = [];
    SbjBetaBursts.duration_samples(idx_tooShortBursts) = [];
    SbjBetaBursts.duration_time(idx_tooShortBursts) = [];
    
    
    nBursts = size(SbjBetaBursts.start,2);
    BurstsPerSecond = nBursts/(size(vector,2)/fs);
    for iBurst=1:nBursts
        try  SbjBetaBursts.amplitude(1,iBurst)=max(data (SbjBetaBursts.start(1,iBurst):SbjBetaBursts.end(1,iBurst)));
        catch
            disp ('.');
        end
    end
    
    if nBursts~=0
        output.withinTrialBurstDescriptives{1,iTrial}.nBursts = nBursts;
        output.withinTrialBurstDescriptives{1,iTrial}.nSamples = size(vector,2);
        output.withinTrialBurstDescriptives{1,iTrial}.meanAmpBurst = mean(SbjBetaBursts.amplitude);
        output.withinTrialBurstDescriptives{1,iTrial}.meanDurationBurst = mean(SbjBetaBursts.duration_time);
        output.withinTrialBurstDescriptives{1,iTrial}.BurstsPerSecond = BurstsPerSecond;
        output.singleBurstCharacteristics{1,iTrial} = SbjBetaBursts;
    else
        output.withinTrialBurstDescriptives{1,iTrial}.nBursts = nBursts;
        output.withinTrialBurstDescriptives{1,iTrial}.nSamples = size(vector,2);
        output.withinTrialBurstDescriptives{1,iTrial}.meanAmpBurst = nan;
        output.withinTrialBurstDescriptives{1,iTrial}.meanDurationBurst = nan;
        output.withinTrialBurstDescriptives{1,iTrial}.BurstsPerSecond = 0;
        SbjBetaBursts.start(idx_tooShortBursts) = nan;
        SbjBetaBursts.end(idx_tooShortBursts) = nan;
        SbjBetaBursts.duration_samples(idx_tooShortBursts) = nan;
        SbjBetaBursts.duration_time(idx_tooShortBursts) =nan;
        output.singleBurstCharacteristics{1,iTrial} = SbjBetaBursts;
    end
    
end
end

