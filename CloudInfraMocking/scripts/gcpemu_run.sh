#! /bin/sh

gcloud beta emulators bigtable start > /var/log/bigtable.log 2>&1 &
gcloud beta emulators pubsub start > /var/log/pubsub.log 2>&1 &
gcloud beta emulators datastore start > /var/log/datastore.log 2>&1 &
gcloud beta emulators firestore start > /var/log/firestore.log 2>&1 &

sleep 5
tail -f /var/log/*.log
