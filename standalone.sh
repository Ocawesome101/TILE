#!/bin/bash
# make a standalone `tle' Lua script with no external dependencies
# note that you may need to install the 'bc' package.

cat base.lua | head -n 3 > tle
cat term/iface.lua | head -n -2 >> tle
cat term/kbd.lua | head -n -2 >> tle
cat base.lua | tail -n $(echo "`wc -l base.lua | cut -d ' ' -f1` - 5" | bc) >> tle
chmod +x tle
