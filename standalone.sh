#!/bin/bash
# make a standalone `tle' Lua script with no external dependencies

set -xe
cat base.lua | head -n 3 > tle
cat lib/iface.lua | head -n -2 >> tle
cat lib/kbd.lua | head -n -2 >> tle
echo "local rc" >> tle
cat lib/tlerc.lua >> tle
cat lib/syntax.lua | head -n -2 >> tle
cat base.lua | tail -n $(echo "`wc -l base.lua | cut -d ' ' -f1` - 7" | bc) >> tle
chmod +x tle
