--!nonstrict
-- Shared between the poller, widget and panel. Each entry runs in its own VM,
-- so this module is loaded once per entry; only plain data crosses between
-- them, through noctalia.state ("ygg" and "refresh").

local M = {}

M.CLI = "/run/current-system/sw/bin/yggdrasilctl"
M.PANEL = "mbenevides/yggdrasil:panel"

-- Glyph and palette role per state. "isolated" means the daemon answers but
-- no peer is up.
M.STYLES = {
  offline = { glyph = "topology-star-off", color = "outline", label = "Offline" },
  isolated = { glyph = "topology-star-3", color = "tertiary", label = "No peers up" },
  online = { glyph = "topology-star-3", color = "primary", label = "Online" },
}

-- Schemes yggdrasil 0.5 accepts in a peer URI.
local SCHEMES = {
  tcp = true,
  tls = true,
  quic = true,
  ws = true,
  wss = true,
  socks = true,
  sockstls = true,
  unix = true,
}

-- string.gsub returns (string, count); keep only the string.
local function trim(s: string): string
  local out = string.gsub(s, "^%s+", "")
  out = string.gsub(out, "%s+$", "")
  return out
end
M.trim = trim

-- A runAsync result holding `yggdrasilctl -json ...` output: the decoded
-- value, or nil and an error message.
function M.decode(result)
  if result.exitCode ~= 0 then
    local err = trim(result.stderr)
    if err == "" then
      err = trim(result.stdout)
    end
    return nil, if err ~= "" then err else `yggdrasilctl exited with {result.exitCode}`
  end
  local value, err = noctalia.json.decode(result.stdout)
  if value == nil then
    return nil, `invalid yggdrasilctl output: {err}`
  end
  return value
end

-- Peer latency arrives as a Go time.Duration, in nanoseconds.
function M.latency(ns: number?): string
  if not ns or ns <= 0 then
    return "–"
  end
  return string.format("%.1f ms", ns / 1e6)
end

function M.bytes(n: number?): string
  n = n or 0
  local units = { "B", "KiB", "MiB", "GiB", "TiB" }
  local i = 1
  while n >= 1024 and i < #units do
    n /= 1024
    i += 1
  end
  return if i == 1 then `{n} B` else string.format("%.1f %s", n, units[i])
end

function M.uptime(seconds: number?): string
  local s = math.floor(seconds or 0)
  if s < 60 then
    return `{s}s`
  elseif s < 3600 then
    return `{s // 60}m`
  elseif s < 86400 then
    return `{s // 3600}h {(s % 3600) // 60}m`
  end
  return `{s // 86400}d {(s % 86400) // 3600}h`
end

-- The "names" setting, "<address>=<name>" entries, as { [address] = name }.
function M.names(list): { [string]: string }
  local out = {}
  for _, entry in ipairs(list or {}) do
    local address, name = string.match(entry, "^%s*([^=%s]+)%s*=%s*(.-)%s*$")
    if address and name ~= "" then
      out[address] = name
    end
  end
  return out
end

function M.validUri(uri: string): boolean
  if string.find(uri, "%s") then
    return false
  end
  local scheme = string.match(uri, "^(%a+)://.+")
  return scheme ~= nil and SCHEMES[string.lower(scheme)] == true
end

-- Ask the poller for an immediate refresh (it watches this key). Watchers only
-- fire on change, and several entries may ask, so the value has to be fresh.
function M.requestRefresh()
  noctalia.state.set("refresh", math.random())
end

return M
