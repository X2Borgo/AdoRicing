--!nonstrict
-- Bar [[widget]] entry: Amaki logo + count of untranslated + fuzzy strings on
-- the main checkouts. Count tints untranslated_color when anything is
-- untranslated, fuzzy_color when only fuzzy strings remain. No inline buttons,
-- so a click anywhere on the capsule toggles the panel.

local PANEL_ID = "alborghi/instal-i18n:panel"
local ICON = "assets/amaki-icon.png"

local function colorSetting(key, fallback)
  local value = noctalia.getConfig(key)
  if type(value) ~= "string" or value == "" then
    return fallback
  end
  return value
end

local function render()
  local counts = noctalia.state.get("main_counts")
  local refreshing = noctalia.state.get("refreshing") == true

  local text, color = "…", "on_surface"
  if counts ~= nil then
    local untr = counts.untranslated or 0
    local fuzzy = counts.fuzzy or 0
    text = tostring(untr + fuzzy)
    if untr > 0 then
      color = colorSetting("untranslated_color", "error")
    elseif fuzzy > 0 then
      color = colorSetting("fuzzy_color", "#E5C07B")
    end
    barWidget.setTooltip(noctalia.tr("bar.tooltip", { untranslated = untr, fuzzy = fuzzy }))
  end

  local isVertical = barWidget.isVertical()
  local container = isVertical and ui.column or ui.row
  local layout = { gap = 4, align = "center" }
  if isVertical then
    layout.paddingV = 4
  else
    layout.paddingH = 4
  end
  barWidget.render(container(layout, {
    ui.image({ path = ICON, width = 16, height = 16, fit = "contain" }),
    ui.label({ text = text, color = color, opacity = refreshing and 0.6 or 1 }),
  }))
end

noctalia.state.watch("rev", function()
  render()
end)

render()

function onClick()
  noctalia.togglePanel(PANEL_ID)
end

function onConfigChanged()
  render()
end
