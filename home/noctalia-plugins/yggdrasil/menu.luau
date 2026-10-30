--!nonstrict
-- The single bar icon: mesh state as glyph colour, "<up>/<total>" peers as
-- text, and the node address in the tooltip. Opens the panel on click.

local ygg = require("./lib/ygg.luau")

local function render(state)
  state = state or { status = "offline", error = "", peers = {} }
  local style = ygg.STYLES[state.status] or ygg.STYLES.offline
  barWidget.setGlyph(style.glyph)
  barWidget.setGlyphColor(style.color)

  if state.status == "offline" then
    barWidget.setText("")
    barWidget.setTooltip({
      { "Yggdrasil", style.label },
      { "Error", if state.error ~= "" then state.error else "no answer from yggdrasilctl" },
    })
    return
  end

  local up = 0
  for _, peer in ipairs(state.peers) do
    if peer.up then
      up += 1
    end
  end
  barWidget.setText(`{up}/{#state.peers}`)
  barWidget.setTooltip({
    { "Yggdrasil", style.label },
    { "Address", state.self.address },
    { "Peers", `{up} up of {#state.peers}` },
  })
end

noctalia.state.watch("ygg", render)
render(noctalia.state.get("ygg"))

function update()
  -- Everything is pushed by the poller; nothing to do on ticks.
  noctalia.setUpdateInterval(60000)
end

function onClick()
  noctalia.togglePanel(ygg.PANEL)
end
