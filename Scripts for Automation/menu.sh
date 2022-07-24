#!/usr/bin/env bash

echo "

╔═╗╔═╗╔═╗╦═╗  ╔╦╗╔═╗╔═╗╔╦╗
╠═╣║  ╚═╗╠╦╝   ║ ║╣ ╠═╣║║║
╩ ╩╚═╝╚═╝╩╚═   ╩ ╚═╝╩ ╩╩ ╩
                 
"

read -p "Welcome : Press enter to start.." ID

echo "1) To create Vm
2) To destroy Vm
3) To check list of VM
4) To boot VM
5) To start sample tracing
6) Continuos tracing
"

read -p "Enter your choice:" choice 

if [[ $choice -eq 1 ]]
then
 
  sudo xl create /etc/xen/win7.cfg
  ID=$(sudo xl list | grep -oP '(?<=windows7-sp1)[^33]*')
  ID= echo ${ID%%*( )}
  echo "creating VM..."
  echo "creation done..."
elif [[ $choice -eq 2 ]]
then
 
 ID=$(sudo xl list | grep -oP '(?<=windows7-sp1)[^33]*')
 ID= echo ${ID%%*( )}
 sudo xl destroy $ID
 echo "destroying..."
elif [[ $choice -eq 3 ]]
then
  sudo xl list
  ID=$(sudo xl list | grep -oP '(?<=windows7-sp1)[^33]*')
  ID= echo ${ID%%*( )}
  echo $ID
elif [[ $choice -eq 4 ]]
then
  sudo gvncviewer localhost
elif [[ $choice -eq 5 ]]
then
  ID=$(sudo xl list | grep -oP '(?<=windows7-sp1)[^33]*')
  ID= echo ${ID%%*( )}
  # sudo vmi-process-list windows7-sp1
  var = $(sudo vmi-process-list windows7-sp1 | grep -h "explorer.exe" | cut -c 3-6)

  $(sudo ./src/drakvuf -r /root/windows7-sp1.json -d $ID -x socketmon -t 10 -i $var -e "E:\\vundo\\vundo1.exe" > /home/pc-1/Desktop/malware/vundo_network/vundo1.txt && sudo tcpdump -G 10 -W 1 -w "/home/pc-1/Desktop/malware/vundo_network/vundo1.pcap" -i vif9.0-emu  )
  echo "Command Run successfully, Can start Continuos tracing now"
elif [[ $choice -eq 6 ]]
then
 
  
  
  ID=$(sudo xl list | grep -oP '(?<=windows7-sp1)[^33]*' |  cut -c 34)
  ID= echo ${ID%%*( )}
  var=$(sudo vmi-process-list windows7-sp1 | grep -h "explorer.exe" | cut -c 3-6)
  echo "explorer id = $var"
  var1="vif$ID.0-emu"
  for i in {404..500..1}
  do
  echo "Loop Id is = $i"
  $(sudo ./src/drakvuf -r /root/windows7-sp1.json -d $ID -x socketmon -t 120 -i $var -e "E:\\zeroaccess\\zeroaccess$i.exe" > /home/pc2/Desktop/malware/logs_text/zeroaccess$i.txt & sudo tcpdump -G 120 -W 1 -w "/home/pc2/Desktop/malware/logs_network/zeroaccess$i.pcap" -i $var1)
  er=$(sudo head -1 /home/pc2/Desktop/malware/logs_text/zeroaccess$i.txt | sudo grep -o STATUS:Error )

  if [[ "$er" == "STATUS:Error" ]]
   then
     echo "Error Present : $er"
     mv /home/pc2/Desktop/malware/logs_network/zeroaccess$i.pcap /home/pc2/Desktop/malware/logs_network/ne$i.pcap
     mv /home/pc2/Desktop/malware/logs_text/zeroaccess$i.txt /home/pc2/Desktop/malware/logs_text/ne$i.txt
  fi
  sleep 5
  done
  
fi

