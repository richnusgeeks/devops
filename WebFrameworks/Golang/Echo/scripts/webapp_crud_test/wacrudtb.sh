#! /bin/sh

WACRUDSRVR=${WACRUD_SERVER:-wacrudtest}
WACRUDSPRT=${WACRUD_SVRPRT:-8080}

dockerize -wait "tcp://${WACRUDSRVR}:${WACRUDSPRT}"
 
curl -s -X DELETE "${WACRUDSRVR}:${WACRUDSPRT}/employees/45"
echo
curl -s -X GET "${WACRUDSRVR}:${WACRUDSPRT}/employees/5"
echo
curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"name":"pinkfloyd", "salary":"10000000", "age":"55"}' \
  "${WACRUDSRVR}:${WACRUDSPRT}/employees"
echo
curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"name":"ledzeppelin", "salary":"5000000", "age":"53"}' \
  "${WACRUDSRVR}:${WACRUDSPRT}/employees"
echo
curl -s -X POST \
  -H 'Content-Type: application/json' \
  -d '{"name":"blacksabbath", "salary":"2000000", "age":"53"}' \
  "${WACRUDSRVR}:${WACRUDSPRT}/employees"
echo
curl -s -X GET "${WACRUDSRVR}:${WACRUDSPRT}/employees"
echo
curl -s -X PUT \
  -H 'Content-Type: application/json' \
  -d '{"name":"blacksabbath", "salary":"3000000", "age":"53"}' \
  "${WACRUDSRVR}:${WACRUDSPRT}/employees/3"
echo
curl -s -X GET "${WACRUDSRVR}:${WACRUDSPRT}/employees/3"
echo
curl -s -X DELETE "${WACRUDSRVR}:${WACRUDSPRT}/employees/2"
curl -s -X DELETE "${WACRUDSRVR}:${WACRUDSPRT}/employees/3"
echo
curl -s -X GET "${WACRUDSRVR}:${WACRUDSPRT}/employees"
