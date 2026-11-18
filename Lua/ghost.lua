local MAILBOX = 0x020375d8

local function dump()
  console:log(string.format("active=%d group=%d num=%d x=%d y=%d",
    emu:read8(MAILBOX), emu:read8(MAILBOX + 1), emu:read8(MAILBOX + 2),
    emu:read16(MAILBOX + 4), emu:read16(MAILBOX + 6)))
end

local frames = 0
callbacks:add("frame", function()
  frames = frames + 1
  if frames % 60 == 0 then   -- about once per second
    dump()
  end
end)