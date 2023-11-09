function [Thresh] = determineThresh(cfg, input)
if ~isfield(cfg, 'BetaThresh')
    cfg.BetaThresh = 0.75;
else end

nThresh=round(size(input,2)*(1-cfg.BetaThresh));
sorted=sort(input(:,:), 2, 'descend');
Thresh = sorted(:,nThresh);

end