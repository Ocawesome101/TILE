# TILE - the Text-Interface Lua Editor

Usage: `tile.lua [file]`

Similar to `nano`, but written in Lua and with different commands.  Will attempt to load syntax highlighting for the current file extension from `tile/syntax/$LANG.lua`.

Use arrow keys to navigate.

Commands:

 - `alt-H`: toggle syntax highlighting
 - `^B`: bring up buffer selection interface
 - `^S`: save current buffer
 - `^W`: close current buffer
 - `^Q`: close editor
 - `^F`: find
 - `^R`: find and replace by Lua pattern
 - `^G`: go to line
