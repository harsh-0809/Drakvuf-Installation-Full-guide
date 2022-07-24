#!/usr/bin/env bash

DISPLAY=:0 konsole --new-tab -e bash -c "sudo xl list;sleep 5" &
konsole --noclose --new-tab -e bash -c "gvncviewer localhost" &
konsole --noclose --new-tab -e bash -c "sudo bash /home/pc2/drakvuf/star_up.sh"

