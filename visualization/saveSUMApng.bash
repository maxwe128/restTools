#!/bin/bash

##############saveSUMApng.bash
prefix=$1
npb=$2

DriveSuma -npb $npb -com viewer_cont -key r
DriveSuma -npb $npb -com recorder_cont -save_as $prefix.png
