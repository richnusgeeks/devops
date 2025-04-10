#! /bin/sh

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
echo
)
