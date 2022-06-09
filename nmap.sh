#!/bin/bash

# Network scanning and notification by Telegram of new IPś on the network.
# It runs every 60 min and notifies via Telegram if a new IP has been found.
# Also, for new IPś a more aggressive scan is performed, saved and sent via Telegram.

# VARIABLES
work_dir="/home/USER_HERE/bin/nmap"			# CHANGE Work dir
TOKEN="****************************************"	# INSERT BOT TOKEN
ID="*********"						# INSERT USERID Telegram
net="192.168.1.0/24"					# PUT Network to scan

nmap_know="${work_dir}/nmap_know"			# Known IP's
nmap_tmp="${work_dir}/.nmap_tmp"			# Temporary files
nmap_new="${work_dir}/nmap_new"				# Last scan file
logs="local0.info"					# Priority or route to logs

# FUNCTIONS
function send_tel	# Send Telegram message
{
	URL_men="https://api.telegram.org/bot$TOKEN/sendMessage"
	curl -s -X POST $URL_men -d chat_id=$ID -d text="$1"
}

function send_file	# Send file Telegram
{
	URL_arch="https://api.telegram.org/bot$TOKEN/sendDocument"
	curl --fail -F chat_id="$ID" -F document=@"$1" $URL_arch -X POST --progress-bar -o tmp --connect-timeout 0
}

# Create remote directory and first scan

[ -d $work_dir ] || mkdir -pv $work_dir
nmap -sn -T4 -n $net > $nmap_tmp
logger -t NMAP -p $logs -f $nmap_tmp

# This is last scan file to compare with known equipment
cat $nmap_tmp | grep "Nmap scan" | cut -d " " -f 5,6 | sort -n > $nmap_new
cp $nmap_new $nmap_tmp


# A message will be sent by Telegram with each of the new IPś.
# More aggressive scanning will be performed to discover equipment.
[ -f $nmap_know ] || touch $nmap_know
	for ip in `diff $nmap_know $nmap_tmp | grep ">" | cut -d" " -f 2`
	do
	send_tel "$ip es nueva en la red"
	nmap -T4 -sS -A $ip > ${work_dir}/$ip.txt
	send_tel "`cat ${work_dir}/$ip.txt | grep 'MAC Address'`"
	done

# The new IPs are added to the acquaintances file and reordered
cat $nmap_tmp >> $nmap_know
cat $nmap_know | sort -n | uniq > $nmap_tmp
cp $nmap_tmp $nmap_know

# All new team files will be sent by Telegram
for file in `find $work_dir/ -cmin -59 -name "*.txt"`
do
	send_file "$file"
done

