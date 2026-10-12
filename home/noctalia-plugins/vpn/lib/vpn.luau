--!nonstrict
-- Shared between the poller, widget and panel. Each entry runs in its own VM,
-- so this module is loaded once per entry; only plain data crosses between
-- them, through noctalia.state ("vpns" and "refresh").

local M = {}

M.CLI = "/run/current-system/sw/bin/jumpcloud-vpn"
M.PANEL = "mbenevides/vpn:panel"

-- Glyph and palette role per state.
M.STYLES = {
  off = { glyph = "shield-off", color = "outline" },
  connecting = { glyph = "shield-half", color = "tertiary" },
  connected = { glyph = "shield-check", color = "primary" },
}

-- string.gsub returns (string, count); keep only the string.
local function strip(s: string, pattern: string): string
  local out = string.gsub(s, pattern, "")
  return out
end

-- `jumpcloud-vpn <p> status` prints "<p>: <openvpn3 status line>", with an
-- empty status when there is no session for that profile.
function M.parse(result): (string, string)
  if result.exitCode ~= 0 then
    return "off", strip(result.stderr, "%s+$")
  end
  local detail = strip(strip(result.stdout, "^[^:]*:%s*"), "%s+$")
  if detail == "" then
    return "off", ""
  elseif string.find(detail, "Client connected", 1, true) then
    return "connected", detail
  end
  return "connecting", detail
end

-- The worst-case summary across profiles, for the single bar icon.
function M.summary(vpns, profiles): string
  local overall = "off"
  for _, profile in ipairs(profiles) do
    local entry = vpns[profile]
    if entry and entry.state == "connected" then
      overall = "connected"
    elseif entry and entry.state == "connecting" and overall == "off" then
      overall = "connecting"
    end
  end
  return overall
end

-- Ask the poller for an immediate refresh (it watches this key). Watchers only
-- fire on change, and several entries may ask, so the value has to be fresh.
function M.requestRefresh()
  noctalia.state.set("refresh", math.random())
end

return M
