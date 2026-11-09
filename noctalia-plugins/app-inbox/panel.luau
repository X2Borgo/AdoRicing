--!nonstrict
-- [[panel]]: port of AppInboxPopout.qml. Header (provider title + summary,
-- refresh, close), provider tabs, search, filter chips (+ GitHub sort and repo
-- filter), then a list on the left and the selected item's detail on the
-- right with an "Open in ..." action. Clicking a row selects it; the row's
-- open button (the DMS double-click) opens its URL directly.
--
-- Everything provider-specific arrives pre-normalized from service.luau; this
-- file only filters/sorts by the generic fields (search, tags, ts, rank).

local C = require("./lib/common.luau")

local MAX_ROWS = 100

local FILTERS = {
  github = { { "All", "all" }, { "CI failed", "failed" } },
  slack = { { "All", "all" }, { "Unread", "unread" }, { "DMs", "dms" }, { "Channels", "channels" } },
  linear = {
    { "All", "all" }, { "Urgent", "urgent" }, { "High", "high" }, { "Todo", "todo" },
    { "In Progress", "in progress" }, { "In Review", "review" },
  },
  gmail = { { "All", "all" }, { "Unread", "unread" }, { "Important", "important" }, { "Starred", "starred" } },
  calendar = { { "All", "all" }, { "Today", "today" }, { "Next 7 days", "week" } },
  deployments = { { "All", "all" }, { "Problems", "problems" }, { "Docker", "docker" }, { "Kubernetes", "kubernetes" } },
}

local PLACEHOLDER = {
  github = "Search PR number, title, repository, CI...",
  slack = "Search conversation or message...",
  linear = "Search issue number, title, project, status...",
  gmail = "Search sender, subject, message...",
  calendar = "Search event title, location, date...",
  deployments = "Search workload, namespace, image, status...",
}

local isOpen = false
local apps = {}
local items = {}
local activeProvider = "github"
local searchQuery = ""
local searchKeyRev = 0
local activeFilter = "all"
local githubSortFailedFirst = false
local githubRepo = "All repositories"
local selectedUid = nil

local render

local function requestRefresh(provider)
  local prev = noctalia.state.get("refresh_requested")
  local nonce = (type(prev) == "table" and tonumber(prev.nonce) or 0) + 1
  noctalia.state.set("refresh_requested", { provider = provider, nonce = nonce })
end

local function enabledProviders()
  local list = {}
  for _, p in ipairs(C.PROVIDERS) do
    if C.enabled(p.key) then
      table.insert(list, p)
    end
  end
  return list
end

local function resetView()
  searchQuery = ""
  searchKeyRev += 1 -- fresh key clears the uncontrolled input
  activeFilter = "all"
  selectedUid = nil
end

local function setProvider(key)
  if key == activeProvider then
    return
  end
  activeProvider = key
  resetView()
  requestRefresh(key)
  render()
end

local function githubRepos()
  local seen, list = {}, {}
  for _, it in ipairs(items) do
    if it.provider == "github" and it.repo and not seen[it.repo] then
      seen[it.repo] = true
      table.insert(list, it.repo)
    end
  end
  table.sort(list)
  table.insert(list, 1, "All repositories")
  return list
end

local function matchesFilter(it, now)
  local tags = it.tags or {}
  local f = activeFilter
  local p = activeProvider
  if p == "calendar" then
    if (f == "all" or f == "week") and (it.endTs or 0) <= now then
      return false
    end
    if f == "today" and not C.sameDay(it.ts or 0, now) then
      return false
    end
    if f == "week" and (it.ts or 0) > now + 7 * 86400 then
      return false
    end
    return true
  end
  if f == "all" then
    return not (p == "linear" and tags.hidden_all)
  end
  return tags[f] == true
end

local function visibleItems()
  local q = string.lower(noctalia.string.trim(searchQuery))
  local now = os.time()
  local list = {}
  for index, it in ipairs(items) do
    if it.provider == activeProvider then
      local ok = q == "" or string.find(it.search or "", q, 1, true) ~= nil
      if ok and activeProvider == "github" and githubRepo ~= "All repositories" and it.repo ~= githubRepo then
        ok = false
      end
      if ok and matchesFilter(it, now) then
        it._index = index
        table.insert(list, it)
      end
    end
  end
  if activeProvider == "github" then
    table.sort(list, function(a, b)
      if githubSortFailedFirst then
        local af, bf = a.tags.failed == true, b.tags.failed == true
        if af ~= bf then
          return af
        end
      end
      if a.ts ~= b.ts then
        return a.ts > b.ts
      end
      return a._index < b._index
    end)
  elseif activeProvider == "linear" and activeFilter == "all" then
    table.sort(list, function(a, b)
      if a.rank ~= b.rank then
        return a.rank < b.rank
      end
      return a._index < b._index
    end)
  end
  return list
end

local function chip(text, selected, onClick, glyph)
  return ui.button({
    key = "chip:" .. text,
    text = text,
    glyph = glyph,
    controlSize = "sm",
    variant = selected and "primary" or "outline",
    selected = selected,
    onClick = onClick,
  })
end

local function header(app)
  local meta = C.BY_KEY[activeProvider]
  return ui.row({ gap = 12, align = "center" }, {
    ui.glyph({ name = meta.glyph, size = 22, color = "primary" }),
    ui.column({ gap = 0, flexGrow = 1 }, {
      ui.label({ text = meta.title, fontSize = 16, fontWeight = "bold", maxLines = 1 }),
      ui.label({
        text = (app and app.detail) or "",
        fontSize = 11,
        color = "on_surface_variant",
        maxLines = 1,
      }),
    }),
    ui.button({
      glyph = "refresh",
      variant = "primary",
      tooltip = "Refresh",
      enabled = not (app and app.loading),
      onClick = function()
        requestRefresh(activeProvider)
      end,
    }),
    ui.button({ glyph = "settings", variant = "ghost", tooltip = "Settings", onClick = function()
      noctalia.openSettings()
    end }),
    ui.button({ glyph = "close", variant = "primary", tooltip = "Close", onClick = function()
      panel.close()
    end }),
  })
end

local function tabs()
  local children = {}
  for _, p in ipairs(enabledProviders()) do
    local key = p.key
    local a = apps[key]
    local count = a and (key == "calendar" and (a.eventCount or 0) or (a.count or 0)) or 0
    table.insert(children, ui.button({
      key = "tab:" .. key,
      glyph = p.glyph,
      text = p.label .. (count > 0 and (" " .. tostring(count)) or ""),
      controlSize = "sm",
      variant = key == activeProvider and "primary" or "secondary",
      selected = key == activeProvider,
      onClick = function()
        setProvider(key)
      end,
    }))
  end
  table.insert(children, ui.spacer({ flexGrow = 1 }))
  return ui.row({ gap = 6, align = "center" }, children)
end

local function filterRow()
  local children = {}
  for _, f in ipairs(FILTERS[activeProvider] or {}) do
    local value = f[2]
    table.insert(children, chip(f[1], activeFilter == value, function()
      activeFilter = value
      selectedUid = nil
      render()
    end))
  end
  table.insert(children, ui.spacer({ flexGrow = 1 }))
  if activeProvider == "github" then
    local repos = githubRepos()
    local selectedIndex = 0
    for i, r in ipairs(repos) do
      if r == githubRepo then
        selectedIndex = i - 1
      end
    end
    if selectedIndex == 0 then
      githubRepo = "All repositories"
    end
    table.insert(children, ui.select({
      key = "repo-select",
      options = repos,
      selectedIndex = selectedIndex,
      controlSize = "sm",
      width = 220,
      onChange = function(value)
        githubRepo = repos[(tonumber(value) or 0) + 1] or "All repositories"
        selectedUid = nil
        render()
      end,
    }))
    table.insert(children, chip(githubSortFailedFirst and "Failed first" or "Latest", true, function()
      githubSortFailedFirst = not githubSortFailedFirst
      selectedUid = nil
      render()
    end, "arrows-sort"))
  end
  return ui.row({ gap = 6, align = "center" }, children)
end

local function row(it, selected)
  local idChildren = {
    ui.row({ border = "outline", borderWidth = 1, radius = 9, paddingH = 8, paddingV = 3, align = "center", justify = "center" }, {
      ui.label({ text = it.badge or "", fontSize = 11, fontWeight = "bold", color = "primary", maxLines = 1 }),
    }),
  }
  if it.sub then
    local subs = {}
    for _, s in ipairs(it.sub) do
      table.insert(subs, ui.glyph({ name = s.glyph, size = 14, color = s.color }))
    end
    table.insert(idChildren, ui.row({ gap = 4, justify = "center" }, subs))
  end

  local uid = it.uid
  local children = {
    ui.column({ gap = 2, width = 90, align = "center" }, idChildren),
    ui.column({ gap = 3, flexGrow = 1 }, {
      ui.label({ text = it.title or "", fontSize = 13, fontWeight = "medium", maxLines = 1 }),
      ui.label({ text = it.meta or "", fontSize = 11, color = "on_surface_variant", maxLines = 1 }),
    }),
  }
  if it.url and it.url ~= "" then
    table.insert(children, ui.button({
      key = "open:" .. uid,
      glyph = "external-link",
      variant = "ghost",
      controlSize = "sm",
      tooltip = it.openLabel or "Open",
      onClick = function()
        C.openUrl(it.url)
      end,
    }))
  end
  table.insert(children, ui.box({ width = 6, height = 34, radius = 3, fill = it.color or "on_surface_variant" }))

  return ui.row({
    key = "row:" .. uid,
    gap = 10,
    align = "center",
    paddingH = 10,
    paddingV = 8,
    radius = 7,
    fill = selected and "surface_variant" or "surface_variant/0.0",
    onClick = function()
      selectedUid = uid
      render()
    end,
  }, children)
end

local function emptyText(app)
  local p = activeProvider
  if p == "calendar" and app and (not app.configured or (app.error or "") ~= "") then
    return app.detail or ""
  end
  if (p == "gmail" or p == "deployments" or p == "slack") and app then
    return app.detail or ""
  end
  if app and app.loading then
    return "Loading…"
  end
  return "No matching items"
end

local function detail(it)
  if not it then
    return ui.column({ flexGrow = 9, fill = "surface", radius = 8, border = "outline", borderWidth = 1, padding = 12 }, {})
  end
  local children = {
    ui.row({ gap = 8, align = "center" }, {
      ui.row({ border = "outline", borderWidth = 1, radius = 9, paddingH = 8, paddingV = 3, fill = "surface_variant" }, {
        ui.label({ text = it.badge or "", fontSize = 11, fontWeight = "bold", color = "primary" }),
      }),
      ui.label({ text = it.context or "", fontSize = 11, color = "on_surface_variant", maxLines = 1, flexGrow = 1 }),
    }),
    ui.label({ text = it.title or "", fontSize = 16, fontWeight = "bold", maxLines = 4, maxWidth = 380 }),
    ui.label({ text = it.detailMeta or "", fontSize = 11, color = it.color or "on_surface_variant", maxLines = 3, maxWidth = 380 }),
    ui.separator({ thickness = 1, color = "outline" }),
    ui.scroll({ flexGrow = 1 }, {
      ui.label({ key = "body:" .. it.uid, text = it.body or "No description provided.", fontSize = 12, maxWidth = 380 }),
    }),
  }
  if activeProvider ~= "deployments" and it.url and it.url ~= "" then
    table.insert(children, ui.row({}, {
      ui.button({
        glyph = "external-link",
        text = it.openLabel or "Open",
        variant = "primary",
        onClick = function()
          C.openUrl(it.url)
        end,
      }),
      ui.spacer({ flexGrow = 1 }),
    }))
  end
  return ui.column({
    flexGrow = 9,
    gap = 10,
    fill = "surface",
    radius = 8,
    border = "outline",
    borderWidth = 1,
    padding = 12,
  }, children)
end

render = function()
  if not isOpen then
    return
  end
  if not C.enabled(activeProvider) then
    local first = enabledProviders()[1]
    activeProvider = first and first.key or "github"
  end
  local app = apps[activeProvider]
  local list = visibleItems()

  local selected = nil
  for _, it in ipairs(list) do
    if it.uid == selectedUid then
      selected = it
    end
  end
  if not selected and #list > 0 then
    selected = list[1]
    selectedUid = selected.uid
  end

  local rows = {}
  for i, it in ipairs(list) do
    if i > MAX_ROWS then
      break
    end
    table.insert(rows, row(it, it.uid == selectedUid))
  end

  local listPane
  if #list == 0 then
    listPane = ui.column({ flexGrow = 11, align = "center", justify = "center", fill = "surface_variant/0.4", radius = 8, border = "outline", borderWidth = 1, padding = 16 }, {
      ui.label({ text = emptyText(app), color = "on_surface_variant", textAlign = "center", maxLines = 4, maxWidth = 420 }),
    })
  else
    listPane = ui.scroll({ flexGrow = 11, gap = 4, padding = 6, fill = "surface_variant/0.4", radius = 8, border = "outline", borderWidth = 1 }, rows)
  end

  panel.render(ui.column({ flexGrow = 1, gap = 8, padding = 4 }, {
    header(app),
    tabs(),
    ui.input({
      key = "search:" .. activeProvider .. ":" .. searchKeyRev,
      value = searchQuery,
      placeholder = PLACEHOLDER[activeProvider] or "Search...",
      onChange = function(text)
        searchQuery = text or ""
        selectedUid = nil
        render()
      end,
    }),
    filterRow(),
    ui.row({ gap = 8, flexGrow = 1 }, { listPane, detail(selected) }),
  }))
end

local function sync()
  apps = noctalia.state.get("apps") or {}
  items = noctalia.state.get("items") or {}
end

noctalia.state.watch("apps", function()
  sync()
  render()
end)

function onOpen(context)
  sync()
  local requested = noctalia.state.get("requested_provider")
  if type(context) == "string" and C.BY_KEY[context] then
    requested = context
  end
  if type(requested) == "string" and C.BY_KEY[requested] and requested ~= activeProvider then
    activeProvider = requested
    resetView()
  end
  noctalia.state.set("requested_provider", "")
  isOpen = true
  render()
end

function onClose()
  isOpen = false
end
