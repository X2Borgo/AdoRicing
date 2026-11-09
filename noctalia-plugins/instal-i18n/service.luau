--!nonstrict
-- Headless [[service]] entry: the only place that runs the InstalI18n scripts.
-- The scripts are called in place from the `scripts_dir` setting (never copied).
--
-- State keys published:
--   summary        summarize.py JSON {generated, untranslated, fuzzy, obsolete,
--                  worktrees = [{name, repo, branch, untranslated, fuzzy, obsolete}]} or nil
--   main_counts    {untranslated, fuzzy} summed over branch == "main" checkouts only
--                  (feature worktrees carry duplicate catalogs)
--   refreshing     bool, refresh.sh running
--   wt_data        worktrees.py JSON {generated, total, cleanable, dirty,
--                  worktrees = [{name, repo, branch, dirty, ahead, upstream, pr, state}]} or nil
--   wt_refreshing  bool, worktrees.py collect running
--   rev            bumped LAST after every change, watchers key on it
-- State keys consumed (monotonic nonces bumped by the panel):
--   refresh_requested, wt_refresh_requested, dashboard_requested

local tr = noctalia.tr

local lastRefresh = noctalia.state.get("refresh_requested") or 0
local lastWtRefresh = noctalia.state.get("wt_refresh_requested") or 0
local lastDashboard = noctalia.state.get("dashboard_requested") or 0

local function scriptsDir()
  local dir = noctalia.getConfig("scripts_dir")
  if type(dir) ~= "string" or dir == "" then
    dir = "~/Projects/ricing/AdoRicing/dms-plugins/InstalI18n/scripts"
  end
  dir = noctalia.expandPath(dir)
  if dir:sub(-1) ~= "/" then
    dir ..= "/"
  end
  return dir
end

local function bump()
  noctalia.state.set("rev", (noctalia.state.get("rev") or 0) + 1)
end

local function intervalMs()
  local minutes = tonumber(noctalia.getConfig("refresh_interval")) or 30
  return math.max(1, minutes) * 60 * 1000
end

local function decode(result)
  if result.exitCode ~= 0 or result.timedOut or result.stdoutTruncated then
    return nil
  end
  local ok, decoded = pcall(noctalia.json.decode, result.stdout)
  if ok and type(decoded) == "table" then
    return decoded
  end
  return nil
end

local function applySummary(summary)
  local untr, fuzzy = 0, 0
  if type(summary.worktrees) == "table" then
    for _, w in ipairs(summary.worktrees) do
      if w.branch == "main" then
        untr += tonumber(w.untranslated) or 0
        fuzzy += tonumber(w.fuzzy) or 0
      end
    end
  end
  noctalia.state.set("summary", summary)
  noctalia.state.set("main_counts", { untranslated = untr, fuzzy = fuzzy })
end

-- summary.sh: cached data (it runs refresh.sh itself when there is no cache).
local function loadSummary()
  noctalia.runAsync({ scriptsDir() .. "summary.sh" }, function(result)
    local summary = decode(result)
    if summary then
      applySummary(summary)
      bump()
    elseif result.exitCode ~= 0 then
      noctalia.log(`instal-i18n: summary.sh exited {result.exitCode}: {result.stderr}`)
    end
  end)
end

local function refresh()
  if noctalia.state.get("refreshing") then
    return
  end
  noctalia.state.set("refreshing", true)
  bump()
  local started = noctalia.runAsync({ scriptsDir() .. "refresh.sh" }, function(result)
    noctalia.state.set("refreshing", false)
    local summary = decode(result)
    if summary then
      applySummary(summary)
      noctalia.notify(tr("translations.refreshed"))
    else
      local detail = result.exitCode ~= 0 and `exit {result.exitCode}` or nil
      noctalia.notifyError(tr("translations.refresh_failed"), detail)
    end
    bump()
  end)
  if not started then
    noctalia.state.set("refreshing", false)
    noctalia.notifyError(tr("translations.refresh_failed"), "could not start refresh.sh")
    bump()
  end
end

local function loadWorktreesCached()
  noctalia.runAsync({ "python3", scriptsDir() .. "worktrees.py", "cached" }, function(result)
    local data = decode(result)
    if data then
      noctalia.state.set("wt_data", data)
      bump()
    end
  end)
end

local function refreshWorktrees()
  if noctalia.state.get("wt_refreshing") then
    return
  end
  noctalia.state.set("wt_refreshing", true)
  bump()
  local started = noctalia.runAsync({ "python3", scriptsDir() .. "worktrees.py", "collect" }, function(result)
    noctalia.state.set("wt_refreshing", false)
    local data = decode(result)
    if data then
      noctalia.state.set("wt_data", data)
    else
      local detail = result.exitCode ~= 0 and `exit {result.exitCode}` or nil
      noctalia.notifyError(tr("worktrees.scan_failed"), detail)
    end
    bump()
  end)
  if not started then
    noctalia.state.set("wt_refreshing", false)
    noctalia.notifyError(tr("worktrees.scan_failed"), "could not start worktrees.py")
    bump()
  end
end

-- Open the freshest dashboard.html; build it first if missing. open.sh avoids
-- xdg-open (it hangs on this system). The scripts dir is passed as $1 so no
-- dynamic value is spliced into the shell source.
local OPEN_SCRIPT = 'f="${XDG_CACHE_HOME:-$HOME/.cache}/instal-i18n/dashboard.html"; '
  .. '[ -f "$f" ] || "$1refresh.sh" > /dev/null; '
  .. 'exec "$1open.sh" "file://$f"'

local function openDashboard()
  noctalia.runAsync({ "sh", "-c", OPEN_SCRIPT, "sh", scriptsDir() })
end

local function loadAll()
  loadSummary()
  loadWorktreesCached()
end

noctalia.state.watch("refresh_requested", function(value)
  local nonce = tonumber(value) or 0
  if nonce ~= lastRefresh then
    lastRefresh = nonce
    refresh()
  end
end)

noctalia.state.watch("wt_refresh_requested", function(value)
  local nonce = tonumber(value) or 0
  if nonce ~= lastWtRefresh then
    lastWtRefresh = nonce
    refreshWorktrees()
  end
end)

noctalia.state.watch("dashboard_requested", function(value)
  local nonce = tonumber(value) or 0
  if nonce ~= lastDashboard then
    lastDashboard = nonce
    openDashboard()
  end
end)

-- A restarted service must not inherit a stuck in-flight flag.
noctalia.state.set("refreshing", false)
noctalia.state.set("wt_refreshing", false)
noctalia.setUpdateInterval(intervalMs())
loadAll()
bump()

function update()
  loadAll()
end

-- Keeps the service alive across settings edits; re-read config-derived values.
function onConfigChanged()
  noctalia.setUpdateInterval(intervalMs())
  loadAll()
end

function onIpc(event, _payload)
  if event == "refresh" then
    refresh()
  elseif event == "refresh-worktrees" then
    refreshWorktrees()
  elseif event == "dashboard" then
    openDashboard()
  end
end
