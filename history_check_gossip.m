function [newSources, newHistory] = history_check_gossip(srcs, history)
% HISTORY_CHECK_GOSSIP filters out nodes already in history,
% applies gossiping probability p, and updates the history list.
%   - returns: 
%               sources (unique wrt history)
%               history (updated with the new sources probabilistically)

if isempty(srcs)
    newSources = [];
    newHistory = history;
    return
end

% Step 1: keep only nodes that are not in history
mask_new = ~ismember(srcs, history);
srcs_new = srcs(mask_new);

% Step 2: apply gossiping probability p
p = 0.5; % gossip probability
mask_prob = rand(size(srcs_new)) < p;
newSources = srcs_new(mask_prob);

% Step 3: update history
newHistory = unique([history, srcs_new], 'stable'); % all nodes that have received the message
end