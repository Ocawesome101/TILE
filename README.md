# TLE - The Lua Editor

Usage: `tle [file]`

Somewhat similar to `nano`, but written in Lua and with different commands.  Will attempt to load syntax highlighting for the current file extension from `TLE/$EXTENSION.vle` in two places (see below).

Use arrow keys to navigate.

Run `standalone.sh` to generate a standalone TLE script.  Copy (or `ln -s`) `syntax` to `$HOME/.local/share/VLE` or `/usr/share/VLE` to get syntax highlighting support.

*Update Feb 11 2021:  TLE now uses an identical syntax highlighting scheme to VLE, as well as the same file position caching scheme.  This means that if VLE is already installed, syntax highlighting should Just Work(TM).*

Commands:

 - `^T`: reload syntax highlighting
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
