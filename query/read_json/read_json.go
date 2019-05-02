package read_json

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	//"strconv"
)

// type Settings struct {
// 	time_span        string `json:"time_span"`
//     time_granularity string `json:"time_granularity"`
//     house_ratio      string `json:"house_ratio"`
//     num_devices      string `json:"num_devices"`
//     gridLength       string `json:"gridLength"`
//     clusterDiv       string `json:"clusterDiv"`
//     city             string `json:"city"`
// }

type Schedules struct {
	Dyson_AM09                 []Schedule `json:"Dyson_AM09"`
	Bryant_697CN030B           []Schedule `json:"Bryant_697CN030B"`
	Rheem_XE40M12ST45U1        []Schedule `json:"Rheem_XE40M12ST45U1"`
	Roomba_880                 []Schedule `json:"Roomba_880"`
	Tesla_S	                   []Schedule `json:"Tesla_S"`
	GE_WSM2420D3WW_wash	       []Schedule `json:"GE_WSM2420D3WW_wash"`
	GE_WSM2420D3WW_dry	       []Schedule `json:"GE_WSM2420D3WW_dry"`
	Kenmore_790_0x2E_91312013       []Schedule `json:"Kenmore_790_0x2E_91312013"`
	Kenmore_665_0x2E_13242K900      []Schedule `json:"Kenmore_665_0x2E_13242K900"`
	Thermostat_heat	           []Schedule `json:"thermostat_heat"`
	Thermostat_cool	           []Schedule `json:"thermostat_cool"`
	Water_heat_sensor          []Schedule `json:"water_heat_sensor"`
	Dust_sensor	               []Schedule `json:"dust_sensor"`
	IRobot_651_battery         []Schedule `json:"iRobot_651_battery"`
	Tesla_S_battery	           []Schedule `json:"Tesla_S_battery"`
	GE_WSM2420D3WW_wash_sensor []Schedule `json:"GE_WSM2420D3WW_wash_sensor"`
	GE_WSM2420D3WW_dry_sensor  []Schedule `json:"GE_WSM2420D3WW_dry_sensor"`
	Kenmore_790_sensor         []Schedule `json:"Kenmore_790_sensor"`
	Kenmore_665_sensor         []Schedule `json:"Kenmore_665_sensor"`
}

type Schedule struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Vacuum     int     `json:"vacuum"`
	Heat       int     `json:"heat"`
	Regular    int     `json:"regular"`
	Wash       int     `json:"wash"`
	Charge_48a int     `json:"charge_48a"`
	Bake       int     `json:"bake"`
	Broil      int     `json:"broil"`
	Charge     int     `json:"charge"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
}

func Read(filepath string) map[string]map[interface{}][]interface{}{
	// Open our jsonFile
	jsonFile, err := os.Open(filepath)
	//jsonFile, err := os.Open("C:/Users/xwa24/cse_project/solver/schedule.json")
	// if we os.Open returns an error then handle it
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println("Successfully Opened")
	// defer the closing of our jsonFile so that we can parse it later on
	defer jsonFile.Close()

	// read our opened xmlFile as a byte array.
	byteValue, _ := ioutil.ReadAll(jsonFile)

	// we initialize our Users array
	//var myschedule Schedules
	var m map[string]map[interface{}][]interface{}

	// we unmarshal our byteArray which contains our
	// jsonFile's content into 'users' which we defined above
	json.Unmarshal(byteValue, &m)

	//fmt.Println(myschedule.Roomba_880)
	return m
}


