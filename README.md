# TLE - The Lua Editor

Usage: `tle [file]`

Somewhat similar to `nano`, but written in Lua and with different commands.  Will attempt to load syntax highlighting for the current file extension from `TLE/$LANG.lua` in two places (see below).

Use arrow keys to navigate.

Run `standalone.sh` to generate a standalone TILE script.  Copy `syntax` to `$HOME/.local/share/TLE` or `/usr/share/TLE` to get syntax highlighting.

Commands:

 - `^H`: reload syntax highlighting
 - `^N`: open a file for editing
 - `^B`: go to next buffer
 - `^V`: go to previous buffer
 - `^S`: save current buffer
 - `^W`: close current buffer
 - `^Q`: close editor
 - `^F`: find by Lua pattern
 - `^R`: find and replace by Lua pattern
 - `^G`: go to line
 - `^K`: delete lines
