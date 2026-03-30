#!/bin/bash
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
RAM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
printf " %0.0f%%   %0.0f%%" "$CPU" "$RAM"
