local ADDON, ns = ...

local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

L.NOTE_DEFAULT   = "Note %d"
L.NOTE_ADDED     = "Note \"%s\" added at %.1f, %.1f."
L.NO_POSITION    = "Could not read your position on this map."
L.OPEN_MAP       = "Open the world map first."
L.NO_PINS        = "No notes on this map."
L.PLAYER         = "Player"
L.CURSOR         = "Cursor"
L.TT_COORDS      = "%.1f, %.1f"
L.TT_HINT_CLICK  = "Click: set waypoint"
L.TT_HINT_DELETE = "Shift + right click: delete"
L.WAYPOINT_SET   = "Waypoint set on \"%s\"."
L.WAYPOINT_FAIL  = "Could not set the waypoint."
L.NOTE_REMOVED   = "Note \"%s\" removed."
L.CLEARED        = "%d note(s) removed from this map."
L.ON             = "on"
L.OFF            = "off"
L.COORDS_STATE   = "Coordinates: %s"
L.OPACITY_STATE  = "Map opacity: %d%%"
L.DEBUG_STATE    = "Debug: %s"
L.LOG_EMPTY      = "The log is empty."
L.GAMEPAD_STATE  = "Gamepad active: %s"
L.HELP = {
    "/gm note [name] - add a note at your position",
    "/gm list - list notes on the current map",
    "/gm clear - remove all notes on the current map",
    "/gm coords on|off - show coordinates on the map",
    "/gm opacity 0.3-1 - map opacity (keyboard/mouse)",
    "/gm debug on|off - log gamepad and taint events",
    "/gm log - print the last log entries",
}
L.BINDING_HEADER = "GamepadMaps"
L.BINDING_ADDNOTE = "Add note at my position"
L.BINDING_NEXTPIN = "Select next note"
L.BINDING_PREVPIN = "Select previous note"
L.BINDING_WAYPOINT = "Set waypoint on selected note"
L.BINDING_DELETEPIN = "Delete selected note"

if GetLocale() == "ptBR" then
    L.NOTE_DEFAULT   = "Nota %d"
    L.NOTE_ADDED     = "Nota \"%s\" adicionada em %.1f, %.1f."
    L.NO_POSITION    = "Não foi possível ler sua posição neste mapa."
    L.OPEN_MAP       = "Abra o mapa-múndi primeiro."
    L.NO_PINS        = "Nenhuma nota neste mapa."
    L.PLAYER         = "Jogador"
    L.CURSOR         = "Cursor"
    L.TT_HINT_CLICK  = "Clique: definir waypoint"
    L.TT_HINT_DELETE = "Shift + botão direito: apagar"
    L.WAYPOINT_SET   = "Waypoint definido em \"%s\"."
    L.WAYPOINT_FAIL  = "Não foi possível definir o waypoint."
    L.NOTE_REMOVED   = "Nota \"%s\" removida."
    L.CLEARED        = "%d nota(s) removida(s) deste mapa."
    L.ON             = "ligado"
    L.OFF            = "desligado"
    L.COORDS_STATE   = "Coordenadas: %s"
    L.OPACITY_STATE  = "Opacidade do mapa: %d%%"
    L.DEBUG_STATE    = "Debug: %s"
    L.LOG_EMPTY      = "O log está vazio."
    L.GAMEPAD_STATE  = "Gamepad ativo: %s"
    L.HELP = {
        "/gm note [nome] - adiciona uma nota na sua posição",
        "/gm list - lista as notas do mapa atual",
        "/gm clear - remove todas as notas do mapa atual",
        "/gm coords on|off - mostra coordenadas no mapa",
        "/gm opacity 0.3-1 - opacidade do mapa (teclado/mouse)",
        "/gm debug on|off - registra eventos de gamepad e taint",
        "/gm log - mostra as últimas entradas do log",
    }
    L.BINDING_ADDNOTE = "Adicionar nota na minha posição"
    L.BINDING_NEXTPIN = "Selecionar próxima nota"
    L.BINDING_PREVPIN = "Selecionar nota anterior"
    L.BINDING_WAYPOINT = "Definir waypoint na nota selecionada"
    L.BINDING_DELETEPIN = "Apagar nota selecionada"
end

-- Global strings used by Bindings.xml.
BINDING_HEADER_GAMEPADMAPS = L.BINDING_HEADER
BINDING_NAME_GAMEPADMAPS_ADDNOTE = L.BINDING_ADDNOTE
BINDING_NAME_GAMEPADMAPS_NEXTPIN = L.BINDING_NEXTPIN
BINDING_NAME_GAMEPADMAPS_PREVPIN = L.BINDING_PREVPIN
BINDING_NAME_GAMEPADMAPS_WAYPOINT = L.BINDING_WAYPOINT
BINDING_NAME_GAMEPADMAPS_DELETEPIN = L.BINDING_DELETEPIN
