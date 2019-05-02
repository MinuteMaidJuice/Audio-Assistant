package input

import (
  "bufio"
  "fmt"
  "log"
  "os"
  "strings"
  "math"
  "sort"
)

var DeviceKeys []string
var TableKeys []string
var ActionKeys []string
var ATableKeys []string
var QuestionKeys []string
var QTableKeys []string

var Dlist = []string {
	"dyson", "bryant", "rheem", "roomba", "tesla", "washer", "dryer", "baker", "dishwasher",
}
var Alist = []string {
	"on", "off", "temp", "battery", "bake", "broil",
}
var Qlist = []string {
	"why", "change", "set", "sche",
}
var time_step = []string {
    "midnight","one","two","three","four","five","six","seven","eight",
    "nine","ten","eleven","twelve","now","1","2","3","4","5","6","7",
    "8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24",
}

func InputT(strin string) []string{
  	lines, err := readLines("device.txt")
  	if err != nil {
    	log.Fatalf("readLines: %s", err)
  	}
  	wcDevice := WordCount(lines)
  	wcTable := WordTable(lines)

  	for keys := range wcDevice {
  		DeviceKeys = append(DeviceKeys, keys)
  	}
  	sort.Strings(DeviceKeys)
  	for keys := range wcTable {
  		TableKeys = append(TableKeys, keys)
  	}
  	sort.Strings(TableKeys)

  	dMatrix := BuildMatrix(wcDevice, wcTable, DeviceKeys)
  	// for i,l := range dMatrix {
  	// 	fmt.Println(i,l)
  	// }
  	// fmt.Println(DeviceKeys)

  	// fmt.Println(similirity(dMatrix, DeviceKeys, "heater", "dyson"))

  	alines, err := readLines("action.txt")
  	if err != nil {
    	log.Fatalf("readLines: %s", err)
  	}
  	wcAction := WordCount(alines)
  	wcATable := WordTable(alines)

  	// fmt.Println(wcAction)
  	// fmt.Println(wcATable)

  	for keys := range wcAction {
  		ActionKeys = append(ActionKeys, keys)
  	}
  	sort.Strings(ActionKeys)
  	// fmt.Println(ActionKeys)
  	for keys := range wcATable {
  		ATableKeys = append(ATableKeys, keys)
  	}
  	sort.Strings(ATableKeys)
  	// fmt.Println(ATableKeys)

  	aMatrix := BuildMatrix(wcAction, wcATable, ActionKeys)
  	// fmt.Println(aMatrix)
  	// fmt.Println(ActionKeys)

  	// fmt.Println(similirity(aMatrix, ActionKeys, "sche", "schedule"))

  	qlines, err := readLines("question.txt")
  	if err != nil {
    	log.Fatalf("readLines: %s", err)
  	}
  	wcQuestion := WordCount(qlines)
  	wcQTable := WordTable(qlines)

  	// fmt.Println(wcAction)
  	// fmt.Println(wcATable)

  	for keys := range wcQuestion {
  		QuestionKeys = append(QuestionKeys, keys)
  	}
  	sort.Strings(QuestionKeys)
  	// fmt.Println(ActionKeys)
  	for keys := range wcQTable {
  		QTableKeys = append(QTableKeys, keys)
  	}
  	sort.Strings(QTableKeys)
  	// fmt.Println(ATableKeys)

  	qMatrix := BuildMatrix(wcQuestion, wcQTable, QuestionKeys)

  	strout := InputTrans(dMatrix, DeviceKeys, aMatrix, ActionKeys, qMatrix, QuestionKeys, strin)
  	return strout
}


// readLines reads a whole file into memory
// and returns a slice of its lines.
func readLines(path string) ([]string, error) {
  	file, err := os.Open(path)
  	if err != nil {
    	return nil, err
  	}
  	defer file.Close()

  	var lines []string
  	scanner := bufio.NewScanner(file)
  	for scanner.Scan() {
    	lines = append(lines, scanner.Text())
  	}
  	return lines, scanner.Err()
}

// writeLines writes the lines to the given file.
func writeLines(lines []string, path string) error {
  	file, err := os.Create(path)
  	if err != nil {
    	return err
  	}
  	defer file.Close()

  	w := bufio.NewWriter(file)
  	for _, line := range lines {
    	fmt.Fprintln(w, line)
  	}
  	return w.Flush()
}

// WordCount returns a map of the counts of each “word” in the string s.
func WordCount(lines []string) map[string]int {
	counts := make(map[string]int)

	for _,line := range lines {
		words := strings.Split(line, ", ")
    	for _, word := range words {
        	counts[word]++
    	}
	}
	
    return counts
}

// WordTable returns a table of same devices
func WordTable(lines []string) map[string][]int {
	counts := make(map[string][]int)

	for i,line := range lines {
		words := strings.Split(line, ", ")
    	for _, word := range words {
        	counts[word] = append(counts[word], i)
    	}
	}
	
    return counts
}

// BuildMatrix returns a similirity matrix of the words
func BuildMatrix(words map[string]int, wordsT map[string][]int, keys []string) [][]float64 {
	matrix := make([][]float64, len(words))
	for k := range matrix {
    	matrix[k] = make([]float64, len(words))
	}
	for i,name1 := range keys {
		for j,name2 := range keys {
			if name1 == name2 {
				matrix[i][j] = 1
			} else {
				combined := make(map[int]int)
				for _,num1 := range wordsT[name1] {
					combined[num1]++
					// fmt.Print(combined)
				}
				for _,num2 := range wordsT[name2] {
					combined[num2]++
					// fmt.Print(combined)
				}
				// if name1 == "heater" && name2 == "hot"{fmt.Println(len(wordsT[name1]),len(wordsT[name2]),len(combined))}
				inter := len(wordsT[name1])+len(wordsT[name2])-len(combined)
				matrix[i][j] = float64(inter)/float64(len(combined))
			}
		}
	}
	return matrix
}

func similirity(m [][]float64, keys []string, a string, b string) float64 {
	sim := 0.0
	sima := 0.0
	simb := 0.0
	aloc := -1
	bloc := -1
	for k,word := range keys {
		if word == a {
			aloc = k
		}
		if word == b {
			bloc = k
		}
	}
	// fmt.Println(aloc,bloc,a,b)
	if aloc < 0 || bloc < 0 {
		return 0
	}
	for j,_ := range m[aloc] {
		sim += m[aloc][j]*m[bloc][j]
		sima += m[aloc][j]*m[aloc][j]
		simb += m[bloc][j]*m[bloc][j]
	}
	// fmt.Println(sim,sima,simb)
	return sim/(math.Sqrt(sima*simb))
}

func InputTrans(dm [][]float64, dkeys []string, am [][]float64, akeys []string, qm [][]float64, qkeys []string, strin string) []string{

	var strout []string
	words := strings.Split(strin, " ")
	dsum := 0.0
	dloc := -1

	for k,device := range Dlist {
		tempsum := 0.0
		for _,word := range words {
			tempsum += similirity(dm, dkeys, word, device)
			// fmt.Println(tempsum)
			// fmt.Println(k,device,word,tempsum)
		}
		if dsum < tempsum {
			dsum = tempsum
			dloc = k
			// fmt.Println(dsum,k)
		}

	}
	if dloc >= 0 {
		strout = append(strout, Dlist[dloc])
	} else {
		strout = append(strout, "none")
	}
	

	asum := 0.0
	aloc := -1

	for k,action := range Alist {
		tempsum := 0.0
		for _,word := range words {
			tempsum += similirity(am, akeys, word, action)
			// fmt.Println(k,action,word,similirity(am, akeys, word, action))
		}
		if asum < tempsum {
			asum = tempsum
			aloc = k
			// fmt.Println(asum,k)
		}
	}
	if aloc >= 0 {
		strout = append(strout, Alist[aloc])
	} else {
		strout = append(strout, "none")
	}

	qsum := 0.0
	qloc := -1

	for k,q := range Qlist {
		tempsum := 0.0
		for _,word := range words {
			tempsum += similirity(qm, qkeys, word, q)
			// fmt.Println(k,q,word,tempsum)
		}
		if qsum < tempsum {
			qsum = tempsum
			qloc = k
			// fmt.Println(asum,k)
		}
	}
	if qloc >= 0 {
		strout = append(strout, Qlist[qloc])
	} else {
		strout = append(strout, "none")
	}

	var time string
	var time_ex string
	count := 0
	for _ , ts := range time_step {
		
        if strings.Contains(strin, ts) && strout[1] != "change"{
            time = ts
        }
        if strings.Contains(strin, ts) && strout[1] == "change" && count == 0 {
            time = ts
            count += 1
        }
        if strings.Contains(strin, ts) && count == 1 {
            time_ex = ts
        }

    }

    if count == 1 {
    	strout = append(strout, time)
    	strout = append(strout, time_ex)
    } else {
    	strout = append(strout, time)
    	strout = append(strout, "none")
    }

 return strout
}


















