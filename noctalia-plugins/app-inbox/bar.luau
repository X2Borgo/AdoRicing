--!nonstrict
-- Bar [[widget]]: inbox glyph + total count (DMS AppInbox.qml pill).
-- With show_breakdown on a horizontal bar it renders one chip per enabled
-- provider ("GH 3", "SL 5", ...) like the DMS pill; clicking a chip opens the
-- panel on that provider. Clicking the rest of the capsule toggles the panel.

local C = require("./lib/common.luau")

local PANEL_ID = "alborghi/app-inbox:panel"

local apps = noctalia.state.get("apps") or {}
local total = noctalia.state.get("total") or 0

local function openOn(key)
  noctalia.state.set("requested_provider", key)
  noctalia.togglePanel(PANEL_ID)
end

local function anyError()
  local gh = apps.github
  return gh ~= nil and gh.enabled and gh.loading == false and gh.authenticated == false
end

local function render()
  if noctalia.getConfig("hide_when_zero") == true and total == 0 then
    barWidget.setVisible(false)
    return
  end
  barWidget.setVisible(true)

  local glyph = noctalia.getConfig("glyph")
  if type(glyph) ~= "string" or glyph == "" then
    glyph = "inbox"
  end
  local vertical = barWidget.isVertical()
  local container = vertical and ui.column or ui.row
  local layout = { gap = 4, align = "center" }
  if vertical then
    layout.paddingV = 4
  else
    layout.paddingH = 4
  end

  local children = {}
  if noctalia.getConfig("show_breakdown") == true and not vertical then
    for _, p in ipairs(C.PROVIDERS) do
      local a = apps[p.key]
      if a and a.enabled then
        local key = p.key
        table.insert(children, ui.button({
          key = "chip:" .. key,
          glyph = p.glyph,
          text = p.short .. " " .. tostring(a.count or 0),
          glyphSize = 13,
          fontSize = 11,
          variant = "ghost",
          tooltip = p.label .. ": " .. tostring(a.detail or ""),
          onClick = function()
            openOn(key)
          end,
        }))
      end
    end
  else
    table.insert(children, ui.glyph({ name = glyph, size = 16, color = anyError() and "error" or "on_surface" }))
    table.insert(children, ui.label({ text = tostring(total) }))
  end
  barWidget.render(container(layout, children))

  local rows = {}
  for _, p in ipairs(C.PROVIDERS) do
    local a = apps[p.key]
    if a and a.enabled then
      table.insert(rows, { key = p.label, value = tostring(a.count or 0) .. " · " .. tostring(a.detail or "") })
    end
  end
  barWidget.setTooltip(rows)
end

noctalia.state.watch("apps", function(value)
  apps = value or {}
  total = noctalia.state.get("total") or 0
  render()
end)

render()

function update()
  noctalia.setUpdateInterval(10000)
  render()
end

function onClick()
  noctalia.togglePanel(PANEL_ID)
end
