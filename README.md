# TILE - the Text-Interface Lua Editor

Usage: `tile.lua [file]`

Somewhat similar to `nano`, but written in Lua and with different commands.  Will attempt to load syntax highlighting for the current file extension from `tile/syntax/$LANG.lua`.\*

Use arrow keys to navigate.

Commands:

 - `alt-H`: toggle syntax highlighting
 - `^N`: open a file for editing
 - `^B`: go to next buffer
 - `^V`: go to previous buffer
 - `^S`: save current buffer
 - `^W`: close current buffer
 - `^Q`: close editor
 - `^F`: find by Lua pattern
 - `^R`: find and replace by Lua pattern
 - `^G`: go to line

\* *disclaimer: syntax highlighting is not yet implemented*
