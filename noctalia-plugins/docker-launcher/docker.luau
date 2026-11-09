--!nonstrict
-- Each entry runs ~/.config/hypr/scripts/DockerMenu.sh with the matching view flag.

local ENTRIES = {
  { id = "", title = "Docker Menu", subtitle = "Open the Docker menu", glyph = "brand-docker" },
  { id = "--ps", title = "Docker: Running Containers", subtitle = "List running containers", glyph = "player-play" },
  { id = "--ps-all", title = "Docker: All Containers", subtitle = "List all containers", glyph = "box" },
  { id = "--images", title = "Docker: Images", subtitle = "List images", glyph = "stack-2" },
  { id = "--compose-ps", title = "Docker: Compose Projects", subtitle = "List compose projects", glyph = "stack" },
}

function onQuery(query)
  local text = noctalia.string.trim(query):lower()
  local rows = {}
  for _, entry in ENTRIES do
    if text == "" or entry.title:lower():find(text, 1, true) then
      table.insert(rows, entry)
    end
  end
  launcher.setResults(query, rows)
end

function onActivate(id)
  local script = noctalia.expandPath("~/.config/hypr/scripts/DockerMenu.sh")
  local argv = { "sh", "-lc", 'exec "$0" "$@"', script }
  if id ~= "" then
    table.insert(argv, id)
  end
  noctalia.runAsync(argv)
end
