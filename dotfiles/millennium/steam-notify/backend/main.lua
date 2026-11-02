-- Steam notification backend: the frontend (sandboxed inside Steam) cannot
-- spawn processes, so it asks this Lua host to do it.
local logger     = require("logger")
local millennium = require("millennium")

-- Log file for load and error messages, never the notification text. Millennium
-- backend logs are only visible in its own window; this file is readable outside.
local LOG = os.getenv("HOME") .. "/.cache/steam-notify.log"

---@ffi
--- Append a line to ~/.cache/steam-notify.log.
---@param msg string
---@return boolean
function log(msg)
    local f = io.open(LOG, "a")
    if not f then return false end
    f:write(os.date("%Y-%m-%d %H:%M:%S "), tostring(msg), "\n")
    f:close()
    return true
end

local function q(s)
    return "'" .. (tostring(s or ""):gsub("'", "'\\''")) .. "'"
end

---@ffi
--- Show a notification through notify-send (picked up by Caelestia/Quickshell
--- or any other notification daemon).
---@param title string
---@param body string
---@param urgency string
---@return boolean
function notify(title, body, urgency)
    -- Steam's runtime environment confuses system binaries; strip it.
    local cmd = "env -u LD_LIBRARY_PATH -u LD_PRELOAD notify-send -a Steam -i steam -u " .. q(urgency)
        .. " -- " .. q(title) .. " " .. q(body) .. " >/dev/null 2>&1 &"
    local ok = os.execute(cmd)
    if not ok then
        logger:error("notify-send failed")
        log("notify-send failed")
    end
    return ok and true or false
end

local function on_load()
    logger:info("steam-notify loaded, Millennium " .. millennium.version())
    log("backend loaded, Millennium " .. millennium.version())
    millennium.ready()
end

return {
    on_load = on_load,
}
