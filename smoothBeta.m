function [output] = smoothBeta (cfg, input)
if ~isfield(cfg,'feedback')
    cfg.feedback= 'no';
else end

output = input;
nTrials = size(input.trial,2);
smoothwin = input.fsample * cfg.smoothwin;

for iTrial= 1:nTrials
    output.trial{1,iTrial}=movmean(input.trial{1,iTrial},smoothwin,2);
end

if strcmp(cfg.feedback, 'yes')
    plot(input.trial{1, 1}(1,:)); hold on
    plot(output.trial{1, 1}(1,:));
    xlim ([0 1000]);
else end

end
