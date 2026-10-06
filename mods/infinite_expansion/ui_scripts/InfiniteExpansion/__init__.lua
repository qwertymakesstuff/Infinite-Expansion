-- Infinite Expansion - CHARACTER button in the zombies main menu.
--
-- Adds a base-game style button under the zombies main menu's buttons that
-- opens a character list. The choice is made here, before a match, and lasts
-- the whole match. It is saved in two places:
--   - the archived dvar ix_character, which the mod's GSC applies when this
--     player hosts a zombies match (custom_scripts/ix/player/character.gsc);
--   - for a special character, also the stock lobby field characterSelect in
--     the player's own stats, which travel with the player into other
--     players' matches. Regular characters have no lobby value, so in someone
--     else's match the game picks one at random (KNOWN_LIMITATIONS.md L29).
--
-- Everything here uses only widgets and calls that iw7-mod's own ui_scripts
-- use, and those files are the same in v1.1.0 and develop:
--   MainMenu/CPMainMenuButtons.lua   the "MenuButton" type and the button layout
--   Mods/ModSelectMenu.lua           list menus, "ModSelectButton" rows, titles
--   Stats/__init__.lua, MainMenu/CPMainMenu.lua   wrapping a registered builder

if not Engine.InFrontend() then
    return
end

local modelPath = "frontEnd.IXCharacter"

-- key: the value stored in ix_character ("random" lets the game pick).
-- select: the stock lobby's characterSelect value for a special character
-- (zombies_loadout::get_player_character_num in the stock scripts).
local characters = {
    { key = "random", label = "Random", text = "The game picks your character, as usual." },
    { key = "sally", label = "Sally", text = "Spaceland: Valley Girl. Rave: Gangster. Shaolin: Disco. Radioactive Thing: Schoolgirl." },
    { key = "poindexter", label = "Poindexter", text = "Spaceland: Nerd. Rave: Raver. Shaolin: Punk. Radioactive Thing: Scientist." },
    { key = "andre", label = "Andre", text = "Spaceland: Rapper. Rave: Grunge. Shaolin: Activist. Radioactive Thing: Soldier." },
    { key = "aj", label = "A.J.", text = "Spaceland: Jock. Rave: Hip-Hop. Shaolin: Sleaze Bag. Radioactive Thing: Rebel." },
    { key = "hoff", label = "The Hoff", select = 1, text = "Special character of Zombies in Spaceland. Needs that map's soul key." },
    { key = "willard", label = "Willard Wyler", select = 5, text = "Special character of Zombies in Spaceland. Needs a win against The Beast from Beyond's final boss." },
    { key = "kevin", label = "Kevin Smith", select = 2, text = "Special character of Rave in the Redwoods. Needs that map's soul key." },
    { key = "pam", label = "Pam Grier", select = 3, text = "Special character of Shaolin Shuffle. Needs that map's soul key." },
    { key = "elvira", label = "Elvira", select = 4, text = "Special character of Attack of the Radioactive Thing. Needs that map's soul key." },
}

local regularNote = " Used in matches you host. When you join someone else's match, the game picks for you."
local specialNote = " Also used when you join someone else's match on that map. Other maps: only if the host sets ix_character_crossmap 1 (experimental)."

local function currentKey()
    local ok, value = pcall(Engine.GetDvarString, "ix_character")
    if not ok or value == nil or value == "" then
        return "random"
    end
    return string.lower(value)
end

local function labelFor(key)
    for i = 1, #characters do
        if characters[i].key == key then
            return characters[i].label
        end
    end
    return key
end

local function describe(character)
    if character.key == "random" then
        return character.text
    end
    if character.select then
        return character.text .. specialNote
    end
    return character.text .. regularNote
end

local function showInfo(element, character)
    local menu = element:GetCurrentMenu()
    if menu and menu.IXInfoTitle and menu.IXInfoText then
        menu.IXInfoTitle:setText(ToUpperCase(character.label))
        menu.IXInfoText:setText(describe(character))
    end
    Engine.PlaySound(CoD.SFX.SPMinimap)
end

local function chooseCharacter(element, character)
    Engine.Exec("seta ix_character " .. character.key)
    -- 0 clears a special picked earlier. iw7-mod's own director_cut setting
    -- writes coop stats the same way: setCoopPlayerData, then uploadstats
    -- (src/client/component/stats.cpp).
    Engine.Exec("setCoopPlayerData zombiePlayerLoadout characterSelect " .. (character.select or 0))
    Engine.Exec("uploadstats")
    local menu = element:GetCurrentMenu()
    if menu and menu.IXSelected then
        menu.IXSelected:setText("Selected: " .. character.label)
    end
    LUI.FlowManager.RequestLeaveMenu(element)
end

local function leaveMenu(element, controllerIndex)
    LUI.FlowManager.RequestLeaveMenu(element)
end

local function fillList(menu, controllerIndex)
    local dataSource = LUI.DataSourceFromList.new(#characters)
    dataSource.MakeDataSourceAtIndex = function(source, index, sourceControllerIndex)
        local character = characters[index + 1]
        return {
            buttonLabel = LUI.DataSourceInGlobalModel.new(modelPath .. ".characters." .. index, character.label),
            buttonOnClickFunction = function(buttonElement, eventArgs)
                chooseCharacter(buttonElement, character)
            end,
            buttonOnHoverFunction = function(buttonElement, eventArgs)
                showInfo(buttonElement, character)
            end,
        }
    end
    menu.IXCharacterList:SetGridDataSource(dataSource, controllerIndex)
end

local function focusFirstRow(menu, controllerIndex)
    local list = menu.IXCharacterList
    if list:getNumChildren() == 0 then
        return
    end
    local offset = list:GetContentOffset(LUI.DIRECTION.vertical)
    list:SetFocusedPosition({ x = 0, y = offset }, true)
    local row = list:GetElementAtPosition(0, offset)
    if row then
        row:processEvent({ name = "gain_focus", controllerIndex = controllerIndex })
    end
end

local function newText(id, size, font, top, bottom)
    local text = LUI.UIStyledText.new()
    text.id = id
    text:setText("", 0)
    text:SetFontSize(size * _1080p)
    text:SetFont(FONTS.GetFont(font))
    text:SetAlignment(LUI.Alignment.Left)
    text:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 1254, _1080p * 1824, _1080p * top, _1080p * bottom)
    return text
end

function IXCharacterMenu(parent, controller)
    local menu = LUI.UIElement.new()
    menu.id = "IXCharacterMenu"

    local controllerIndex = controller and controller.controllerIndex
    if not controllerIndex and not Engine.InFrontend() then
        controllerIndex = menu:getRootController()
    end
    assert(controllerIndex)

    menu:playSound("menu_open")

    local helperBar = MenuBuilder.BuildRegisteredType("ButtonHelperBar", { controllerIndex = controllerIndex })
    helperBar.id = "ButtonHelperBar"
    helperBar:SetAnchorsAndPosition(0, 0, 1, 0, 0, 0, _1080p * -85, 0)
    menu:addElement(helperBar)
    menu.ButtonHelperBar = helperBar

    local title
    if Engine.IsAliensMode() then
        title = MenuBuilder.BuildRegisteredType("CPMenuTitle", { controllerIndex = controllerIndex })
    else
        title = MenuBuilder.BuildRegisteredType("MenuTitle", { controllerIndex = controllerIndex })
        title.MenuBreadcrumbs:setText(ToUpperCase(""), 0)
    end
    title.id = "MenuTitle"
    title.MenuTitle:setText(ToUpperCase("Character"), 0)
    title:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 96, _1080p * 1056, _1080p * 54, _1080p * 134)
    menu:addElement(title)
    menu.MenuTitle = title

    local infoTitle = newText("IXInfoTitle", 30, FONTS.MainMedium.File, 216, 246)
    menu:addElement(infoTitle)
    menu.IXInfoTitle = infoTitle

    local infoText = newText("IXInfoText", 20, FONTS.MainCondensed.File, 252, 352)
    menu:addElement(infoText)
    menu.IXInfoText = infoText

    local list = LUI.UIDataSourceGrid.new(nil, {
        maxVisibleColumns = 1,
        maxVisibleRows = #characters,
        controllerIndex = controllerIndex,
        buildChild = function()
            return MenuBuilder.BuildRegisteredType("ModSelectButton", { controllerIndex = controllerIndex })
        end,
        wrapX = true,
        wrapY = true,
        spacingX = _1080p * 10,
        spacingY = _1080p * 10,
        columnWidth = _1080p * 500,
        rowHeight = _1080p * 30,
        scrollingThresholdX = 1,
        scrollingThresholdY = 1,
        adjustSizeToContent = false,
        horizontalAlignment = LUI.Alignment.Left,
        verticalAlignment = LUI.Alignment.Top,
        springCoefficient = 600,
        maxVelocity = 5000
    })
    list.id = "IXCharacterList"
    list:setUseStencil(false)
    list:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 130, _1080p * 630, _1080p * 216, _1080p * 886)
    menu:addElement(list)
    menu.IXCharacterList = list

    local selected = LUI.UIText.new()
    selected.id = "IXSelected"
    selected:setText("Selected: " .. labelFor(currentKey()), 0)
    selected:SetFontSize(20 * _1080p)
    selected:SetFont(FONTS.GetFont(FONTS.MainBold.File))
    selected:SetAlignment(LUI.Alignment.Left)
    selected:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * 130, _1080p * 630, _1080p * 942, _1080p * 966)
    menu:addElement(selected)
    menu.IXSelected = selected

    menu.addButtonHelperFunction = function(element, eventArgs)
        element:AddButtonHelperText({
            helper_text = Engine.Localize("MENU_BACK"),
            button_ref = "button_secondary",
            side = "left",
            clickable = true
        })
    end
    menu:addEventHandler("menu_create", menu.addButtonHelperFunction)

    local bindButton = LUI.UIBindButton.new()
    bindButton.id = "selfBindButton"
    menu:addElement(bindButton)
    menu.bindButton = bindButton
    bindButton:addEventHandler("button_secondary", leaveMenu)

    fillList(menu, controllerIndex)
    menu:addEventHandler("gain_focus", function(element, eventControllerIndex)
        focusFirstRow(element, controllerIndex)
    end)

    local blur = LUI.UIElement.new({ worldBlur = 5 })
    blur:setupWorldBlur()
    blur.id = "blur"
    menu:addElement(blur)

    return menu
end

MenuBuilder.registerType("IXCharacterMenu", IXCharacterMenu)
LUI.FlowManager.RegisterStackPopBehaviour("IXCharacterMenu", function()
    WipeGlobalModelsAtPath(modelPath)
end)

-- The zombies main menu's button list: add CHARACTER under the last button and
-- move the description line below it.
--
-- iw7-mod replaces the stock list with its own (MainMenu/CPMainMenuButtons.lua
-- assigns MenuBuilder.m_types["CPMainMenuButtons"]). Whether that script runs
-- before or after this one depends on the install: iw7-mod searches
-- <game>/iw7-mod/ before its own scripts, and a Mods-menu folder after them
-- (filesystem.cpp). So the button is added when the list is built, whichever
-- script registered it last, and only once.
local function addCharacterButton(navigator, controller)
    if not navigator or navigator.IXCharacterButton then
        return
    end

    local controllerIndex = controller and controller.controllerIndex
    if not controllerIndex then
        controllerIndex = navigator:getRootController()
    end

    local button = MenuBuilder.BuildRegisteredType("MenuButton", { controllerIndex = controllerIndex })
    button.id = "IXCharacterButton"
    button.buttonDescription = "Choose who you play as. Unlocked special characters also follow you into other players' matches."
    button.Text:setText(ToUpperCase("Character"), 0)
    button:SetAnchorsAndPosition(0, 1, 0, 1, 0, _1080p * 340, _1080p * 350, _1080p * 380)
    navigator:addElement(button)
    navigator.IXCharacterButton = button

    if navigator.ButtonDescription then
        navigator.ButtonDescription:SetAnchorsAndPosition(0, 0, 0, 1, 0, 0, _1080p * 390, _1080p * 448)
    end
    navigator:SetAnchorsAndPosition(0, 1, 0, 1, 0, 500 * _1080p, 0, 460 * _1080p)

    button:addEventHandler("button_action", function(element, eventArgs)
        LUI.FlowManager.RequestAddMenu("IXCharacterMenu", true, eventArgs.controller, false)
    end)
end

-- Builders this file has wrapped, so that each is wrapped once.
local wrappedBuilders = {}

local function wrapButtonList()
    local builder = MenuBuilder.m_types["CPMainMenuButtons"]
    if not builder or wrappedBuilders[builder] then
        return
    end
    local wrapper = function(menu, controller)
        local navigator = builder(menu, controller)
        addCharacterButton(navigator, controller)
        return navigator
    end
    wrappedBuilders[wrapper] = true
    MenuBuilder.m_types["CPMainMenuButtons"] = wrapper
end

-- Loaded after iw7-mod's scripts (Mods-menu install): its list is registered now.
wrapButtonList()

-- Loaded before them (<game>/iw7-mod/ install): every menu is built after all
-- scripts have loaded, so wrap whatever list is registered then, and decorate a
-- list built by name in case the stock menu builds it that way.
local BuildRegisteredType_original = MenuBuilder.BuildRegisteredType
MenuBuilder.BuildRegisteredType = function(typeName, controller, ...)
    wrapButtonList()
    local element = BuildRegisteredType_original(typeName, controller, ...)
    if typeName == "CPMainMenuButtons" then
        addCharacterButton(element, controller)
    end
    return element
end

-- iw7-mod names every player "Unknown Soldier" until the name setting is
-- changed (component/patches.cpp). The Windows setup writes the player's Steam
-- name next to this file (installer/IXSetup.Core.ps1); use it, but only while
-- the name is still that default, so a name the player chose stays.
local steamNameFile = "iw7-mod/ui_scripts/InfiniteExpansion/steam-name.txt"

local function applySteamName()
    if not io.fileexists(steamNameFile) then
        return
    end
    local ok, current = pcall(Engine.GetDvarString, "name")
    if not ok or (current ~= nil and current ~= "" and current ~= "Unknown Soldier") then
        return
    end
    local name = io.readfile(steamNameFile)
    if not name then
        return
    end
    name = string.gsub(name, "[%c\"\\;%%%^]", "")
    name = string.match(name, "^%s*(.-)%s*$")
    if name ~= "" then
        Engine.SetDvarString("name", name)
    end
end

pcall(applySteamName)
