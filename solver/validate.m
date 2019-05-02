function [result, flag] = validate(filepath)
% This script reads a schedule and determines, first, whether it is a
% feasible schedule and, second, whethre it is an optimal one.
% Ray Wu, WUSTL, May-July, 2018.

% Variables that need to be passes to Jenn:
% 1. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare workspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% read the instance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cd matconvnet-1.0-beta25%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%input_schedule = struct2cell(loadjson('C:\Users\xwa24\cse_project\solver\schedule.json'));
input_schedule = struct2cell(loadjson(filepath));
input_condition = loadjson('C:\Users\xwa24\cse_project\solver\condition.json');
instance = loadjson('C:\Users\xwa24\cse_project\SHDS_dataset-master\SHDS_dataset\datasets\instance_DM_a7_c1.json');
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
%% read the information of the initial conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
optimal_cost = input_condition.fval;
init_air_temp = input_condition.init_air_temp;
init_dust = input_condition.init_dust;
init_water_temp = input_condition.init_water_temp;
init_battery_levels = input_condition.init_battery_levels;
init_bake = input_condition.init_bake;
init_laundry_wash = input_condition.init_laundry_wash;
init_laundry_dry = input_condition.init_laundry_dry;
init_dish = input_condition.init_dish;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% define variables and state properties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modify the devices matrix to eliminate '.'
for i = 1:num_devices
    devices{i} = strrep(devices{i},'.','_0x2E_');
end

keySet = {'air_temp', 'dust', 'water_temp', 'battery_level_robot', 'battery_level_Tesla', 'bake', 'laundry_wash', 'laundry_dry', 'dish'};
valueSet = {0,0,0,0,0,0,0,0,0};
category_map = containers.Map(keySet,valueSet);

max_actions = 3;        % A device has at most three actions 
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
end

air_temp = zeros(num_interval,1);
dust = zeros(num_interval,1);
water_temp = zeros(num_interval,1,category_map('water_temp'));
battery_levels = zeros(num_interval,1,num_devices);
bake = zeros(num_interval,1,category_map('bake'));
laundry_wash = zeros(num_interval,1,category_map('laundry_wash'));
laundry_dry = zeros(num_interval,1,category_map('laundry_dry'));
dish = zeros(num_interval,1,category_map('dish'));

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
            % new
            air_temp_schedule = struct2cell(input_schedule{find_air_temp_actuator}{1});
            % new
            for j = 1:size(current_actions,1)
                air_temp(1) = air_temp(1) + air_temp_schedule{j+3} * current_actions{j}.effects{end}.delta;
                % use "end" because the effects on air temp for heater, cooler, and oven are all in the last position
            end
            for i = 2:num_interval
                air_temp(i) = air_temp(i-1);
                % new
                air_temp_schedule = struct2cell(input_schedule{find_air_temp_actuator}{i});
                % new
                for j = 1:size(current_actions,1)
                   air_temp(i) = air_temp(i) + air_temp_schedule{j+3} * current_actions{j}.effects{end}.delta;
                    % use "end" because the effects on air temp for heater, cooler, and oven are all in the last position
                end
            end
        else
            for k = 1:num_interval          % for all time intervals
                for i = 1:k                 % add all effects before interval k to the expression
                    % new
                    air_temp_schedule = struct2cell(input_schedule{find_air_temp_actuator}{i});
                    % new
                    for j = 1:size(current_actions,1)
                        air_temp(k) = air_temp(k) + air_temp_schedule{j+3} * current_actions{j}.effects{end}.delta;
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
        % new
        dust_schedule = struct2cell(input_schedule{find_dust_actuator}{1});
        % new
        for j = 1:size(current_actions,1)-1     % -1 because the effect of the last action is incomplete
            dust(1,:,rank_dust) = dust(1,:,rank_dust) + dust_schedule{j+3} * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            dust(i,:,rank_dust) = dust(i-1,:,rank_dust);
            % new
            dust_schedule = struct2cell(input_schedule{find_dust_actuator}{i});
            % new
            for j = 1:size(current_actions,1)-1     % -1 because the effect of the last action is incomplete
                dust(i,:,rank_dust) = dust(i,:,rank_dust) + dust_schedule{j+3} * current_actions{j}.effects{1}.delta;
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
        % new
        water_temp_schedule = struct2cell(input_schedule{find_water_temp_actuator}{1});
        % new
        for j = 1:size(current_actions,1)
            water_temp(1,:,rank_water_temp) = water_temp(1,:,rank_water_temp) + water_temp_schedule{j+3} * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            water_temp(i,:,rank_water_temp) = water_temp(i-1,:,rank_water_temp);
            % new
            water_temp_schedule = struct2cell(input_schedule{find_water_temp_actuator}{i});
            % new
            for j = 1:size(current_actions,1)
                water_temp(i,:,rank_water_temp) = water_temp(i,:,rank_water_temp) + water_temp_schedule{j+3} * current_actions{j}.effects{1}.delta;
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
        % new
        battery_levels_schedule = struct2cell(input_schedule{find_battery_levels_actuator}{1});
        % new
        for j = 1:size(current_actions,1)
            battery_levels(1,:,find_battery_levels_actuator) = battery_levels(1,:,find_battery_levels_actuator) + battery_levels_schedule{j+3} * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            battery_levels(i,:,find_battery_levels_actuator) = battery_levels(i-1,:,find_battery_levels_actuator);
            % new
            battery_levels_schedule = struct2cell(input_schedule{find_battery_levels_actuator}{i});
            % new
            for j = 1:size(current_actions,1)
                battery_levels(i,:,find_battery_levels_actuator) = battery_levels(i,:,find_battery_levels_actuator) + battery_levels_schedule{j+3} * current_actions{j}.effects{1}.delta;
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
        % new
        battery_levels_schedule = struct2cell(input_schedule{find_battery_levels_actuator}{1});
        % new
        for j = 1:size(current_actions,1)
            battery_levels(1,:,find_battery_levels_actuator) = battery_levels(1,:,find_battery_levels_actuator) + battery_levels_schedule{j+3} * current_actions{j}.effects{end}.delta;
            % use "end" because the effect of the last action is incomplete
        end
        for i = 2:num_interval
            battery_levels(i,:,find_battery_levels_actuator) = battery_levels(i-1,:,find_battery_levels_actuator);
            % new
            battery_levels_schedule = struct2cell(input_schedule{find_battery_levels_actuator}{i});
            % new
            for j = 1:size(current_actions,1)
                battery_levels(i,:,find_battery_levels_actuator) = battery_levels(i,:,find_battery_levels_actuator) + battery_levels_schedule{j+3} * current_actions{j}.effects{end}.delta;
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
        % new
        bake_schedule = struct2cell(input_schedule{find_bake_actuator}{1});
        % new
        for j = 1:size(current_actions,1)
            bake(1,:,rank_bake) = bake(1,:,rank_bake) + bake_schedule{j+3} * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            bake(i,:,rank_bake) = bake(i-1,:,rank_bake);
            % new
            bake_schedule = struct2cell(input_schedule{find_bake_actuator}{i});
            % new
            for j = 1:size(current_actions,1)
                bake(i,:,rank_bake) = bake(i,:,rank_bake) + bake_schedule{j+3} * current_actions{j}.effects{1}.delta;
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
        % new
        laundry_wash_schedule = struct2cell(input_schedule{find_laundry_wash_actuator}{1});
        % new
        for j = 1:size(current_actions,1)
            laundry_wash(1,:,rank_laundry_wash) = laundry_wash(1,:,rank_laundry_wash) + laundry_wash_schedule{j+3} * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            laundry_wash(i,:,rank_laundry_wash) = laundry_wash(i-1,:,rank_laundry_wash);
            % new
        laundry_wash_schedule = struct2cell(input_schedule{find_laundry_wash_actuator}{i});
        % new
            for j = 1:size(current_actions,1)
                laundry_wash(i,:,rank_laundry_wash) = laundry_wash(i,:,rank_laundry_wash) + laundry_wash_schedule{j+3} * current_actions{j}.effects{1}.delta;
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
        % new
        laundry_dry_schedule = struct2cell(input_schedule{find_laundry_dry_actuator}{1});
        % new
        for j = 1:size(current_actions,1)
            laundry_dry(1,:,rank_laundry_dry) = laundry_dry(1,:,rank_laundry_dry) + laundry_dry_schedule{j+3} * current_actions{j}.effects{1}.delta;
        end
        for i = 2:num_interval
            laundry_dry(i,:,rank_laundry_dry) = laundry_dry(i-1,:,rank_laundry_dry);
            % new
            laundry_dry_schedule = struct2cell(input_schedule{find_laundry_dry_actuator}{i});
            % new
            for j = 1:size(current_actions,1)
                laundry_dry(i,:,rank_laundry_dry) = laundry_dry(i,:,rank_laundry_dry) + laundry_dry_schedule{j+3} * current_actions{j}.effects{1}.delta;
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
        % new
        dish_schedule = struct2cell(input_schedule{find_dish_actuator}{1});
        % new
        for j = 1:size(current_actions,1)
            dish(1,:,rank_dish) = dish(1,:,rank_dish) + dish_schedule{j+3} * current_actions{j}.effects{1}.delta;
            % use "j+3" because the actions start from the 4th position
        end
        for i = 2:num_interval
            dish(i,:,rank_dish) = dish(i-1,:,rank_dish);
            % new
            dish_schedule = struct2cell(input_schedule{find_dish_actuator}{i});
            % new
            for j = 1:size(current_actions,1)
                dish(i,:,rank_dish) = dish(i,:,rank_dish) + dish_schedule{j+3} * current_actions{j}.effects{1}.delta;
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% check all constraints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
valid = true;
check_one_action = zeros(num_interval,1,num_devices);
check_constraints = zeros(num_constraints,1);

%% first, check constraints for not having two actions at the same time
% for all devices
for i = 1:num_devices
    % if the device is not room
    if devices{i} ~= "room"
        current_actions = struct2cell(current_dictionary.(devices{i}).actions);
        % for all time steps
        for k = 1:num_interval
            one_action_schedule = struct2cell(input_schedule{i}{k});
            one_action_sum = 0;
            for j = 1:size(current_actions,1)
                one_action_sum = one_action_sum + one_action_schedule{j+3};
            end
            if one_action_sum ~= 1
                valid = false;
                check_one_action(k,1,i) = 1;
            end
        end
    end
end

%% Then, check all active and passive constraints
if valid
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
            
            for j = 1:size(current_constraint,1)
                if current_constraint(j)==0
                    valid = false;
                    check_constraints(i) = 1;
                end
            end
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
            
            for j = 1:size(current_constraint,1)
                if ~current_constraint(j)
                    valid = false;
                    check_constraints(i) = 1;
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% calculate objective
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
optimal = true;
% if it satisfies all constraints
if valid
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
        for k = 1:num_interval
            energy_schedule = struct2cell(input_schedule{i}{k});
            for j = 1:size(struct2cell(current_dictionary.(devices{i}).actions),1)
                energy_consumption(k) = energy_consumption(k) + energy_schedule{j+3} * current_device_actions{j}.power_consumed;
            end
        end
    end
    %% total cost
    cost = (background_load + energy_consumption) * electricity_price';
    % tolerance
    tol = 1e-5;
    if cost > optimal_cost + tol
        optimal = false;
        %cost - optimal_cost
    else
        optimal = true;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% report result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Three possibilities:
% 1.The schedule is illegal. (It violates some constraints)
% 2.The schedule is not optimal (Its cost is higher than that of the optimal solution)
% 3.The schedule is also an optimal solution.
flag = false;
if ~valid
    validation_result = "The input schedule is not valid as it violates constraints.";
%     disp(validation_result);
    for i = 1:num_devices
        for j = 1:num_interval
            if check_one_action(j,1,i) == 1
%                 disp(strcat("The ",num2str(i),"th device cannot perform more/less than one action at the ",num2str(j),"th time step."));
            end
        end
    end
    
    for i = 1:num_constraints
        if check_constraints(i) == 1
%             disp(strcat("The ",num2str(i),"th constraint is violated."));
        end
    end
elseif ~optimal
    validation_result = strcat("The input schedule is not optimal as its cost is ",num2str(cost),", which is higher than the optimal cost, ",num2str(optimal_cost),", with a tolerance of ",num2str(tol),".");
%     disp(validation_result);
else
    validation_result = "The input schedule is an optimal one.";
%     disp(validation_result);
    flag = true;
end

result = validation_result;

