local ADDON, ns = ...

-- Globals referenced by Bindings.xml. They only call into our own code.
function GamepadMaps_AddNote()     ns.Notes:AddAtPlayer() end
function GamepadMaps_NextPin()     ns.Pins:Cycle(1) end
function GamepadMaps_PrevPin()     ns.Pins:Cycle(-1) end
function GamepadMaps_WaypointPin() ns.Pins:WaypointSelected() end
function GamepadMaps_DeletePin()   ns.Pins:DeleteSelected() end
