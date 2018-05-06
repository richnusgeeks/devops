package main

import (
  "bufio"
  "flag"
  "fmt"
  "io/ioutil"
//  "log"
  "net/http"
  "strconv"
  "strings"
)

func main() {

  esmstr := flag.String("esmstr", "localhost", "IP/Hostname of the ES master with http enabled")
  httprt := flag.String("httprt", "9200", "HTTP port on ES master with http enabled")
  esvrsn := flag.String("esvrsn", "5.5.0", "Elasticsearch version")
  jrevrsn := flag.String("jrevrsn", "1.8.0_152", "JRE version")
  numfds := flag.String("numfds", "65000", "Elasticsearch max file")
  
  flag.Parse()

  endpnt := fmt.Sprintf("http://%s:%s/_cat/nodes?h=name,ip,version,node.role,jdk,ram.max,heap.max,file_desc.max,&s=name", *esmstr, *httprt)
 
  resp, err := http.Get(endpnt)
  if err != nil {
    fmt.Printf("The HTTP request failed with error %s\n", err)
  }
  defer resp.Body.Close()
 
  datab, _ := ioutil.ReadAll(resp.Body)
  datas := string(datab)
  //fmt.Printf("%s", datas)

  scanner := bufio.NewScanner(strings.NewReader(datas))
  for scanner.Scan() {
    line := scanner.Text()
    if strings.Fields(line)[2] != *esvrsn {
      fmt.Printf(" %s %s %s\n", strings.Fields(line)[0],strings.Fields(line)[1],strings.Fields(line)[2])
    }

    if strings.Fields(line)[4] != *jrevrsn {
      fmt.Printf(" %s %s %s\n", strings.Fields(line)[0],strings.Fields(line)[1],strings.Fields(line)[4])
    }

    if strings.Fields(line)[7] > strconv.Atoi((*numfds)) {
      fmt.Printf(" %s %s %s\n", strings.Fields(line)[0],strings.Fields(line)[1],strings.Fields(line)[7])
    }
  }

}
