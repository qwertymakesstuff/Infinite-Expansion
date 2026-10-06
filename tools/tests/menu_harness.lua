-- Runs ui_scripts/InfiniteExpansion/__init__.lua in plain Lua 5.1 with stand-ins
-- for the parts of IW7's Lua UI it touches, then builds the zombies main menu's
-- button list the way the game does. Prints one line per observation for
-- tools/tests/test_installer.py.
--
--   lua5.1 tools/tests/menu_harness.lua <__init__.lua> <scenario>
--
-- Scenarios (the order iw7-mod loads scripts in depends on the install):
--   iw7mod_folder   the mod's script runs before iw7-mod's MainMenu script
--   mods_menu       the mod's script runs after it
--   name_default    the player is still "Unknown Soldier" and the setup wrote a name
--   name_custom     the player already chose a name
--   name_missing    the setup wrote no name file
local script, scenario = arg[1], arg[2]

local function newElement(id)
    local element = { id = id, children = {} }
    function element:addElement(child)
        self.children[#self.children + 1] = child
    end
    function element:SetAnchorsAndPosition(...)
        self.anchors = { ... }
    end
    function element:getRootController()
        return 0
    end
    function element:addEventHandler(name, handler)
        self.handlers = self.handlers or {}
        self.handlers[name] = handler
    end
    element.Text = { setText = function(_, text) element.text = text end }
    return element
end

MenuBuilder = { m_types = {} }
function MenuBuilder.registerType(name, builder)
    MenuBuilder.m_types[name] = builder
end
function MenuBuilder.BuildRegisteredType(name, controller)
    local builder = MenuBuilder.m_types[name]
    if builder then
        return builder(nil, controller)
    end
    return newElement(name)
end

LUI = { FlowManager = { RegisterStackPopBehaviour = function() end, RequestAddMenu = function() end } }
_1080p = 1
function ToUpperCase(text)
    return string.upper(text)
end
function WipeGlobalModelsAtPath()
end

local dvars = { name = "Unknown Soldier" }
local setCalls = {}
Engine = {
    InFrontend = function() return true end,
    GetDvarString = function(name) return dvars[name] or "" end,
    SetDvarString = function(name, value)
        dvars[name] = value
        setCalls[#setCalls + 1] = name .. "=" .. value
    end,
}

local nameFile = nil
io.fileexists = function(path)
    return nameFile ~= nil and path == "iw7-mod/ui_scripts/InfiniteExpansion/steam-name.txt"
end
io.readfile = function(path)
    return nameFile
end

-- The stock button list, and iw7-mod's replacement, which it assigns directly.
local function listBuilder(tag)
    return function(menu, controller)
        local navigator = newElement("CPMainMenuButtons")
        navigator.builtBy = tag
        navigator.ButtonDescription = newElement("ButtonDescription")
        return navigator
    end
end
local function loadIw7modMainMenu()
    MenuBuilder.m_types["CPMainMenuButtons"] = listBuilder("iw7-mod")
end

local function report(how, navigator)
    local count, text = 0, ""
    for _, child in ipairs(navigator.children) do
        if child.id == "IXCharacterButton" then
            count = count + 1
            text = child.text
        end
    end
    print(string.format("list %s builtBy=%s buttons=%d text=%s", how, navigator.builtBy, count, text))
end

MenuBuilder.m_types["CPMainMenuButtons"] = listBuilder("stock")

if scenario == "iw7mod_folder" then
    dofile(script)
    loadIw7modMainMenu()
elseif scenario == "mods_menu" then
    loadIw7modMainMenu()
    dofile(script)
else
    if scenario == "name_default" then
        nameFile = '  "Rank\\zies;^1\r\n'
    elseif scenario == "name_custom" then
        nameFile = "SteamName\n"
        dvars.name = "Custom"
    end
    dofile(script)
    print("name " .. dvars.name)
    print("sets " .. #setCalls)
    return
end

-- The game builds the list by name, and twice: once more after another menu.
report("by_name", MenuBuilder.BuildRegisteredType("CPMainMenuButtons", { controllerIndex = 0 }))
MenuBuilder.BuildRegisteredType("SomethingElse", { controllerIndex = 0 })
report("direct", MenuBuilder.m_types["CPMainMenuButtons"](nil, { controllerIndex = 0 }))
report("again", MenuBuilder.BuildRegisteredType("CPMainMenuButtons", { controllerIndex = 0 }))
