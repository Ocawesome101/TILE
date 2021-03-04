#!/usr/bin/env lua
-- TLE - The Lua Editor --

local vt = require("lib/iface")
local kbd = require("lib/kbd")
require("lib/tlerc")
local syntax = require("lib/syntax")

local args = {...}

local cbuf = 1
local w, h = 1, 1
local buffers = {}

local function get_abs_path(file)
  local pwd = os.getenv("PWD")
  if file:sub(1,1) == "/" or not pwd then return file end
  return string.format("%s/%s", pwd, file):gsub("[\\/]+", "/")
end

local function read_file(file)
  local handle, err = io.open(file, "r")
  if not handle then
    return ""
  end
  local data = handle:read("a")
  handle:close()
  return data
end

local function write_file(file, data)
  local handle, err = io.open(file, "w")
  if not handle then return end
  handle:write(data)
  handle:close()
end

local function get_last_pos(file)
  local abs = get_abs_path(file)
  local pdata = read_file(os.getenv("HOME") .. "/.vle_positions")
  local pat = abs:gsub("[%[%]%(%)%^%$%%%+%*%*]", "%%%1") .. ":(%d+)\n"
  if pdata:match(pat) then
    local n = tonumber(pdata:match(pat))
    return n or 1
  end
  return 1
end

local function save_last_pos(file, n)
  local abs = get_abs_path(file)
  local escaped = abs:gsub("[%[%]%(%)%^%$%%%+%*%*]", "%%%1")
  local pat = "(" .. escaped .. "):(%d+)\n"
  local vp_path = os.getenv("HOME") .. "/.vle_positions"
  local data = read_file(vp_path)
  if data:match(pat) then
    data = data:gsub(pat, string.format("%%1:%d\n", n))
  else
    data = data .. string.format("%s:%d\n", abs, n)
  end
  write_file(vp_path, data)
end

local commands -- forward declaration so commands and load_file can access this
local function load_file(file)
  local n = #buffers + 1
  buffers[n] = {name=file, cline = 1, cpos = 0, scroll = 1, lines = {}, cache = {}}
  local handle = io.open(file, "r")
  cbuf = n
  if not handle then
    buffers[n].lines[1] = ""
    return
  end
  for line in handle:lines() do
    buffers[n].lines[#buffers[n].lines + 1] =
                                     (line:gsub("[\r\n]", ""):gsub("\t", "  "))
  end
  handle:close()
  buffers[n].cline = math.min(#buffers[n].lines,
    get_last_pos(get_abs_path(file)))
  buffers[n].scroll = math.min(1, buffers[n].cline - h)
  if commands and commands.t then commands.t() end
end

if args[1] == "--help" then
  print("usage: tle [FILE]")
  os.exit()
elseif args[1] then
  for i=1, #args, 1 do
    load_file(args[i])
  end
else
  buffers[1] = {name="<new>", cline = 1, cpos = 0, scroll = 1, lines = {""}, cache = {}}
end

local function truncate_name(n, bn)
  if #n > 16 then
    n = "..." .. (n:sub(-13))
  end
  if buffers[bn].unsaved then n = n .. "*" end
  return n
end

-- TODO: may not draw correctly on small terminals or with long buffer names
local function draw_open_buffers()
  vt.set_cursor(1, 1)
  local draw = "\27[2K\27[46m"
  local dr = ""
  for i=1, #buffers, 1 do
    dr = dr .. truncate_name(buffers[i].name, i) .. "   "
    draw = draw .. "\27[36m \27["..(i == cbuf and "107" or "46")..";30m " .. truncate_name(buffers[i].name, i) .. " \27[46m"
  end
  local diff = string.rep(" ", w - #dr)
  draw = draw .. "\27[46m" .. diff .. "\27[39;49m"
  if #dr:gsub("\27%[[%d.]+m", "") > w then
    draw = draw:sub(1, w)
  end
  io.write(draw, "\27[39;49m")--, "\n\27[G\27[2K\27[36m", string.rep("-", w))
end

local function draw_line(line_num, line_text)
  local write
  if line_text then
    line_text = line_text:gsub("\t", " ")
    if #line_text > (w - 4) then
      line_text = line_text:sub(1, w - 5)
    end
    if buffers[cbuf].highlighter then
      line_text = buffers[cbuf].highlighter(line_text)
    end
    write = string.format("\27[2K\27[36m%4d\27[37m %s", line_num,
                                   line_text)
  else
    write = "\27[2K\27[96m~\27[37m"
  end
  io.write(write)
end

-- dynamically getting dimensions makes the experience slightly nicer for the
-- 2%, at the cost of a rather significant performance drop on slower
-- terminals.  hence, I have removed it.
--
-- to re-enable it, just move the below line inside the draw_buffer() function.
-- you may want to un-comment it.
-- w, h = vt.get_term_size()
local function draw_buffer()
  io.write("\27[39;49m")
  draw_open_buffers()
  local buffer = buffers[cbuf]
  local top_line = buffer.scroll
  for i=1, h - 1, 1 do
    local line = top_line + i - 1
    if (not buffer.cache[line]) or
        (buffer.lines[line] and buffer.lines[line] ~= buffer.cache[line]) then
      vt.set_cursor(1, i + 1)
      draw_line(line, buffer.lines[line])
      buffer.cache[line] = buffer.lines[line] or "~"
    end
  end
end

local function update_cursor()
  local buf = buffers[cbuf]
  local mw = w - 5
  local cx = (#buf.lines[buf.cline] - buf.cpos) + 6
  local cy = buf.cline - buf.scroll + 2
  if cx > mw then
    vt.set_cursor(1, cy)
    draw_line(buf.cline, (buf.lines[buf.cline]:sub(cx - mw + 1, cx)))
    cx = mw
  end
  vt.set_cursor(cx, cy)
end

local arrows -- these forward declarations will kill me someday
local function insert_character(char)
  local buf = buffers[cbuf]
  buf.unsaved = true
  if char == "\n" then
    local text = ""
    local old_cpos = buf.cpos
    if buf.cline > 1 then -- attempt to get indentation of previous line
      local prev = buf.lines[buf.cline]
      local indent = #prev - #(prev:gsub("^[%s]+", ""))
      text = (" "):rep(indent)
    end
    if buf.cpos > 0 then
      text = text .. buf.lines[buf.cline]:sub(-buf.cpos)
      buf.lines[buf.cline] = buf.lines[buf.cline]:sub(1,
                                          #buf.lines[buf.cline] - buf.cpos)
    end
    table.insert(buf.lines, buf.cline + 1, text)
    arrows.down()
    buf.cpos = old_cpos
    return
  end
  local ln = buf.lines[buf.cline]
  if char == "\8" then
    buf.cache[buf.cline] = nil
    buf.cache[buf.cline - 1] = nil
    buf.cache[buf.cline + 1] = nil
    buf.cache[#buf.lines] = nil
    if buf.cpos < #ln then
      buf.lines[buf.cline] = ln:sub(0, #ln - buf.cpos - 1)
                                                  .. ln:sub(#ln - buf.cpos + 1)
    elseif ln == "" then
      if buf.cline > 1 then
        table.remove(buf.lines, buf.cline)
        arrows.up()
        buf.cpos = 0
      end
    elseif buf.cline > 1 then
      local line = table.remove(buf.lines, buf.cline)
      local old_cpos = buf.cpos
      arrows.up()
      buf.cpos = old_cpos
      buf.lines[buf.cline] = buf.lines[buf.cline] .. line
    end
  else
    buf.lines[buf.cline] = ln:sub(0, #ln - buf.cpos) .. char
                                                  .. ln:sub(#ln - buf.cpos + 1)
  end
end

local function trim_cpos()
  if buffers[cbuf].cpos > #buffers[cbuf].lines[buffers[cbuf].cline] then
    buffers[cbuf].cpos = #buffers[cbuf].lines[buffers[cbuf].cline]
  end
  if buffers[cbuf].cpos < 0 then
    buffers[cbuf].cpos = 0
  end
end

local function try_get_highlighter()
  local ext = buffers[cbuf].name:match("%.(.-)$")
  if not ext then
    return
  end
  local try = "/usr/share/VLE/"..ext..".vle"
  local also_try = os.getenv("HOME").."/.local/share/VLE/"..ext..".vle"
  local ok, ret = pcall(syntax.load, also_try)
  if ok then
    return ret
  else
    ok, ret = pcall(syntax.load, try)
    if ok then
      return ret
    else
      ok, ret = pcall(syntax.load, "syntax/"..ext..".vle")
      if ok then
        io.stderr:write("OKAY")
        return ret
      end
    end
  end
  return nil
end

arrows = {
  up = function()
    local buf = buffers[cbuf]
    if buf.cline > 1 then
      local dfe = #(buf.lines[buf.cline] or "") - buf.cpos
      buf.cline = buf.cline - 1
      if buf.cline < buf.scroll and buf.scroll > 0 then
        buf.scroll = buf.scroll - 1
        buf.cache = {}
      end
      buf.cpos = #buf.lines[buf.cline] - dfe
    end
    trim_cpos()
  end,
  down = function()
    local buf = buffers[cbuf]
    if buf.cline < #buf.lines then
      local dfe = #(buf.lines[buf.cline] or "") - buf.cpos
      buf.cline = buf.cline + 1
      if buf.cline > buf.scroll + h - 3 then
        buf.scroll = buf.scroll + 1
        buf.cache = {}
      end
      buf.cpos = #buf.lines[buf.cline] - dfe
    end
    trim_cpos()
  end,
  left = function()
    local buf = buffers[cbuf]
    if buf.cpos < #buf.lines[buf.cline] then
      buf.cpos = buf.cpos + 1
    elseif buf.cline > 1 then
      arrows.up()
      buf.cpos = 0
    end
  end,
  right = function()
    local buf = buffers[cbuf]
    if buf.cpos > 0 then
      buf.cpos = buf.cpos - 1
    elseif buf.cline < #buf.lines then
      arrows.down()
      buf.cpos = #buf.lines[buf.cline]
    end
  end,
  -- not strictly an arrow but w/e
  backspace = function()
    insert_character("\8")
  end
}

-- TODO: clean up this function
local function prompt(text)
  -- box is max(#text, 18)x3
  local box_w = math.max(#text, 18)
  local box_x, box_y = w//2 - (box_w//2), h//2 - 1
  vt.set_cursor(box_x, box_y)
  io.write("\27[46m", string.rep(" ", box_w))
  vt.set_cursor(box_x, box_y)
  io.write("\27[30;46m", text)
  local inbuf = ""
  local function redraw()
    vt.set_cursor(box_x, box_y + 1)
    io.write("\27[46m", string.rep(" ", box_w))
    vt.set_cursor(box_x + 1, box_y + 1)
    io.write("\27[36;40m", inbuf:sub(-(box_w - 2)), string.rep(" ",
                                                          (box_w - 2) - #inbuf))
    vt.set_cursor(box_x, box_y + 2)
    io.write("\27[46m", string.rep(" ", box_w))
    vt.set_cursor(box_x + 1 + math.min(box_w - 2, #inbuf), box_y + 1)
  end
  repeat
    redraw()
    local c, f = kbd.get_key()
    f = f or {}
    if c == "backspace" or (f.ctrl and c == "h") then
      inbuf = inbuf:sub(1, -2)
    elseif not (f.ctrl or f.alt) then
      inbuf = inbuf .. c
    end
  until (c == "m" and (f or {}).ctrl)
  io.write("\27[39;49m")
  buffers[cbuf].cache = {}
  return inbuf
end

local prev_search
commands = {
  b = function()
    if cbuf < #buffers then
      cbuf = cbuf + 1
      buffers[cbuf].cache = {}
    end
  end,
  v = function()
    if cbuf > 1 then
      cbuf = cbuf - 1
      buffers[cbuf].cache = {}
    end
  end,
  f = function()
    local search_pattern = prompt("Search pattern:")
    if #search_pattern == 0 then search_pattern = prev_search end
    prev_search = search_pattern
    for i = buffers[cbuf].cline + 1, #buffers[cbuf].lines, 1 do
      if buffers[cbuf].lines[i]:match(search_pattern) then
        commands.g(i)
        return
      end
    end
    for i = 1, #buffers[cbuf].lines, 1 do
      if buffers[cbuf].lines[i]:match(search_pattern) then
        commands.g(i)
        return
      end
    end
  end,
  g = function(i)
    i = i or tonumber(prompt("Goto line:"))
    i = math.min(i, #buffers[cbuf].lines)
    buffers[cbuf].cline = i
    buffers[cbuf].scroll = i - math.min(i, h // 2)
  end,
  k = function()
    local del = prompt("# of lines to delete:")
    del = tonumber(del)
    if del and del > 0 then
      for i=1, del, 1 do
        local ln = buffers[cbuf].cline
        if ln > #buffers[cbuf].lines then return end
        table.remove(buffers[cbuf].lines, ln)
      end
      buffers[cbuf].cpos = 0
      buffers[cbuf].unsaved = true
      if buffers[cbuf].cline > #buffers[cbuf].lines then
        buffers[cbuf].cline = #buffers[cbuf].lines
      end
    end
  end,
  r = function()
    local search_pattern = prompt("Search pattern:")
    local replace_pattern = prompt("Replace with?")
    for i = 1, #buffers[cbuf].lines, 1 do
      buffers[cbuf].lines[i] = buffers[cbuf].lines[i]:gsub(search_pattern,
                                                                replace_pattern)
    end
  end,
  t = function()
    buffers[cbuf].highlighter = try_get_highlighter()
    buffers[cbuf].cache = {}
  end,
  h = function()
    insert_character("\8")
  end,
  m = function() -- this is how we insert a newline - ^M == "\n"
    insert_character("\n")
  end,
  n = function()
    local file_to_open = prompt("Enter file path:")
    load_file(file_to_open)
  end,
  s = function()
    local ok, err = io.open(buffers[cbuf].name, "w")
    if not ok then
      prompt(err)
      return
    end
    for i=1, #buffers[cbuf].lines, 1 do
      ok:write(buffers[cbuf].lines[i], "\n")
    end
    ok:close()
    save_last_pos(buffers[cbuf].name, buffers[cbuf].cline)
    buffers[cbuf].unsaved = false
  end,
  w = function()
    -- the user may have unsaved work, prompt
    local unsaved
    for i=1, #buffers, 1 do
      if buffers[i].unsaved then
        unsaved = true
       break
      end
    end
    if unsaved then
      local really = prompt("Delete unsaved work? [y/N] ")
      if really ~= "y" then
        return
      end
    end
    table.remove(buffers, cbuf)
    cbuf = math.min(cbuf, #buffers)
    if #buffers == 0 then
      commands.q()
    end
    buffers[cbuf].cache = {}
  end,
  q = function()
    if #buffers > 0 then -- the user may have unsaved work, prompt
      local unsaved
      for i=1, #buffers, 1 do
        if buffers[i].unsaved then
          unsaved = true
          break
        end
      end
      if unsaved then
        local really = prompt("Delete unsaved work? [y/N] ")
        if really ~= "y" then
          return
        end
      end
    end
    io.write("\27[2J\27[1;1H\27[m")
    if os.getenv("TERM") == "paragon" then
      io.write("\27(r\27(L")
    else
      os.execute("stty sane")
    end
    os.exit()
  end
}

for i=1, #buffers, 1 do
  cbuf = i
  buffers[cbuf].highlighter = try_get_highlighter()
end
io.write("\27[2J")
if os.getenv("TERM") == "paragon" then
  io.write("\27(R\27(l\27[8m")
else
  os.execute("stty raw -echo")
end
w, h = vt.get_term_size()

while true do
  draw_buffer()
  update_cursor()
  local key, flags = kbd.get_key()
  flags = flags or {}
  if flags.ctrl then
    if commands[key] then
      commands[key]()
    end
  elseif flags.alt then
  elseif arrows[key] then
    arrows[key]()
  elseif #key == 1 then
    insert_character(key)
  end
end
