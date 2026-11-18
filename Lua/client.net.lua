local ROLE = "client"
local PORT = 8888
local HOST_IP = "127.0.0.1"
local MAILBOX = 0x020375d8   -- update from grep
local OUTBOX  = 0x020375e0   -- update from grep

local conn = nil
local inbuf = ""

local function handleLine(line)
  local g, n, x, y = line:match("^(%d+),(%d+),(%d+),(%d+)$")
  if g then
    emu:write8(MAILBOX + 1, tonumber(g))
    emu:write8(MAILBOX + 2, tonumber(n))
    emu:write16(MAILBOX + 4, tonumber(x))
    emu:write16(MAILBOX + 6, tonumber(y))
    emu:write8(MAILBOX, 1)
  end
end

local function onReceived()
  local data, err = conn:receive(1024)
  if data then
    inbuf = inbuf .. data
    for line in inbuf:gmatch("([^\n]*)\n") do
      handleLine(line)
    end
    inbuf = inbuf:match("([^\n]*)$")
  end
end

if ROLE == "host" then
  local server = socket.bind(nil, PORT)
  server:listen()
  server:add("received", function()
    conn = server:accept()
    conn:add("received", onReceived)
    console:log("client connected")
  end)
  console:log("waiting for client...")
else
  local c, err = socket.connect(HOST_IP, PORT)
  if c then
    conn = c
    conn:add("received", onReceived)
    console:log("connected to host")
  else
    console:error("connect failed")
  end
end

local last = ""
local frames = 0
callbacks:add("frame", function()
  frames = frames + 1
  if conn and frames % 6 == 0 then
    local msg = string.format("%d,%d,%d,%d\n",
      emu:read8(OUTBOX + 1), emu:read8(OUTBOX + 2),
      emu:read16(OUTBOX + 4), emu:read16(OUTBOX + 6))
    if msg ~= last then
      conn:send(msg)
      last = msg
    end
  end
end)