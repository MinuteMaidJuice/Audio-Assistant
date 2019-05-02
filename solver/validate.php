<html>
	<head>
		<title>Validate</title>
	</head>
	<body>
		<button type="button" onclick="test();">Test</button>
		<p id="result"></p>
		<?php
			//ignore the following line. $schedule should already be a variable in the PHP
			$schedule = file_get_contents('C:\Users\Ray\Documents\MATLAB\research\Step4_validate\schedule.json');
			$input_condition = file_get_contents('C:\Users\Ray\Documents\MATLAB\research\Step4_validate\condition.json');
			$instance = file_get_contents('C:\Users\Ray\Desktop\Summer Research\SHDS_dataset-master\SHDS_dataset-master\SHDS_dataset\datasets\instance_DM_a7_c1.json');
			$dictionary = file_get_contents('C:\Users\Ray\Desktop\Summer Research\SHDS_dataset-master\SHDS_dataset-master\SHDS_dataset\inputs\DeviceDictionary.json');
		?>
		<script>
			//helper function that create all-zero array
			function zeros(dimensions) {
				var array = [];
				for (var i = 0; i < dimensions[0]; ++i) {
					array.push(dimensions.length == 1 ? 0 : zeros(dimensions.slice(1)));
				}
				return array;
			}
			
			//helper function that compares an array with a number
			function compareArrayWithNumber(array,number,operator){
				var result = Array(array.length).fill(false);
				if(operator=="lt"){
					for(var i = 0; i < array.length; i++){
						if(array[i] <= number - 1){
							result[i] = true;
						}
					}
				}
				else if(operator=="gt"){
					for(var i = 0; i < array.length; i++){
						if(array[i] >= number + 1){
							result[i] = true;
						}
					}
				}
				else if(operator=="leq"){
					for(var i = 0; i < array.length; i++){
						if(array[i] <= number){
							result[i] = true;
						}
					}
				}
				else if(operator=="geq"){
					for(var i = 0; i < array.length; i++){
						if(array[i] >= number){
							result[i] = true;
						}
					}
				}
				else if(operator=="eq"){
					for(var i = 0; i < array.length; i++){
						if(array[i] == number){
							result[i] = true;
						}
					}
				}
				return result;
			}
			
			function allTrueArray(array){
				for(var i = 0; i < array.length; i++){
					if(!array[i]){
						return false;
					}
				}
				return true;
			}
		
			function validate(){
				///////////////////////////////////////////////////////////////////////////
				//read the instance
				///////////////////////////////////////////////////////////////////////////
				var input_schedule = <?php echo $schedule; ?>;
				//build index
				var input_schedule_index = [];
				for (var x in input_schedule) {
				   input_schedule_index.push(x);
				}
				
				var input_condition = <?php echo $input_condition; ?>;
				var instance = <?php echo $instance; ?>;
				var dictionary = <?php echo $dictionary; ?>;
				
				///////////////////////////////////////////////////////////////////////////
				//read the information of the instance
				///////////////////////////////////////////////////////////////////////////
				current_house = instance.agents.h1;
				current_dictionary = dictionary[current_house.houseType];
				num_interval = instance.horizon;
				//electricity_price = instance.priceSchema;
				electricity_price = [0.198,0.198,0.198,0.198,0.198,0.198,0.198,0.198,0.225,0.225,0.225,0.225,0.249,0.249,0.849,0.849,0.849,0.849,0.225,0.225,0.225,0.225,0.198,0.198];
				background_load = current_house.backgroundLoad;
				devices = current_house.actuators;
				devices_complete = current_house.actuators;
				constraints = current_house.rules;
				
				//derived constants
				num_devices = devices.length;
				num_constraints = constraints.length;
				
				///////////////////////////////////////////////////////////////////////////
				//read the information of the initial conditions
				///////////////////////////////////////////////////////////////////////////
				optimal_cost = input_condition.fval;
				init_air_temp = input_condition.init_air_temp;
				init_dust = input_condition.init_dust;
				init_water_temp = input_condition.init_water_temp;
				init_battery_levels = input_condition.init_battery_levels;
				init_bake = input_condition.init_bake;
				init_laundry_wash = input_condition.init_laundry_wash;
				init_laundry_dry = input_condition.init_laundry_dry;
				init_dish = input_condition.init_dish;
				
				///////////////////////////////////////////////////////////////////////////
				//define variables and state properties
				///////////////////////////////////////////////////////////////////////////
				var category_map = new Map();
				category_map.set('air_temp',0);
				category_map.set('dust',0);
				category_map.set('water_temp',0);
				category_map.set('battery_level_robot',0);
				category_map.set('battery_level_Tesla',0);
				category_map.set('bake',0);
				category_map.set('laundry_wash',0);
				category_map.set('laundry_dry',0);
				category_map.set('dish',0);
				
				for(var i = 0; i < num_devices; i++){
					if(devices[i].substring(devices[i].length-2,devices[i].length-1)=="_" && !isNaN(devices[i].substring(devices[i].length-1,devices[i].length))){
						devices[i] = devices[i].substring(0,devices[i].length-2);
					}
					
					if(devices[i] == "Dyson_AM09"){
						category_map.set('air_temp',category_map.get('air_temp')+1);
					}
					else if(devices[i] == "Bryant_697CN030B"){
						category_map.set('air_temp',category_map.get('air_temp')+1);
					}
					else if(devices[i] == "Rheem_XE40M12ST45U1"){
						category_map.set('water_temp',category_map.get('water_temp')+1);
					}
					else if(devices[i] == "Roomba_880"){
						category_map.set('battery_level_robot',category_map.get('battery_level_robot')+1);
						category_map.set('dust',category_map.get('dust')+1);
					}
					else if(devices[i] == "Tesla_S"){
						category_map.set('battery_level_Tesla',category_map.get('battery_level_Tesla')+1);
					}
					else if(devices[i] == "GE_WSM2420D3WW_wash"){
						category_map.set('laundry_wash',category_map.get('laundry_wash')+1);
					}
					else if(devices[i] == "GE_WSM2420D3WW_dry"){
						category_map.set('laundry_dry',category_map.get('laundry_dry')+1);
					}
					else if(devices[i] == "Kenmore_790.91312013"){
						category_map.set('bake',category_map.get('bake')+1);
						category_map.set('air_temp',category_map.get('air_temp')+1);
					}
					else if(devices[i] == "Kenmore_665.13242K900"){
						category_map.set('dish',category_map.get('dish')+1);
					}
					else if(devices[i] == "water_tank"){
						devices[i] = "Rheem_XE40M12ST45U1";
						category_map.set('water_temp',category_map.get('water_temp')+1);
					}
					else{
						continue;
					}
				}
				
				///////////////////////////////////////////////////////////////////////////
				//calculate energy consumption
				///////////////////////////////////////////////////////////////////////////
				var air_temp = Array(num_interval).fill(0);
				var dust = zeros([category_map.get('dust'),num_interval]);
				var water_temp = zeros([category_map.get('water_temp'),num_interval]);
				var battery_levels = zeros([num_devices,num_interval]);
				var bake = zeros([category_map.get('bake'),num_interval]);
				var laundry_wash = zeros([category_map.get('laundry_wash'),num_interval]);
				var laundry_dry = zeros([category_map.get('laundry_dry'),num_interval]);
				var dish = zeros([category_map.get('dish'),num_interval]);

				///////////////////////////////////////////////////////////////////////////
				//calculate the state properties
				///////////////////////////////////////////////////////////////////////////
				//air tempereature (common)
				var find_air_temp_actuator = -1;
				var count_air_temp = 0;
				while(count_air_temp != category_map.get('air_temp')){		
					for(var i = find_air_temp_actuator+1; i < num_devices; i++){
						if(devices[i] == "Dyson_AM09" || devices[i] == "Bryant_697CN030B" || devices[i] == "Kenmore_790.91312013"){
							find_air_temp_actuator = i;
							count_air_temp = count_air_temp + 1;
							break;
						}
					}
					if(find_air_temp_actuator != -1){
						var current_actions = current_dictionary[devices[find_air_temp_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(count_air_temp == 1){
							air_temp[0] = init_air_temp;
							//new
							var air_temp_schedule = input_schedule[input_schedule_index[find_air_temp_actuator]][0];
							//new
							//build index
							var air_temp_schedule_index = [];
							for (var x in air_temp_schedule) {
							   air_temp_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								air_temp[0] = air_temp[0] + air_temp_schedule[air_temp_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[Object.keys(current_actions[current_actions_index[j]].effects).length-1].delta;
								//use "Object.keys(current_actions[current_actions_index[j]].effects).length-1" because the effects on air temp for heater, cooler, and oven are all in the last position
							}
							for(var i = 1; i < num_interval; i++){
								air_temp[i] = air_temp[i-1];
								//new
								var air_temp_schedule = input_schedule[input_schedule_index[find_air_temp_actuator]][i];
								//new
								//build index
								var air_temp_schedule_index = [];
								for (var x in air_temp_schedule) {
								   air_temp_schedule_index.push(x);
								}
								for(var j = 0; j < Object.keys(current_actions).length; j++){
									air_temp[i] = air_temp[i] + air_temp_schedule[air_temp_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[Object.keys(current_actions[current_actions_index[j]].effects).length-1].delta;
									//use "Object.keys(current_actions[current_actions_index[j]].effects).length-1" because the effects on air temp for heater, cooler, and oven are all in the last position
								}
							}
						}
						else{
							for(var k = 1; k <= num_interval; k++){          //for all time intervals
								for(var i = 0; i < k; i++){                 //add all effects before interval k to the expression
									//new
									var air_temp_schedule = input_schedule[input_schedule_index[find_air_temp_actuator]][i];
									//new
									//build index
									var air_temp_schedule_index = [];
									for (var x in air_temp_schedule) {
									   air_temp_schedule_index.push(x);
									}
									for(var j = 0; j < Object.keys(current_actions).length; j++){
										air_temp[k-1] = air_temp[k-1] + air_temp_schedule[air_temp_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[Object.keys(current_actions[current_actions_index[j]].effects).length-1].delta;
										//use "Object.keys(current_actions[current_actions_index[j]].effects).length-1" because the effects on air temp for heater, cooler, and oven are all in the last position
									}
								}
							}
						}
					}
				}
				
				//floor cleanliness
				var find_dust_actuator = -1;
				var count_dust = 0;
				while(count_dust != category_map.get('dust')){
					for(var i = find_dust_actuator+1; i < num_devices; i++){
						if(devices[i] == "Roomba_880"){
							find_dust_actuator = i;
							count_dust = count_dust + 1;

							//determine the rank of the device
							if(devices[i].substring(devices[i].length-2,devices[i].length-1)=="_" && !isNaN(devices[i].substring(devices[i].length-1,devices[i].length))){
								rank_dust = Number(devices[i].substring(devices[i].length-1,devices[i].length));
							}
							else{
								rank_dust = 0;
							}

							break;
						}
					}
					if(find_dust_actuator != -1){
						var current_actions = current_dictionary[devices[find_dust_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(!isNaN(init_dust)){
							dust[rank_dust][0] = init_dust;
						}
						else{
							dust[rank_dust][0] = init_dust[rank_dust];
						}
						//new
						var dust_schedule = input_schedule[input_schedule_index[find_dust_actuator]][0];
						//new
						//build index
						var dust_schedule_index = [];
						for (var x in dust_schedule) {
						   dust_schedule_index.push(x);
						}
						for(var j = 0; j < Object.keys(current_actions).length - 1; j++){     //-1 because the effect of the last action is incomplete
							dust[rank_dust][0] = dust[rank_dust][0] + dust_schedule[dust_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
						}
						for(var i = 1; i < num_interval; i++){
							dust[rank_dust][i] = dust[rank_dust][i-1];
							//new
							var dust_schedule = input_schedule[input_schedule_index[find_dust_actuator]][i];
							//new
							//build index
							var dust_schedule_index = [];
							for (var x in dust_schedule) {
							   dust_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length - 1; j++){     //-1 because the effect of the last action is incomplete
								dust[rank_dust][i] = dust[rank_dust][i] + dust_schedule[dust_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
							}
						}
					}
				}
				
				//water temperature
				var find_water_temp_actuator = -1;
				var count_water_temp = 0;
				while(count_water_temp != category_map.get('water_temp')){
					for(var i = find_water_temp_actuator+1; i < num_devices; i++){
						if(devices[i] == "Rheem_XE40M12ST45U1"){
							find_water_temp_actuator = i;
							count_water_temp = count_water_temp + 1;

							//determine the rank of the device
							if(devices[i].substring(devices[i].length-2,devices[i].length-1)=="_" && !isNaN(devices[i].substring(devices[i].length-1,devices[i].length))){
								rank_water_temp = Number(devices[i].substring(devices[i].length-1,devices[i].length));
							}
							else{
								rank_water_temp = 0;
							}

							break;
						}
					}
					if(find_water_temp_actuator != -1){
						var current_actions = current_dictionary[devices[find_water_temp_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(!isNaN(init_water_temp)){
							water_temp[rank_water_temp][0] = init_water_temp;
						}
						else{
							water_temp[rank_water_temp][0] = init_water_temp[rank_water_temp];
						}
						//new
						var water_temp_schedule = input_schedule[input_schedule_index[find_water_temp_actuator]][0];
						//new
						//build index
						var water_temp_schedule_index = [];
						for (var x in water_temp_schedule) {
						   water_temp_schedule_index.push(x);
						}
						for(var j = 0; j < Object.keys(current_actions).length; j++){
							water_temp[rank_water_temp][0] = water_temp[rank_water_temp][0] + water_temp_schedule[water_temp_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
						}
						for(var i = 1; i < num_interval; i++){
							water_temp[rank_water_temp][i] = water_temp[rank_water_temp][i-1];
							//new
							var water_temp_schedule = input_schedule[input_schedule_index[find_water_temp_actuator]][i];
							//new
							//build index
							var water_temp_schedule_index = [];
							for (var x in water_temp_schedule) {
							   water_temp_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								water_temp[rank_water_temp][i] = water_temp[rank_water_temp][i] + water_temp_schedule[water_temp_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
							}
						}
					}
				}
				
				//battery level
				//Tesla
				var find_battery_levels_actuator = -1;
				var count_battery_level_Tesla = 0;
				while(count_battery_level_Tesla != category_map.get('battery_level_Tesla')){
					for(var i = find_battery_levels_actuator+1; i < num_devices; i++){
						if(devices[i] == "Tesla_S"){
							find_battery_levels_actuator = i;
							count_battery_level_Tesla = count_battery_level_Tesla + 1;            
							break;
						}
					}
					if(find_battery_levels_actuator != -1){
						var current_actions = current_dictionary[devices[find_battery_levels_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(!isNaN(init_battery_levels)){
							battery_levels[find_battery_levels_actuator][0] = init_battery_levels;
						}
						else{
							battery_levels[find_battery_levels_actuator][0] = init_battery_levels[find_battery_levels_actuator];
						}
						//new
						var battery_levels_schedule = input_schedule[input_schedule_index[find_battery_levels_actuator]][0];
						//new
						//build index
						var battery_levels_schedule_index = [];
						for (var x in battery_levels_schedule) {
						   battery_levels_schedule_index.push(x);
						}
						for(var j = 0; j < Object.keys(current_actions).length; j++){
							battery_levels[find_battery_levels_actuator][0] = battery_levels[find_battery_levels_actuator][0] + battery_levels_schedule[battery_levels_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;;
						}
						for(var i = 1; i < num_interval; i++){
							battery_levels[find_battery_levels_actuator][i] = battery_levels[find_battery_levels_actuator][i-1];
							//new
							battery_levels_schedule = input_schedule[input_schedule_index[find_battery_levels_actuator]][i];
							//new
							//build index
							var battery_levels_schedule_index = [];
							for (var x in battery_levels_schedule) {
							   battery_levels_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								battery_levels[find_battery_levels_actuator][i] = battery_levels[find_battery_levels_actuator][i] + battery_levels_schedule[battery_levels_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;;
							}
						}
					}
				}
				
				//vacuum robot
				var find_battery_levels_actuator = -1;
				var count_battery_level_robot = 0;
				while(count_battery_level_robot != category_map.get('battery_level_robot')){
					for(var i = find_battery_levels_actuator+1; i < num_devices; i++){
						if(devices[i] == "Roomba_880"){
							find_battery_levels_actuator = i;
							count_battery_level_robot = count_battery_level_robot + 1;            
							break;
						}
					}
					if(find_battery_levels_actuator != -1){
						var current_actions = current_dictionary[devices[find_battery_levels_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(!isNaN(init_battery_levels)){
							battery_levels[find_battery_levels_actuator][0] = init_battery_levels;
						}
						else{
							battery_levels[find_battery_levels_actuator][0] = init_battery_levels[find_battery_levels_actuator];
						}
						//new
						var battery_levels_schedule = input_schedule[input_schedule_index[find_battery_levels_actuator]][0];
						//new
						//build index
						var battery_levels_schedule_index = [];
						for (var x in battery_levels_schedule) {
						   battery_levels_schedule_index.push(x);
						}
						for(var j = 0; j < Object.keys(current_actions).length; j++){
							battery_levels[find_battery_levels_actuator][0] = battery_levels[find_battery_levels_actuator][0] + battery_levels_schedule[battery_levels_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[Object.keys(current_actions[current_actions_index[j]].effects).length-1].delta;;
							//use "Object.keys(current_actions[current_actions_index[j]].effects).length-1" because the effect of the last action is incomplete
						}
						for(var i = 1; i < num_interval; i++){
							battery_levels[find_battery_levels_actuator][i] = battery_levels[find_battery_levels_actuator][i-1];
							//new
							battery_levels_schedule = input_schedule[input_schedule_index[find_battery_levels_actuator]][i];
							//new
							//build index
							var battery_levels_schedule_index = [];
							for (var x in battery_levels_schedule) {
							   battery_levels_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								battery_levels[find_battery_levels_actuator][i] = battery_levels[find_battery_levels_actuator][i] + battery_levels_schedule[battery_levels_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[Object.keys(current_actions[current_actions_index[j]].effects).length-1].delta;;
								//use "Object.keys(current_actions[current_actions_index[j]].effects).length-1" because the effect of the last action is incomplete
							}
						}
					}
				}
				
				//bake
				var find_bake_actuator = -1;
				var count_bake = 0;
				while(count_bake != category_map.get('bake')){
					for(var i = find_bake_actuator+1; i < num_devices; i++){
						if(devices[i] == "Kenmore_790.91312013"){
							find_bake_actuator = i;
							count_bake = count_bake + 1;

							//determine the rank of the device
							if(devices[i].substring(devices[i].length-2,devices[i].length-1)=="_" && !isNaN(devices[i].substring(devices[i].length-1,devices[i].length))){
								rank_bake = Number(devices[i].substring(devices[i].length-1,devices[i].length));
							}
							else{
								rank_bake = 0;
							}

							break;
						}
					}
					if(find_bake_actuator != -1){
						var current_actions = current_dictionary[devices[find_bake_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(!isNaN(init_bake)){
							bake[rank_bake][0] = init_bake;
						}
						else{
							bake[rank_bake][0] = init_bake[rank_bake];
						}
						//new
						var bake_schedule = input_schedule[input_schedule_index[find_bake_actuator]][0];
						//new
						//build index
						var bake_schedule_index = [];
						for (var x in bake_schedule) {
						   bake_schedule_index.push(x);
						}
						for(var j = 0; j < Object.keys(current_actions).length; j++){
							bake[rank_bake][0] = bake[rank_bake][0] + bake_schedule[bake_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
						}
						for(var i = 1; i < num_interval; i++){
							bake[rank_bake][i] = bake[rank_bake][i-1];
							//new
							var bake_schedule = input_schedule[input_schedule_index[find_bake_actuator]][i];
							//new
							//build index
							var bake_schedule_index = [];
							for (var x in bake_schedule) {
							   bake_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								bake[rank_bake][i] = bake[rank_bake][i] + bake_schedule[bake_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
							}
						}
					}
				}
				
				//laundry_wash
				var find_laundry_wash_actuator = -1;
				var count_laundry_wash = 0;
				while(count_laundry_wash != category_map.get('laundry_wash')){
					for(var i = find_laundry_wash_actuator+1; i < num_devices; i++){
						if(devices[i] == "GE_WSM2420D3WW_wash"){
							find_laundry_wash_actuator = i;
							count_laundry_wash = count_laundry_wash + 1;

							//determine the rank of the device
							if(devices[i].substring(devices[i].length-2,devices[i].length-1)=="_" && !isNaN(devices[i].substring(devices[i].length-1,devices[i].length))){
								rank_laundry_wash = Number(devices[i].substring(devices[i].length-1,devices[i].length));
							}
							else{
								rank_laundry_wash = 0;
							}

							break;
						}
					}
					if(find_laundry_wash_actuator != -1){
						var current_actions = current_dictionary[devices[find_laundry_wash_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(!isNaN(init_laundry_wash)){
							laundry_wash[rank_laundry_wash][0] = init_laundry_wash;
						}
						else{
							laundry_wash[rank_laundry_wash][0] = init_laundry_wash[rank_laundry_wash];
						}
						//new
						var laundry_wash_schedule = input_schedule[input_schedule_index[find_laundry_wash_actuator]][0];
						//new
						//build index
						var laundry_wash_schedule_index = [];
						for (var x in laundry_wash_schedule) {
						   laundry_wash_schedule_index.push(x);
						}
						for(var j = 0; j < Object.keys(current_actions).length; j++){
							laundry_wash[rank_laundry_wash][0] = laundry_wash[rank_laundry_wash][0] + laundry_wash_schedule[laundry_wash_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
						}
						for(var i = 1; i < num_interval; i++){
							laundry_wash[rank_laundry_wash][i] = laundry_wash[rank_laundry_wash][i-1];
							//new
							var laundry_wash_schedule = input_schedule[input_schedule_index[find_laundry_wash_actuator]][i];
							//new
							//build index
							var laundry_wash_schedule_index = [];
							for (var x in laundry_wash_schedule) {
							   laundry_wash_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								laundry_wash[rank_laundry_wash][i] = laundry_wash[rank_laundry_wash][i] + laundry_wash_schedule[laundry_wash_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
							}
						}
					}
				}
				
				//laundry_dry
				var find_laundry_dry_actuator = -1;
				var count_laundry_dry = 0;
				while(count_laundry_dry != category_map.get('laundry_dry')){
					for(var i = find_laundry_dry_actuator+1; i < num_devices; i++){
						if(devices[i] == "GE_WSM2420D3WW_dry"){
							find_laundry_dry_actuator = i;
							count_laundry_dry = count_laundry_dry + 1;

							//determine the rank of the device
							if(devices[i].substring(devices[i].length-2,devices[i].length-1)=="_" && !isNaN(devices[i].substring(devices[i].length-1,devices[i].length))){
								rank_laundry_dry = Number(devices[i].substring(devices[i].length-1,devices[i].length));
							}
							else{
								rank_laundry_dry = 0;
							}

							break;
						}
					}
					if(find_laundry_dry_actuator != -1){
						var current_actions = current_dictionary[devices[find_laundry_dry_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(!isNaN(init_laundry_dry)){
							laundry_dry[rank_laundry_dry][0] = init_laundry_dry;
						}
						else{
							laundry_dry[rank_laundry_dry][0] = init_laundry_dry[rank_laundry_dry];
						}
						//new
						var laundry_dry_schedule = input_schedule[input_schedule_index[find_laundry_dry_actuator]][0];
						//new
						//build index
						var laundry_dry_schedule_index = [];
						for (var x in laundry_dry_schedule) {
						   laundry_dry_schedule_index.push(x);
						}
						for(var j = 0; j < Object.keys(current_actions).length; j++){
							laundry_dry[rank_laundry_dry][0] = laundry_dry[rank_laundry_dry][0] + laundry_dry_schedule[laundry_dry_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
						}
						for(var i = 1; i < num_interval; i++){
							laundry_dry[rank_laundry_dry][i] = laundry_dry[rank_laundry_dry][i-1];
							//new
							var laundry_dry_schedule = input_schedule[input_schedule_index[find_laundry_dry_actuator]][i];
							//new
							//build index
							var laundry_dry_schedule_index = [];
							for (var x in laundry_dry_schedule) {
							   laundry_dry_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								laundry_dry[rank_laundry_dry][i] = laundry_dry[rank_laundry_dry][i] + laundry_dry_schedule[laundry_dry_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
							}
						}
					}
				}
				
				//dish
				var find_dish_actuator = -1;
				var count_dish = 0;
				while(count_dish != category_map.get('dish')){
					for(var i = find_dish_actuator+1; i < num_devices; i++){
						if(devices[i] == "Kenmore_665.13242K900"){
							find_dish_actuator = i;
							count_dish = count_dish + 1;

							//determine the rank of the device
							if(devices[i].substring(devices[i].length-2,devices[i].length-1)=="_" && !isNaN(devices[i].substring(devices[i].length-1,devices[i].length))){
								rank_dish = Number(devices[i].substring(devices[i].length-1,devices[i].length));
							}
							else{
								rank_dish = 0;
							}

							break;
						}
					}
					if(find_dish_actuator != -1){
						var current_actions = current_dictionary[devices[find_dish_actuator]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						if(!isNaN(init_dish)){
							dish[rank_dish][0] = init_dish;
						}
						else{
							dish[rank_dish][0] = init_dish[rank_dish];
						}
						//new
						var dish_schedule = input_schedule[input_schedule_index[find_dish_actuator]][0];
						//new
						//build index
						var dish_schedule_index = [];
						for (var x in dish_schedule) {
						   dish_schedule_index.push(x);
						}
						for(var j = 0; j < Object.keys(current_actions).length; j++){
							dish[rank_dish][0] = dish[rank_dish][0] + dish_schedule[dish_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
						}
						for(var i = 1; i < num_interval; i++){
							dish[rank_dish][i] = dish[rank_dish][i-1];
							//new
							var dish_schedule = input_schedule[input_schedule_index[find_dish_actuator]][i];
							//new
							//build index
							var dish_schedule_index = [];
							for (var x in dish_schedule) {
							   dish_schedule_index.push(x);
							}
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								dish[rank_dish][i] = dish[rank_dish][i] + dish_schedule[dish_schedule_index[j+3]] * current_actions[current_actions_index[j]].effects[0].delta;
							}
						}
					}
				}
				
				///////////////////////////////////////////////////////////////////////////
				//check all constraints
				///////////////////////////////////////////////////////////////////////////
				var valid = true;
				var check_one_action = zeros([num_devices,num_interval]);
				var check_constraints = Array(num_constraints).fill(true);

				//first, check constraints for not having two actions at the same time
				for(var i = 0; i < num_devices; i++){
					//if the device is not room
					if(devices[i] != "room"){
						var current_actions = current_dictionary[devices[i]].actions;
						//build index
						var current_actions_index = [];
						for (var x in current_actions) {
						   current_actions_index.push(x);
						}
						//for all time steps
						for(var k = 0; k < num_interval; k++){
							var one_action_schedule = input_schedule[input_schedule_index[i]][k];
							//build index
							var one_action_schedule_index = [];
							for (var x in one_action_schedule) {
							   one_action_schedule_index.push(x);
							}
							var one_action_sum = 0;
							for(var j = 0; j < Object.keys(current_actions).length; j++){
								one_action_sum = one_action_sum + one_action_schedule[one_action_schedule_index[j+3]];
							}
							if(one_action_sum != 1){
								valid = false;
								check_one_action[i][k] = 1;
							}
						}
					}
				}

				//Then, check all active and passive constraints
				if(valid){
					for(var i = 0; i < num_constraints; i++){
						//extract information from the constraints
						var info = constraints[i].split(" ");
						var constraint_type = Number(info[0]);
						var device_or_location = info[1];
						var state_property = info[2];
						var relation = info[3];
						var goal_state = Number(info[4]);
						var time_relation = "";
						var goal_time = "";
						
						if(constraint_type==1){
							time_relation = info[5];
							goal_time = Number(info[6]);
						}
						
						var rank = -1;
						var current_state;
					    //form constraint by type
						//passive constraint
						if(constraint_type==0){
							//determine the rank of the device
							if(device_or_location.substring(device_or_location.length-2,device_or_location.length-1)=="_" && !isNaN(device_or_location.substring(device_or_location.length-1,device_or_location.length))){
								rank = Number(device_or_location.substring(device_or_location.length-1,device_or_location.length));
							}
							else{
								rank = 0;
							}

							if(state_property=="charge"){
								for(var j = 0; j < num_devices; j++){
									if(devices_complete[j]==device_or_location){
										current_state = battery_levels[j];
										break;
									}
								}
							}
							else if(state_property=="bake"){
								current_state = bake[rank];
							}
							else if(state_property=="laundry_wash"){
								current_state = laundry_wash[rank];
							}
							else if(state_property=="laundry_dry"){
								current_state = laundry_dry[rank];
							}
							else if(state_property=="temperature_heat"){
								current_state = air_temp;
							}
							else if(state_property=="temperature_cool"){
								current_state = air_temp;
							}
							else if(state_property=="water_temp"){
								current_state = water_temp[rank];
							}
							else if(state_property=="cleanliness"){
								current_state = dust[rank];
							}
							else if(state_property=="dish_wash"){
								current_state = dish[rank];
							}
							
							var current_constraint = compareArrayWithNumber(current_state,goal_state,relation);
							
							if(!allTrueArray(current_constraint)){
								valid = false;
								check_constraints[i] = false;
							}
						}
						//active constraint
						else{
							//determine the rank of the device
							if(device_or_location.substring(device_or_location.length-2,device_or_location.length-1)=="_" && !isNaN(device_or_location.substring(device_or_location.length-1,device_or_location.length))){
								rank = Number(device_or_location.substring(device_or_location.length-1,device_or_location.length));
							}
							else{
								rank = 0;
							}

							if(state_property=="charge"){
								for(var j = 0; j < num_devices; j++){
									if(devices_complete[j]==device_or_location){
										current_state = battery_levels[j];
										break;
									}
								}
							}
							else if(state_property=="bake"){
								current_state = bake[rank];
							}
							else if(state_property=="laundry_wash"){
								current_state = laundry_wash[rank];
							}
							else if(state_property=="laundry_dry"){
								current_state = laundry_dry[rank];
							}
							else if(state_property=="temperature_heat"){
								current_state = air_temp;
							}
							else if(state_property=="temperature_cool"){
								current_state = air_temp;
							}
							else if(state_property=="water_temp"){
								current_state = water_temp[rank];
							}
							else if(state_property=="cleanliness"){
								current_state = dust[rank];
							}
							else if(state_property=="dish_wash"){
								current_state = dish[rank];
							}

							/*omit MATLAB comments*/
							var current_constraint;
							if(time_relation=="before"){
								/*omit MATLAB comments*/
								current_constraint = compareArrayWithNumber(current_state.slice(goal_time-1,goal_time),goal_state,relation);
							}
							else if(time_relation=="at"){
								/*omit MATLAB comments*/
								current_constraint = compareArrayWithNumber(current_state.slice(goal_time-1,goal_time),goal_state,relation);
							}
							else if(time_relation=="after"){
								/*omit MATLAB comments*/
								current_constraint = compareArrayWithNumber(current_state.slice(goal_time-1),goal_state,relation);
							}
							
							if(!allTrueArray(current_constraint)){
								valid = false;
								check_constraints[i] = false;
							}
						}
					}
				}
				
				///////////////////////////////////////////////////////////////////////////
				//calculate objective
				///////////////////////////////////////////////////////////////////////////
				var optimal = true;
				//if it satisfies all constraints
				if(valid){
					//energy consumption
					var device_energy_consumption = Array(num_interval).fill(0);
					for(var i = 0; i < num_devices; i++){
						if (devices[i]!="Dyson_AM09"&&devices[i]!="Bryant_697CN030B"&&devices[i]!="Rheem_XE40M12ST45U1"&&devices[i]!="Roomba_880"&&devices[i]!="Tesla_S"&&devices[i]!="GE_WSM2420D3WW_wash"&&devices[i]!="GE_WSM2420D3WW_dry"&&devices[i]!="Kenmore_790.91312013"&&devices[i]!="Kenmore_665.13242K900"){
							continue;
						}
						current_device_actions = current_dictionary[devices[i]].actions;
						//build index
						var current_device_actions_index = [];
						for (var x in current_device_actions) {
						   current_device_actions_index.push(x);
						}
						
						for(var k = 0; k < num_interval; k++){
							var energy_schedule = input_schedule[input_schedule_index[i]][k];
							//build index
							var energy_schedule_index = [];
							for (var y in energy_schedule) {
							   energy_schedule_index.push(y);
							}
							
							for(var j = 0; j < Object.keys(current_device_actions).length; j++){
								device_energy_consumption[k] = device_energy_consumption[k] + energy_schedule[energy_schedule_index[j+3]] * current_device_actions[current_device_actions_index[j]].power_consumed;
							}
						}
					}
				
					var total_energy_consumption = Array(num_interval).fill(0);
					for(var l = 0; l < num_interval; l++){
						total_energy_consumption[l] = background_load[l] + device_energy_consumption[l];
					}
					
					//calculate cost
					var cost = 0;
					for(var m = 0; m < num_interval; m++){
						cost = cost + total_energy_consumption[m] * electricity_price[m];
					}
					
					//tolerance
					var tol = 1e-5;
					if(cost > optimal_cost + tol){
						optimal = false;
					}
					else{
						optimal = true;
					}
				}				
				
				///////////////////////////////////////////////////////////////////////////
				//report result
				///////////////////////////////////////////////////////////////////////////
				//Three possibilities:
				//1.The schedule is illegal. (It violates some constraints)
				//2.The schedule is not optimal (Its cost is higher than that of the optimal solution)
				//3.The schedule is also an optimal solution.
				var validation_result = "";
				if(!valid){
					validation_result = "The input schedule is not valid as it violates the following constraints.";
					console.log(validation_result);
					for(var i = 0; i < num_devices; i++){
						for(var j = 0; j < num_interval; j++){
							if(check_one_action[i][j] == 1){
								console.log("The " + (i+1) + "th device cannot perform more/less than one action at the " + (j+1) + "th time step.");
							}
						}
					}
					
					for(var i = 0; i < num_constraints; i++){
						if(!check_constraints[i]){
							console.log("The " + (i+1) + "th constraint is violated.");
						}
					}
				}
				else if(!optimal){
					validation_result = "The input schedule is not optimal as its cost is " + cost + ", which is higher than the optimal cost, " + optimal_cost + ", with a tolerance of " + tol + ".";
					console.log(validation_result);
				}
				else{
					validation_result = "The input schedule is an optimal one.";
					console.log(validation_result);
				}
			}
			
			function test(){
				console.time('validate');
				validate(); // run whatever needs to be timed in between the statements
				console.timeEnd('validate');
			}
		</script>
	</body>
</html>