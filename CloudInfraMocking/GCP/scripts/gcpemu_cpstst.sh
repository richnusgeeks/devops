#! /bin/sh

echo
echo ' <Start of Cloud PubSub Quick Test>'
dockerize -wait tcp://gcpcpsemu:8085

cd python-pubsub/samples/snippets || exit
python3 publisher.py demo create demo
python3 subscriber.py demo create demo demo
python3 publisher.py demo publish demo
python3 subscriber.py demo receive demo 20
echo ' <End of Cloud PubSub Quick Test>'
echo
