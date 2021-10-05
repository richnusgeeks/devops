#! /bin/sh

dockerize -wait tcp://gcpcbtemu:8086

cbt createtable cbt-run-demo
cbt ls
cbt createfamily cbt-run-demo cf1
cbt ls cbt-run-demo
cbt set cbt-run-demo r1 cf1:c1=test-value
cbt read cbt-run-demo
cbt deletetable cbt-run-demo
cbt deleteinstance demo-instance
