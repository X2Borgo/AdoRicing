--!nonstrict
-- [[panel]] entry: "Instal tools" with a Translations card (refresh + open
-- dashboard) and a read-only Worktrees card (totals + per-worktree state).
-- All process work happens in the service; buttons bump state nonces.

local tr = noctalia.tr
local WT_LIST_MAX_HEIGHT = 300
local FUZZY_FALLBACK = "#E5C07B"

local isOpen = false

local function bumpNonce(key)
  noctalia.state.set(key, (noctalia.state.get(key) or 0) + 1)
end

local function warningColor()
  -- Panel entries cannot read widget settings; mirror the bar's default.
  return FUZZY_FALLBACK
end

local function wtStateLabel(w)
  local s = w.state
  if s == "broken" then
    return tr("worktrees.state.broken")
  elseif s == "dirty" then
    return tr("worktrees.state.dirty")
  elseif s == "unpushed" then
    if w.upstream then
      return tr("worktrees.state.unpushed", { count = w.ahead or 0 })
    end
    return tr("worktrees.state.no_upstream")
  elseif s == "merged-clean" then
    return tr("worktrees.state.merged_clean")
  elseif s == "open-pr" then
    return tr("worktrees.state.open_pr")
  end
  return tr("worktrees.state.no_pr")
end

local function wtStateColor(w)
  local s = w.state
  if s == "broken" or s == "dirty" then
    return "error"
  elseif s == "unpushed" then
    return warningColor()
  elseif s == "merged-clean" then
    return "primary"
  end
  return "on_surface_variant"
end

local function cardHeader(title, subtitle, refreshing, tooltip, nonceKey)
  return ui.row({ gap = 8, align = "center" }, {
    ui.column({ gap = 2, flexGrow = 1 }, {
      ui.label({ text = title, fontSize = 14, fontWeight = "semibold", color = "on_surface" }),
      ui.label({ text = subtitle, fontSize = 11, color = "on_surface_variant", maxLines = 3 }),
    }),
    ui.button({
      glyph = "refresh",
      variant = "ghost",
      tooltip = tooltip,
      enabled = not refreshing,
      onClick = function()
        bumpNonce(nonceKey)
      end,
    }),
  })
end

local function card(children)
  return ui.column({
    gap = 8,
    padding = 12,
    radius = 12,
    fill = "surface_variant/0.35",
    align = "stretch",
  }, children)
end

local function translationsCard()
  local summary = noctalia.state.get("summary")
  local counts = noctalia.state.get("main_counts")
  local refreshing = noctalia.state.get("refreshing") == true

  local subtitle
  if refreshing then
    subtitle = tr("translations.refreshing")
  elseif summary == nil or counts == nil then
    subtitle = tr("translations.no_data")
  else
    subtitle = tr("translations.summary", { untranslated = counts.untranslated, fuzzy = counts.fuzzy })
      .. "\n" .. tr("translations.data_from", { time = summary.generated or "?" })
  end

  return card({
    cardHeader(tr("translations.title"), subtitle, refreshing, tr("translations.refresh_tooltip"), "refresh_requested"),
    ui.row({ align = "center" }, {
      ui.button({
        text = tr("translations.open_dashboard"),
        glyph = "external-link",
        variant = "secondary",
        onClick = function()
          bumpNonce("dashboard_requested")
        end,
      }),
      ui.spacer({ flexGrow = 1 }),
    }),
  })
end

local function worktreesCard()
  local data = noctalia.state.get("wt_data")
  local refreshing = noctalia.state.get("wt_refreshing") == true

  local subtitle
  if refreshing then
    subtitle = tr("worktrees.refreshing")
  elseif data == nil then
    subtitle = tr("translations.no_data")
  else
    subtitle = tr("worktrees.summary", { total = data.total or 0, cleanable = data.cleanable or 0, dirty = data.dirty or 0 })
      .. "\n" .. tr("translations.data_from", { time = data.generated or "?" })
  end

  local children = {
    cardHeader(tr("worktrees.title"), subtitle, refreshing, tr("worktrees.refresh_tooltip"), "wt_refresh_requested"),
  }

  local list = data and data.worktrees
  if type(list) == "table" and #list > 0 then
    local rows = {}
    for _, w in ipairs(list) do
      table.insert(rows, ui.row({ key = `wt:{w.name}`, gap = 8, align = "center", height = 24 }, {
        ui.label({
          text = `{w.name}  ·  {w.branch}`,
          fontSize = 11,
          color = "on_surface",
          maxLines = 1,
          flexGrow = 1,
        }),
        ui.label({ text = wtStateLabel(w), fontSize = 11, fontWeight = "semibold", color = wtStateColor(w) }),
      }))
    end
    table.insert(children, ui.scroll({
      gap = 2,
      align = "stretch",
      height = math.min(#list * 26, WT_LIST_MAX_HEIGHT),
    }, rows))
  end

  return card(children)
end

local function render()
  if not isOpen then
    return
  end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ gap = 8, align = "center" }, {
      ui.image({ path = "assets/amaki-icon.png", width = 20, height = 20, fit = "contain" }),
      ui.label({ text = tr("title"), fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
      ui.button({ glyph = "close", variant = "ghost", onClick = panel.close }),
    }),
    translationsCard(),
    worktreesCard(),
    ui.spacer({ flexGrow = 1 }),
  }))
end

noctalia.state.watch("rev", function()
  render()
end)

function onOpen(_context)
  isOpen = true
  render()
end

function onClose()
  isOpen = false
end
