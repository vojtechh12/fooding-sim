function retval = flood_neighbors(nodes_dist, src_id, comm_range, nNodes)
% FLOOD_NEIGBORS: return a vector of nodes in comm range of a given source
% node based on given nodes distances and comm range

neighbors = [];
debug = sort(nodes_dist(src_id,:));

if isempty(src_id)
    retval = [];
    return;
end


for i=1:nNodes
    if nodes_dist(src_id,i) <= comm_range && (nodes_dist(src_id,i) > 0)
        neighbors = [neighbors, i];
    end
end

retval = neighbors;
end