#!/bin/bash -e

# Run gzserver and check if it starts correctly
# Regression test for https://github.com/RoboStack/ros-noetic/issues/55
echo "Launch gzserver in verbose mode"
gzserver --verbose & 

echo "Sleep for 10 seconds"
sleep 10

echo "Test if gzserver is still running"
pgrep -x "gzserver"

echo "Kill gzserver"
pkill gzserver
