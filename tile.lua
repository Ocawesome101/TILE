-- TILE - the Terminal-Interface Lua Editor --

local vt = require("tile/term_iface")
local kbd = require("tile/term_kbd")

local buffers = {{name = "<new>", lines = {"This is a test :)", "A test of my editor!"}}}

-- TODO: may not draw correctly on small terminals or with long buffer names
local function draw_open_buffers(max_width, current)
  vt.set_cursor(1, 1)
  local total = 0
  local max_buffer = 0
  for i=1, #buffers, 1 do
    total = total + #buffers[i].name + 4
    if total > max_width then
      max_buffer = i - 1
    end
  end
  max_buffer = math.max(1, max_buffer)
  local draw = ""
  for i=1, max_buffer, 1 do
    draw = draw .. "\27[36m| \27["..(i == current and 97 or 37).."m" .. buffers[i].name
  end
  draw = draw .. " \27[36m|\27[37m"
  io.write(draw, "\n", string.rep("-", max_width))
end

local function draw_line(line_num, line_text, max_width)
  local write
  if line_text then
    write = string.format("\27[36m%4d\27[37m %s", line_num,
                                   (line_text:sub(#line_text - max_width - 4)))
  else
    write = "\27[96m~\27[37m"
  end
  io.write(write)
end

local function draw_buffer(num, top_line)
  local w, h = vt.get_term_size()
  io.write("\27[2J")
  draw_open_buffers(w, num)
  for i=1, h - 2, 1 do
    vt.set_cursor(1, i + 2)
    draw_line(top_line + i - 1, buffers[num].lines[top_line + i - 1], w)
  end
end

draw_buffer(1, 1)


while true do
  draw_buffer(1,1)
  local key, flags = kbd.get_key()
  flags = flags or {}
  if key == "w" and flags.ctrl then
    io.write("\27[2J")
    os.exit()
  end
end
