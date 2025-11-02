close all
clear all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%1. Step: Define basic parameters%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Simulation_area = [500 500];  % Simulation area in m 
No_nodes = 500; % Definition of number of nodes
Sim_drops = 1000;  % Definition of number of drops (for outer loop) [controls time to compute]
Max_comm_d = 10:5:100; % Definition of max. comm. distance in m (for inner loop) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2. Step: Define variables to save results%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Total_messages=zeros(19,3);
Total_hops=zeros(19,3);

% START OF OUTER LOOP (For averaging over simmulation drops)
%---------------------------------------------------
%---------------------------------------------------

for K=1:Sim_drops
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %3. Step: Randomly generate positions of each node%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Nodes_position=zeros(No_nodes,2);
    for node=1:No_nodes
        Nodes_position(node,1)=rand*Simulation_area(1,1); % x coordinates
        Nodes_position(node,2)=rand*Simulation_area(1,2); % y coordinates
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %4. Step: Select randomly one source (S) and one destination (D)%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Index_S_D=zeros(2,1); % parameter to store indexes of S and D
    Index_S_D(1,1)=ceil(rand*No_nodes); % Index of S node
    D=0;
    while D==0
        Index_S_D(2,1)=ceil(rand*No_nodes); % Index of D node
        if Index_S_D(2,1)~=Index_S_D(1,1) % Check if S and D are different   
            D=1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %5. Step: Calculation of distance between nodes%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Node_distance=zeros(No_nodes,No_nodes);
    for i=1:No_nodes
        for j=1:No_nodes
            Node_distance(i,j)=sqrt((abs(Nodes_position(i,1)-Nodes_position(j,1)))^2 + (abs(Nodes_position(i,2)-Nodes_position(j,2)))^2);
        end
    end
    
    
    % START OF INNER LOOP (Change of communication range)
    %---------------------------------------------------               
     
    for CommRange=1:19
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %6. Step: Set communication range%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Max_comm_distance = Max_comm_d(1,CommRange); % Calculation of current comm range
        
                      
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %7. Step: Flooding principles for specific communication range%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        % Basic flooding                                              %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        destReached = 0;
        nHops = 0;
        nMess = 0;
        TTL = 100;
        % get source for first hop
        sources = Index_S_D(1,1);

        while destReached ~= 1 && nHops < TTL
            % update nMess & nHops
            nHops = nHops + 1;
            nMess = nMess + length(sources);
            % reset temp_srcs for next hop
            temp_srcs = zeros(1,No_nodes);
            count = 0;  % count of valid entries in temp srcs [basically len of usable temp_srcs]
            
            % call flood_neighbors
            for iSrc=sources
                temp = flood_neighbors(Node_distance,iSrc,Max_comm_distance,No_nodes);
                n = length(temp);
                if n>0
                    temp_srcs(count+1:count+n) = temp;
                    count = count + n;
                end
            end

            temp_srcs = temp_srcs(1:count); % keepin only valid entries
                                    
            % call unique on sources (form non-duplicit vector of tx nodes)
                % if a node receives a message from 2 nodes in one hop, it only
                % transmits one message in the next hop
            sources = unique(temp_srcs, 'stable');

            % check for destination
            destReached = ismember(Index_S_D(2,1), sources);

        end
        Total_hops(CommRange,1) = Total_hops(CommRange,1) + nHops;
        Total_messages(CommRange,1) = Total_messages(CommRange,1) + nMess;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Improved flooding                                             %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        destReached = 0;
        nHops = 0;
        nMess = 0;
        TTL = 100;
        % get source for first hop
        sources = Index_S_D(1,1);
        history = sources;

        while destReached ~= 1 && nHops < TTL
            % update nMess & nHops
            nHops = nHops + 1;
            nMess = nMess + length(sources);

            % preallocate temp_srcs
            temp_srcs = zeros(1, No_nodes);
            count = 0;
            
            % call flood_neighbors
            for iSrc=sources
                temp = flood_neighbors(Node_distance,iSrc,Max_comm_distance,No_nodes);
                n = length(temp);
                if n>0
                    temp_srcs(count+1:count+n) = temp;
                    count = count + n;
                end
            end

            temp_srcs = temp_srcs(1:count); % trim to current range
                         
            % call unique on sources (form non-duplicit vector of tx nodes)
                % if a node receives a message from 2 nodes in one hop, it only
                % transmits one message in the next hop
            sources = unique(temp_srcs, 'stable');

            % update sources wrt to history (then update history)
            [sources,history] = history_check(sources,history);

            % check for destination
            destReached = ismember(Index_S_D(2,1), sources);

        end
        Total_hops(CommRange,2) = Total_hops(CommRange,2) + nHops;
        Total_messages(CommRange,2) = Total_messages(CommRange,2) + nMess;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Gossiping                                                     %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        destReached = 0;
        nHops = 0;
        nMess = 0;
        TTL = 100;
        % get source for first hop
        sources = Index_S_D(1,1);
        history = sources;

        while destReached ~= 1 && nHops < TTL
            % update nMess & nHops
            nHops = nHops + 1;
            nMess = nMess + length(sources);
            
            % preallocate temp_srcs
            temp_srcs = zeros(1, No_nodes);
            count = 0;
            
            % call flood_neighbors
            for iSrc=sources
                temp = flood_neighbors(Node_distance,iSrc,Max_comm_distance,No_nodes);
                n = length(temp);
                if n>0
                    temp_srcs(count+1:count+n) = temp;
                    count = count + n;
                end
            end

            temp_srcs = temp_srcs(1:count);
                         
            % call unique on sources (form non-duplicit vector of tx nodes)
                % if a node receives a message from 2 nodes in one hop, it only
                % transmits one message in the next hop
            sources = unique(temp_srcs, 'stable');

            % update sources wrt to history (then update history)
            [sources, history] = history_check_gossip(sources,history);

            % check for destination
            destReached = ismember(Index_S_D(2,1), history);

        end
        Total_hops(CommRange,3) = Total_hops(CommRange,3) + nHops;
        Total_messages(CommRange,3) = Total_messages(CommRange,3) + nMess;
        
    end
    
        
    
    % END of INNER LOOP
    %---------------------------------------------------
    
    K   % debug: shows simulation drop currently calculated
    
end

% END OF OUTER LOOP
%---------------------------------------------------
%---------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%8. Step: Average the results over K simulation drops%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Total_messages=Total_messages/Sim_drops;
Total_hops=Total_hops/Sim_drops;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%9. Step: Plot the results%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%


figure (1)
hold on
grid on
axis([1 19 0 ceil(max(Total_messages(:,1)))]);

set(gca, 'fontweight', 'normal', ...
    'fontsize', 14)
xlabel('Maximum communication range [m]')
ylabel('Average number of messages')
a=plot(1:19,Total_messages(1:19,1),'b>-','MarkerSize',6,'LineWidth',1);
b=plot(1:19,Total_messages(1:19,2),'r*-','MarkerSize',6,'LineWidth',1);
c=plot(1:19,Total_messages(1:19,3),'g+-','MarkerSize',6,'LineWidth',1);
set(gca,'XTick',[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19])
set(gca,'XTickLabel',{'10','15','20','25','30','35','40','45','50','55','60','65','70','75','80','85','90','95','100'})
legend([a,b,c],'Basic flooding','Improved flooding','Gossiping (p=0.5)','Location','northeast');
print('-f1', '-r300', '-dpng','Messages')

figure (2)
hold on
grid on
axis([1 19 0 ceil(max(Total_hops(:,1)))]);

set(gca, 'fontweight', 'normal', ...
    'fontsize', 14)
xlabel('Maximum communication range [m]')
ylabel('Average number of hops')
a=plot(1:19,Total_hops(1:19,1),'b>-','MarkerSize',6,'LineWidth',1);
b=plot(1:19,Total_hops(1:19,2),'r*-','MarkerSize',6,'LineWidth',1);
c=plot(1:19,Total_hops(1:19,3),'g+-','MarkerSize',6,'LineWidth',1);
set(gca,'XTick',[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19])
set(gca,'XTickLabel',{'10','15','20','25','30','35','40','45','50','55','60','65','70','75','80','85','90','95','100'})
legend([a,b,c],'Basic flooding','Improved flooding','Gossiping (p=0.5)','Location','northeast');
print('-f2', '-r300', '-dpng','Hops')


