--!nonstrict
-- The single bar icon: summarises every profile (connected wins over
-- connecting over off) and opens the panel on click.

local vpn = require("./lib/vpn.luau")

local profiles = noctalia.getConfig("profiles") or {}

local function render(vpns)
  vpns = vpns or {}
  local style = vpn.STYLES[vpn.summary(vpns, profiles)]
  barWidget.setGlyph(style.glyph)
  barWidget.setGlyphColor(style.color)

  local lines = { "JumpCloud VPN" }
  for _, profile in ipairs(profiles) do
    local entry = vpns[profile]
    table.insert(lines, `{profile}: {if entry then entry.state else "…"}`)
  end
  barWidget.setTooltip(table.concat(lines, "\n"))
end

noctalia.state.watch("vpns", render)
render(noctalia.state.get("vpns"))

function update()
  -- Everything is pushed by the poller; nothing to do on ticks.
  noctalia.setUpdateInterval(60000)
end

function onClick()
  noctalia.togglePanel(vpn.PANEL)
end
