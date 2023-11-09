clc;  close all; warning off all; clearvars;



% preparation
fileScript = matlab.desktop.editor.getActiveFilename;
[pathProject,name,ext] = fileparts(fileScript) ;                % path to working directory/current folder
addpath (pathProject);
pathData = ([pathProject '/data']);
pathFT = ([pathProject '/fieldtrip-20220310']);

BetaThresh = 0.75;                                                              % burst definition at 75% percentile of amplitude according to Tinkhauser et al. 2020 Jneurosci
betafreq = 19;


cd (pathData)
load('LFP_patxx.mat')


%% calculate beta bursts
% first filter around beta, rectify, and smooth if fieldtrip is in the project folder
% if fieldtrip cannot be found, scip this and load the preprocessed data

if exist(pathFT, 'dir')
    addpath (pathFT)
    ft_defaults;
    % beta-envelope
    % filter
    cfg = [];
    cfg.bpfilter = 'yes';
    cfg.bpfreq = [betafreq-2 betafreq+2];
    cfg.bpfiltord = 2;
    cfg.channel = {'LFP_cl'};
    LFP_beta = ft_preprocessing(cfg, dataLFP_Sbj);

    % rectify
    cfg = [];
    cfg.rectify = 'yes';
    LFP_beta_rect = ft_preprocessing(cfg, LFP_beta);

    % smooth
    cfg = [];
    cfg.smoothwin = 0.2;                                                                                     % size of moving window in seconds
    LFP_beta_rect_smooth = smoothBeta(cfg, LFP_beta_rect);




    %% extract base and draw intervals
    Toilims = [];
    Toilims(:,1:2) = [cell2mat(info_Sbj.timesBaseOn)' cell2mat(info_Sbj.timesBaseOff)'];
    Toilims(:,3:4) = [cell2mat(info_Sbj.timesDrawOn)' cell2mat(info_Sbj.timesDrawOff)'];


    Thresh = [];
    beta_thresh = [];
    beta_base = [];
    LFP_base_beta_rect_smooth =[];
    LFP_draw_beta_rect_smooth =[];

    cfg= [];
    cfg.toilim = [Toilims(:,1:2)]
    LFP_base_beta_rect_smooth = ft_redefinetrial(cfg, LFP_beta_rect_smooth);       % base
    LFP_base = ft_redefinetrial(cfg, dataLFP_Sbj);

    cfg.toilim = [Toilims(:,3:4)]
    LFP_draw_beta_rect_smooth = ft_redefinetrial(cfg, LFP_beta_rect_smooth);       % draw
    LFP_draw = ft_redefinetrial(cfg, dataLFP_Sbj);



    nTrials = size(LFP_base_beta_rect_smooth.trial,2);
    idxCL=1;
    nSamplePerTrial=size(LFP_base_beta_rect_smooth.trial{1,1},2);
    BetaEnvelope(1:nTrials*nSamplePerTrial)=0;
    for iTrial=1:nTrials
        sampleInfo(iTrial,:)=[(iTrial*nSamplePerTrial)-(nSamplePerTrial-1) iTrial*nSamplePerTrial];
        BetaEnvelope(1,sampleInfo(iTrial,1):sampleInfo(iTrial,2))=LFP_base_beta_rect_smooth.trial{1, iTrial} (idxCL,:);
    end




    %% Frequency analysis
    for iTrial = 1:8
        cfg = [];
        cfg.trials = iTrial
        data_base = ft_redefinetrial(cfg,  LFP_base);
        data_draw = ft_redefinetrial(cfg,  LFP_draw);


        cfg = [];
        cfg.length = 1;
        dataLFP_base_1s = ft_redefinetrial(cfg,  data_base);
        dataLFP_draw_1s = ft_redefinetrial(cfg,  data_draw);

        cfg = [];
        cfg.output  = 'pow';
        cfg.channel = 'all';
        cfg.method  = 'mtmfft';
        cfg.taper   = 'dpss';
        cfg.tapsmofrq = 2;
        cfg.foi     = 1:1:100;
        freq_base = ft_freqanalysis(cfg, dataLFP_base_1s);
        freq_draw = ft_freqanalysis(cfg, dataLFP_draw_1s);

        pow_rest(iTrial,:) = freq_base.powspctrm(1,:);
        pow_draw(iTrial,:) = freq_draw.powspctrm(1,:);

    end


else % if fieldtrip is not available this loads the preprocessed data from the steps before
    disp ('fieldtrip not available...')
    disp ('loading already preprocessed data')
    load ('LFP_patxx_beta_rect_smooth.mat')
end


% determine threshold during rest
cfg= [];
cfg.BetaThresh = BetaThresh;
Thresh=determineThresh(cfg, BetaEnvelope);



% get burst features rest
cfg = [];
input = LFP_base_beta_rect_smooth;
cfg.thresh = Thresh;
BurstFeatures_base = betaBurstFeatures(cfg, input);

% get burst features draw
cfg = [];
input = LFP_draw_beta_rect_smooth;
cfg.thresh = Thresh;
BurstFeatures_draw = betaBurstFeatures(cfg, input);




% plot trials
figure
for iTrial = 1:8
    subplot(2,4,iTrial)
    ThreshVec = [];
    BetaEnvelopeTrial = [];
    time = [];

    BetaEnvelopeTrial = LFP_draw_beta_rect_smooth.trial{1, iTrial};
    nSamples = size(BetaEnvelopeTrial,2);
    time = 0:0.005:(0.005*nSamples)-0.005;  %LFP_draw_beta_rect_smooth.time{1, iTrial};
    ThreshVec(1:nSamples) = Thresh;
    plot(time,BetaEnvelopeTrial,'k'); hold on
    plot(time,ThreshVec,'r')

    legend ({'beta amplitude signal'; 'threshold'})
    xlabel ('time(s)')
    ylabel ('amplitude')
    title ({'beta burst determination' ...
        ['number of bursts: ' num2str(BurstFeatures_draw.withinTrialBurstDescriptives{1, iTrial}.nBursts)] ...
        ['average burst amplitude: ' num2str(BurstFeatures_draw.withinTrialBurstDescriptives{1, iTrial}.meanAmpBurst)] ...
        ['average burst duration: ' num2str(BurstFeatures_draw.withinTrialBurstDescriptives{1, iTrial}.meanDurationBurst)] ...
        })
    hold off

end




% plot Powerspectrum
pow_restMean = mean(pow_rest,1);
pow_drawMean = mean(pow_draw,1);

figure
plot(freq_base.freq(12:35), pow_restMean(12:35)); hold on
plot(freq_base.freq(12:35),pow_drawMean(12:35));
title ('Spectral power')
xlabel ('Frequency (Hz)')
ylabel ('absolute Power (uV²)')
legend ({'rest' 'draw'})

cd (pathProject)





