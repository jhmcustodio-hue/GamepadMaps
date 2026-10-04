local ADDON, ns = ...
local L = ns.L

local Map = {}
ns.Map = Map

local UPDATE_INTERVAL = 0.1

local driver, coordsText
local lastMapID

local function CursorXY()
    local container = WorldMapFrame.ScrollContainer
    if not (container and container.GetNormalizedCursorPosition) then return end
    local ok, x, y = pcall(container.GetNormalizedCursorPosition, container)
    if ok and x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
        return x, y
    end
end

local function PlayerXY(mapID)
    if not (mapID and C_Map and C_Map.GetPlayerMapPosition) then return end
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return end
    local x, y = pos:GetXY()
    if x and y and not (x == 0 and y == 0) then return x, y end
end

local function FormatXY(x, y)
    if not x then return "--" end
    return L.TT_COORDS:format(x * 100, y * 100)
end

local function UpdateCoords()
    if not (ns.db.coords and coordsText) then return end
    local mapID = WorldMapFrame:GetMapID()
    local px, py = PlayerXY(mapID)
    local cx, cy = CursorXY()
    coordsText:SetText(("%s: %s    %s: %s"):format(L.PLAYER, FormatXY(px, py), L.CURSOR, FormatXY(cx, cy)))
end

function Map:ApplyCoordsVisibility()
    if coordsText then coordsText:SetShown(ns.db.coords) end
end

function Map:ApplyOpacity()
    if not (driver and WorldMapFrame) then return end
    local alpha = 1
    if ns.db.opacity < 1 and (ns.db.opacityOnGamepad or not ns.IsGamepadActive()) then
        alpha = ns.db.opacity
    end
    WorldMapFrame:SetAlpha(alpha)
end

local function OnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < UPDATE_INTERVAL then return end
    self.elapsed = 0

    local mapID = WorldMapFrame:GetMapID()
    if mapID ~= lastMapID then
        lastMapID = mapID
        ns.Pins:Refresh()
    else
        ns.Pins:Layout()
    end
    UpdateCoords()
end

function Map:Init()
    if driver or not WorldMapFrame then return end

    local container = WorldMapFrame.ScrollContainer or WorldMapFrame

    -- Everything we add is a child frame of ours; no Blizzard field is written.
    driver = CreateFrame("Frame", nil, WorldMapFrame)
    driver:SetAllPoints(container)
    driver:SetFrameLevel(container:GetFrameLevel() + 100)
    driver:EnableMouse(false)

    coordsText = driver:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    coordsText:SetPoint("BOTTOMLEFT", driver, "BOTTOMLEFT", 10, 8)
    coordsText:SetShadowColor(0, 0, 0, 1)
    coordsText:SetShadowOffset(1, -1)

    driver:SetScript("OnUpdate", OnUpdate)
    driver:SetScript("OnShow", function()
        lastMapID = nil
        Map:ApplyOpacity()
    end)

    Map:ApplyCoordsVisibility()
    Map:ApplyOpacity()
    ns.Log("Map initialised")
end
