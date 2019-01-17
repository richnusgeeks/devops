#! /bin/bash

createBigFile() {

  local low=1024
  local high=20480
  # file size = blocks x bs , max file size = 20GB
  local numblks=$((RANDOM%high+low))
  dd if=/dev/zero of=/tmp/hungry4space$(date +%s) count=${numblks} bs=1048576

}

killProcess() {

  true  

}

main() {

  createBigFile
#  killProcess

}

main 2>&1
