-- Runs ui_scripts/InfiniteExpansion/__init__.lua in plain Lua 5.1 with stand-ins
-- for the parts of IW7's Lua UI it touches, then builds menus the way the game
-- does and prints one line per observation for tools/tests/test_menu_script.py.
--
--   lua5.1 tools/tests/menu_harness.lua <__init__.lua> <scenario> [name=value ...]
--
-- Scenarios:
--   lobby       the Solo Match / Custom Game lobby. Options:
--                 order=registered  the game registers its lobby types before
--                                   the mod's script runs (default)
--                 order=lazy        ... after it, with MenuBuilder.registerType
--                 order=assigned    ... after it, by assigning MenuBuilder.m_types
--                 build=byname      the lobby is built with BuildRegisteredType
--                                   (default)
--                 build=direct      ... by calling MenuBuilder.m_types directly
--                 boss=1            boss battles are on (BOSS BATTLE button)
--   menu        the CHARACTER menu: hovers and clicks every row
--   mainmenu    the zombies main menu's button list (iw7-mod's replacement)
--   name_default / name_custom / name_missing   the Steam name file
-- Shared options:
--   character=<key>   the saved ix_character
--   keys=a,b          soul keys the player has (soul_key_1 ...)
--   merits=a,b        merits the player has (mt_dlc4_troll2)
--   specials=<n>      ix_character_specials
--
-- The stock lobby stand-ins follow the game's ui/frontend/cp/cpprivatematchbuttons.lua
-- and cpprivatematchmenu.lua (IW_API_NOTES.md section 16): element names,
-- positions, the two boss battle layouts, and the reset of characterSelect.
local script, scenario = arg[1], arg[2]
local options = {}
for i = 3, #arg do
    local name, value = string.match(arg[i], "^([%w_]+)=(.*)$")
    options[name] = value
end

local function set(list)
    local result = {}
    for item in string.gmatch(list or "", "[^,]+") do
        result[item] = true
    end
    return result
end

-- Elements ------------------------------------------------------------------

local Element = {}
Element.__index = Element

local function newElement(id)
    return setmetatable({ id = id, children = {}, rect = { 0, 0, 0, 0 }, handlers = {} }, Element)
end

function Element:addElement(child)
    child.parent = self
    self.children[#self.children + 1] = child
end
function Element:SetAnchorsAndPosition(leftAnchor, rightAnchor, topAnchor, bottomAnchor, left, right, top, bottom)
    self.rect = { left, top, right, bottom }
end
function Element:getLocalRect()
    return self.rect[1], self.rect[2], self.rect[3], self.rect[4]
end
function Element:SetTop(value)
    self.rect[2] = value
end
function Element:SetBottom(value)
    self.rect[4] = value
end
function Element:getRootController()
    return 0
end
function Element:addEventHandler(name, handler)
    local list = self.handlers[name] or {}
    list[#list + 1] = handler
    self.handlers[name] = list
end
function Element:fire(name, event)
    for _, handler in ipairs(self.handlers[name] or {}) do
        handler(self, event or {})
    end
end
function Element:AnimateSequence(name)
    local sequence = self._sequences and self._sequences[name]
    if sequence then
        sequence()
    end
end
function Element:setText(text)
    self.text = text
end
function Element:SetFontSize(size)
    self.fontSize = size
end
function Element:SetFont(font)
    self.font = font
end
function Element:SetAlignment(alignment)
    self.alignment = alignment
end
function Element:SetAlpha(alpha)
    self.alpha = alpha
end
function Element:SetRGBFromInt(color)
    self.color = color
end
function Element:setImage(material)
    self.image = material
end
function Element:SetGridDataSource(source)
    self.dataSource = source
end
function Element:getNumChildren()
    return 0
end
function Element:playSound() end
function Element:setUseStencil() end
function Element:setupWorldBlur() end
function Element:AddButtonHelperText() end

local function rectText(element)
    return string.format("%g %g %g %g", element.rect[1], element.rect[2], element.rect[3], element.rect[4])
end

-- IW7's UI ------------------------------------------------------------------

local requests = {}
local function newOf()
    return { new = function()
        return newElement()
    end }
end

LUI = {
    UIElement = {
        new = function()
            return newElement()
        end,
        addElementBefore = function(element, before)
            local parent = before.parent
            for index, child in ipairs(parent.children) do
                if child == before then
                    table.insert(parent.children, index, element)
                    element.parent = parent
                    return
                end
            end
            error("addElementBefore: not a child")
        end,
    },
    UIImage = newOf(),
    UIStyledText = newOf(),
    UIText = newOf(),
    UIBindButton = newOf(),
    UIVerticalNavigator = newOf(),
    UIDataSourceGrid = {
        new = function(definition, gridOptions)
            local grid = newElement()
            grid.options = gridOptions
            return grid
        end,
    },
    DataSourceFromList = {
        new = function(count)
            return { count = count }
        end,
    },
    DataSourceInGlobalModel = {
        new = function(path, value)
            return { path = path, value = value }
        end,
    },
    FlowManager = {
        RegisterStackPopBehaviour = function() end,
        RequestAddMenu = function(name)
            requests[#requests + 1] = "open " .. name
        end,
        RequestLeaveMenu = function()
            requests[#requests + 1] = "leave"
        end,
    },
    Alignment = { Left = "left", Center = "center", Top = "top" },
    DIRECTION = { vertical = "vertical" },
}
FONTS = {
    GetFont = function(file)
        return file
    end,
    MainMedium = { File = "MainMedium" },
    MainBold = { File = "MainBold" },
    MainCondensed = { File = "MainCondensed" },
}
CoD = { SFX = { SPMinimap = "minimap" }, StatsGroup = { Coop = "coop", Ranked = "ranked" } }
_1080p = 1
function ToUpperCase(text)
    return string.upper(text)
end
function RegisterMaterial(name)
    return "material:" .. name
end
function WipeGlobalModelsAtPath() end

local dvars = { name = "Unknown Soldier", ix_character = options.character, ix_character_specials = options.specials }
local stats = { characterSelect = 0, keys = set(options.keys), merits = set(options.merits) }
local execs, nameSets = {}, 0

Engine = {
    InFrontend = function()
        return true
    end,
    IsAliensMode = function()
        return true
    end,
    GetDvarString = function(name)
        return dvars[name] or ""
    end,
    SetDvarString = function(name, value)
        dvars[name] = value
        nameSets = nameSets + 1
    end,
    Exec = function(command)
        execs[#execs + 1] = command
        local dvar, value = string.match(command, "^seta (%S+) (.*)$")
        if dvar then
            dvars[dvar] = value
        end
        local field = string.match(command, "^setCoopPlayerData zombiePlayerLoadout characterSelect (%d+)$")
        if field then
            stats.characterSelect = tonumber(field)
        end
    end,
    GetPlayerDataEx = function(controller, group, name, field)
        assert(group == CoD.StatsGroup.Coop, "zombies stats are read from the Coop group")
        if name == "haveSoulKeys" then
            return stats.keys[field] == true
        elseif name == "meritState" then
            return stats.merits[field] and 1 or 0
        end
        error("unexpected stat " .. tostring(name))
    end,
    PlaySound = function() end,
    Localize = function(text)
        return text
    end,
}

local nameFile = nil
io.fileexists = function(path)
    return nameFile ~= nil and path == "iw7-mod/ui_scripts/InfiniteExpansion/steam-name.txt"
end
io.readfile = function()
    return nameFile
end

-- The menu builder ----------------------------------------------------------

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

local function widget(name, fields)
    return function()
        local element = newElement(name)
        for _, field in ipairs(fields or {}) do
            local child = newElement(field)
            element:addElement(child)
            element[field] = child
        end
        return element
    end
end
MenuBuilder.m_types.MenuButton = widget("MenuButton", { "Text" })
MenuBuilder.m_types.CPMenuTitle = widget("CPMenuTitle", { "MenuTitle" })
MenuBuilder.m_types.ButtonHelperBar = widget("ButtonHelperBar")
MenuBuilder.m_types.ModSelectButton = widget("ModSelectButton")
MenuBuilder.m_types.ContractsButtonCP = widget("ContractsButtonCP")

-- The stock lobby ------------------------------------------------------------

local function stockPrivateMatchButtons(menu, controller)
    local self = LUI.UIVerticalNavigator.new()
    self.id = "CPPrivateMatchButtons"
    self:SetAnchorsAndPosition(0, 1, 0, 1, 0, 500, 0, 400)
    local function add(element, id, left, right, top, bottom)
        element.id = id
        element:SetAnchorsAndPosition(0, 1, 0, 1, left, right, top, bottom)
        self:addElement(element)
        self[id] = element
    end
    local function button(id, top)
        add(MenuBuilder.BuildRegisteredType("MenuButton", { controllerIndex = 0 }), id, 0, 340, top, top + 30)
    end
    button("StartMatch", 0)
    button("Loadout", 40)
    button("Barracks", 80)
    button("ChooseMap", 120)
    if options.boss then
        button("BossBattle", 160)
    end
    button("Tips", 200)
    button("Armory", 240)
    add(LUI.UIImage.new(), "ForSpacing", 0, 5, 280, 285)
    add(newElement(), "ButtonDescription", 0, 504, 350, 415)
    add(MenuBuilder.BuildRegisteredType("ContractsButtonCP", { controllerIndex = 0 }), "ContractsButton", 0, 340, 280, 340)

    local function steps(list)
        return function()
            for _, step in ipairs(list) do
                self[step[1]]:SetAnchorsAndPosition(0, 1, 0, 1, 0, step[2], step[3], step[4], 0)
            end
        end
    end
    self._sequences = {
        bossBattleOff = steps({ { "Tips", 340, 160, 190 }, { "Armory", 340, 200, 230 }, { "ForSpacing", 5, 240, 245 },
            { "ButtonDescription", 504, 310, 375 }, { "ContractsButton", 340, 240, 300 } }),
        bossBattleOn = steps({ { "BossBattle", 340, 160, 190 }, { "Tips", 340, 200, 230 }, { "Armory", 340, 240, 270 },
            { "ButtonDescription", 504, 350, 415 }, { "ContractsButton", 340, 280, 340 } }),
    }
    self:AnimateSequence("bossBattleOff")
    if options.boss then
        self:AnimateSequence("bossBattleOn")
    end
    return self
end

local function stockPrivateMatchMenu(menu, controller)
    local self = LUI.UIElement.new()
    self.id = "CPPrivateMatchMenu"
    local buttons = MenuBuilder.BuildRegisteredType("CPPrivateMatchButtons", { controllerIndex = 0 })
    buttons.id = "CPPrivateMatchButtons"
    buttons:SetAnchorsAndPosition(0, 1, 0, 1, 131, 631, 200, 600)
    self:addElement(buttons)
    self.CPPrivateMatchButtons = buttons
    -- PostLoadFunc: ACTIONS.CharacterSelect(self, controller, 0)
    stats.characterSelect = 0
    return self
end

local function defineLobby(how)
    if how == "assigned" then
        MenuBuilder.m_types.CPPrivateMatchButtons = stockPrivateMatchButtons
        MenuBuilder.m_types.CPPrivateMatchMenu = stockPrivateMatchMenu
    else
        MenuBuilder.registerType("CPPrivateMatchButtons", stockPrivateMatchButtons)
        MenuBuilder.registerType("CPPrivateMatchMenu", stockPrivateMatchMenu)
    end
end

local function openLobby()
    local lobby
    if options.build == "direct" then
        lobby = MenuBuilder.m_types.CPPrivateMatchMenu(nil, { controllerIndex = 0 })
    else
        lobby = MenuBuilder.BuildRegisteredType("CPPrivateMatchMenu", { controllerIndex = 0 })
    end
    lobby:fire("menu_create")
    return lobby
end

local function reportList(prefix, list)
    local count, order = 0, {}
    for _, child in ipairs(list.children) do
        order[#order + 1] = child.id
        if child.id == "IXCharacterButton" then
            count = count + 1
        end
    end
    print(prefix .. " buttons " .. count)
    print(prefix .. " order " .. table.concat(order, ","))
    for _, child in ipairs(list.children) do
        print(prefix .. " rect " .. child.id .. " " .. rectText(child))
    end
end

-- Scenarios ------------------------------------------------------------------

if scenario == "lobby" then
    local order = options.order or "registered"
    if order == "registered" then
        defineLobby(order)
        dofile(script)
    else
        dofile(script)
        defineLobby(order)
    end

    local lobby = openLobby()
    local list = lobby.CPPrivateMatchButtons
    reportList("first", list)
    print("field " .. stats.characterSelect)

    -- The stock list switches layouts again: the offsets stay.
    list:AnimateSequence("bossBattleOff")
    if options.boss then
        list:AnimateSequence("bossBattleOn")
    end
    reportList("relayout", list)

    -- Pressing CHARACTER opens the menu.
    if list.IXCharacterButton then
        list.IXCharacterButton:fire("button_action", { controller = 0 })
    end
    print("requests " .. table.concat(requests, ","))

    -- Opening the lobby again: still one button.
    stats.characterSelect = 0
    reportList("second", openLobby().CPPrivateMatchButtons)
    print("field " .. stats.characterSelect)
elseif scenario == "menu" then
    dofile(script)
    local menu = MenuBuilder.BuildRegisteredType("IXCharacterMenu", { controllerIndex = 0 })
    for _, id in ipairs({ "IXInfoTitle", "IXInfoStatus", "IXInfoText", "IXSelected", "IXInitials" }) do
        local text = menu[id]
        print(string.format("text %s font=%g height=%g", id, text.fontSize, text.rect[4] - text.rect[2]))
    end
    print("selected " .. menu.IXSelected.text)
    print("shown " .. menu.IXInfoTitle.text)

    local source = menu.IXCharacterList.dataSource
    for index = 0, source.count - 1 do
        local row = source:MakeDataSourceAtIndex(index, 0)
        local button = {
            GetCurrentMenu = function()
                return menu
            end,
        }
        row.buttonOnHoverFunction(button, {})
        local picture = "initials=" .. tostring(menu.IXInitials.text)
        if menu.IXPortrait.alpha == 1 then
            local width = menu.IXPortrait.rect[3] - menu.IXPortrait.rect[1]
            local height = menu.IXPortrait.rect[4] - menu.IXPortrait.rect[2]
            picture = string.format("image=%s size=%gx%g", menu.IXPortrait.image, width, height)
        end
        print(string.format("row %d label=%s title=%s status=%s %s", index, row.buttonLabel.value,
            menu.IXInfoTitle.text, menu.IXInfoStatus.text, picture))

        execs, requests = {}, {}
        row.buttonOnClickFunction(button, {})
        print(string.format("click %d exec=%s requests=%s", index, table.concat(execs, ";"), table.concat(requests, ",")))
    end
elseif scenario == "mainmenu" then
    dofile(script)
    -- iw7-mod's MainMenu/CPMainMenuButtons.lua assigns its own list.
    MenuBuilder.m_types.CPMainMenuButtons = function()
        local navigator = newElement("CPMainMenuButtons")
        navigator:addElement(MenuBuilder.BuildRegisteredType("MenuButton", { controllerIndex = 0 }))
        return navigator
    end
    reportList("main", MenuBuilder.BuildRegisteredType("CPMainMenuButtons", { controllerIndex = 0 }))
else
    if scenario == "name_default" then
        nameFile = '  "Rank\\zies;^1\r\n'
    elseif scenario == "name_custom" then
        nameFile = "SteamName\n"
        dvars.name = "Custom"
    end
    dofile(script)
    print("name " .. dvars.name)
    print("sets " .. nameSets)
end
