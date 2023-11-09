clc;  close all; warning off all; clearvars;



% preparation
fileScript = matlab.desktop.editor.getActiveFilename;
[pathProject,name,ext] = fileparts(fileScript) ;                % path to working directory/current folder                                % path to working directory/main folder
addpath (pathProject)
addpath ([pathProject '/kinematics'])
pathData = ([pathProject '/data']);
FilesToLoad = {'Spiral_patxx.mat', 'Spiral_model.mat', 'Spiral_HC.mat'}

cd (pathData)

iFile=1;    % 1 = Spiral_patxx.mat, 2 = Spiral_model.mat, 3 = Spiral_HC.mat
load (FilesToLoad{iFile})

%% filter (4th order LP 10Hz butterworth)
fc = 10;
fs = 100;
fordbutter = 4;
[b,a] = butter(fordbutter,fc/(fs/2));
x = filter (b,a, x);
y = filter (b,a, y);



%% calculate velocity, gauss filter
dt = t(2)-t(1);
vTan = tangvelocity([x,y], 2);
vTan = vTan/dt;                    % get correct units (cm/s)

% set start and end of movement
vTan = vTan(Sstart:Send);
t = t(Sstart:Send);
t = t-t(1);


% set to 0/0
x = x(Sstart:Send);
y = y(Sstart:Send);
x = x-x(1);
y = y-y(1);



%% calculate average tangential velocity
distance = sum(abs(vTan))/fs;
vTan_avg = distance/t(end);



%% radius-angle-transform, RMSE, Slope
pos=find(x>0);
neg = find (x<0);
xBin(pos)=1;
xBin(neg)=-1;

posTransitions = (find (diff(xBin)>0)+1)';
nFullLoops = size (posTransitions,1)-1;
[theta,rho] = cart2pol(x,y);
transition1 = posTransitions(2);
transitionLast = posTransitions(end);

theta_glm = unwrap(theta);
theta_glm = theta_glm/-pi;  % to clockwise (pi rad)
theta1 = theta_glm(transition1);
thetaLast=  theta_glm(transitionLast);

rho_glm = rho;
mdl = fitlm(theta_glm(transition1:end),rho_glm(transition1:end));  % rho ~ 1 + theta   --> excluding first loop
RMSE_glm = mdl.RMSE;
Slope_glm = table2array(mdl.Coefficients (2,1));
residuals(1:size(vTan,1)) = nan;
residuals(transition1:end)= mdl.Residuals.Raw;



%% slope of the velocity signal around burst
if iFile ==1
    load ("LFP_patxx_beta_rect_smooth.mat")

    cfg= [];
    cfg.BetaThresh = BetaThresh;
    Thresh=determineThresh(cfg, BetaEnvelope);

    input = LFP_draw_beta_rect_smooth;
    cfg.thresh = Thresh;
    Features_draw_cl = betaBurstFeatures(cfg, input);

    iTrial = 3;
    BurstWindow = 0.25;
    normalise = 1;
    NWindow = BurstWindow*100*2+1;
    lenVec = 1+2*(BurstWindow*100);
    halfVec = (lenVec-1)/2;
    nBursts = Features_draw_cl.withinTrialBurstDescriptives{1, iTrial}.nBursts;

    BurstOnsets = Features_draw_cl.singleBurstCharacteristics{1, iTrial}.start;
    BurstOnsetsSpiral = round(BurstOnsets/2);

    for iBurst = 1:nBursts
        vTan_aligned = nan(1,NWindow);
        residuals_aligned = nan(1,NWindow);
        samplePreBurst = BurstOnsetsSpiral(iBurst)-(BurstWindow*100);
        samplePostBurst = BurstOnsetsSpiral(iBurst)+(BurstWindow*100);

        skip_slope = 0;
        if samplePreBurst < 1
            skip_slope = 1;
        end

        if samplePostBurst > size(vTan,1)
            skip_slope = 2;
        end

        BDuration = [];
        BAmplitude = [];
        if skip_slope == 0
            vTan_aligned      = vTan(samplePreBurst:samplePostBurst)';
            residuals_aligned = residuals(samplePreBurst:samplePostBurst);

            if normalise == 1
                vTan_aligned = vTan_aligned-vTan_aligned(1,1+halfVec);
                try     % residuals only calculated after the first full loop
                    residuals_aligned =  residuals_aligned-residuals_aligned(1,1+halfVec);
                catch
                    disp 'residuals only calculated after the first full loop'
                end
            end

            vTan_BurstOnsets(iTrial,iBurst,1:NWindow)      = vTan_aligned;
            residuals_BurstOnsets(iTrial,iBurst,1:NWindow) = residuals_aligned;

            % vTan
            slopePre_onset(iTrial,iBurst)  = (vTan_aligned(halfVec+1)-vTan_aligned(1)) / halfVec;                  %   slope = (y2-y1)/(x2-x1)
            slopePost_onset(iTrial,iBurst) = (vTan_aligned(lenVec)-vTan_aligned(halfVec+1)) / halfVec;

            slope_pre(iTrial,iBurst)   = slopePre_onset(iTrial,iBurst);
            slope_post(iTrial,iBurst)  = slopePost_onset(iTrial,iBurst);
            slope_delta(iTrial,iBurst) = slope_post(iTrial,iBurst) - slope_pre(iTrial,iBurst);

            % residual
            slopePre_residuals_onset(iTrial,iBurst)  = (residuals_aligned(halfVec+1)-residuals_aligned(1)) / halfVec;                  %   slope = (y2-y1)/(x2-x1)
            slopePost_residuals_onset(iTrial,iBurst) = (residuals_aligned(lenVec)-residuals_aligned(halfVec+1)) / halfVec;

            slope_residuals_pre(iTrial,iBurst)   = slopePre_residuals_onset(iTrial,iBurst);
            slope_residuals_post(iTrial,iBurst)  = slopePost_residuals_onset(iTrial,iBurst);
            slope_residuals_delta(iTrial,iBurst) = slope_residuals_post(iTrial,iBurst) - slope_residuals_pre(iTrial,iBurst);
        end
    end
else
end




%% plot spiral, vTan, radius-angle-transform
% plot spiral
subplot(2,2,1)
plot(x,y) ;
xlim ([-6 6])
ylim ([-6 6])
axis square
xlabel ('pos x (cm)')
ylabel ('pos y (cm)')

% plot tangential velocity
subplot(2,2,2)
plot(t,vTan)
title ({'tangential velocity', ...
    ['average velocity = ', num2str(vTan_avg), ' cm/s' ], ...
    });
xlabel ('time (seconds)')
ylabel ('vTan (cm/s)')

% plot radius-angle-transform, glm, optimal spiral
subplot(224);
hold on;
plot(mdl,...
    'color',[0 0 0], 'Markersize', 1);
title ({'radius-angle-transform:', ...
    ['RMSE (glm) = ', num2str(RMSE_glm) ], ...
    ['Slope (glm) = ', num2str(Slope_glm) ], ...
    });
xlabel ('angle (pi radians)');
ylabel ('radius (cm)');
hold off

cd (pathProject)






