--!nonstrict
-- Shared constants and pure helpers for the service, bar widget and panel.

local M = {}

-- Provider order, labels and glyphs, mirroring the DMS popout tabs.
M.PROVIDERS = {
  { key = "github", label = "GitHub", short = "GH", glyph = "brand-github", title = "GitHub Pull Requests" },
  { key = "slack", label = "Slack", short = "SL", glyph = "brand-slack", title = "Slack" },
  { key = "linear", label = "Linear", short = "LN", glyph = "subtask", title = "Linear Issues" },
  { key = "gmail", label = "Gmail", short = "GM", glyph = "mail", title = "Gmail" },
  { key = "calendar", label = "Calendar", short = "CA", glyph = "calendar-event", title = "Google Calendar" },
  { key = "deployments", label = "Deploy", short = "DP", glyph = "server", title = "Deployment Status" },
}

M.BY_KEY = {}
for _, p in ipairs(M.PROVIDERS) do
  M.BY_KEY[p.key] = p
end

function M.enabled(key)
  return noctalia.getConfig("enable_" .. key) ~= false
end

-- Days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant).
local function daysFromCivil(y, m, d)
  if m <= 2 then
    y -= 1
  end
  local era = math.floor(y / 400)
  local yoe = y - era * 400
  local mp = (m + 9) % 12
  local doy = math.floor((153 * mp + 2) / 5) + d - 1
  local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
  return era * 146097 + doe - 719468
end

-- ISO-8601 -> unix seconds. Date-only and offset-less values are local time.
function M.parseIso(s)
  if type(s) ~= "string" or s == "" then
    return nil
  end
  local y, mo, d = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)")
  if not y then
    return nil
  end
  y, mo, d = tonumber(y), tonumber(mo), tonumber(d)
  local h, mi, sec = s:match("^%d+-%d+-%d+[T ](%d%d):(%d%d):?(%d*)")
  if not h then
    return os.time({ year = y, month = mo, day = d, hour = 0, min = 0, sec = 0 })
  end
  h, mi, sec = tonumber(h), tonumber(mi), tonumber(sec) or 0
  local rest = s:sub(17)
  local offset
  if rest:match("Z$") then
    offset = 0
  else
    local sign, oh, om = rest:match("([%+%-])(%d%d):?(%d%d)$")
    if sign then
      offset = (tonumber(oh) * 3600 + tonumber(om) * 60) * (sign == "-" and -1 or 1)
    end
  end
  if offset == nil then
    return os.time({ year = y, month = mo, day = d, hour = h, min = mi, sec = sec })
  end
  return daysFromCivil(y, mo, d) * 86400 + h * 3600 + mi * 60 + sec - offset
end

function M.relative(ts)
  if not ts or ts <= 0 then
    return "unknown"
  end
  local seconds = math.max(0, os.time() - ts)
  if seconds < 60 then
    return "just now"
  elseif seconds < 3600 then
    return `{math.floor(seconds / 60)}m ago`
  elseif seconds < 86400 then
    return `{math.floor(seconds / 3600)}h ago`
  end
  return `{math.floor(seconds / 86400)}d ago`
end

function M.sameDay(a, b)
  return os.date("%Y-%m-%d", a) == os.date("%Y-%m-%d", b)
end

function M.openUrl(url)
  if type(url) == "string" and url ~= "" then
    noctalia.runAsync({ "xdg-open", url })
  end
end

return M
