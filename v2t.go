// Sample speech-quickstart uses the Google Cloud Speech API to transcribe
// audio.
package main

import (
    "fmt"
    "strings"
    "encoding/json"
    "strconv"
    "os/exec"
    "bufio"
    "os"
    "log"
    "./input"
    "reflect"
    // "io/ioutil"
    re "./record_prj"
    rjson "./read_json"
    "github.com/hegedustibor/htgo-tts"
)

var timemap = map[string]int {
    "midnight":0,
    "one":1,
    "two":2,
    "three":3,
    "four":4,
    "five":5,
    "six":6,
    "seven":7,
    "eight":8,
    "nine":9,
    "ten":10,
    "eleven":11,
    "twelve":12,
    "1":1,
    "2":2,
    "3":3,
    "4":4,
    "5":5,
    "6":6,
    "7":7,
    "8":8,
    "9":9,
    "10":10,
    "11":11,
    "12":12,
    "13":13,
    "14":14,
    "15":15,
    "16":16,
    "17":17,
    "18":18,
    "19":19,
    "20":20,
    "21":21,
    "22":22,
    "23":23,
    "24":24,
    "now":-1,
}

type DevData struct {
    States bool
    Schedule [24]int
}

var dev = map[string]DevData{
    "done": DevData{
        true,
        [24]int{1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0},
    },
    "dtwo": DevData{
        false,
        [24]int{0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0},
    },
}
var myschedule rjson.Schedules
var myinstance rjson.Instance

func main() {

    // var flag bool = false
    // var query string
    // var temp string
    
    // re.Playing("The Tesla_S will be on at 5am ")
    //var test string = "Roomba_880"

    // fmt.Println(input.InputT("why my car charge at five"))

    myinstance = rjson.ReadIns("C:/Users/xwa24/cse_project/SHDS_dataset-master/SHDS_dataset/datasets/instance_DM_a7_c1.json")
    // fmt.Println(myinstance.Agents.H1.Rules[0])

//  Goal 1 questions
    // myschedule = rjson.ReadSche("C:/Users/xwa24/cse_project/solver/schedule.json")
    myschedule = rjson.ReadSche("C:/Users/xwa24/cse_project/newschedule.json")
    // nameee := "Dyson_AM09"
    // nameeee := "Off"
    // fmt.Println(((reflect.ValueOf(myschedule)).FieldByName(nameee)).Index(0).FieldByName(nameeee))
    // fmt.Println(myschedule.Dyson_AM09[0])

    var rnum int = 0
    re.Recording("r"+strconv.Itoa(rnum))
    text := re.Recognizing("r"+strconv.Itoa(rnum))
    // text := "turn my oven off at 17"
    // fmt.Println(text)
    writetofile(text)

    // reader := bufio.NewReader(os.Stdin)
    // fmt.Print("Enter text: ")
    // text, _ := reader.ReadString('\n')

    words := input.InputT(text)
	device := words[0]
    action := words[1]
    question := words[2]
    time := timemap[words[3]]
    time_ex := -10
    if question == "change" {
        time_ex = timemap[words[4]]
    }
    fmt.Println(words)

    var outtext string

    if question == "why" {
        outtext = goal1q(device,action,time,time_ex)
    } else if question == "change" {
        outtext = goal2q(device,action,time,time_ex)
    } else if question == "sche" {
        outtext = printsche(device, action)
    } else if question == "set" || question == "none" {
        outtext = goal3q(device,action,time)
    } else {
        outtext = "Sorry, I don't understand."
    }

    writetofile(outtext)
    
    writetofile("-------------------------------------------------------")
    

    // fmt.Println(question)
    
    //fmt.Println(myschedule.Tesla_S)
    

    // for !flag {
    //     //re.Recording("r"+strconv.Itoa(rnum))
    //     //temp = re.Recognizing("r"+strconv.Itoa(rnum))
    //     //temp = "Will oven baker be on at midnight"
    //     temp = "Why my car charging at 4?"
    //     sim := re.Sim(temp)
    //     if(sim<0) {
    //         fmt.Printf("Not yet implemented\n")
    //         rnum++
    //         flag = true
    //     } else {
    //         query = re.Querys[sim]
    //         flag = true
    //     }
    // }
    
    

    // words := strings.Fields(query)
    // num := words[len(words)-1]
    // var name strings.Builder
    // var stro string

    // name.WriteString("d")
    // name.WriteString(num)


    // if strings.Contains(temp, "battery") {
    //     fmt.Printf("The device %s is %t\n", num, dev[name.String()].States)
    // } else if strings.Contains(temp, "schedule") {
    //     stro = "Device " + num +" will be on at " + timetable(dev[name.String()].Schedule);
    //     fmt.Printf(stro)
    //     // fmt.Printf("Device %s will be on at %s\n", num, timetable(dev[name.String()].Schedule))
    //     speech := htgotts.Speech{Folder: "audio", Language: "en"}
    //     speech.Speak("test", stro)
    //     re.Playing("test")
    // }
}
// "dyson", "bryant", "rheem", "roomba", "tesla", "washer", "dryer", "baker", "dishwasher",
func nameactionmap(name string, action string) (string,[]string) {
    var nout string
    var aout []string
    if name == "dyson" {
        nout = "Dyson_AM09"
        if action == "on" || action == "off"{
            aout = append(aout,"Off")
            aout = append(aout,"Heat")
        }
    } else if name == "rheem" {
        nout = "Rheem_XE40M12ST45U1"
        if action == "on" || action == "off"{
            aout = append(aout,"Off")
            aout = append(aout,"Heat")
        }
    } else if name == "roomba" {
        nout = "Roomba_880"
        if action == "on" || action == "off" {
            aout = append(aout,"Off")
            aout = append(aout,"Vacuum")
        } else if action == "charge" {
            aout = append(aout,"Off")
            aout = append(aout,"Charge")
        }
    } else if name == "tesla" {
        nout = "Tesla_S"
        if action == "on" || action == "off" {
            aout = append(aout,"Off")
            aout = append(aout,"Charge_48a")
        } else if action == "charge" {
            aout = append(aout,"Off")
            aout = append(aout,"Charge_48a")
        }
    } else if name == "washer" {
        nout = "GE_WSM2420D3WW_wash"
        if action == "on" || action == "off"{
            aout = append(aout,"Off")
            aout = append(aout,"Regular")
        }
    } else if name == "dryer" {
        nout = "GE_WSM2420D3WW_dry"
        if action == "on" || action == "off"{
            aout = append(aout,"Off")
            aout = append(aout,"Regular")
        }
    } else if name == "baker" {
        nout = "Kenmore_790_0x2E_91312013"
        if action == "on" || action == "off" || action == "bake" || action == "broil"{
            aout = append(aout,"Off")
            aout = append(aout,"Bake")
        }
    }  else if name == "dishwasher" {
        nout = "Kenmore_665_0x2E_13242K900"
        if action == "on" || action == "off"{
            aout = append(aout,"Off")
            aout = append(aout,"Wash")
        }
    }
    return nout,aout
}

func goal1q(namein string, actionin string, time int, time_ex int) string {
    
    name,actions := nameactionmap(namein,actionin)
    if len(name)==0 || len(actions)==0 {
        stro := "Device name or action missing"
        audioout(stro)
        return stro
    }
    // fmt.Println(name,actions,time,time_ex,actionin)
    changable := true
//  Loop though all possible 
    v := reflect.ValueOf(myschedule).FieldByName(name)
    for i := 0; i < v.Len(); i++ {
        sche := v.Index(i)
        if i == time-1 {

            a0 := sche.FieldByName(actions[0])
            a1 := sche.FieldByName(actions[1])
            fmt.Println(a0.Int(),a1.Int())
            if a0.Int() == 1 && actionin == "off"{
                a0.Set(reflect.ValueOf(0))
                a1.Set(reflect.ValueOf(1))
                break
            } else if a0.Int() == 0 && actionin == "on"{
                a0.Set(reflect.ValueOf(1))
                a1.Set(reflect.ValueOf(0))
                break
            } else {
                changable = false
                break
            }            
        }
    }
    
    if !changable {
        stro := "The "+ name +" is not "+ actionin +" during that time"
        audioout(stro)
        return stro
    } else {
        for i := 0; i < v.Len(); i++ {
            sche := v.Index(i)
            a0 := sche.FieldByName(actions[0])
            a1 := sche.FieldByName(actions[1])
            if a0.Int() == 1 && i != time && actionin == "on"{
                a0.Set(reflect.ValueOf(0))
                a1.Set(reflect.ValueOf(1))
            
                outfilename := "./output"+ strconv.Itoa(i) +".json"
                jsonData, err := json.Marshal(myschedule)
                jsonFile, err := os.Create(outfilename)
                if err != nil {
                    panic(err)
                }
                defer jsonFile.Close()
                jsonFile.Write(jsonData)
                jsonFile.Close()

                a0.Set(reflect.ValueOf(1))
                a1.Set(reflect.ValueOf(0))
            } else if a0.Int() == 0 && i != time && actionin == "off"{
                a0.Set(reflect.ValueOf(1))
                a1.Set(reflect.ValueOf(0))
            
                outfilename := "./output"+ strconv.Itoa(i) +".json"
                jsonData, err := json.Marshal(myschedule)
                jsonFile, err := os.Create(outfilename)
                if err != nil {
                    panic(err)
                }
                defer jsonFile.Close()
                jsonFile.Write(jsonData)
                jsonFile.Close()

                a0.Set(reflect.ValueOf(0))
                a1.Set(reflect.ValueOf(1))
            }
        }
    }

    var output string
    if changable {
        out, err := exec.Command("matlab", "-nosplash", "-nodesktop", "-nodesktop", "-wait", "-r", "addpath(genpath('solver')); checkall", "-logfile", "log.txt").Output()
        if err != nil {
            log.Fatal(err)
        }
        fmt.Print(out)
        
        // Open the file.
        f, _ := os.Open("log.txt")
        // Create a new Scanner for the file.
        scanner := bufio.NewScanner(f)
        // Loop over all lines in the file and print them.
        linenum := 0
        for scanner.Scan() {
            line := scanner.Text()
            if strings.Contains(line, "time") {
                fmt.Println(line)
                output = output + line
            }
            linenum = linenum + 1    
        }
    }
    audioout(output)
    return output
}

func goal2q(namein string, actionin string, time int, time_ex int) string{

    name,actions := nameactionmap(namein,actionin)
    if len(name)==0 || len(actions)==0 {
        stro := "Device name or action missing"
        audioout(stro)
        return stro
    }
//  Loop though all possible 
    v := reflect.ValueOf(myschedule).FieldByName(name)
    for i := time-1; i < time_ex; i++ {
        sche := v.Index(i)
        a0 := sche.FieldByName(actions[0])
        a1 := sche.FieldByName(actions[1])

        if a0.Int() == 0 && actionin == "off"{
            a0.Set(reflect.ValueOf(1))
            a1.Set(reflect.ValueOf(0))
        } else if a0.Int() == 1 && actionin == "on"{
            a0.Set(reflect.ValueOf(0))
            a1.Set(reflect.ValueOf(1))
        }          
    }
    
    fmt.Println("writing to the json file")
    outfilename := "./newschedule.json"
    jsonData, err := json.Marshal(myschedule)
    jsonFile, err := os.Create(outfilename)
    if err != nil {
        panic(err)
    }
    defer jsonFile.Close()
    jsonFile.Write(jsonData)
    jsonFile.Close()
    stro := "Schedule Modified"
    audioout(stro)
    return stro
}

func goal3q(namein string,actionin string,time int) string{
    name,actions := nameactionmap(namein,actionin)
    if len(name)==0 || len(actions)==0 {
        stro := "Device name or action missing"
        audioout(stro)
        return stro
    }
    changable := true
//  Loop though all possible 
    v := reflect.ValueOf(myschedule).FieldByName(name)
    fmt.Println(time)
    for i := 0; i < v.Len(); i++ {
        sche := v.Index(i)
        if i == time-1 {

            a0 := sche.FieldByName(actions[0])
            a1 := sche.FieldByName(actions[1])
            fmt.Println(a0,a1)
            if a0.Int() == 0 && actionin == "off"{
                a0.Set(reflect.ValueOf(1))
                a1.Set(reflect.ValueOf(0))
                break
            } else if a0.Int() == 1 && actionin == "on"{
                a0.Set(reflect.ValueOf(0))
                a1.Set(reflect.ValueOf(1))
                break
            } else {
                changable = false
                break
            }            
        }
    }
    
    if !changable {
        stro := "The "+ name +" is "+ actionin +" during that time"
        fmt.Println(stro)
        audioout(stro)
        return stro
    } else {
        fmt.Println("writing to the json file")
        outfilename := "./newschedule.json"
        jsonData, err := json.Marshal(myschedule)
        jsonFile, err := os.Create(outfilename)
        if err != nil {
            panic(err)
        }
        defer jsonFile.Close()
        jsonFile.Write(jsonData)
        jsonFile.Close()
        stro := "Schedule Modified"
        audioout(stro)
        return stro
    } 
}

func printsche(namein string, actionin string) string{
    name,_ := nameactionmap(namein,actionin)
    // fmt.Println(name)
    v := reflect.ValueOf(myschedule).FieldByName(name)
    var table []int64
    for i := 0; i < v.Len(); i++ {
        sche := v.Index(i)
        a0 := sche.FieldByName("Off")
        if actionin == "off"{
            table = append(table, a0.Int())
        } else if actionin == "on"{
            table = append(table, 1-a0.Int())
        } else {
            actionin = "on"
            table = append(table, 1-a0.Int())
        }                
    }
    // fmt.Println(table)
    stro := timetable(table)
    if stro != ""{
        newstro := "The "+name+" will be on at "+stro
        audioout(newstro)
        return newstro
    } else {
        newstro := "The "+name+" will not be "+actionin
        audioout(newstro)
        return newstro
    }
    
}

func timetable(table[]int64) string{
    var temp strings.Builder
    for i := range table{
        if table[i]>0 {
            if i<11 {
                temp.WriteString(strconv.Itoa(i+1)+"am ")
            } else if i == 11 {
                temp.WriteString(strconv.Itoa(i+1)+"pm ")
            } else if i<23{
                temp.WriteString(strconv.Itoa(i-11)+"pm ")
            } else {
                temp.WriteString(strconv.Itoa(i-11)+"am ")
            }            
        }
    }
    return temp.String()
}

func removespace(input string) string {
    var strout string
    twords := strings.Split(input, " ")
    for _,tword := range twords {
        strout = strout + tword
    }
    return strout
}

func audioout(input string) {
    speech := htgotts.Speech{Folder: "audio", Language: "en"}
    fmt.Println(input)
    filename := removespace(input)
    speech.Speak(filename, input)
    re.Playing(filename)
}

func writetofile(input string) {
    f, err := os.OpenFile("result.txt", os.O_APPEND|os.O_WRONLY, 0666)
    if err != nil {
        panic(err)
    }

    defer f.Close()

    if _, err = f.WriteString(input+" \n"); err != nil {
        panic(err)
    }
}