// Record Windows Audio project main.go
package record

import (
    "fmt"
    "io/ioutil"
    "log"
    "strings"
    "syscall"
    "time"
    "unsafe"
    "github.com/arbovm/levenshtein"

    // Imports the Google Cloud Speech API client package.
    "golang.org/x/net/context"
    speech "cloud.google.com/go/speech/apiv1"
    speechpb "google.golang.org/genproto/googleapis/cloud/speech/v1"
)

var (
    winmm         = syscall.MustLoadDLL("winmm.dll")
    mciSendString = winmm.MustFindProc("mciSendStringW")
)

var Querys = []string {
    "What is the electricity price at time_step",
    "What is the energy consumption at time_step",
    "What is the schedule of device_id",
    "Will device_id be states at time_step",
    "When will the device_id be charged",
    "What is the battery level of device_id",
    "What is the temperature of room_id",
    "When will the room_id be cleaned",
}
var time_step = []string {
    "midnight","one","two","three","four","five","six","seven","eight",
    "nine","ten","eleven","twelve","now",
}
var day_step = []string {
    "am",
    "pm",
}
var room_id = []string {
    "room one",
    "room two",
}
var device_id = []string {
    "heater",
    "cooler",
    "water heater",
    "vacuum cleaner",
    "car",
    "washer",
    "dryer",
    "oven baker",
    "dishwasher",
}
var states = []string {
    "on",
    "off",
}

type intSlice []int
var temp strings.Builder

func MCIWorker(lpstrCommand string, lpstrReturnString string, uReturnLength int, hwndCallback int) uintptr {
    i, _, _ := mciSendString.Call(uintptr(unsafe.Pointer(syscall.StringToUTF16Ptr(lpstrCommand))),
        uintptr(unsafe.Pointer(syscall.StringToUTF16Ptr(lpstrReturnString))),
        uintptr(uReturnLength), uintptr(hwndCallback))
    return i
}

func Recording(name string) {

    i := MCIWorker("open new type waveaudio alias capture", "", 0, 0)
    if i != 0 {
        log.Fatal("Error Code A: ", i)
    }

    i = MCIWorker("set capture alignment 2 bitspersample 16 samplespersec 44100 channels 1 bytespersec 88200", "", 0, 0)
    if i != 0 {
        log.Fatal("Error Code S: ", i)
    }

    i = MCIWorker("record capture", "", 0, 0)
    if i != 0 {
        log.Fatal("Error Code B: ", i)
    }

    fmt.Println("Listening...")

    time.Sleep(6 * time.Second)

    i = MCIWorker("save capture "+name+".wav", "", 0, 0)
    if i != 0 {
        log.Fatal("Error Code C: ", i)
    }

    i = MCIWorker("close capture", "", 0, 0)
    if i != 0 {
        log.Fatal("Error Code D: ", i)
    }

}

func Playing(name string) {

    i := MCIWorker("open ./audio/"+name+".mp3 type mpegvideo alias song1", "", 0, 0)
    if i != 0 {
        log.Fatal("Error Code pA: ", i)
    }

    i = MCIWorker("play song1 wait", "", 0, 0)
    if i != 0 {
        log.Fatal("Error Code pS: ", i)
    }

    i = MCIWorker("close song1", "", 0, 0)
    if i != 0 {
        log.Fatal("Error Code pB: ", i)
    }
}



// similarity function

func Sim(input string) int {
    simqu := make([]int, len(Querys))
    simts := make([]int, len(time_step))
    // simds := make([]int, len(day_step))
    simdi := make([]int, len(device_id))
    // simri := make([]int, len(room_id))
    simst := make([]int, len(states))
    var output string

    for i, query := range Querys {
        simqu[i] = levenshtein.Distance(input, query)
    }
    output = Querys[pos(simqu, MinIntSlice(simqu))]

    if strings.Contains(output, "time_step") {
        for i, ts := range time_step {
            temp := strings.Replace(output, "time_step", ts, 1)
            simts[i] = levenshtein.Distance(temp, input)
        }

        // for i, ds := range day_step {
        //     temp := output + " " + ds
        //     simds[i] = levenshtein.Distance(temp, input)
        // }
        // output = output + day_step[pos(simds, MinIntSlice(simds))]
    }
    output = strings.Replace(output, "time_step", time_step[pos(simts, MinIntSlice(simts))], 1)

    if strings.Contains(output, "device_id") {
        for i, dname := range device_id {
            temp := strings.Replace(output, "device_id", dname, 1)
            simdi[i] = levenshtein.Distance(temp, input)
        }
    }
    output = strings.Replace(output, "device_id", device_id[pos(simdi, MinIntSlice(simdi))], 1)

    if strings.Contains(output, "states") {
        for i, dname := range states {
            temp := strings.Replace(output, "states", dname, 1)
            simst[i] = levenshtein.Distance(temp, input)
        }
    }
    output = strings.Replace(output, "states", states[pos(simst, MinIntSlice(simst))], 1)

    sim := levenshtein.Distance(output, input)
    if sim>10 {
        fmt.Printf("Did you mean %v\n", output)
        return -1
    } else {
        fmt.Printf("The distance between %v and %v is %v\n",
            input, output, sim)
        return sim
    }
        
}

func MinIntSlice(v []int) (m int) {
    if len(v) > 0 {
        m = v[0]
    }
    for i := 1; i < len(v); i++ {
        if v[i] < m {
            m = v[i]
        }
    }
    return
}


func pos(slice intSlice, value int) int {
    for p, v := range slice {
        if (v == value) {
            return p
        }
    }
    return -1
}

func Recognizing (name string) string {
    ctx := context.Background()
    // Creates a client.
    client, err := speech.NewClient(ctx)
    if err != nil {
        log.Fatalf("Failed to create client: %v", err)
    }
    // Sets the name of the audio file to transcribe.
    filename := "C:/Users/xwa24/cse_project/"+name+".wav"

    // Reads the audio file into memory.
    data, err := ioutil.ReadFile(filename)
    if err != nil {
        log.Fatalf("Failed to read file: %v", err)
    }
    // Detects speech in the audio file.
    resp, err := client.Recognize(ctx, &speechpb.RecognizeRequest{
        Config: &speechpb.RecognitionConfig{
            Encoding:        speechpb.RecognitionConfig_LINEAR16,
            SampleRateHertz: 44100,
            LanguageCode:    "en-US",
        },
        Audio: &speechpb.RecognitionAudio{
            AudioSource: &speechpb.RecognitionAudio_Content{Content: data},
        },
    })
    if err != nil {
        log.Fatalf("failed to recognize: %v", err)
    }
    // Prints the results.
    for _, result := range resp.Results {
        for _, alt := range result.Alternatives {
            fmt.Printf("\"%v\" (confidence=%3f)\n", alt.Transcript, alt.Confidence)
            temp.WriteString(alt.Transcript)
        }
    }
    return(temp.String())
}