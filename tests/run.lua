-- Smoke test with a minimal WoW API stub. Run from the repo root:
--   lua5.4 tests/run.lua
-- It only proves the addon loads and its logic paths run without Lua errors;
-- it does not prove behaviour inside the real client.

local printed = {}
_G.print = function(...) printed[#printed + 1] = table.concat({ ... }, " ") end

local function Stub()
    local obj = {}
    return setmetatable(obj, {
        __index = function(t, k)
            if k == "GetSize" then return function() return 1000, 800 end end
            if k == "GetScale" then return function() return 1 end end
            if k == "GetFrameLevel" then return function() return 1 end end
            if k == "IsShown" then return function(self) return rawget(self, "_shown") ~= false end end
            if k == "SetScript" then return function(self, name, fn) if not rawget(self, "_scripts") then rawset(self, "_scripts", {}) end; self._scripts[name] = fn end end
            if k == "RegisterEvent" then return function() end end
            if k == "GetParent" then return function(self) return rawget(self, "_parent") end end
            if k == "Show" then return function(self) rawset(self, "_shown", true) end end
            if k == "Hide" then return function(self) rawset(self, "_shown", false) end end
            if k == "CreateTexture" or k == "CreateFontString" then return function() return Stub() end end
            return function() return Stub() end
        end,
    })
end

function CreateFrame(_, _, parent)
    local f = Stub()
    f._parent = parent
    return f
end

local canvas = Stub()
WorldMapFrame = Stub()
WorldMapFrame.ScrollContainer = Stub()
WorldMapFrame.ScrollContainer.GetNormalizedCursorPosition = function() return 0.5, 0.25 end
WorldMapFrame.GetCanvas = function() return canvas end
WorldMapFrame.GetMapID = function() return 100 end
WorldMapFrame.IsShown = function() return true end

UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { m, x, y } end }
C_Map = {
    GetBestMapForUnit = function() return 100 end,
    GetPlayerMapPosition = function() return { GetXY = function() return 0.4, 0.6 end } end,
    SetUserWaypoint = function() end,
}
C_SuperTrack = { SetSuperTrackedUserWaypoint = function() end }
C_GamePad = { GetActiveDeviceID = function() return 1 end }
function GetLocale() return "enUS" end
function IsShiftKeyDown() return false end
SlashCmdList = {}
date = os.date

local handlerFrame
local realCreate = CreateFrame
function CreateFrame(t, n, p)
    local f = realCreate(t, n, p)
    handlerFrame = handlerFrame or f -- Core.lua creates the event frame first
    return f
end

local ns = {}
for _, file in ipairs({ "Locale.lua", "Core.lua", "Pins.lua", "Map.lua", "Bindings.lua" }) do
    assert(loadfile("GamepadMaps/" .. file))("GamepadMaps", ns)
end

local fire = function(event, ...) handlerFrame._scripts.OnEvent(handlerFrame, event, ...) end
fire("ADDON_LOADED", "GamepadMaps")
assert(ns.db and ns.db.notes, "db initialised")
fire("PLAYER_LOGIN")
fire("GAME_PAD_ACTIVE_CHANGED", true)
assert(ns.IsGamepadActive(), "gamepad flag set")
fire("ADDON_ACTION_BLOCKED", "Questie", "SetPreferredGamepadInteractTarget()")
assert(#ns.db.log >= 1, "taint event logged")

local slash = SlashCmdList["GAMEPADMAPS"]
slash("note Test")
assert(#ns.db.notes[100] == 1 and ns.db.notes[100][1].name == "Test", "note added")
slash("list")
slash("coords off"); slash("coords on")
slash("opacity 0.5"); assert(ns.db.opacity == 0.5)
slash("debug on"); slash("debug off")
slash("log")
slash("")

GamepadMaps_NextPin(); GamepadMaps_PrevPin(); GamepadMaps_WaypointPin()
GamepadMaps_AddNote()
assert(#ns.db.notes[100] == 2, "second note added via binding")
GamepadMaps_NextPin(); GamepadMaps_DeletePin()
assert(#ns.db.notes[100] == 1, "selected note deleted")
slash("clear")
assert(ns.db.notes[100] == nil, "notes cleared")

print = nil
io.write("OK - ", #printed, " chat lines printed\n")
