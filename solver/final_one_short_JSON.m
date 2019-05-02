function flag = final_one_short_JSON(filepath, filename)
% This script solves reads an instance of SHDS problems and solves it.
% Ray Wu, WUSTL, May-July, 2018.

% remaining problems:
% 1. The format of vacuum robot is not very friendly.
% 2. The interpretations of before, at and after should be further
% clearified.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare workspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%clear;
flag = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% read the instance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
instance = loadjson(filepath);
dictionary = loadjson('C:\Users\xwa24\cse_project\SHDS_dataset-master\SHDS_dataset\inputs\DeviceDictionary.json');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% read the information of the instance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
current_house = instance.agents.h1;
current_dictionary = dictionary(current_house.houseType+1);
current_dictionary = current_dictionary{1};
num_interval = instance.horizon;
%electricity_price = instance.priceSchema;
electricity_price = [0.198,0.198,0.198,0.198,0.198,0.198,0.198,0.198,0.225,0.225,0.225,0.225,0.249,0.249,0.849,0.849,0.849,0.849,0.225,0.225,0.225,0.225,0.198,0.198];
background_load = current_house.backgroundLoad;
devices = current_house.actuators;
devices_complete = current_house.actuators;
constraints = current_house.rules;

%% derived constants
num_devices = size(devices,2);
num_constraints = size(constraints,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% initialize the problem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
schedule = optimproblem;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create optimization variables and state properties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modify the devices matrix to eliminate '.'
for i = 1:num_devices
    devices{i} = strrep(devices{i},'.','_0x2E_');
end

keySet = {'air_temp', 'dust', 'water_temp', 'battery_level_robot', 'battery_level_Tesla', 'bake', 'laundry_wash', 'laundry_dry', 'dish'};
valueSet = {0,0,0,0,0,0,0,0,0};
category_map = containers.Map(keySet,valueSet);

max_actions = 3;        % A device has at most three actions 
working_states = optimexpr(num_interval,1,max_actions,num_devices);
device_count = ones(num_devices,1);
for i = 1:num_devices
    if extractBetween(devices{i},size(convertStringsToChars(devices{i}),2)-1,size(convertStringsToChars(devices{i}),2)-1)=='_' && isstrprop(extractAfter(devices{i},size(convertStringsToChars(devices{i}),2)-1),'digit')
        devices{i} = extractBefore(devices{i},size(convertStringsToChars(devices{i}),2)-1);
    end
    
    % if there is a duplicate, add one to the count
    switch devices{i}
        case "Dyson_AM09"
            category_map('air_temp') = category_map('air_temp')+1;
        case "Bryant_697CN030B"
            category_map('air_temp') = category_map('air_temp')+1;
        case "Rheem_XE40M12ST45U1"
            category_map('water_temp') = category_map('water_temp')+1;
        case "Roomba_880"
            category_map('battery_level_robot') = category_map('battery_level_robot')+1;
            category_map('dust') = category_map('dust')+1;
        case "Tesla_S"
            category_map('battery_level_Tesla') = category_map('battery_level_Tesla')+1;
        case "GE_WSM2420D3WW_wash"
            category_map('laundry_wash') = category_map('laundry_wash')+1;
        case "GE_WSM2420D3WW_dry"
            category_map('laundry_dry') = category_map('laundry_dry')+1;
        case "Kenmore_790_0x2E_91312013"
            category_map('bake') = category_map('bake')+1;
            category_map('air_temp') = category_map('air_temp')+1;
        case "Kenmore_665_0x2E_13242K900"
            category_map('dish') = category_map('dish')+1;
        case "water_tank"
            devices{i} = "Rheem_XE40M12ST45U1";
            category_map('water_temp') = category_map('water_temp')+1;
        otherwise
            continue
    end
    
    for j = 1:size(struct2cell(current_dictionary.(devices{i}).actions),1)
        working_states(:,:,j,i) = optimvar(strcat('device_',num2str(i),'_action_',num2str(j)),num_interval,1,'Type','integer','LowerBound',0,'UpperBound',1);
    end
end

%% state properties
% common state properties
init_air_temp = randi([0,33]);

air_temp = optimexpr(num_interval,1);

% individual state properties
init_dust = randi([0,100],1,category_map('dust'));
init_water_temp = randi([10,55],1,category_map('water_temp'));
init_battery_levels = randi([0,33],1,num_devices);
init_bake = zeros(1,category_map('bake'));
init_laundry_wash = zeros(1,category_map('laundry_wash'));
init_laundry_dry = zeros(1,category_map('laundry_dry'));
init_dish = zeros(1,category_map('dish'));

dust = optimexpr(num_interval,1,category_map('dust'));
water_temp = optimexpr(num_interval,1,category_map('water_temp'));
battery_levels = optimexpr(num_interval,1,num_devices);
bake = optimexpr(num_interval,1,category_map('bake'));
laundry_wash = optimexpr(num_interval,1,category_map('laundry_wash'));
laundry_dry = optimexpr(num_interval,1,category_map('laundry_dry'));
dish = optimexpr(num_interval,1,category_map('dish'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% calculate the state properties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% air tempereature (common)
find_air_temp_actuator = 0;
count_air_temp = 0;
while count_air_temp ~= category_map('air_temp')
    for i = (find_air_temp_actuator+1):num_devices
        if devices{i} == "Dyson_AM09" || devices{i} == "Bryant_697CN030B" || devices{i} == "Kenmore_790_0x2E_91312013"
            find_air_temp_actuator = i;
            count_air_temp = count_air_temp + 1;
            break
        end
    end
    if find_air_temp_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_air_temp_actuator}).actions);
        if count_air_temp == 1
            air_temp(1) = init_air_temp;
            for j = 1:size(current_actions,1)
                air_temp(1) = air_temp(1) + working_states(1,:,j,find_air_temp_actuator) * current_actions{j}.effects{end}.delta;
                % use "end" because the effects on air temp for heater, cooler, and oven are all in the last position
            end
            for i = 2:num_interval
                air_temp(i) = air_temp(i-1);
                for j = 1:size(current_actions,1)
                    air_temp(i) = air_temp(i) + working_states(i,:,j,find_air_temp_actuator) * current_actions{j}.effects{end}.delta;
                    % use "end" because the effects on air temp for heater, cooler, and oven are all in the last position
                end
            end
        else
            for k = 1:num_interval          % for all time intervals
                for i = 1:k                 % add all effects before interval k to the expression
                    for j = 1:size(current_actions,1)
                        air_temp(k) = air_temp(k) + working_states(i,:,j,find_air_temp_actuator) * current_actions{j}.effects{end}.delta;
                        % use "end" because the effects on air temp for heater, cooler, and oven are all in the last position
                    end
                end
            end
        end
    end
end

%% floor cleanliness
find_dust_actuator = 0;
count_dust = 0;
while count_dust ~= category_map('dust')
    for i = (find_dust_actuator+1):num_devices
        if devices{i} == "Roomba_880"
            find_dust_actuator = i;
            count_dust = count_dust + 1;
            
            % determine the rank of the device
            if extractBetween(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1,size(convertStringsToChars(devices_complete{i}),2)-1)=='_' && isstrprop(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1),'digit')
                rank_dust = str2double(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1)) + 1;
            else
                rank_dust = 1;
            end
            
            break
        end
    end
    if find_dust_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_dust_actuator}).actions);
        dust(1,:,rank_dust) = init_dust(rank_dust);
        for j = 1:size(current_actions,1)-1     % -1 because the effect of the last action is incomplete
            dust(1,:,rank_dust) = dust(1,:,rank_dust) + working_states(1,:,j,find_dust_actuator) * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            dust(i,:,rank_dust) = dust(i-1,:,rank_dust);
            for j = 1:size(current_actions,1)-1     % -1 because the effect of the last action is incomplete
                dust(i,:,rank_dust) = dust(i,:,rank_dust) + working_states(i,:,j,find_dust_actuator) * current_actions{j}.effects{1}.delta;
            end
        end
    end
end

%% water temperature
find_water_temp_actuator = 0;
count_water_temp = 0;
while count_water_temp ~= category_map('water_temp')
    for i = (find_water_temp_actuator+1):num_devices
        if devices{i} == "Rheem_XE40M12ST45U1"
            find_water_temp_actuator = i;
            count_water_temp = count_water_temp + 1;
            
            % determine the rank of the device
            if extractBetween(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1,size(convertStringsToChars(devices_complete{i}),2)-1)=='_' && isstrprop(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1),'digit')
                rank_water_temp = str2double(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1)) + 1;
            else
                rank_water_temp = 1;
            end
            
            break
        end
    end
    if find_water_temp_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_water_temp_actuator}).actions);
        water_temp(1,:,rank_water_temp) = init_water_temp(rank_water_temp);
        for j = 1:size(current_actions,1)
            water_temp(1,:,rank_water_temp) = water_temp(1,:,rank_water_temp) + working_states(1,:,j,find_water_temp_actuator) * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            water_temp(i,:,rank_water_temp) = water_temp(i-1,:,rank_water_temp);
            for j = 1:size(current_actions,1)
                water_temp(i,:,rank_water_temp) = water_temp(i,:,rank_water_temp) + working_states(i,:,j,find_water_temp_actuator) * current_actions{j}.effects{1}.delta;
            end
        end
    end
end

%% battery level
% Tesla
find_battery_levels_actuator = 0;
count_battery_level_Tesla = 0;
while count_battery_level_Tesla ~= category_map('battery_level_Tesla')
    for i = (find_battery_levels_actuator+1):num_devices
        if devices{i} == "Tesla_S"
            find_battery_levels_actuator = i;
            count_battery_level_Tesla = count_battery_level_Tesla + 1;            
            break
        end
    end
    if find_battery_levels_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_battery_levels_actuator}).actions);
        battery_levels(1,:,find_battery_levels_actuator) = init_battery_levels(find_battery_levels_actuator);
        for j = 1:size(current_actions,1)
            battery_levels(1,:,find_battery_levels_actuator) = battery_levels(1,:,find_battery_levels_actuator) + working_states(1,:,j,find_battery_levels_actuator) * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            battery_levels(i,:,find_battery_levels_actuator) = battery_levels(i-1,:,find_battery_levels_actuator);
            for j = 1:size(current_actions,1)
                battery_levels(i,:,find_battery_levels_actuator) = battery_levels(i,:,find_battery_levels_actuator) + working_states(i,:,j,find_battery_levels_actuator) * current_actions{j}.effects{1}.delta;
            end
        end
    end
end

% vacuum robot
find_battery_levels_actuator = 0;
count_battery_level_robot = 0;
while count_battery_level_robot ~= category_map('battery_level_robot')
    for i = (find_battery_levels_actuator+1):num_devices
        if devices{i} == "Roomba_880"
            find_battery_levels_actuator = i;
            count_battery_level_robot = count_battery_level_robot + 1;
            break
        end
    end
    if find_battery_levels_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_battery_levels_actuator}).actions);
        battery_levels(1,:,find_battery_levels_actuator) = init_battery_levels(find_battery_levels_actuator);
        for j = 1:size(current_actions,1)
            battery_levels(1,:,find_battery_levels_actuator) = battery_levels(1,:,find_battery_levels_actuator) + working_states(1,:,j,find_battery_levels_actuator) * current_actions{j}.effects{end}.delta;
            % use "end" because the effect of the last action is incomplete
        end
        for i = 2:num_interval
            battery_levels(i,:,find_battery_levels_actuator) = battery_levels(i-1,:,find_battery_levels_actuator);
            for j = 1:size(current_actions,1)
                battery_levels(i,:,find_battery_levels_actuator) = battery_levels(i,:,find_battery_levels_actuator) + working_states(i,:,j,find_battery_levels_actuator) * current_actions{j}.effects{end}.delta;
                % use "end" because the effect of the last action is incomplete
            end
        end
    end
end

%% bake
find_bake_actuator = 0;
count_bake = 0;
while count_bake ~= category_map('bake')
    for i = (find_bake_actuator+1):num_devices
        if devices{i} == "Kenmore_790_0x2E_91312013"
            find_bake_actuator = i;
            count_bake = count_bake + 1;
            
            % determine the rank of the device
            if extractBetween(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1,size(convertStringsToChars(devices_complete{i}),2)-1)=='_' && isstrprop(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1),'digit')
                rank_bake = str2double(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1)) + 1;
            else
                rank_bake = 1;
            end
            
            break
        end
    end
    if find_bake_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_bake_actuator}).actions);
        bake(1,:,rank_bake) = init_bake(rank_bake);
        for j = 1:size(current_actions,1)
            bake(1,:,rank_bake) = bake(1,:,rank_bake) + working_states(1,:,j,find_bake_actuator) * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            bake(i,:,rank_bake) = bake(i-1,:,rank_bake);
            for j = 1:size(current_actions,1)
                bake(i,:,rank_bake) = bake(i,:,rank_bake) + working_states(i,:,j,find_bake_actuator) * current_actions{j}.effects{1}.delta;
            end
        end
    end
end

%% laundry_wash
find_laundry_wash_actuator = 0;
count_laundry_wash = 0;
while count_laundry_wash ~= category_map('laundry_wash')
    for i = (find_laundry_wash_actuator+1):num_devices
        if devices{i} == "GE_WSM2420D3WW_wash"
            find_laundry_wash_actuator = i;
            count_laundry_wash = count_laundry_wash + 1;
            
            % determine the rank of the device
            if extractBetween(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1,size(convertStringsToChars(devices_complete{i}),2)-1)=='_' && isstrprop(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1),'digit')
                rank_laundry_wash = str2double(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1)) + 1;
            else
                rank_laundry_wash = 1;
            end
            
            break
        end
    end
    if find_laundry_wash_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_laundry_wash_actuator}).actions);
        laundry_wash(1,:,rank_laundry_wash) = init_laundry_wash(rank_laundry_wash);
        for j = 1:size(current_actions,1)
            laundry_wash(1,:,rank_laundry_wash) = laundry_wash(1,:,rank_laundry_wash) + working_states(1,:,j,find_laundry_wash_actuator) * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            laundry_wash(i,:,rank_laundry_wash) = laundry_wash(i-1,:,rank_laundry_wash);
            for j = 1:size(current_actions,1)
                laundry_wash(i,:,rank_laundry_wash) = laundry_wash(i,:,rank_laundry_wash) + working_states(i,:,j,find_laundry_wash_actuator) * current_actions{j}.effects{1}.delta;
            end
        end
    end
end

%% laundry_dry
find_laundry_dry_actuator = 0;
count_laundry_dry = 0;
while count_laundry_dry ~= category_map('laundry_dry')
    for i = (find_laundry_dry_actuator+1):num_devices
        if devices{i} == "GE_WSM2420D3WW_dry"
            find_laundry_dry_actuator = i;
            count_laundry_dry = count_laundry_dry + 1;
            
            % determine the rank of the device
            if extractBetween(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1,size(convertStringsToChars(devices_complete{i}),2)-1)=='_' && isstrprop(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1),'digit')
                rank_laundry_dry = str2double(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1)) + 1;
            else
                rank_laundry_dry = 1;
            end
            
            break
        end
    end
    if find_laundry_dry_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_laundry_dry_actuator}).actions);
        laundry_dry(1,:,rank_laundry_dry) = init_laundry_dry(rank_laundry_dry);
        for j = 1:size(current_actions,1)
            laundry_dry(1,:,rank_laundry_dry) = laundry_dry(1,:,rank_laundry_dry) + working_states(1,:,j,find_laundry_dry_actuator) * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            laundry_dry(i,:,rank_laundry_dry) = laundry_dry(i-1,:,rank_laundry_dry);
            for j = 1:size(current_actions,1)
                laundry_dry(i,:,rank_laundry_dry) = laundry_dry(i,:,rank_laundry_dry) + working_states(i,:,j,find_laundry_dry_actuator) * current_actions{j}.effects{1}.delta;
            end
        end
    end
end

%% dish
find_dish_actuator = 0;
count_dish = 0;
while count_dish ~= category_map('dish')
    for i = (find_dish_actuator+1):num_devices
        if devices{i} == "Kenmore_665_0x2E_13242K900"
            find_dish_actuator = i;
            count_dish = count_dish + 1;
            
            % determine the rank of the device
            if extractBetween(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1,size(convertStringsToChars(devices_complete{i}),2)-1)=='_' && isstrprop(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1),'digit')
                rank_dish = str2double(extractAfter(devices_complete{i},size(convertStringsToChars(devices_complete{i}),2)-1)) + 1;
            else
                rank_dish = 1;
            end
            
            break
        end
    end
    if find_dish_actuator ~= 0
        current_actions = struct2cell(current_dictionary.(devices{find_dish_actuator}).actions);
        dish(1,:,rank_dish) = init_dish(rank_dish);
        for j = 1:size(current_actions,1)
            dish(1,:,rank_dish) = dish(1,:,rank_dish) + working_states(1,:,j,find_dish_actuator) * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            dish(i,:,rank_dish) = dish(i-1,:,rank_dish);
            for j = 1:size(current_actions,1)
                dish(i,:,rank_dish) = dish(i,:,rank_dish) + working_states(i,:,j,find_dish_actuator) * current_actions{j}.effects{1}.delta;
            end
        end
    end
end

%% energy consumption
energy_consumption = zeros(1,num_interval);
for i = 1:num_devices
    switch devices{i}
        case "Dyson_AM09"
        case "Bryant_697CN030B"
        case "Rheem_XE40M12ST45U1"
        case "Roomba_880"
        case "Tesla_S"
        case "GE_WSM2420D3WW_wash"
        case "GE_WSM2420D3WW_dry"
        case "Kenmore_790_0x2E_91312013"
        case "Kenmore_665_0x2E_13242K900"
        otherwise
            continue
    end
    
    current_device_actions = struct2cell(current_dictionary.(devices{i}).actions);
    for j = 1:size(struct2cell(current_dictionary.(devices{i}).actions),1)
        energy_consumption = energy_consumption + working_states(:,:,j,i)' * current_device_actions{j}.power_consumed;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create the expression for the costs and include the cost as the objective function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
schedule.Objective = (background_load + energy_consumption) * electricity_price';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analyze constraints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:num_constraints
    %% extract information from the constraints
    info = strsplit(constraints{i}," ");
    constraint_type = str2double(info(1));
    device_or_location = info(2);
    state_property = info(3);
    relation = info(4);
    goal_state = str2double(info(5));
    time_relation = "";
    goal_time = "";
    if(constraint_type==1)
        time_relation = info(6);
        goal_time = str2double(info(7));
    end

    %% form constraint by type
    % passive constraint
    if(constraint_type==0)
        % determine the rank of the device
        if extractBetween(device_or_location,size(convertStringsToChars(device_or_location),2)-1,size(convertStringsToChars(device_or_location),2)-1)=='_' && isstrprop(extractAfter(device_or_location,size(convertStringsToChars(device_or_location),2)-1),'digit')
            rank = str2double(extractAfter(device_or_location,size(convertStringsToChars(device_or_location),2)-1)) + 1;
        else
            rank = 1;
        end
        
        switch state_property
            case "charge"
                for j=1:num_devices
                    if(devices_complete{j}==device_or_location)
                        number_device = j;
                    end
                end
                current_state = battery_levels(:,:,number_device);
            case "bake"
                current_state = bake(:,:,rank);
            case "laundry_wash"
                current_state = laundry_wash(:,:,rank);
            case "laundry_dry"
                current_state = laundry_dry(:,:,rank);
            case "temperature_heat"
                current_state = air_temp;
            case "temperature_cool"
                current_state = air_temp;
            case "water_temp"
                current_state = water_temp(:,:,rank);
            case "cleanliness"
                current_state = dust(:,:,rank);
            case "dish_wash"
                current_state = dish(:,:,rank);
        end
        switch relation
            case "lt"
                current_constraint = current_state <= goal_state - 1;
            case "gt"
                current_constraint = current_state >= goal_state + 1;
            case "leq"
                current_constraint = current_state <= goal_state;
            case "geq"
                current_constraint = current_state >= goal_state;
            case "eq"
                current_constraint = current_state == goal_state;
        end
        schedule.Constraints.(strcat('passive_constraint_', num2str(i))) = current_constraint;
    % active constraint
    else
        % determine the rank of the device
        if extractBetween(device_or_location,size(convertStringsToChars(device_or_location),2)-1,size(convertStringsToChars(device_or_location),2)-1)=='_' && isstrprop(extractAfter(device_or_location,size(convertStringsToChars(device_or_location),2)-1),'digit')
            rank = str2double(extractAfter(device_or_location,size(convertStringsToChars(device_or_location),2)-1)) + 1;
        else
            rank = 1;
        end
        
        switch state_property
            case "charge"
                for j=1:num_devices
                    if(devices_complete{j}==device_or_location)
                        number_device = j;
                    end
                end
                current_state = battery_levels(:,:,number_device);
            case "bake"
                current_state = bake(:,:,rank);
            case "laundry_wash"
                current_state = laundry_wash(:,:,rank);
            case "laundry_dry"
                current_state = laundry_dry(:,:,rank);
            case "temperature_heat"
                current_state = air_temp;
            case "temperature_cool"
                current_state = air_temp;
            case "water_temp"
                current_state = water_temp(:,:,rank);
            case "cleanliness"
                current_state = dust(:,:,rank);
            case "dish_wash"
                current_state = dish(:,:,rank);
        end
        
        switch time_relation
            case "before"
                time_range = goal_time;
            case "at"
                time_range = goal_time;
            case "after"
                time_range = (goal_time+1):num_interval;
        end
        
        switch relation
            case "lt"
                %current_constraint = current_state(time_range) <= goal_state - 1;
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) <= goal_state - 1;
                    case "at"
                        current_constraint = current_state(goal_time) <= goal_state - 1;
                    case "after"
                        current_constraint = current_state(goal_time:num_interval) <= goal_state - 1;
                end
                %{
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) <= goal_state - 1;
                    case "at"
                        current_constraint = current_state(goal_time) <= goal_state - 1;
                        current_constraint_2 = current_state(1:goal_time-1) >= goal_state;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                    case "after"
                        current_constraint = current_state(num_interval) <= goal_state - 1;
                        current_constraint_2 = current_state(goal_time:num_interval-1) >= goal_state;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                end
                %}
            case "gt"
                %current_constraint = current_state(time_range) >= goal_state + 1;
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) >= goal_state + 1;
                    case "at"
                        current_constraint = current_state(goal_time) >= goal_state + 1;
                    case "after"
                        current_constraint = current_state(goal_time:num_interval) >= goal_state + 1;
                end
                %{
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) >= goal_state + 1;
                    case "at"
                        current_constraint = current_state(goal_time) >= goal_state + 1;
                        current_constraint_2 = current_state(1:goal_time-1) <= goal_state;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                    case "after"
                        current_constraint = current_state(num_interval) >= goal_state + 1;
                        current_constraint_2 = current_state(goal_time:num_interval-1) <= goal_state;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                end
                %}
            case "leq"
                %current_constraint = current_state(time_range) <= goal_state;
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) <= goal_state;
                    case "at"
                        current_constraint = current_state(goal_time) <= goal_state;
                    case "after"
                        current_constraint = current_state(goal_time:num_interval) <= goal_state;
                end
                %{
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) <= goal_state;
                    case "at"
                        current_constraint = current_state(goal_time) <= goal_state;
                        current_constraint_2 = current_state(1:goal_time-1) >= goal_state + 1;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                    case "after"
                        current_constraint = current_state(num_interval) <= goal_state;
                        current_constraint_2 = current_state(goal_time:num_interval-1) >= goal_state + 1;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                end
                %}
            case "geq"
                %current_constraint = current_state(time_range) >= goal_state;
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) >= goal_state;
                    case "at"
                        current_constraint = current_state(goal_time) >= goal_state;
                    case "after"
                        current_constraint = current_state(goal_time:num_interval) >= goal_state;
                end
                %{
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) >= goal_state;
                    case "at"
                        current_constraint = current_state(goal_time) >= goal_state;
                        current_constraint_2 = current_state(1:goal_time-1) <= goal_state - 1;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                    case "after"
                        current_constraint = current_state(num_interval) >= goal_state;
                        current_constraint_2 = current_state(goal_time:num_interval-1) <= goal_state - 1;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                end
                %}
            case "eq"
                %current_constraint = current_state(time_range) == goal_state;
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) == goal_state;
                    case "at"
                        current_constraint = current_state(goal_time) == goal_state;
                    case "after"
                        current_constraint = current_state(goal_time:num_interval) == goal_state;
                end
                %{
                switch time_relation
                    case "before"
                        current_constraint = current_state(goal_time) == goal_state;            
                    case "at"
                        current_constraint = current_state(goal_time) == goal_state;
                        current_constraint_2 = current_state(1:goal_time-1) ~= goal_state;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                    case "after"
                        current_constraint = current_state(num_interval) == goal_state;
                        current_constraint_2 = current_state(goal_time:num_interval-1) ~= goal_state;
                        schedule.Constraints.(strcat('active_constraint2_', num2str(i))) = current_constraint_2;
                end
                %}      
        end
        schedule.Constraints.(strcat('active_constraint_', num2str(i))) = current_constraint;
    end
end

%% extra constraints for not having two actions at the same time
for i = 1:num_devices
    if devices{i} ~= "room"
        schedule.Constraints.(strcat('one_action_constraint_', num2str(i))) = sum(working_states(:,:,:,i),3) == 1;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% solve the problem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[sol,fval] = solve(schedule);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% connvert solution to json format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
schedules = zeros(num_interval,1,max_actions,num_devices);
schedules_json = strings(num_devices,1);
% check if there is a solution
try
    for i = 1:num_devices
        % if the device is room
        if devices{i} == "room"
            continue
        end
        for j = 1:size(struct2cell(current_dictionary.(devices{i}).actions),1)
            schedules(:,:,j,i) = uint8(sol.(strcat('device_',num2str(i),'_action_',num2str(j))));
        end
    end
    
ts = (1:num_interval)';
bl = background_load.';
ep = electricity_price.';

for i = 1:num_devices
    schedule_table = table(ts,bl,ep);
    
    % if the device is room
    if devices{i} == "room"
        schedules_json(i) = strcat('{\n"Message":"There is no schedule for ',{' '},devices_complete{i},'"\n}');
        continue
    end
    
    % actions
    current_device_actions_table = struct2table(current_dictionary.(devices{i}).actions);

    for j = 1:size(struct2cell(current_dictionary.(devices{i}).actions),1)
        % get the name of the action
        current_action_name = current_device_actions_table.Properties.VariableNames{j};
        eval(strcat(current_action_name,' = schedules(:,:,j,i);'));
        eval(strcat(current_action_name,' = array2table(',current_action_name,');'));
        expression = strcat('schedule_table = [schedule_table',{' '},current_action_name,'];');
        expression = expression{1};
        eval(expression);
    end
    
    % calculate the energy consumption and add it to the table
    dec = zeros(num_interval,1);
    current_device_actions = struct2cell(current_dictionary.(devices{i}).actions);
    for j = 1:size(struct2cell(current_dictionary.(devices{i}).actions),1)
        dec = dec + schedules(:,:,j,i) * current_device_actions{j}.power_consumed;
    end
    dec = array2table(dec);
    schedule_table = [schedule_table dec];
    
    % calculate battery level and add charge and battery level to the table
    if devices{i} == "Tesla_S" || devices{i} == "Roomba_880"
        dc = schedules(:,:,end,i);
        dc = array2table(dc);
        schedule_table = [schedule_table dc];
        
        % calculate battery level
        dbl = zeros(num_interval,1);
        current_actions = struct2cell(current_dictionary.(devices{i}).actions);
        dbl(1) = init_battery_levels(i);
        for j = 1:size(current_actions,1)
            dbl(1) = dbl(1) + schedules(1,:,j,i) * current_actions{j}.effects{end}.delta;
        end
        for k = 2:num_interval
            dbl(k) = dbl(k-1);
            for j = 1:size(current_actions,1)
                dbl(k) = dbl(k) + schedules(k,:,j,i) * current_actions{j}.effects{end}.delta;
            end
        end
        dbl = array2table(dbl);        
        schedule_table = [schedule_table dbl];
    else
        dc = -1 * ones(num_interval,1);
        dc = array2table(dc);
        schedule_table = [schedule_table dc];
        
        dbl = -1 * ones(num_interval,1);       
        dbl = array2table(dbl);        
        schedule_table = [schedule_table dbl];
    end
    
    schedules_json(i) = jsonencode(schedule_table);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write schedule into JSON files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear the file
fileID_clear = fopen(filename,'w');
fprintf(fileID_clear,"");
fclose(fileID_clear);

% write data into it
fileID = fopen(filename,'a');
fprintf(fileID,"{");
for i = 1:num_devices
    fprintf(fileID,strcat('"',devices{i},'":'));
    fprintf(fileID,schedules_json(i));
    if i < num_devices
        fprintf(fileID,",");
    else
        fprintf(fileID,"}");
    end
end
fclose(fileID);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% connvert condition to json format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_condition_json = jsonencode(table(fval,init_air_temp,init_dust,init_water_temp,init_battery_levels,init_bake,init_laundry_wash,init_laundry_dry,init_dish));
init_condition_json = extractBetween(init_condition_json,2,size(convertStringsToChars(init_condition_json),2)-1);
init_condition_json = init_condition_json{1};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write conditions into JSON files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear the file
fileID_clear = fopen('condition.json','w');
fprintf(fileID_clear,"");
fclose(fileID_clear);

% write data into it
fileID = fopen('condition.json','a');
fprintf(fileID,init_condition_json);
fclose(fileID);

catch ME
    warning('The constraints given are infeasible, so there is no solution.');
    flag = false;
end
%{
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% connect to MySQL database
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
datasource = 'SmartHomeSchedule';
username = 'sdsp';
password = 'sdsp';
driver = '/Users/wuzihui/Desktop/mysql-connector-java-5.1.46/mysql-connector-java-5.1.46.jar';
url = 'jdbc:mysql://18.191.81.148:3306/SmartHomeSchedule';
conn = database(datasource,username,password,driver,url);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write devices into database
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colname = {'name'};
whereclauses = cell(num_devices,1);
devices_data = cell(num_devices,1);
for i = 1:num_devices
    whereclauses{i,1} = strcat('WHERE ID = ',num2str(i));
    devices_data{i,1} = devices_complete{i};
end
update(conn,'devices',colname,devices_data,whereclauses);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% write schedules into database
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
colname = {'schedule'};
whereclauses = cell(num_devices,1);
schedules_json_data = cell(num_devices,1);
for i = 1:num_devices
    whereclauses{i,1} = strcat('WHERE device_ID = ',num2str(i));
    schedules_json_data{i,1} = schedules_json(i);
end
update(conn,'schedule',colname,schedules_json_data,whereclauses);
close(conn)
%}
