#!/bin/bash

set -u
echo "+--------------------------------------------+"
echo "|                                            |"
echo "|          System Health Check               |"
echo "|                                            |"
echo "+--------------------------------------------+"

echo
echo "Hostname: $(hostname)"

echo 
echo "Current User: $(whoami)"

echo
echo "System Uptime: $(uptime -p)"

echo
echo "Memory Usage:"
free -h

echo
echo "Swap Usage:"
swapon --show


echo 
echo "Disk Usage:"
df -h

echo
echo "CPU Load:"
top -bn1 | grep "load average"

echo
echo "Warning Checks:"

mem_total=$(free | awk '/^Mem:/ {print $2}')
mem_used=$(free | awk '/^Mem:/ {print $3}')
mem_percent=$(awk -v used="$mem_used" -v total="$mem_total" 'BEGIN { printf "%.0f", (used / total) * 100 }')

if [ "$mem_total" -gt 0 ] && [ "$(awk -v p="$mem_percent" 'BEGIN {print (p >= 80) ? 1 : 0}')" -eq 1 ]; then
  echo "WARNING: Memory usage is ${mem_percent}% (threshold: 80%)."
else
  echo "OK: Memory usage is ${mem_percent}% (threshold: 80%)."
fi

disk_used_pct=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$disk_used_pct" -ge 85 ]; then
  echo "WARNING: Disk usage on / is ${disk_used_pct}% (threshold: 85%)."
else
  echo "OK: Disk usage on / is ${disk_used_pct}% (threshold: 85%)."
fi

cpu_count=$(nproc)
load_1m=$(uptime | sed -E 's/.*load average: ([0-9.]+),.*/\1/')

if [ "$cpu_count" -gt 0 ] && awk -v load="$load_1m" -v cores="$cpu_count" 'BEGIN { exit !(load > cores * 0.8) }'; then
  echo "WARNING: CPU load is ${load_1m} on ${cpu_count} cores (threshold: > 80% utilization)."
else
  echo "OK: CPU load is ${load_1m} on ${cpu_count} cores (threshold: > 80% utilization)."
fi

echo
echo "System Health Check Completed."