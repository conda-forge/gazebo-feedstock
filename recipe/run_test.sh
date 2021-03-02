#!/bin/bash -e

# Run gzserver and check if it starts correctly
# Regression test for https://github.com/RoboStack/ros-noetic/issues/55
gzserver --verbose & 

sleep 5

# Test if gzserver is still running
pgrep -x "gzserver"

# Kill gzserver
pkill gzserver
