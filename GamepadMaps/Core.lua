local ADDON, ns = ...
local L = ns.L

-- Design rule for the whole addon: never write to Blizzard tables, never replace
-- Blizzard functions and never register pins in Blizzard data providers. The
-- native gamepad UI taints when addon code runs inside its secure paths, so every
-- frame here is our own and everything we read from the map is read-only.

local DEFAULTS = {
    coords = true,
    opacity = 1,
    opacityOnGamepad = false,
    debug = false,
    notes = {},
    log = {},
}

local MAX_LOG = 100

local function CopyDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            if type(v) == "table" then
                dst[k] = CopyDefaults({}, v)
            else
                dst[k] = v
            end
        end
    end
    return dst
end

function ns.Print(msg)
    print("|cff33ccffGamepadMaps|r: " .. tostring(msg))
end

-- Always logs when force is true (taint events); otherwise only in debug mode.
function ns.Log(msg, force)
    if not ns.db then return end
    if not (force or ns.db.debug) then return end
    local log = ns.db.log
    log[#log + 1] = date("%H:%M:%S") .. " " .. tostring(msg)
    if #log > MAX_LOG then table.remove(log, 1) end
    if ns.db.debug then ns.Print(msg) end
end

function ns.IsGamepadActive()
    return ns.gamepadActive == true
end

local function SafeRegister(frame, event)
    -- Unknown events raise an error on modern clients; the pcall keeps us loading.
    return pcall(frame.RegisterEvent, frame, event)
end

local function ReadGamepadState()
    local ok, active = pcall(function()
        if C_GamePad and C_GamePad.GetActiveDeviceID then
            return C_GamePad.GetActiveDeviceID() ~= nil
        end
        return false
    end)
    ns.gamepadActive = ok and active or false
end

local handlers = {}

function handlers.ADDON_LOADED(name)
    if name == ADDON then
        GamepadMapsDB = CopyDefaults(GamepadMapsDB or {}, DEFAULTS)
        ns.db = GamepadMapsDB
    end
    if ns.db and (name == ADDON or name == "Blizzard_WorldMap") then
        ns.Map:Init()
    end
end

function handlers.PLAYER_LOGIN()
    ReadGamepadState()
    if ns.db then ns.Map:Init() end
end

function handlers.GAME_PAD_ACTIVE_CHANGED(isActive)
    ns.gamepadActive = isActive and true or false
    ns.Log("GAME_PAD_ACTIVE_CHANGED -> " .. tostring(isActive))
    ns.Map:ApplyOpacity()
end

function handlers.GAME_PAD_CONNECTED()
    ns.Log("GAME_PAD_CONNECTED")
end

function handlers.GAME_PAD_DISCONNECTED()
    ns.Log("GAME_PAD_DISCONNECTED")
end

-- Taint reports: always keep these, they are the reason this addon exists.
function handlers.ADDON_ACTION_BLOCKED(addonName, func)
    ns.Log(("ADDON_ACTION_BLOCKED addon=%s func=%s"):format(tostring(addonName), tostring(func)), true)
end

function handlers.ADDON_ACTION_FORBIDDEN(addonName, func)
    ns.Log(("ADDON_ACTION_FORBIDDEN addon=%s func=%s"):format(tostring(addonName), tostring(func)), true)
end

local frame = CreateFrame("Frame")
for event in pairs(handlers) do SafeRegister(frame, event) end
frame:SetScript("OnEvent", function(_, event, ...)
    handlers[event](...)
end)

--------------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------------

local function OnOff(value)
    return value and L.ON or L.OFF
end

local commands = {}

function commands.note(rest)
    ns.Notes:AddAtPlayer(rest)
end

function commands.list()
    local mapID = ns.Pins:GetMapID() or C_Map.GetBestMapForUnit("player")
    local list = mapID and ns.db.notes[mapID]
    if not list or #list == 0 then
        ns.Print(L.NO_PINS)
        return
    end
    for i, note in ipairs(list) do
        ns.Print(("%d. %s (%.1f, %.1f)"):format(i, note.name, note.x * 100, note.y * 100))
    end
end

function commands.clear()
    local mapID = ns.Pins:GetMapID() or C_Map.GetBestMapForUnit("player")
    local list = mapID and ns.db.notes[mapID]
    local count = list and #list or 0
    if mapID then ns.db.notes[mapID] = nil end
    ns.Pins:Refresh()
    ns.Print(L.CLEARED:format(count))
end

function commands.coords(rest)
    local arg = rest:lower()
    if arg == "on" then ns.db.coords = true
    elseif arg == "off" then ns.db.coords = false
    else ns.db.coords = not ns.db.coords end
    ns.Map:ApplyCoordsVisibility()
    ns.Print(L.COORDS_STATE:format(OnOff(ns.db.coords)))
end

function commands.opacity(rest)
    local value = tonumber(rest)
    if value then
        ns.db.opacity = math.min(1, math.max(0.3, value))
        ns.Map:ApplyOpacity()
    end
    ns.Print(L.OPACITY_STATE:format(ns.db.opacity * 100))
end

function commands.debug(rest)
    local arg = rest:lower()
    if arg == "on" then ns.db.debug = true
    elseif arg == "off" then ns.db.debug = false
    else ns.db.debug = not ns.db.debug end
    ns.Print(L.DEBUG_STATE:format(OnOff(ns.db.debug)))
    ns.Print(L.GAMEPAD_STATE:format(OnOff(ns.IsGamepadActive())))
end

function commands.log()
    local log = ns.db.log
    if #log == 0 then
        ns.Print(L.LOG_EMPTY)
        return
    end
    for i = math.max(1, #log - 19), #log do print(log[i]) end
end

SLASH_GAMEPADMAPS1 = "/gm"
SLASH_GAMEPADMAPS2 = "/gamepadmaps"
SlashCmdList["GAMEPADMAPS"] = function(input)
    if not ns.db then return end
    local cmd, rest = (input or ""):match("^(%S*)%s*(.-)$")
    local fn = commands[cmd:lower()]
    if fn then
        fn(rest)
    else
        for _, line in ipairs(L.HELP) do ns.Print(line) end
    end
end
