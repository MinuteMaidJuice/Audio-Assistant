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

type Instance struct {
	Horizon int `json:"horizon"`
	Granularity int `json:"granularity"`
	PriceSchema []int `json:"priceSchema"`
	Agents Agent `json:"agents"`
}

type Agent struct {
	H1 Home `json:"h1"`
	H2 Home `json:"h2"`
	H3 Home `json:"h3"`
	H4 Home `json:"h4"`
	H5 Home `json:"h5"`
	H6 Home `json:"h6"`
	H7 Home `json:"h7"`
}

type Home struct {
	Actuators []string `json:"actuators"`
	Sensors []string `json:"sensors"`
	Neighbors []string `json:"neighbors"`
	BackgroundLoad []float64 `json:"backgroundLoad"`
	HouseType int `json:"houseType"`
	Rules []string `json:"rules"`
}

type Schedules struct {
	Roomba_880                 []Roomba      `json:"Roomba_880"`
	Rheem_XE40M12ST45U1        []Rheem       `json:"Rheem_XE40M12ST45U1"`
	Dyson_AM09                 []Dyson       `json:"Dyson_AM09"`
	GE_WSM2420D3WW_dry	       []GE_dry      `json:"GE_WSM2420D3WW_dry"`
	Room                       Roomm         `json:"room"`
	Kenmore_665_0x2E_13242K900 []Kenmore_665 `json:"Kenmore_665_0x2E_13242K900"`
	Tesla_S	                   []Tesla       `json:"Tesla_S"`
	Kenmore_790_0x2E_91312013  []Kenmore_790 `json:"Kenmore_790_0x2E_91312013"`
	GE_WSM2420D3WW_wash	       []GE_wash     `json:"GE_WSM2420D3WW_wash"`
}

type Roomba struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Vacuum     int     `json:"vacuum"`
	Charge     int     `json:"charge"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
}

type Rheem struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Heat       int     `json:"heat"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
}

type Dyson struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Heat       int     `json:"heat"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
}

type GE_dry struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Regular    int     `json:"regular"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
}

type Roomm struct {
	Message    string  `json:Message`
}

type Kenmore_665 struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Wash       int     `json:"wash"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
}

type Tesla struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Charge_48a int     `json:"charge_48a"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
}

type Kenmore_790 struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Bake       int     `json:"bake"`
	Broil      int     `json:"broil"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
}

type GE_wash struct {
	Ts         int     `json:"ts"`
	Bl         float64 `json:"bl"`
	Ep         float64 `json:"ep"`
	Off        int     `json:"off"`
	Regular    int     `json:"regular"`
	Dec        int     `json:"dec"`
	Dc         int 	   `json:"dc"`
	Dbl        float64 `json:"dbl"`
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

func ReadSche(filepath string) Schedules{
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
	var m Schedules

	// we unmarshal our byteArray which contains our
	// jsonFile's content into 'users' which we defined above
	json.Unmarshal(byteValue, &m)

	//fmt.Println(myschedule.Roomba_880)
	return m
}

func ReadIns(filepath string) Instance{
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
	var m Instance

	// we unmarshal our byteArray which contains our
	// jsonFile's content into 'users' which we defined above
	json.Unmarshal(byteValue, &m)

	//fmt.Println(myschedule.Roomba_880)
	return m
}


