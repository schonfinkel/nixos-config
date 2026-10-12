--!nonstrict
-- Pop-up with one row per profile: status glyph, name, openvpn3 status and a
-- toggle. Connecting goes through jumpcloud-vpn, which opens the JumpCloud
-- login in the browser and sends progress notifications.

local vpn = require("./lib/vpn.luau")

local profiles = noctalia.getConfig("profiles") or {}
local vpns = noctalia.state.get("vpns") or {}
local isOpen = false

local function row(profile: string)
  local entry = vpns[profile] or { state = "off", detail = "" }
  local style = vpn.STYLES[entry.state]

  return ui.row({ key = profile, gap = 10, align = "center", paddingV = 4 }, {
    ui.glyph({ name = style.glyph, size = 20, color = style.color }),
    ui.column({ gap = 2, flexGrow = 1 }, {
      ui.label({ text = profile, fontWeight = "semibold" }),
      ui.label({
        text = if entry.detail ~= "" then entry.detail else entry.state,
        fontSize = 11,
        color = "on_surface_variant",
        maxLines = 1,
      }),
    }),
    ui.toggle({
      checked = entry.state ~= "off",
      onChange = function(value)
        -- Detached: `up` blocks until the browser login finishes, and the
        -- poller reports progress anyway. Show the change right away.
        local action = if value == "true" then "up" else "down"
        vpns[profile] = { state = if action == "up" then "connecting" else "off", detail = "" }
        noctalia.runAsync({ vpn.CLI, profile, action })
        render()
        vpn.requestRefresh()
      end,
    }),
  })
end

function render()
  if not isOpen then
    return
  end
  local rows = {}
  for _, profile in ipairs(profiles) do
    table.insert(rows, row(profile))
  end
  panel.render(ui.column({ gap = 8, padding = 16 }, {
    ui.label({ text = "JumpCloud VPN", fontWeight = "bold", fontSize = 15 }),
    ui.separator({}),
    ui.scroll({ gap = 4, flexGrow = 1 }, rows),
  }))
end

noctalia.state.watch("vpns", function(value)
  vpns = value or {}
  render()
end)

function onOpen()
  isOpen = true
  vpns = noctalia.state.get("vpns") or {}
  render()
  vpn.requestRefresh()
end

function onClose()
  isOpen = false
end
