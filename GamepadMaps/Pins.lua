local ADDON, ns = ...
local L = ns.L

local Notes = {}
ns.Notes = Notes

local Pins = {}
ns.Pins = Pins

local ICON = "Interface\\Icons\\INV_Misc_Map_01"
local PIN_SIZE = 22

local layer, tooltip
local pool, active = {}, {}
local selected -- index into `active`
local lastW, lastH, lastScale

function Pins:GetMapID()
    if WorldMapFrame and WorldMapFrame.GetMapID then
        return WorldMapFrame:GetMapID()
    end
end

--------------------------------------------------------------------------------
-- Notes (saved data)
--------------------------------------------------------------------------------

function Notes:Add(mapID, x, y, name)
    local list = ns.db.notes[mapID]
    if not list then
        list = {}
        ns.db.notes[mapID] = list
    end
    if not name or name == "" then
        name = L.NOTE_DEFAULT:format(#list + 1)
    end
    local note = { x = x, y = y, name = name }
    list[#list + 1] = note
    Pins:Refresh()
    return note
end

function Notes:Remove(mapID, index)
    local list = ns.db.notes[mapID]
    local note = list and table.remove(list, index)
    if list and #list == 0 then ns.db.notes[mapID] = nil end
    Pins:Refresh()
    return note
end

function Notes:AddAtPlayer(name)
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    local x, y
    if pos then x, y = pos:GetXY() end
    if not x or (x == 0 and y == 0) then
        ns.Print(L.NO_POSITION)
        return
    end
    local note = Notes:Add(mapID, x, y, name)
    ns.Print(L.NOTE_ADDED:format(note.name, x * 100, y * 100))
end

--------------------------------------------------------------------------------
-- Pin layer. Our own frames, parented to the map canvas, never registered in a
-- Blizzard data provider so the gamepad map cursor does not iterate over them.
--------------------------------------------------------------------------------

local function EnsureLayer()
    if layer then return layer end
    if not (WorldMapFrame and WorldMapFrame.GetCanvas) then return end
    local canvas = WorldMapFrame:GetCanvas()
    if not canvas then return end

    layer = CreateFrame("Frame", nil, canvas)
    layer:SetAllPoints(canvas)
    layer:SetFrameLevel(canvas:GetFrameLevel() + 200)
    layer:SetScript("OnHide", function() tooltip:Hide() end)

    -- Private tooltip: the shared GameTooltip is part of the gamepad UI flow.
    tooltip = CreateFrame("GameTooltip", "GamepadMapsTooltip", UIParent, "GameTooltipTemplate")
    return layer
end

function Pins:ShowTooltip(pin)
    if not tooltip then return end
    local note = pin.note
    tooltip:SetOwner(pin, "ANCHOR_RIGHT")
    tooltip:SetText(note.name, 1, 1, 1)
    tooltip:AddLine(L.TT_COORDS:format(note.x * 100, note.y * 100), 0.8, 0.8, 0.8)
    tooltip:AddLine(L.TT_HINT_CLICK, 0.5, 0.8, 0.5)
    tooltip:AddLine(L.TT_HINT_DELETE, 0.8, 0.5, 0.5)
    tooltip:Show()
end

function Pins:SetWaypoint(mapID, x, y)
    local ok = pcall(function()
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end)
    return ok
end

local function WaypointPin(pin)
    if Pins:SetWaypoint(pin.mapID, pin.note.x, pin.note.y) then
        ns.Print(L.WAYPOINT_SET:format(pin.note.name))
    else
        ns.Print(L.WAYPOINT_FAIL)
    end
end

local function DeletePin(pin)
    local note = Notes:Remove(pin.mapID, pin.index)
    if note then ns.Print(L.NOTE_REMOVED:format(note.name)) end
end

local function NewPin()
    local pin = table.remove(pool)
    if pin then return pin end

    pin = CreateFrame("Button", nil, layer)
    pin:SetSize(PIN_SIZE, PIN_SIZE)

    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints()
    pin.icon:SetTexture(ICON)

    pin.highlight = pin:CreateTexture(nil, "OVERLAY")
    pin.highlight:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    pin.highlight:SetBlendMode("ADD")
    pin.highlight:SetPoint("CENTER")
    pin.highlight:SetSize(PIN_SIZE * 1.8, PIN_SIZE * 1.8)
    pin.highlight:Hide()

    pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    pin:SetScript("OnEnter", function(self) Pins:ShowTooltip(self) end)
    pin:SetScript("OnLeave", function() tooltip:Hide() end)
    pin:SetScript("OnClick", function(self, button)
        if button == "RightButton" and IsShiftKeyDown() then
            DeletePin(self)
        elseif button == "LeftButton" then
            WaypointPin(self)
        end
    end)
    return pin
end

local function ReleaseAll()
    for i = #active, 1, -1 do
        local pin = active[i]
        pin:Hide()
        pin.highlight:Hide()
        pool[#pool + 1] = pin
        active[i] = nil
    end
    selected = nil
end

function Pins:Layout(force)
    if not layer then return end
    local canvas = layer:GetParent()
    local w, h = canvas:GetSize()
    local scale = 1 / math.max(canvas:GetScale(), 0.01)
    if not force and w == lastW and h == lastH and scale == lastScale then return end
    lastW, lastH, lastScale = w, h, scale

    for _, pin in ipairs(active) do
        pin:SetScale(scale)
        pin:ClearAllPoints()
        -- Offsets are expressed in the pin's own (scaled) units.
        pin:SetPoint("CENTER", canvas, "TOPLEFT", pin.note.x * w / scale, -pin.note.y * h / scale)
    end
end

function Pins:Refresh()
    if not EnsureLayer() then return end
    ReleaseAll()
    local mapID = self:GetMapID()
    local list = mapID and ns.db.notes[mapID]
    if list then
        for index, note in ipairs(list) do
            local pin = NewPin()
            pin.mapID, pin.index, pin.note = mapID, index, note
            pin:Show()
            active[#active + 1] = pin
        end
    end
    self:Layout(true)
end

--------------------------------------------------------------------------------
-- Gamepad-friendly navigation (bound to controller buttons in the key bindings)
--------------------------------------------------------------------------------

local function SetSelected(index)
    if selected and active[selected] then active[selected].highlight:Hide() end
    selected = index
    local pin = index and active[index]
    if pin then
        pin.highlight:Show()
        Pins:ShowTooltip(pin)
    elseif tooltip then
        tooltip:Hide()
    end
end

local function MapIsOpen()
    if WorldMapFrame and WorldMapFrame:IsShown() then return true end
    ns.Print(L.OPEN_MAP)
    return false
end

function Pins:Cycle(direction)
    if not MapIsOpen() then return end
    if #active == 0 then
        ns.Print(L.NO_PINS)
        return
    end
    if not selected then
        SetSelected(direction > 0 and 1 or #active)
    else
        SetSelected(((selected - 1 + direction) % #active) + 1)
    end
end

function Pins:WaypointSelected()
    if not MapIsOpen() then return end
    local pin = selected and active[selected]
    if pin then WaypointPin(pin) else ns.Print(L.NO_PINS) end
end

function Pins:DeleteSelected()
    if not MapIsOpen() then return end
    local pin = selected and active[selected]
    if pin then DeletePin(pin) else ns.Print(L.NO_PINS) end
end
