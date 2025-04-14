#!/bin/bash
hyprpicker -r -z &
sleep 0.1
hyprshot -m region --clipboard-only 
wl-paste | swappy -f -
