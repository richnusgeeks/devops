#! /bin/bash
set -uo pipefail

IPV4ADDRS=${1:-ipv4addrs.txt}

isValidIPv4() {

  local ipv4addr=${1}

  if  ! echo "${ipv4addr}" | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null 2>&1
  then
    return
  fi

  numfld="$(echo "${ipv4addr}"|awk -F "." '{print NF}')"
  if [[ 4 -ne "${numfld}" ]]
  then
    return
  fi  	  

  ipv4addr1="$(echo "${ipv4addr}"|awk -F"." '{print $1}')"
  ipv4addr2="$(echo "${ipv4addr}"|awk -F"." '{print $2}')"
  ipv4addr3="$(echo "${ipv4addr}"|awk -F"." '{print $3}')"
  ipv4addr4="$(echo "${ipv4addr}"|awk -F"." '{print $4}')"

  if [[ ${ipv4addr1} -gt 255 ]] || \
     [[ ${ipv4addr2} -gt 255 ]] || \
     [[ ${ipv4addr3} -gt 255 ]] || \
     [[ ${ipv4addr4} -gt 255 ]]
  then
    return
  fi

  echo "${ipv4addr}"

}

while read addr
do
  isValidIPv4 "${addr}"
done < "${IPV4ADDRS}" | sort | uniq -c | sort -rk1
