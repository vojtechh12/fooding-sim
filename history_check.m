function [newSources,newHistory] = history_check(srcs, history)
%HISTORY_CHECK goes through a sources[] vector and only keeps the nodes
%that had not trasnmitted this message in the past
%   - returns: 
%               sources (unique wrt history)
%               history (updated with the new sources)

    mask = ~ismember(srcs, history);
    newSources = srcs(mask);
    newHistory = [history, newSources];
end