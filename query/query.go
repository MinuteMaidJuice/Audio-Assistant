package main

import (
	"fmt"
	// "io/ioutil"
	// "os"
	rjson "./read_json"
	//"strings"
)



var Devices = []string {
	"Dyson_AM09",                 
	"Bryant_697CN030B",           
	"Rheem_XE40M12ST45U1",        
	"Roomba_880",                 
	"Tesla_S",	                    
	"GE_WSM2420D3WW_wash",	       
	"GE_WSM2420D3WW_dry",	       
	"Kenmore_790_0x2E_91312013",  
	"Kenmore_665_0x2E_13242K900", 
	"Thermostat_heat",	           
	"Thermostat_cool",	           
	"Water_heat_sensor",          
	"Dust_sensor",
	"IRobot_651_battery",
	"Tesla_S_battery",
	"GE_WSM2420D3WW_wash_sensor",
	"GE_WSM2420D3WW_dry_sensor",
	"Kenmore_790_sensor",
	"Kenmore_665_sensor",
}
var myschedule map[string]map[interface{}][]interface{}

func main() {
	var dev_id string = "Tesla_S"
	var para_id string = "Dbl"
	var t_step int = 1
	var path string = "C:/Users/xwa24/cse_project/solver/schedule.json"

	fmt.Println(Query(dev_id, para_id, t_step, path))
}

func Query(dev_id string, para_id string, t_step int, p2schedule string) string {
	
	var output string = "haha"
	myschedule = rjson.Read(p2schedule)
	fmt.Println(myschedule)


	// switch v := myschedule[dev_id][t_step-1].(type) {
	// case int:
	//     fmt.Println("int",v)
	// case float64:
	//     fmt.Println("float", v)
	// case string:
	//     fmt.Println("string", v)
	// default:
	// 	fmt.Printf("(%v, %T)\n", v, v)
	//     // i isn't one of the types above
	// }
	

	return output


}

