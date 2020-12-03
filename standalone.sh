#!/bin/bash
# make a standalone `tile' Lua script with no external dependencies

cat tile.lua | head -n 3 > tile_standalone.lua
cat term/iface.lua | head -n -2 >> tile_standalone.lua
cat term/kbd.lua | head -n -2 >> tile_standalone.lua
cat tile.lua | tail -n $(echo "`wc -l tile.lua | cut -d ' ' -f1` - 5" | bc) >> tile_standalone.lua
chmod +x tile_standalone.lua
