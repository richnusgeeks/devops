#! /bin/sh
(
echo ' <Start of Cloud Big Table Quick Test>'
dockerize -wait tcp://gcpcbtemu:8086

cbt createtable cbt-run-demo
cbt ls
cbt createfamily cbt-run-demo cf1
cbt ls cbt-run-demo
cbt set cbt-run-demo r1 cf1:c1=test-value
cbt read cbt-run-demo
cbt deletetable cbt-run-demo
cbt deleteinstance demo-instance
echo ' <End of Cloud Big Table Quick Test>'
echo
) 2>/dev/null

(
echo ' <Start of Cloud Spanner Quick Test>'
dockerize -wait tcp://gcpcspemu:9020

gcloud spanner instances create test-instance \
  --config=emulator-config --description="Test Instance" --nodes=1
gcloud spanner instances list \
  --configuration=emulator-config
gcloud spanner instances delete test-instance \
  --configuration=emulator-config --quiet
echo ' <End of Cloud Spanner Quick Test>'
)
