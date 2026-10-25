#!/bin/bash
# get values

arch=$(uname -a)
pcpu=$(grep 'physical id' /proc/cpuinfo | sort -u |wc -l)
vcpu=$(grep -c 'processor' /proc/cpuinfo)
memu=$(free -m | awk 'NR==2 {printf "%s/%sMB (%.2f%%)", $3, $2, $3*100/$2}')
disku=$(df -BG / | awk 'NR==2 {gsub("G","",$2); gsub("G","",$3); printf "%s/%sGB (%s)",$3,$2,$5}')
# cpul=$(top -bn1 | grep '%Cpu' | sed 's/.*, *\([0-9.]*\) id.*/\1/' | awk '{printf "%.1f%%", 100 - $1}')
# cpul=$(top -bn1 | grep 'Cpu' | sed 's/,/ /g' | awk '{printf "#CPU load: %.1f%%\n",100-$8}')
cpul=$(top -bn1 | grep 'Cpu' | sed 's/,/ /g' | awk '{for(i=1;i<=NF;i++) if($i==id) printf"%.1f%%\n", 100-&(i-1)}')
lboot=$(who -b | awk '{print $3, $4}')
lvmu=$(lsblk | grep -q 'lvm' && echo yes || echo no)
tcpc=$(ss -tan state established | tail -n +2 | wc -l)
userl=$(who | wc -l)
nw1=$(hostname -I | awk '{printf $1}')
nw2=$(ip link show | awk '/link\/ether/ {printf $2; exit}')
sd=$(journalctl -q _COMM=sudo | grep -c COMMAND)

wall "#Architecture: $arch
#Physical CPU: $pcpu
#vCPU: $vcpu
#Memory Usage: $memu
#Disk Usage: $disku
#CPU load: $cpul
#Last boot: $lboot
#LVM use: $lvmu
#TCP Connections: $tcpc
#User log: $userl
#Network: IP$nw1 $nw2
#Sudo: $sd"