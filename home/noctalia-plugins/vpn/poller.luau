--!nonstrict
-- Headless service: polls every profile and publishes
-- state "vpns" = { [profile] = { state = "off"|"connecting"|"connected", detail } }.

local vpn = require("./lib/vpn.luau")

local POLL_MS = 3000

local profiles = noctalia.getConfig("profiles") or {}
local vpns = {}
local inFlight = 0

local function poll()
  -- Skip a tick rather than pile up subprocesses if openvpn3 is slow.
  if inFlight > 0 then
    return
  end
  local function settle()
    inFlight -= 1
    if inFlight == 0 then
      noctalia.state.set("vpns", vpns)
    end
  end

  inFlight = #profiles
  for _, profile in ipairs(profiles) do
    local launched = noctalia.runAsync({ vpn.CLI, profile, "status" }, function(result)
      local state, detail = vpn.parse(result)
      vpns[profile] = { state = state, detail = detail }
      settle()
    end)
    if not launched then
      vpns[profile] = { state = "off", detail = "jumpcloud-vpn could not be started" }
      settle()
    end
  end
end

noctalia.state.watch("refresh", function()
  poll()
end)

function update()
  noctalia.setUpdateInterval(POLL_MS)
  poll()
end

function onConfigChanged()
  profiles = noctalia.getConfig("profiles") or {}
  vpns = {}
  poll()
end
