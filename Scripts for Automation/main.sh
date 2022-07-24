#!/usr/bin/env bash
sudo xl create /etc/xen/win7.cfg
sleep 80 && DISPLAY=:0 xterm -e bash -c "echo Vm Create Success;sleep 10"
tab="--tab"
cmd="bash -c 'sudo bash /home/pc2/drakvuf/runc.sh';bash"
foo=""

for i in {1..1..1}; do
      foo+=($tab -e "$cmd")   
          
done

gnome-terminal "${foo[@]}"
exit 0
