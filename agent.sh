#!/bin/bash

# Function to safely get command output
safe_get() {
    output=$($@ 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "N/A"
    else
        echo "$output"
    fi
}

# Collect system information
hostname=$(safe_get hostname)
kernel_version=$(safe_get uname -r)
uptime=$(safe_get uptime -p)
cpu_model=$(safe_get lscpu | grep "Model name" | sed 's/Model name: *//g' | sort -u | paste -sd '/' -)
cpu_usage=$(safe_get top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
ram_total=$(safe_get free -h | awk '/Mem:/ {print $2}')
ram_usage=$(safe_get free -m | awk '/Mem:/ {printf "%.2f%%", $3*100/$2}')
disk_total=$(safe_get df -h / | awk '/\// {print $2}')
disk_usage=$(safe_get df -h / | awk '/\// {print $5}')
last_ssh=$(safe_get last -1 -R | grep -v 'reboot' | awk '{print $4, $5, $6, $7}' | xargs)
load_average=$(safe_get uptime | awk -F'load average:' '{ print $2 }' | sed 's/,//g')
logged_in_users=$(safe_get who | wc -l)
docker_containers=$(safe_get docker ps -q | wc -l)
updates_available=$(safe_get apt list --upgradable 2>/dev/null | grep -c upgradable)

# Get local IP address
local_ip=$(safe_get hostname -I | awk '{print $1}')

# Fetch IP and location information from ipinfo.io
ipinfo=$(curl -s --max-time 5 ipinfo.io)
if [ $? -eq 0 ]; then
    public_ip=$(echo $ipinfo | jq -r '.ip // "N/A"')
    city=$(echo $ipinfo | jq -r '.city // "N/A"')
    region=$(echo $ipinfo | jq -r '.region // "N/A"')
    country=$(echo $ipinfo | jq -r '.country // "N/A"')
    loc=$(echo $ipinfo | jq -r '.loc // "N/A"')
    org=$(echo $ipinfo | jq -r '.org // "N/A"')
else
    public_ip="N/A"
    city="N/A"
    region="N/A"
    country="N/A"
    loc="N/A"
    org="N/A"
fi

# Output as JSON using jq for proper formatting
jq -n \
--arg hostname "$hostname" \
--arg local_ip "$local_ip" \
--arg public_ip "$public_ip" \
--arg city "$city" \
--arg region "$region" \
--arg country "$country" \
--arg loc "$loc" \
--arg org "$org" \
--arg kernel_version "$kernel_version" \
--arg uptime "$uptime" \
--arg cpu_model "$cpu_model" \
--arg cpu_usage "$cpu_usage" \
--arg ram_total "$ram_total" \
--arg ram_usage "$ram_usage" \
--arg disk_total "$disk_total" \
--arg disk_usage "$disk_usage" \
--arg last_ssh "$last_ssh" \
--arg load_average "$load_average" \
--arg logged_in_users "$logged_in_users" \
--arg docker_containers "$docker_containers" \
--arg updates_available "$updates_available" \
'{
  Hostname: $hostname,
  Internal: $local_ip,
  External: $public_ip,
  City: $city,
  Region: $region,
  Country: $country,
  Location: $loc,
  Org: $org,
  Kernel: $kernel_version,
  Uptime: $uptime,
  CPU Model: $cpu_model,
  CPU Usage: $cpu_usage,
  RAM Total: $ram_total,
  RAM Usage: $ram_usage,
  Disk Total: $disk_total,
  Disk Usage: $disk_usage,
  Last SSH: $last_ssh,
  Load Average: $load_average,
  Current Users: $logged_in_users,
  Containers: $docker_containers,
  Available Updates: $updates_available
}'
