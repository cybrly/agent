#!/bin/bash

# Collect system information
hostname=$(hostname)
ip=$(hostname -I | awk '{print $1}')
location=$(cat /etc/location 2>/dev/null || echo "Unknown")
os_version=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om)
kernel_version=$(uname -r)
uptime=$(uptime -p)
ram_total=$(free -h | awk '/Mem:/ {print $2}')
ram_usage=$(free -m | awk '/Mem:/ {printf "%.2f%%", $3*100/$2}')
disk_total=$(df -h / | awk '/\// {print $2}')
disk_usage=$(df -h / | awk '/\// {print $5}')
cpu_model=$(lscpu | grep "Model name" | sed 's/Model name: *//g')
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
last_ssh=$(last -1 -R | grep -v 'reboot' | awk '{print $4, $5, $6, $7}')
load_average=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/,//g')
logged_in_users=$(who | wc -l)
open_ports=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2 | sort -u | tr '\n' ',' | sed 's/,$//')
docker_containers=$(docker ps -q | wc -l 2>/dev/null || echo "N/A")
updates_available=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "N/A")

# Output as JSON
echo "{"
echo "  \"hostname\": \"$hostname\","
echo "  \"ip\": \"$ip\","
echo "  \"location\": \"$location\","
echo "  \"os_version\": \"$os_version\","
echo "  \"kernel_version\": \"$kernel_version\","
echo "  \"uptime\": \"$uptime\","
echo "  \"ram_total\": \"$ram_total\","
echo "  \"ram_usage\": \"$ram_usage\","
echo "  \"disk_total\": \"$disk_total\","
echo "  \"disk_usage\": \"$disk_usage\","
echo "  \"cpu_model\": \"$cpu_model\","
echo "  \"cpu_usage\": \"$cpu_usage\","
echo "  \"last_ssh\": \"$last_ssh\","
echo "  \"load_average\": \"$load_average\","
echo "  \"logged_in_users\": $logged_in_users,"
echo "  \"open_ports\": \"$open_ports\","
echo "  \"docker_containers\": \"$docker_containers\","
echo "  \"updates_available\": \"$updates_available\""
echo "}"
