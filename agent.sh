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

# Output as JSON using jq for proper formatting
jq -n \
--arg hostname "$hostname" \
--arg ip "$ip" \
--arg location "$location" \
--arg os_version "$os_version" \
--arg kernel_version "$kernel_version" \
--arg uptime "$uptime" \
--arg ram_total "$ram_total" \
--arg ram_usage "$ram_usage" \
--arg disk_total "$disk_total" \
--arg disk_usage "$disk_usage" \
--arg cpu_model "$cpu_model" \
--arg cpu_usage "$cpu_usage" \
--arg last_ssh "$last_ssh" \
--arg load_average "$load_average" \
--arg logged_in_users "$logged_in_users" \
--arg open_ports "$open_ports" \
--arg docker_containers "$docker_containers" \
--arg updates_available "$updates_available" \
'{
  hostname: $hostname,
  ip: $ip,
  location: $location,
  os_version: $os_version,
  kernel_version: $kernel_version,
  uptime: $uptime,
  ram_total: $ram_total,
  ram_usage: $ram_usage,
  disk_total: $disk_total,
  disk_usage: $disk_usage,
  cpu_model: $cpu_model,
  cpu_usage: $cpu_usage,
  last_ssh: $last_ssh,
  load_average: $load_average,
  logged_in_users: $logged_in_users,
  open_ports: $open_ports,
  docker_containers: $docker_containers,
  updates_available: $updates_available
}'
