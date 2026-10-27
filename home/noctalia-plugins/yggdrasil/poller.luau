--!nonstrict
-- Headless service: polls the node and its peers and publishes
-- state "ygg" = {
--   status = "offline"|"isolated"|"online", error,
--   self = { address, subnet, key, version, routes },
--   peers = { { remote, up, inbound, address, latency, uptime, rx, tx, lastError } },
-- }.

local ygg = require("./lib/ygg.luau")

local POLL_MS = 5000

local inFlight = 0

local function publish(selfInfo, peersInfo, err)
  if selfInfo == nil then
    noctalia.state.set("ygg", { status = "offline", error = err or "", peers = {} })
    return
  end

  local peers = {}
  local up = 0
  for _, p in ipairs((peersInfo and peersInfo.peers) or {}) do
    if p.up then
      up += 1
    end
    table.insert(peers, {
      remote = p.remote or "",
      up = p.up == true,
      inbound = p.inbound == true,
      address = p.address or "",
      latency = p.latency,
      uptime = p.uptime,
      rx = p.bytes_recvd,
      tx = p.bytes_sent,
      lastError = p.last_error or "",
    })
  end
  -- Up first, then by remote, so the list doesn't shuffle between polls.
  table.sort(peers, function(a, b)
    if a.up ~= b.up then
      return a.up
    end
    return a.remote < b.remote
  end)

  noctalia.state.set("ygg", {
    status = if up > 0 then "online" else "isolated",
    -- getSelf answered but getPeers didn't: still worth surfacing.
    error = err or "",
    self = {
      address = selfInfo.address or "",
      subnet = selfInfo.subnet or "",
      key = selfInfo.key or "",
      version = selfInfo.build_version or "",
      routes = selfInfo.routing_entries or 0,
    },
    peers = peers,
  })
end

local function poll()
  -- Skip a tick rather than pile up subprocesses if the daemon is slow.
  if inFlight > 0 then
    return
  end

  local selfInfo, peersInfo, err
  local function settle()
    inFlight -= 1
    if inFlight == 0 then
      publish(selfInfo, peersInfo, err)
    end
  end

  local function query(command: string, store)
    local launched = noctalia.runAsync({ ygg.CLI, "-json", command }, function(result)
      local value, e = ygg.decode(result)
      store(value)
      if e and not err then
        err = e
      end
      settle()
    end)
    if not launched then
      err = err or "yggdrasilctl could not be started"
      settle()
    end
  end

  inFlight = 2
  query("getSelf", function(v)
    selfInfo = v
  end)
  query("getPeers", function(v)
    peersInfo = v
  end)
end

noctalia.state.watch("refresh", function()
  poll()
end)

function update()
  noctalia.setUpdateInterval(POLL_MS)
  poll()
end
