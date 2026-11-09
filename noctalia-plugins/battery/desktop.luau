--!nonstrict
-- Desktop [[desktop_widget]] entry: battery glyph + percentage, polled from
-- sysfs every 30 s. Renders nothing visible on machines without a battery.

local SYSFS = "/sys/class/power_supply/"
local BATTERIES = { "BAT0", "BAT1", "BATT", "CMB0" }

local function readTrim(path)
  local text = noctalia.readFile(path)
  if type(text) ~= "string" then
    return nil
  end
  return (text:gsub("%s+$", ""))
end

local function readBattery()
  for _, name in BATTERIES do
    local capacity = tonumber(readTrim(SYSFS .. name .. "/capacity"))
    if capacity ~= nil then
      return capacity, readTrim(SYSFS .. name .. "/status") or "Unknown"
    end
  end
  return nil, nil
end

local function glyphFor(capacity, status)
  if status == "Charging" then
    return "battery-charging"
  elseif status == "Full" or status == "Not charging" then
    return "battery-plugged"
  end
  return "battery-" .. math.clamp(math.floor(capacity / 25 + 0.5), 0, 4)
end

local function render()
  local capacity, status = readBattery()
  if capacity == nil then
    desktopWidget.render(ui.row({}, {}))
    return
  end
  local color = "#ffffff"
  if capacity <= 15 and status ~= "Charging" then
    color = "error"
  end
  desktopWidget.render(ui.row({ gap = 8, align = "center", width = 140 }, {
    ui.glyph({ name = glyphFor(capacity, status), size = 26, color = color }),
    ui.label({ text = capacity .. "%", fontSize = 22, fontWeight = "bold", color = color }),
  }))
end

function update()
  noctalia.setUpdateInterval(30000)
  render()
end

render()
