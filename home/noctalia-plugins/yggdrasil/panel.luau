--!nonstrict
-- Pop-up with the node's address (copyable), one row per peer with its
-- telemetry and a remove button, and a field to add a peer. Added and removed
-- peers only live in the running daemon: the configured set comes back when
-- yggdrasil restarts.

local ygg = require("./lib/ygg.luau")

local names = ygg.names(noctalia.getConfig("names"))
local state = noctalia.state.get("ygg") or { status = "offline", error = "", peers = {} }
local isOpen = false
local peerInput = ""
-- Bumped to clear the uncontrolled input after a successful add.
local inputRev = 0

local function run(args, okMessage: string)
  local launched = noctalia.runAsync(args, function(result)
    if result.exitCode ~= 0 then
      local err = ygg.trim(result.stderr)
      noctalia.notifyError("Yggdrasil", if err ~= "" then err else ygg.trim(result.stdout))
    else
      noctalia.notify("Yggdrasil", okMessage)
    end
    ygg.requestRefresh()
  end)
  if not launched then
    noctalia.notifyError("Yggdrasil", "yggdrasilctl could not be started")
  end
end

local function addPeer()
  local uri = ygg.trim(peerInput)
  if not ygg.validUri(uri) then
    noctalia.notifyError("Yggdrasil", `Not a peer URI: {uri}`)
    return
  end
  -- One argv entry: no shell, so the URI is never parsed as anything else.
  run({ ygg.CLI, "addPeer", "uri=" .. uri }, `Added {uri}`)
  peerInput = ""
  inputRev += 1
  render()
end

local function field(label: string, value: string)
  return ui.row({ gap = 8, align = "center" }, {
    ui.label({ text = label, fontSize = 12, color = "on_surface_variant" }),
    ui.label({ text = value, fontSize = 12, fontFamily = "monospace", flexGrow = 1, maxLines = 1 }),
  })
end

local function nodeSection()
  if state.status == "offline" then
    return ui.column({ gap = 4 }, {
      ui.label({
        text = if state.error ~= "" then state.error else "No answer from yggdrasilctl.",
        color = "error",
        fontSize = 12,
      }),
      ui.label({
        text = "Is yggdrasil running, and are you in the `yggdrasil` group (re-login after adding)?",
        color = "on_surface_variant",
        fontSize = 11,
      }),
    })
  end

  local node = state.self
  return ui.column({ gap = 4 }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.label({ text = node.address, fontFamily = "monospace", fontWeight = "semibold", flexGrow = 1 }),
      ui.button({
        glyph = "copy",
        variant = "ghost",
        controlSize = "sm",
        tooltip = "Copy address",
        onClick = function()
          if noctalia.copyToClipboard(node.address, "text/plain") then
            noctalia.notify("Yggdrasil", "Address copied")
          end
        end,
      }),
    }),
    field("Subnet", node.subnet),
    field("Routes", tostring(node.routes)),
    field("Version", node.version),
  })
end

local function peerRow(peer)
  local title = names[peer.address] or peer.remote
  if title == "" then
    title = peer.address
  end
  local detail = if peer.up
    then `{ygg.latency(peer.latency)} · up {ygg.uptime(peer.uptime)} · ↓{ygg.bytes(peer.rx)} ↑{ygg.bytes(peer.tx)}`
    else "down"
  local subtitle = peer.address .. (if peer.inbound then " · inbound" else "")

  local text = {
    ui.label({ text = title, fontWeight = "semibold", maxLines = 1 }),
    ui.label({ text = subtitle, fontSize = 11, fontFamily = "monospace", color = "on_surface_variant", maxLines = 1 }),
    ui.label({ text = detail, fontSize = 11, color = "on_surface_variant", maxLines = 1 }),
  }
  if peer.lastError ~= "" then
    table.insert(text, ui.label({ text = peer.lastError, fontSize = 11, color = "error", maxLines = 2 }))
  end

  local children = {
    ui.glyph({
      name = if peer.up then "plug-connected" else "plug-connected-x",
      size = 18,
      color = if peer.up then "primary" else "outline",
    }),
    ui.column({ gap = 2, flexGrow = 1 }, text),
  }
  -- removePeer only knows configured/added outbound URIs.
  if not peer.inbound and peer.remote ~= "" then
    table.insert(
      children,
      ui.button({
        glyph = "trash",
        variant = "ghost",
        controlSize = "sm",
        tooltip = `Remove {peer.remote} (until yggdrasil restarts)`,
        onClick = function()
          run({ ygg.CLI, "removePeer", "uri=" .. peer.remote }, `Removed {peer.remote}`)
        end,
      })
    )
  end

  return ui.row({ key = peer.remote .. "|" .. peer.address, gap = 10, align = "center", paddingV = 4 }, children)
end

function render()
  if not isOpen then
    return
  end
  local style = ygg.STYLES[state.status] or ygg.STYLES.offline

  local rows = {}
  for _, peer in ipairs(state.peers) do
    table.insert(rows, peerRow(peer))
  end
  if #rows == 0 and state.status ~= "offline" then
    table.insert(rows, ui.label({ text = "No peers.", color = "on_surface_variant" }))
  end

  panel.render(ui.column({ gap = 10, padding = 16 }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.glyph({ name = style.glyph, size = 20, color = style.color }),
      ui.label({ text = "Yggdrasil", fontWeight = "bold", fontSize = 15, flexGrow = 1 }),
      ui.label({ text = style.label, color = style.color, fontSize = 12 }),
      ui.button({
        glyph = "refresh",
        variant = "ghost",
        controlSize = "sm",
        tooltip = "Refresh",
        onClick = function()
          ygg.requestRefresh()
        end,
      }),
    }),
    ui.separator({}),
    nodeSection(),
    ui.separator({}),
    ui.label({ text = `Peers ({#state.peers})`, fontWeight = "semibold", fontSize = 12 }),
    ui.scroll({ gap = 2, flexGrow = 1 }, rows),
    ui.separator({}),
    ui.row({ gap = 8, align = "center" }, {
      ui.column({ flexGrow = 1 }, {
        ui.input({
          key = `peer-input-{inputRev}`,
          placeholder = "tcp://host:port",
          controlSize = "sm",
          enabled = state.status ~= "offline",
          onChange = function(text)
            peerInput = text
          end,
          onSubmit = function(text)
            peerInput = text
            addPeer()
          end,
        }),
      }),
      ui.button({
        text = "Add",
        variant = "primary",
        controlSize = "sm",
        enabled = state.status ~= "offline",
        onClick = addPeer,
      }),
    }),
    ui.label({
      text = "Runtime only, lost when yggdrasil restarts. Add to hostModules.yggdrasil.peers to keep.",
      fontSize = 10,
      color = "on_surface_variant",
    }),
  }))
end

noctalia.state.watch("ygg", function(value)
  state = value or { status = "offline", error = "", peers = {} }
  render()
end)

function onOpen()
  isOpen = true
  names = ygg.names(noctalia.getConfig("names"))
  state = noctalia.state.get("ygg") or state
  render()
  ygg.requestRefresh()
end

function onClose()
  isOpen = false
end
