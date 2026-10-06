-- Infinite Expansion - CHARACTER button in the zombies lobby.
--
-- Adds a base-game style CHARACTER button to the lobby that Solo Match and
-- Custom Game open (CPPrivateMatchMenu), right under SELECT SHOW. It opens a
-- character list with a picture of the highlighted character. The choice is
-- made here, before a match, and lasts the whole match. It is saved in two
-- places:
--   - the archived dvar ix_character, which the mod's GSC applies when this
--     player hosts a zombies match (custom_scripts/ix/player/character.gsc);
--   - for a special character, also the stock lobby field characterSelect in
--     the player's own stats, which travel with the player into other
--     players' matches. Regular characters have no lobby value, so in someone
--     else's match the game picks one at random (KNOWN_LIMITATIONS.md L29).
--
-- Widgets and calls are the ones iw7-mod's own ui_scripts use:
--   MainMenu/CPMainMenuButtons.lua   the "MenuButton" type and button layout
--   Mods/ModSelectMenu.lua           list menus, "ModSelectButton" rows, text
--   Lobby/LobbyMissionButtons.lua    adding a button to a stock button list
--   MainMenu/MPMainMenuButtons.lua   moving stock elements (getLocalRect)
--   Stats/__init__.lua               zombies stats (CoD.StatsGroup.Coop)
-- The stock lobby's layout, element names and rules come from the game's own
-- ui/frontend/cp/cpprivatematchbuttons.lua and cpprivatematchmenu.lua
-- (IW_API_NOTES.md section 16).

if not Engine.InFrontend() then
    return
end

local modelPath = "frontEnd.IXCharacter"

-- key: the value stored in ix_character ("random" lets the game pick).
-- color, initials: the picture for characters the game has no picture of
-- (the player card in custom_scripts/ix/ui/player_card.gsc uses the same colors).
-- select: the stock lobby's characterSelect value for a special character.
-- soulKey, merit: the zombies stats the stock lobby requires before it sets
-- characterSelect (cpprivatematchmenu.lua; KNOWN_LIMITATIONS.md L27).
-- portrait: the stock lobby's picture of a special character; tall pictures
-- are half as wide as they are high, The Hoff's is square.
local characters = {
    { key = "random", label = "Random", initials = "?", color = 0xC8C8C8,
      text = "The game picks your character, as usual." },
    { key = "sally", label = "Sally", initials = "S", color = 0xFF73B3,
      text = "Spaceland: Valley Girl. Rave: Gangster. Shaolin: Disco. Radioactive Thing: Schoolgirl." },
    { key = "poindexter", label = "Poindexter", initials = "P", color = 0x59A6FF,
      text = "Spaceland: Nerd. Rave: Raver. Shaolin: Punk. Radioactive Thing: Scientist." },
    { key = "andre", label = "Andre", initials = "A", color = 0xFF9933,
      text = "Spaceland: Rapper. Rave: Grunge. Shaolin: Activist. Radioactive Thing: Soldier." },
    { key = "aj", label = "A.J.", initials = "AJ", color = 0x73E659,
      text = "Spaceland: Jock. Rave: Hip-Hop. Shaolin: Sleaze Bag. Radioactive Thing: Rebel." },
    { key = "hoff", label = "The Hoff", select = 1, home = "Zombies in Spaceland", soulKey = "soul_key_1",
      portrait = "zm_character_select_hoff", square = true, initials = "H", color = 0xFFD14D,
      text = "Special character of Zombies in Spaceland." },
    { key = "willard", label = "Willard Wyler", select = 5, home = "Zombies in Spaceland", soulKey = "soul_key_5",
      merit = "mt_dlc4_troll2", portrait = "zm_character_willard", initials = "W", color = 0xFFD14D,
      text = "Special character of Zombies in Spaceland, earned in The Beast from Beyond." },
    { key = "kevin", label = "Kevin Smith", select = 2, home = "Rave in the Redwoods", soulKey = "soul_key_2",
      portrait = "zm_character_select_smith", initials = "K", color = 0xFFD14D,
      text = "Special character of Rave in the Redwoods." },
    { key = "pam", label = "Pam Grier", select = 3, home = "Shaolin Shuffle", soulKey = "soul_key_3",
      portrait = "zm_character_select_pam", initials = "P", color = 0xFFD14D,
      text = "Special character of Shaolin Shuffle." },
    { key = "elvira", label = "Elvira", select = 4, home = "Attack of the Radioactive Thing", soulKey = "soul_key_4",
      portrait = "zm_character_select_elvira", initials = "E", color = 0xFFD14D,
      text = "Special character of Attack of the Radioactive Thing." },
}

local regularNote = " Used in matches you host. When you join someone else's match, the game picks for you."
local specialNote = " Also used when you join someone else's match on that map. Other maps: only if the host sets ix_character_crossmap 1 (experimental)."

local statusColors = { regular = 0xC8C8C8, special = 0xFFD14D, locked = 0xFF6464 }

local function currentKey()
    local ok, value = pcall(Engine.GetDvarString, "ix_character")
    if not ok or value == nil or value == "" then
        return "random"
    end
    return string.lower(value)
end

local function characterFor(key)
    for i = 1, #characters do
        if characters[i].key == key then
            return characters[i]
        end
    end
    return nil
end

local function labelFor(key)
    local character = characterFor(key)
    return character and character.label or key
end

-- ix_character_specials, as the GSC reads it: unset = 1 (unlocked ones only).
local function specialsMode()
    local ok, value = pcall(Engine.GetDvarString, "ix_character_specials")
    if not ok or value == nil or value == "" then
        return 1
    end
    return tonumber(value) or 1
end

-- A zombies stat of this player, or nil when it cannot be read.
local function coopStat(controllerIndex, ...)
    local ok, value = pcall(Engine.GetPlayerDataEx, controllerIndex, CoD.StatsGroup.Coop, ...)
    if ok then
        return value
    end
    return nil
end

local function isSet(value)
    return value == true or (type(value) == "number" and value > 0)
end

-- true or false, or nil when the stats cannot be read (the GSC still checks).
local function isUnlocked(character, controllerIndex)
    local soulKey = coopStat(controllerIndex, "haveSoulKeys", character.soulKey)
    if soulKey == nil then
        return nil
    end
    if not isSet(soulKey) then
        return false
    end
    if character.merit then
        local merit = coopStat(controllerIndex, "meritState", character.merit)
        if merit == nil then
            return nil
        end
        return isSet(merit)
    end
    return true
end

-- Why this player cannot choose the character, or nil if they can.
local function unavailableReason(character, controllerIndex)
    if not character.select then
        return nil
    end
    local mode = specialsMode()
    if mode == 0 then
        return "Special characters are off (ix_character_specials 0)."
    end
    if mode >= 2 or isUnlocked(character, controllerIndex) ~= false then
        return nil
    end
    if character.merit then
        return "Locked: beat the final boss of The Beast from Beyond."
    end
    return "Locked: earn the soul key on " .. character.home .. "."
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

-- Character pictures from the matches' own HUD cards, when the player built
-- them with "Build Character Pictures" (installer/IXPictures.ps1): the zone
-- iw7-mod/zone/ix_portraits.ff, and next to it the list of cards it holds. The
-- game's menus can only draw pictures from a loaded zone, and the cards are
-- otherwise only in each map's own zone (KNOWN_LIMITATIONS.md L28). iw7-mod's
-- loadzone keeps a zone loaded for the rest of the session and does not check
-- whether it already is (fastfiles.cpp), so it is loaded once per session
-- (ix_pictures_loaded). ix_pictures 0 turns the pictures off.
local pictureZone = "ix_portraits"
local pictureList = "iw7-mod/zone/ix_portraits.txt"
local packedPictures = {}

local function loadPictures()
    local ok, setting = pcall(Engine.GetDvarString, "ix_pictures")
    if ok and setting == "0" then
        return
    end
    if not io.fileexists(pictureList) or not io.zoneexists(pictureZone) then
        return
    end
    for name in string.gmatch(io.readfile(pictureList) or "", "[%w_]+") do
        packedPictures[name] = true
    end
    local _, loaded = pcall(Engine.GetDvarString, "ix_pictures_loaded")
    if loaded ~= "1" then
        Engine.Exec("loadzone " .. pictureZone)
        Engine.Exec("set ix_pictures_loaded 1")
    end
end

pcall(loadPictures)

-- The map the lobby has selected, as the pack names it.
local mapKeys = { cp_zmb = "zmb", cp_rave = "rave", cp_disco = "disco", cp_town = "town", cp_final = "final" }

local function selectedMapKey()
    local ok, map = pcall(Engine.GetDvarString, "ui_mapname")
    return ok and mapKeys[map] or "zmb"
end

-- A picture from the pack: prefix "ix_card_" for the main card, "ix_icon_"
-- for the team card (the small picture the HUD shows for each teammate). A
-- special character's picture comes from their own map, a regular
-- character's from the selected map. nil if the pack does not have it.
local function packedPicture(prefix, character)
    local name
    if character.select then
        name = prefix .. character.key
    elseif character.key ~= "random" then
        name = prefix .. selectedMapKey() .. "_" .. character.key
    end
    if name and packedPictures[name] then
        return name
    end
    return nil
end

-- The picture: the character's main card from the pack, else a special
-- character's own menu picture, else the team card from the pack, else the
-- initials on a dark panel in the character's color (the four regular
-- characters and Random have no picture in the game's menus). Main cards are
-- 256 x 371 and team cards square (the HUD draws them 128 x 128,
-- ui/ingame/cp/cpplayerinfo.lua); the game's menu pictures are half as wide as
-- high (The Hoff's is square).
local portraitLeft, portraitTop, portraitSize = 1254, 216, 360
local cardWidth = math.floor(portraitSize * 256 / 371)
local iconSize = 256
local listLeft, listTop, rowHeight, rowSpacing = 130, 216, 30, 10

local function showPortrait(menu, character)
    menu.IXPortraitEdge:SetRGBFromInt(character.color, 0)
    local material, width, height = packedPicture("ix_card_", character), cardWidth, portraitSize
    if not material and character.portrait then
        material, width = character.portrait, character.square and portraitSize or portraitSize / 2
    elseif not material then
        material, width, height = packedPicture("ix_icon_", character), iconSize, iconSize
    end
    if material then
        local left = portraitLeft + (portraitSize - width) / 2
        local top = portraitTop + (portraitSize - height) / 2
        menu.IXPortrait:setImage(RegisterMaterial(material), 0)
        menu.IXPortrait:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * left, _1080p * (left + width),
            _1080p * top, _1080p * (top + height))
        menu.IXPortrait:SetAlpha(1, 0)
        menu.IXInitials:SetAlpha(0, 0)
    else
        menu.IXPortrait:SetAlpha(0, 0)
        menu.IXInitials:setText(character.initials, 0)
        menu.IXInitials:SetRGBFromInt(character.color, 0)
        menu.IXInitials:SetAlpha(1, 0)
    end
end

local function showInfo(menu, character)
    local reason = unavailableReason(character, menu.IXControllerIndex)
    local status, color = "", statusColors.regular
    if reason then
        status, color = reason, statusColors.locked
    elseif character.select then
        status, color = "Special character", statusColors.special
    elseif character.key ~= "random" then
        status = "Regular character"
    end
    menu.IXInfoTitle:setText(ToUpperCase(character.label), 0)
    menu.IXInfoStatus:setText(status, 0)
    menu.IXInfoStatus:SetRGBFromInt(color, 0)
    menu.IXInfoText:setText(describe(character), 0)
    showPortrait(menu, character)
end

local function onHover(element, character)
    local menu = element:GetCurrentMenu()
    if menu and menu.IXInfoTitle then
        showInfo(menu, character)
    end
    Engine.PlaySound(CoD.SFX.SPMinimap)
end

local function writeLobbyField(value)
    -- iw7-mod writes coop stats the same way: setCoopPlayerData, then
    -- uploadstats (src/client/component/stats.cpp).
    Engine.Exec("setCoopPlayerData zombiePlayerLoadout characterSelect " .. value)
    Engine.Exec("uploadstats")
end

local function chooseCharacter(element, character)
    local menu = element:GetCurrentMenu()
    if menu and menu.IXInfoTitle and unavailableReason(character, menu.IXControllerIndex) then
        -- Locked: the status line already says why; stay in the list.
        showInfo(menu, character)
        return
    end
    Engine.Exec("seta ix_character " .. character.key)
    -- 0 clears a special character chosen earlier.
    writeLobbyField(character.select or 0)
    if menu and menu.IXSelected then
        menu.IXSelected:setText("Selected: " .. character.label, 0)
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
        local label = character.label
        if unavailableReason(character, controllerIndex) then
            label = label .. " (locked)"
        end
        return {
            buttonLabel = LUI.DataSourceInGlobalModel.new(modelPath .. ".characters." .. index, label),
            buttonOnClickFunction = function(buttonElement, eventArgs)
                chooseCharacter(buttonElement, character)
            end,
            buttonOnHoverFunction = function(buttonElement, eventArgs)
                onHover(buttonElement, character)
            end,
        }
    end
    menu.IXCharacterList:SetGridDataSource(dataSource, controllerIndex)
end

-- Focuses the row of the character chosen now (the first row if none).
local function focusChosenRow(menu, controllerIndex)
    local list = menu.IXCharacterList
    if list:getNumChildren() == 0 then
        return
    end
    local row, key = 0, currentKey()
    for i = 1, #characters do
        if characters[i].key == key then
            row = i - 1
        end
    end
    local offset = list:GetContentOffset(LUI.DIRECTION.vertical)
    list:SetFocusedPosition({ x = 0, y = offset + row }, true)
    local element = list:GetElementAtPosition(0, offset + row)
    if element then
        element:processEvent({ name = "gain_focus", controllerIndex = controllerIndex })
    end
end

-- Text in IW7's menus is as tall as its element: top to bottom is the font
-- size, and longer text wraps downwards below it (Mods/ModSelectMenu.lua).
local function newText(id, size, font, left, right, top, alignment)
    local text = LUI.UIStyledText.new()
    text.id = id
    text:setText("", 0)
    text:SetFontSize(size * _1080p)
    text:SetFont(FONTS.GetFont(font))
    text:SetAlignment(alignment or LUI.Alignment.Left)
    text:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * left, _1080p * right, _1080p * top, _1080p * (top + size))
    return text
end

local function newPanel(id, color, alpha, left, right, top, bottom)
    local panel = LUI.UIImage.new()
    panel.id = id
    panel:setImage(RegisterMaterial("white"), 0)
    panel:SetRGBFromInt(color, 0)
    panel:SetAlpha(alpha, 0)
    panel:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * left, _1080p * right, _1080p * top, _1080p * bottom)
    return panel
end

function IXCharacterMenu(parent, controller)
    local menu = LUI.UIElement.new()
    menu.id = "IXCharacterMenu"

    local controllerIndex = controller and controller.controllerIndex
    if not controllerIndex and not Engine.InFrontend() then
        controllerIndex = menu:getRootController()
    end
    assert(controllerIndex)
    menu.IXControllerIndex = controllerIndex

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

    -- Right side: picture, name, status line and description.
    local right = portraitLeft + 570
    local backdrop = newPanel("IXPortraitBackdrop", 0x000000, 0.45, portraitLeft, portraitLeft + portraitSize,
        portraitTop, portraitTop + portraitSize)
    menu:addElement(backdrop)

    local edge = newPanel("IXPortraitEdge", 0xC8C8C8, 1, portraitLeft - 6, portraitLeft,
        portraitTop, portraitTop + portraitSize)
    menu:addElement(edge)
    menu.IXPortraitEdge = edge

    local initials = newText("IXInitials", 160, FONTS.MainMedium.File, portraitLeft, portraitLeft + portraitSize,
        portraitTop + (portraitSize - 160) / 2, LUI.Alignment.Center)
    menu:addElement(initials)
    menu.IXInitials = initials

    local portrait = LUI.UIImage.new()
    portrait.id = "IXPortrait"
    portrait:SetAlpha(0, 0)
    menu:addElement(portrait)
    menu.IXPortrait = portrait

    local infoTitle = newText("IXInfoTitle", 44, FONTS.MainMedium.File, portraitLeft, right, portraitTop + portraitSize + 20)
    menu:addElement(infoTitle)
    menu.IXInfoTitle = infoTitle

    local infoStatus = newText("IXInfoStatus", 22, FONTS.MainBold.File, portraitLeft, right, portraitTop + portraitSize + 76)
    menu:addElement(infoStatus)
    menu.IXInfoStatus = infoStatus

    local infoText = newText("IXInfoText", 22, FONTS.MainCondensed.File, portraitLeft, right, portraitTop + portraitSize + 112)
    menu:addElement(infoText)
    menu.IXInfoText = infoText

    -- Left side: the list, every row visible (it never scrolls).
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
        spacingY = _1080p * rowSpacing,
        columnWidth = _1080p * 500,
        rowHeight = _1080p * rowHeight,
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
    list:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * listLeft, _1080p * (listLeft + 500), _1080p * listTop, _1080p * 886)
    menu:addElement(list)
    menu.IXCharacterList = list

    -- Each row's team card from the pack, left of the row, like the HUD shows
    -- teammates. Rows are rowHeight tall and rowSpacing apart from the top.
    menu.IXRowIcons = {}
    for i = 1, #characters do
        local icon = packedPicture("ix_icon_", characters[i])
        if icon then
            local top = listTop + (i - 1) * (rowHeight + rowSpacing)
            local image = LUI.UIImage.new()
            image.id = "IXRowIcon" .. i
            image:setImage(RegisterMaterial(icon), 0)
            image:SetAnchorsAndPosition(0, 1, 0, 1, _1080p * (listLeft - rowHeight - 8), _1080p * (listLeft - 8),
                _1080p * top, _1080p * (top + rowHeight))
            menu:addElement(image)
            menu.IXRowIcons[i] = image
        end
    end

    local selected = newText("IXSelected", 24, FONTS.MainBold.File, 130, 630, 640)
    selected:setText("Selected: " .. labelFor(currentKey()), 0)
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

    showInfo(menu, characterFor(currentKey()) or characters[1])
    fillList(menu, controllerIndex)
    menu:addEventHandler("gain_focus", function(element, eventControllerIndex)
        focusChosenRow(element, controllerIndex)
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

-- The lobby that Solo Match and Custom Game open (CPPrivateMatchMenu, see
-- iw7-mod's MainMenu/CPMainMenuButtons.lua) builds its buttons as
-- CPPrivateMatchButtons, a vertical navigator of MenuButtons 40 pixels apart:
-- START GAME 0-30, LOADOUT 40-70, BARRACKS 80-110, SELECT SHOW (ChooseMap)
-- 120-150, then BOSS BATTLE (only when boss battles are on), TUTORIAL (Tips),
-- SURVIVAL DEPOT (Armory), a spacer, the CONTRACTS widget and the description
-- line. CHARACTER goes under SELECT SHOW and everything below it moves down one
-- step. The stock list places those elements again when it switches between
-- its "boss battle on/off" layouts, so each of them keeps the offset for every
-- later placement too.
local lobbyStep = 40
local lobbyElementsBelow = { "BossBattle", "Tips", "Armory", "ForSpacing", "ContractsButton", "ButtonDescription" }

local function moveDown(element, offset)
    if not element or element.IXMovedDown then
        return
    end
    element.IXMovedDown = offset
    local setAnchorsAndPosition = element.SetAnchorsAndPosition
    element.SetAnchorsAndPosition = function(self, leftAnchor, rightAnchor, topAnchor, bottomAnchor, left, right, top, bottom, ...)
        if top and bottom then
            top, bottom = top + offset, bottom + offset
        end
        return setAnchorsAndPosition(self, leftAnchor, rightAnchor, topAnchor, bottomAnchor, left, right, top, bottom, ...)
    end
    local _, top, _, bottom = element:getLocalRect()
    element:SetTop(top + offset, 0)
    element:SetBottom(bottom + offset, 0)
end

local function addLobbyCharacterButton(navigator, controller)
    if not navigator or navigator.IXCharacterButton or not navigator.ChooseMap then
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
    navigator.IXCharacterButton = button

    local _, _, _, showBottom = navigator.ChooseMap:getLocalRect()
    for _, id in ipairs(lobbyElementsBelow) do
        moveDown(navigator[id], lobbyStep * _1080p)
    end
    button:SetAnchorsAndPosition(0, 1, 0, 1, 0, _1080p * 340, showBottom + 10 * _1080p, showBottom + lobbyStep * _1080p)

    -- Right after SELECT SHOW in the list's own order too.
    local nextButton = navigator.BossBattle or navigator.Tips
    if nextButton then
        LUI.UIElement.addElementBefore(button, nextButton)
    else
        navigator:addElement(button)
    end

    button:addEventHandler("button_action", function(element, eventArgs)
        LUI.FlowManager.RequestAddMenu("IXCharacterMenu", true, eventArgs.controller, false)
    end)
end

-- The stock lobby sets characterSelect to 0 every time it opens
-- (cpprivatematchmenu.lua). Put back the special character chosen here, while
-- it is still available, so it follows the player into the match.
local function restoreLobbyField(controllerIndex)
    local character = characterFor(currentKey())
    if character and character.select and not unavailableReason(character, controllerIndex) then
        writeLobbyField(character.select)
    end
end

local function onLobbyBuilt(menu, controller)
    if not menu or menu.IXLobbyFieldRestored then
        return
    end
    menu.IXLobbyFieldRestored = true
    local controllerIndex = controller and controller.controllerIndex
    if not controllerIndex then
        controllerIndex = menu:getRootController()
    end
    restoreLobbyField(controllerIndex)
    -- Again once the menu is up, in case the stock reset runs then.
    menu:addEventHandler("menu_create", function(element, eventArgs)
        restoreLobbyField(controllerIndex)
    end)
end

local lobbyDecorators = {
    CPPrivateMatchButtons = addLobbyCharacterButton,
    CPPrivateMatchMenu = onLobbyBuilt,
}

-- Never let this file break the stock lobby: if the lobby is not built the way
-- it is expected to be, it is left as it is.
local function decorate(typeName, element, controller)
    pcall(lobbyDecorators[typeName], element, controller)
end

-- The stock lobby types may be registered before or after this file runs, and
-- built by name or through MenuBuilder.m_types, so both are covered, once.
local wrappedBuilders = {}

local function wrapBuilder(typeName, builder)
    if not builder or wrappedBuilders[builder] then
        return builder
    end
    local wrapper = function(menu, controller, ...)
        local element = builder(menu, controller, ...)
        decorate(typeName, element, controller)
        return element
    end
    wrappedBuilders[wrapper] = true
    return wrapper
end

local function wrapRegistered()
    for typeName in pairs(lobbyDecorators) do
        local builder = MenuBuilder.m_types[typeName]
        if builder and not wrappedBuilders[builder] then
            MenuBuilder.m_types[typeName] = wrapBuilder(typeName, builder)
        end
    end
end

wrapRegistered()

local registerType_original = MenuBuilder.registerType
MenuBuilder.registerType = function(typeName, builder, ...)
    if lobbyDecorators[typeName] then
        builder = wrapBuilder(typeName, builder)
    end
    return registerType_original(typeName, builder, ...)
end

local BuildRegisteredType_original = MenuBuilder.BuildRegisteredType
MenuBuilder.BuildRegisteredType = function(typeName, controller, ...)
    wrapRegistered()
    local element = BuildRegisteredType_original(typeName, controller, ...)
    if lobbyDecorators[typeName] then
        decorate(typeName, element, controller)
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
