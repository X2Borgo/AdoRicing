--!nonstrict
-- Headless [[service]]: the only entry that talks to providers.
--
-- Each provider adapter mirrors its DMS service (shell/quickshell/Services/*):
-- same commands/scripts, same polling interval, same filtering. Results are
-- normalized here so the panel and widget stay provider-agnostic
-- (quickshell/README.md convention).
--
-- State published:
--   apps   { [key] = { key, name, icon, count, tone, detail, loading,
--                      configured, authenticated, error, enabled } }
--          ("app panel" shape from quickshell/README.md, plus status flags)
--   items  array of normalized items, every provider in one list:
--          { uid, provider, app, icon, title, body, time, priority, color,
--            badge, meta, context, detailMeta, url, search, tags = {..},
--            ts, endTs, rank, sub = { state glyph/priority glyph for Linear } }
--          (app/icon/title/body/time/priority/color = README notification shape)
--   total  number shown on the bar pill
-- State consumed:
--   refresh_requested  { provider = key | "all", nonce = n }
--
-- Secrets are never logged or passed on a command line by this file: Linear's
-- key is read from its file and sent as an HTTP header via noctalia.http; the
-- other providers' secrets are read by the provider's own script / CLI.

local C = require("./lib/common.luau")

local INTERVAL_S = {
  github = 300,
  slack = 60,
  linear = 300,
  gmail = 180,
  calendar = 300,
  deployments = 60,
}
local TIMEOUT_MS = {
  github = 20000,
  slack = 45000,
  linear = 22000,
  gmail = 45000,
  calendar = 30000,
  deployments = 20000,
}

local apps = {}
local itemsByProvider = {}
local lastRun = {}
local inFlight = {}
local generation = {}
local lastNonce = 0
do
  local req = noctalia.state.get("refresh_requested")
  if type(req) == "table" then
    lastNonce = tonumber(req.nonce) or 0
  end
end

local function expand(path)
  return noctalia.expandPath(path or "")
end

local function scriptsDir()
  return expand(noctalia.getConfig("scripts_dir") or "~/Projects/ricing/AdoRicing/noctalia-plugins/app-inbox/scripts")
end

local function secretsDir()
  return expand(noctalia.getConfig("secrets_dir") or "~/.config/DankMaterialShell/secrets")
end

local function python()
  local p = noctalia.getConfig("python")
  if type(p) ~= "string" or p == "" then
    return "/usr/bin/python3"
  end
  return p
end

local function nonEmptyFile(path)
  local info = noctalia.fileInfo(path)
  return info ~= nil and not info.isDir and (info.size or 0) > 0
end

local function decodeStdout(result)
  if result.timedOut then
    return nil, "Request timed out"
  end
  local text = noctalia.string.trim(result.stdout or "")
  if text == "" then
    return nil, nil
  end
  local ok, value = pcall(noctalia.json.decode, text)
  if ok and type(value) == "table" then
    return value, nil
  end
  return nil, nil
end

local function lower(...)
  local parts = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if v ~= nil then
      table.insert(parts, tostring(v))
    end
  end
  return string.lower(table.concat(parts, " "))
end

local function computeTotal()
  local total = 0
  for _, p in ipairs(C.PROVIDERS) do
    local a = apps[p.key]
    if a and a.enabled then
      total += a.count or 0
    end
  end
  return total
end

local function publish()
  local all = {}
  for _, p in ipairs(C.PROVIDERS) do
    if C.enabled(p.key) then
      for _, item in ipairs(itemsByProvider[p.key] or {}) do
        table.insert(all, item)
      end
    end
  end
  noctalia.state.set("items", all)
  noctalia.state.set("total", computeTotal())
  -- apps last: watchers keyed on it see items/total already updated.
  noctalia.state.set("apps", apps)
end

local function setApp(key, fields)
  local meta = C.BY_KEY[key]
  local a = apps[key] or { key = key, name = meta.label, icon = meta.glyph, count = 0, detail = "" }
  for k, v in pairs(fields) do
    a[k] = v
  end
  a.enabled = C.enabled(key)
  apps[key] = a
end

-- Wraps runAsync with generation tracking so a config change mid-flight drops
-- stale callbacks.
local function run(key, argv, onResult)
  local gen = generation[key] or 0
  local started = noctalia.runAsync(argv, function(result)
    if gen ~= (generation[key] or 0) then
      return
    end
    inFlight[key] = false
    onResult(result)
  end, TIMEOUT_MS[key])
  if not started then
    inFlight[key] = false
    onResult({ exitCode = -1, stdout = "", stderr = "could not start " .. tostring(argv[1]), timedOut = false })
  end
end

---------------------------------------------------------------------------
-- GitHub: gh CLI, open PRs authored by me (GitHubService.qml)
---------------------------------------------------------------------------

local GH_QUERY =
  "query($q:String!){search(query:$q,type:ISSUE,first:20){nodes{... on PullRequest{number title body url isDraft updatedAt comments{totalCount} repository{nameWithOwner} commits(last:1){nodes{commit{statusCheckRollup{state}}}}}}}}"

local CI_LABEL = {
  SUCCESS = "CI passed",
  FAILURE = "CI failed",
  ERROR = "CI error",
  PENDING = "CI running",
  EXPECTED = "CI expected",
}
local CI_COLOR = {
  SUCCESS = "#a6e3a1",
  PENDING = "#f9e2af",
  EXPECTED = "#f9e2af",
  FAILURE = "#f38ba8",
  ERROR = "#f38ba8",
}

local function commentLabel(n)
  if n == 0 then
    return "no comments"
  elseif n == 1 then
    return "1 comment"
  end
  return `{n} comments`
end

local function githubFinish(fields, prs)
  local items = {}
  for _, pr in ipairs(prs or {}) do
    if type(pr) == "table" and pr.url then
      local repo = (pr.repository and pr.repository.nameWithOwner) or "GitHub"
      local ci = "NONE"
      local commits = pr.commits and pr.commits.nodes
      if type(commits) == "table" and commits[1] and commits[1].commit and commits[1].commit.statusCheckRollup then
        ci = commits[1].commit.statusCheckRollup.state or "NONE"
      end
      local ts = C.parseIso(pr.updatedAt) or 0
      local comments = (pr.comments and tonumber(pr.comments.totalCount)) or 0
      local ciLabel = CI_LABEL[ci] or "No CI run"
      local detail = commentLabel(comments) .. " • updated " .. C.relative(ts)
      local failed = ci == "FAILURE" or ci == "ERROR"
      local title = pr.title or "Untitled PR"
      table.insert(items, {
        uid = "github:" .. pr.url,
        provider = "github",
        app = "GitHub",
        icon = "git-pull-request",
        badge = "#" .. tostring(pr.number),
        title = title,
        body = (pr.body ~= nil and pr.body ~= "") and pr.body or "No description provided.",
        time = C.relative(ts),
        priority = failed and "high" or "normal",
        color = CI_COLOR[ci] or "on_surface_variant",
        meta = repo .. " · " .. ciLabel .. " · " .. detail,
        context = repo,
        detailMeta = ciLabel .. " · " .. detail .. (pr.isDraft and " · Draft" or ""),
        url = pr.url,
        repo = repo,
        ts = ts,
        search = lower("#" .. tostring(pr.number), title, repo, ciLabel),
        tags = { failed = failed, draft = pr.isDraft == true },
        openLabel = "Open on GitHub",
      })
    end
  end
  itemsByProvider.github = items
  local n = #items
  local detail
  if fields.error and fields.error ~= "" then
    detail = fields.error
  elseif n == 0 then
    detail = "No open PRs authored by you"
  else
    detail = `{n} open PRs · authored by you`
  end
  fields.count = fields.authenticated and n or 0
  fields.detail = detail
  fields.tone = fields.authenticated and "on_surface" or "error"
  fields.loading = false
  setApp("github", fields)
  publish()
end

local function fetchGithub()
  if not noctalia.commandExists("gh") then
    githubFinish({ configured = false, authenticated = false, error = "GitHub CLI is not installed" }, {})
    return
  end
  run("github", { "gh", "auth", "status", "-h", "github.com" }, function(auth)
    if auth.exitCode ~= 0 then
      githubFinish({ configured = true, authenticated = false, error = "Run gh auth login to connect GitHub" }, {})
      return
    end
    inFlight.github = true
    run("github", {
      "gh", "api", "graphql",
      "-f", "query=" .. GH_QUERY,
      "-f", "q=is:pr is:open author:@me archived:false sort:updated-desc",
      "--jq", ".data.search.nodes",
    }, function(result)
      local decoded = nil
      if result.exitCode == 0 then
        decoded = decodeStdout(result)
      end
      if type(decoded) ~= "table" then
        githubFinish({ configured = true, authenticated = true, error = "GitHub PR search failed" }, {})
        return
      end
      githubFinish({ configured = true, authenticated = true, error = "" }, decoded)
    end)
  end)
end

---------------------------------------------------------------------------
-- Slack: slack_inbox.py (keyring tokens via secret-tool) (SlackService.qml)
---------------------------------------------------------------------------

local function fetchSlack()
  local script = scriptsDir() .. "/slack_inbox.py"
  run("slack", { python(), script }, function(result)
    local payload = decodeStdout(result)
    if type(payload) ~= "table" then
      setApp("slack", { authenticated = false, error = "Could not parse Slack response", detail = "Could not parse Slack response", loading = false, tone = "on_surface_variant" })
      publish()
      return
    end
    local configured = payload.configured == true
    local authenticated = payload.authenticated == true
    local err = payload.error or ((result.exitCode ~= 0) and "Slack refresh failed" or "")
    local fields = { configured = configured, authenticated = authenticated, error = err, loading = false }
    if authenticated then
      local workspace = payload.workspace or ""
      local mode = payload.mode or "user"
      local items = {}
      for _, conv in ipairs(payload.rows or {}) do
        local lines = {}
        for _, msg in ipairs(conv.messages or {}) do
          table.insert(lines, tostring(msg.sender) .. ": " .. tostring(msg.text))
        end
        local body = table.concat(lines, "\n\n")
        local activity = tonumber(conv.activity) or 0
        local unread = tonumber(conv.unread) or 0
        local latestTs = tonumber(conv.latest) or 0
        local kind = conv.kind or "Channel"
        table.insert(items, {
          uid = "slack:" .. tostring(conv.id),
          provider = "slack",
          app = "Slack",
          icon = conv.isDm and "message" or "hash",
          badge = tostring(activity),
          title = conv.name or tostring(conv.id),
          body = body ~= "" and body or "No description provided.",
          time = C.relative(math.floor(latestTs)),
          priority = unread > 0 and "high" or "normal",
          color = "#cba6f7",
          meta = kind .. " · " .. `{activity} recent messages`,
          context = workspace ~= "" and workspace or "Slack",
          detailMeta = kind .. " · " .. `{activity} recent messages`,
          url = conv.url,
          ts = latestTs,
          search = lower(conv.name, kind, body),
          tags = { unread = unread > 0, dms = conv.isDm == true, channels = conv.isDm ~= true },
          openLabel = "Open in Slack",
        })
      end
      itemsByProvider.slack = items
      fields.count = tonumber(payload.total) or #items
      fields.workspace = workspace
      fields.user = payload.user or ""
      fields.mode = mode
      if mode == "bot" then
        fields.detail = #items == 0 and "No bot-visible activity in 7 days" or `{#items} active bot-visible conversations`
      else
        fields.detail = #items == 0 and "No recent Slack activity" or `{#items} recent conversations`
      end
      fields.tone = "primary"
    else
      fields.detail = err ~= "" and err or (configured and "Slack authentication failed" or "Slack token required")
      fields.tone = "on_surface_variant"
      fields.count = 0
    end
    setApp("slack", fields)
    publish()
  end)
end

---------------------------------------------------------------------------
-- Linear: GraphQL over noctalia.http, key from <secrets>/linear-api-key
-- (LinearService.qml did this with curl inside sh -c)
---------------------------------------------------------------------------

local LINEAR_QUERY =
  "query AppInbox { viewer { name assignedIssues(first: 50) { nodes { id identifier title description url priority priorityLabel updatedAt dueDate team { name key } project { name } state { name type color } comments(last: 1) { nodes { createdAt user { name } } } } } } }"

local STATE_RANK = { ["in review"] = 0, ["in progress"] = 1, ["todo"] = 2, ["backlog"] = 3 }

local function linearStateGlyph(state)
  if state:find("review", 1, true) then
    return "message-check"
  elseif state:find("progress", 1, true) or state:find("started", 1, true) then
    return "progress"
  elseif state:find("backlog", 1, true) then
    return "archive"
  end
  return "circle-dashed"
end

local PRIORITY_GLYPH = { [1] = "alert-square-rounded", [2] = "chevrons-up", [3] = "equal", [4] = "chevron-down" }
local PRIORITY_COLOR = { [1] = "#f38ba8", [2] = "#f9e2af", [3] = "primary" }

local function linearDone(fields, nodes)
  local items = {}
  local now = os.time()
  for _, issue in ipairs(nodes or {}) do
    local stateType = issue.state and issue.state.type or ""
    if stateType ~= "completed" and stateType ~= "canceled" then
      local stateName = (issue.state and issue.state.name) or "Unknown"
      local stateLower = string.lower(noctalia.string.trim(stateName))
      local priority = tonumber(issue.priority) or 0
      local ts = C.parseIso(issue.updatedAt) or 0
      local context = (issue.project and issue.project.name) or (issue.team and issue.team.name) or "Linear"
      local comments = issue.comments and issue.comments.nodes or {}
      local latest = comments[#comments]
      local commentLabel = ""
      local recentComment = false
      if latest then
        local cts = C.parseIso(latest.createdAt) or 0
        local who = (latest.user and latest.user.name) or "Someone"
        commentLabel = who .. " commented " .. C.relative(cts)
        recentComment = now - cts < 86400
      end
      local updatedLabel = "updated " .. C.relative(ts)
      local priorityLabel = issue.priorityLabel or "No priority"
      local title = issue.title or "Untitled issue"
      local identifier = issue.identifier or ""
      table.insert(items, {
        uid = "linear:" .. tostring(issue.id),
        provider = "linear",
        app = "Linear",
        icon = "subtask",
        badge = identifier,
        title = title,
        body = (issue.description ~= nil and issue.description ~= "") and issue.description or "No description provided.",
        time = C.relative(ts),
        priority = (priority == 1 or priority == 2) and "high" or "normal",
        color = (issue.state and issue.state.color) or "on_surface_variant",
        meta = context .. " · " .. (commentLabel ~= "" and commentLabel or updatedLabel),
        context = context,
        detailMeta = stateName .. " · " .. priorityLabel .. " · " .. (commentLabel ~= "" and commentLabel or updatedLabel),
        url = issue.url,
        ts = ts,
        -- priority 0 ("none") sorts after 4, as in LinearService._priorityRank
        sortPriority = priority == 0 and 5 or priority,
        rank = STATE_RANK[stateLower] or 4,
        dueDate = issue.dueDate or "",
        search = lower(identifier, title, context, stateName, priorityLabel),
        tags = {
          hidden_all = stateLower == "done" or stateLower == "done archive" or stateLower == "duplicate",
          urgent = priority == 1,
          high = priority == 2,
          todo = stateLower:find("todo", 1, true) ~= nil,
          ["in progress"] = stateLower:find("in progress", 1, true) ~= nil,
          review = stateLower:find("review", 1, true) ~= nil,
          recent_comment = recentComment,
        },
        sub = {
          { glyph = linearStateGlyph(stateLower), color = (issue.state and issue.state.color) or "on_surface_variant" },
          { glyph = PRIORITY_GLYPH[priority] or "minus", color = PRIORITY_COLOR[priority] or "on_surface_variant" },
        },
        openLabel = "Open in Linear",
      })
    end
  end
  table.sort(items, function(a, b)
    if a.sortPriority ~= b.sortPriority then
      return a.sortPriority < b.sortPriority
    end
    return a.ts > b.ts
  end)
  itemsByProvider.linear = items
  local n = #items
  fields.count = fields.authenticated and n or 0
  if not fields.configured then
    fields.detail = "Personal API key required"
  elseif fields.error and fields.error ~= "" then
    fields.detail = fields.error
  elseif not fields.authenticated then
    fields.detail = "Linear authentication failed"
  elseif n == 0 then
    fields.detail = "No active issues assigned to you"
  else
    fields.detail = `{n} active issues · assigned to you`
  end
  fields.tone = fields.authenticated and "secondary" or "on_surface_variant"
  fields.loading = false
  setApp("linear", fields)
  publish()
end

local function fetchLinear()
  local keyPath = secretsDir() .. "/linear-api-key"
  if not nonEmptyFile(keyPath) then
    inFlight.linear = false
    linearDone({ configured = false, authenticated = false, error = "" }, {})
    return
  end
  local raw = noctalia.readFile(keyPath)
  local key = raw and (raw:gsub("[\r\n]", "")) or ""
  if key == "" then
    inFlight.linear = false
    linearDone({ configured = false, authenticated = false, error = "" }, {})
    return
  end
  local gen = generation.linear or 0
  local started = noctalia.http({
    url = "https://api.linear.app/graphql",
    method = "POST",
    headers = { "Content-Type: application/json", "Authorization: " .. key },
    body = noctalia.json.encode({ query = LINEAR_QUERY }),
  }, function(res)
    if gen ~= (generation.linear or 0) then
      return
    end
    inFlight.linear = false
    if not res.ok or (tonumber(res.status) or 0) >= 400 then
      linearDone({ configured = true, authenticated = false, error = "Linear API request failed" }, {})
      return
    end
    local ok, response = pcall(noctalia.json.decode, res.body or "")
    if not ok or type(response) ~= "table" then
      linearDone({ configured = true, authenticated = false, error = "Could not parse Linear response" }, {})
      return
    end
    local errors = type(response.errors) == "table" and response.errors or {}
    local viewer = response.data and response.data.viewer
    local nodes = viewer and viewer.assignedIssues and viewer.assignedIssues.nodes or {}
    linearDone({
      configured = true,
      authenticated = viewer ~= nil and #errors == 0,
      error = errors[1] and errors[1].message or "",
      viewer = viewer and viewer.name or "",
    }, nodes)
  end)
  if not started then
    inFlight.linear = false
    linearDone({ configured = true, authenticated = false, error = "Linear API request failed" }, {})
  end
end

---------------------------------------------------------------------------
-- Gmail: gmail_imap.py <secrets>/gmail-address <secrets>/gmail-app-password
-- (GmailService.qml)
---------------------------------------------------------------------------

local function fetchGmail()
  local dir = secretsDir()
  run("gmail", { python(), scriptsDir() .. "/gmail_imap.py", dir .. "/gmail-address", dir .. "/gmail-app-password" }, function(result)
    local payload = decodeStdout(result)
    if type(payload) ~= "table" then
      setApp("gmail", { authenticated = false, error = "Could not parse Gmail response", detail = "Could not parse Gmail response", count = 0, loading = false, tone = "on_surface_variant" })
      publish()
      return
    end
    local configured = payload.configured == true
    local authenticated = payload.authenticated == true
    local err = payload.error or ((result.exitCode ~= 0) and "Gmail request failed" or "")
    local fields = { configured = configured, authenticated = authenticated, error = err, loading = false }
    if authenticated and type(payload.rows) == "table" then
      local items = {}
      local unreadCount = 0
      for i, m in ipairs(payload.rows) do
        if i > 50 then
          break
        end
        local ts = math.floor((tonumber(m.received) or 0) / 1000)
        local unread = m.unread == true
        if unread then
          unreadCount += 1
        end
        local received = C.relative(ts)
        table.insert(items, {
          uid = "gmail:" .. tostring(m.id),
          provider = "gmail",
          app = "Gmail",
          icon = "mail",
          badge = m.starred and "STAR" or "MAIL",
          title = m.subject or "No subject",
          body = (m.snippet ~= nil and m.snippet ~= "") and m.snippet or "No description provided.",
          time = received,
          priority = (m.important or m.starred) and "high" or "normal",
          color = m.starred and "#f9e2af" or "#f38ba8",
          meta = tostring(m.sender) .. " · " .. received,
          context = (m.senderAddress ~= nil and m.senderAddress ~= "") and m.senderAddress or tostring(m.sender),
          detailMeta = (unread and "Unread" or "Read") .. (m.important and " · Important" or "") .. " · " .. received,
          url = m.url,
          ts = ts,
          search = lower(m.sender, m.senderAddress, m.subject, m.snippet),
          tags = { unread = unread, important = m.important == true, starred = m.starred == true },
          openLabel = "Open in Gmail",
        })
      end
      itemsByProvider.gmail = items
      fields.count = unreadCount
      fields.detail = #items == 0 and "Inbox is empty" or `{unreadCount} unread · {#items} recent messages`
      fields.tone = "primary"
    else
      fields.count = 0
      if not configured then
        fields.detail = "Gmail address and App Password required"
      else
        fields.detail = err ~= "" and err or "Gmail authorization required"
      end
      fields.tone = "on_surface_variant"
    end
    setApp("gmail", fields)
    publish()
  end)
end

---------------------------------------------------------------------------
-- Calendar: uv run --script google_calendar_feed.py <secrets>/google-calendar-ical-url
-- (AppCalendarService.qml)
---------------------------------------------------------------------------

local function calendarDone(fields, events)
  local items = {}
  local now = os.time()
  local todayCount = 0
  for _, ev in ipairs(events or {}) do
    if #items >= 100 then
      break
    end
    local startTs = C.parseIso(ev.start) or 0
    local endTs = C.parseIso(ev["end"]) or startTs
    local dayLabel
    if C.sameDay(startTs, now) then
      dayLabel = "Today"
      todayCount += 1
    elseif C.sameDay(startTs, now + 86400) then
      dayLabel = "Tomorrow"
    else
      dayLabel = os.date("%a, %b %d", startTs)
    end
    local timeLabel = ev.allDay and "All day" or (os.date("%H:%M", startTs) .. "–" .. os.date("%H:%M", endTs))
    local location = ev.location or ""
    table.insert(items, {
      uid = "calendar:" .. tostring(ev.id),
      provider = "calendar",
      app = "Calendar",
      icon = "calendar-event",
      badge = dayLabel,
      title = ev.title or "Untitled event",
      body = (ev.description ~= nil and ev.description ~= "") and ev.description or "No description provided.",
      time = dayLabel .. " " .. timeLabel,
      priority = dayLabel == "Today" and "high" or "normal",
      color = "#f38ba8",
      meta = timeLabel .. (location ~= "" and (" · " .. location) or ""),
      context = location ~= "" and location or "Google Calendar",
      detailMeta = dayLabel .. " · " .. timeLabel,
      url = (ev.url ~= nil and ev.url ~= "") and ev.url or "https://calendar.google.com/calendar/u/0/r",
      ts = startTs,
      endTs = endTs,
      search = lower(ev.title, location, dayLabel, timeLabel),
      tags = {},
      openLabel = "Open Google Calendar",
    })
  end
  itemsByProvider.calendar = items
  local hasError = fields.error ~= nil and fields.error ~= ""
  fields.count = (fields.configured and not hasError) and todayCount or 0
  fields.eventCount = (fields.configured and not hasError) and #items or 0
  if not fields.configured then
    fields.detail = "Private iCal URL required"
  elseif hasError then
    fields.detail = fields.error
  elseif #items == 0 then
    fields.detail = "No events in the next 30 days"
  else
    fields.detail = `{#items} events in the next 30 days`
  end
  fields.tone = fields.configured and "error" or "on_surface_variant"
  fields.loading = false
  setApp("calendar", fields)
  publish()
end

local function fetchCalendar()
  local urlPath = secretsDir() .. "/google-calendar-ical-url"
  if not nonEmptyFile(urlPath) then
    inFlight.calendar = false
    calendarDone({ configured = false, error = "" }, {})
    return
  end
  local uv = expand("~/.local/bin/uv")
  if not noctalia.fileExists(uv) then
    if noctalia.commandExists("uv") then
      uv = "uv"
    else
      inFlight.calendar = false
      calendarDone({ configured = true, error = "Calendar runtime not found" }, {})
      return
    end
  end
  run("calendar", { uv, "run", "--script", scriptsDir() .. "/google_calendar_feed.py", urlPath }, function(result)
    local payload = result.exitCode == 0 and decodeStdout(result) or nil
    if type(payload) ~= "table" or type(payload.events) ~= "table" then
      -- DMS keeps the previous events on error but reports the error.
      setApp("calendar", { configured = true, error = "Calendar feed request failed", detail = "Calendar feed request failed", count = 0, loading = false })
      publish()
      return
    end
    calendarDone({ configured = true, error = "" }, payload.events)
  end)
end

---------------------------------------------------------------------------
-- Deployments: deployment_status.py (docker ps + kubectl) (DeploymentService.qml)
---------------------------------------------------------------------------

local function fetchDeployments()
  run("deployments", { python(), scriptsDir() .. "/deployment_status.py" }, function(result)
    local payload = decodeStdout(result)
    if type(payload) ~= "table" then
      itemsByProvider.deployments = {}
      setApp("deployments", { count = 0, error = "Could not read deployment status", detail = "Could not read deployment status", loading = false, tone = "primary" })
      publish()
      return
    end
    local context = payload.context or ""
    local items = {}
    for i, row in ipairs(payload.rows or {}) do
      local docker = row.source == "docker"
      local detail = row.detail or ""
      local sourceLabel = docker and "Docker container" or "Kubernetes pod"
      local body = sourceLabel .. "\nScope: " .. tostring(row.scope) .. "\nStatus: " .. tostring(row.status)
        .. (detail ~= "" and ("\n" .. detail) or "")
      table.insert(items, {
        uid = "deployments:" .. tostring(row.source) .. ":" .. tostring(row.scope) .. ":" .. tostring(row.name) .. ":" .. i,
        provider = "deployments",
        app = "Deploy",
        icon = docker and "brand-docker" or "server",
        badge = tostring(row.id),
        title = row.name or "Unnamed workload",
        body = body,
        time = "",
        priority = row.problem and "high" or "normal",
        color = row.problem and "#f38ba8" or "#a6e3a1",
        meta = tostring(row.scope) .. " · " .. tostring(row.status) .. (detail ~= "" and (" · " .. detail) or ""),
        context = docker and "Local Docker" or context,
        detailMeta = tostring(row.status) .. (detail ~= "" and (" · " .. detail) or ""),
        url = "",
        ts = 0,
        search = lower(row.name, row.source, row.scope, row.status, detail),
        tags = { problems = row.problem == true, docker = docker, kubernetes = row.source == "kubernetes" },
      })
    end
    itemsByProvider.deployments = items
    local problems = tonumber(payload.problemCount) or 0
    local summary
    if problems > 0 then
      summary = `{problems} deployment problems`
    elseif #items > 0 then
      summary = `{#items} workloads healthy`
    elseif (payload.dockerError or "") ~= "" and (payload.kubernetesError or "") ~= "" then
      summary = "Docker and Kubernetes unavailable"
    else
      summary = "No workloads found"
    end
    setApp("deployments", {
      configured = true,
      authenticated = true,
      count = problems,
      error = "",
      detail = summary,
      context = context,
      loading = false,
      tone = problems > 0 and "error" or "primary",
    })
    publish()
  end)
end

---------------------------------------------------------------------------
-- Scheduler
---------------------------------------------------------------------------

local FETCHERS = {
  github = fetchGithub,
  slack = fetchSlack,
  linear = fetchLinear,
  gmail = fetchGmail,
  calendar = fetchCalendar,
  deployments = fetchDeployments,
}

local function start(key, force)
  if not C.enabled(key) then
    return
  end
  if inFlight[key] then
    if not force then
      return
    end
    generation[key] = (generation[key] or 0) + 1
  end
  inFlight[key] = true
  lastRun[key] = os.time()
  setApp(key, { loading = true })
  noctalia.state.set("apps", apps)
  FETCHERS[key]()
end

local function tick()
  local now = os.time()
  for _, p in ipairs(C.PROVIDERS) do
    if (lastRun[p.key] or 0) + INTERVAL_S[p.key] <= now then
      start(p.key, false)
    end
  end
end

local function refreshAll(force)
  for _, p in ipairs(C.PROVIDERS) do
    start(p.key, force)
  end
end

-- Seed placeholders so the UI has a status for every provider immediately.
for _, p in ipairs(C.PROVIDERS) do
  setApp(p.key, { loading = true, detail = "Loading…", count = 0, tone = "on_surface_variant" })
end
publish()

noctalia.state.watch("refresh_requested", function(req)
  if type(req) ~= "table" then
    return
  end
  local nonce = tonumber(req.nonce) or 0
  if nonce == lastNonce then
    return
  end
  lastNonce = nonce
  if req.provider == "all" or req.provider == nil then
    refreshAll(true)
  elseif FETCHERS[req.provider] then
    start(req.provider, true)
  end
end)

noctalia.setUpdateInterval(5000)
refreshAll(false)

function update()
  tick()
end

function onConfigChanged()
  -- Paths or enable flags changed: invalidate in-flight work and refetch.
  for _, p in ipairs(C.PROVIDERS) do
    generation[p.key] = (generation[p.key] or 0) + 1
    inFlight[p.key] = false
    if not C.enabled(p.key) then
      itemsByProvider[p.key] = {}
    end
    setApp(p.key, {})
  end
  publish()
  refreshAll(true)
end

function onIpc(event, payload)
  if event == "refresh" then
    if type(payload) == "string" and FETCHERS[payload] then
      start(payload, true)
    else
      refreshAll(true)
    end
  end
end
